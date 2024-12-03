#!env python3
import json
import sys
import requests
import re
import os

use_version = ""
if len(sys.argv) > 1:
    use_version = sys.argv[1]
    print(f"Using version from command line: {use_version}")

# Get the latest Go version and its hash
print("Downloading Go version information...")
url = "https://go.dev/dl/?mode=json"
response = requests.get(url)
data = json.loads(response.text)

if use_version:
    selected_version = next((item for item in data if item["version"] == use_version), None)
    if selected_version:
        print(f"Using specified version: {use_version}")
        version_info = selected_version
    else:
        print(f"Error: Specified version {use_version} not found.")
        sys.exit(1)
else:
    version_info = data[0]
    print(f"Using latest version: {version_info['version']}")

selected_version = version_info["version"]
src_file = [f for f in version_info["files"] if f["kind"] == "source"][0]
selected_hash = src_file["sha256"]

print(f"Selected version is {selected_version}")

# Update go.mk
go_mk_path = "package/go/go.mk"
with open(go_mk_path, "r") as file:
    go_mk_content = file.read()

selected_version_br = selected_version.lstrip('go')
go_mk_content = re.sub(r"GO_VERSION = .+", f"GO_VERSION = {selected_version_br}", go_mk_content)

with open(go_mk_path, "w") as file:
    file.write(go_mk_content)

# Update go.hash
go_hash_path = "package/go/go-src/go-src.hash"
with open(go_hash_path, "r") as file:
    go_hash_content = file.read()

go_hash_content = re.sub(r"sha256\s+\w+\s+go\d+\.\d+(\.\d+)?\.src\.tar\.gz",
                         f"sha256  {selected_hash}  {src_file['filename']}", go_hash_content)

with open(go_hash_path, "w") as file:
    file.write(go_hash_content)

print(f"Updated {go_hash_path} with Go version: {selected_version}")

# Update go-bin.hash
go_bin_hash_path = "package/go/go-bin/go-bin.hash"
with open(go_bin_hash_path, "r") as file:
    go_bin_hash_lines = file.readlines()

updated_go_bin_hash_lines = []
for line in go_bin_hash_lines:
    if line.strip().startswith('sha256') and 'LICENSE' not in line:
        parts = line.strip().split()
        if len(parts) >= 3:
            old_hash = parts[1]
            old_filename = parts[2]

            # Extract old version from filename
            old_version_pattern = r'go\d+\.\d+(\.\d+)?'
            match = re.search(old_version_pattern, old_filename)
            if match:
                old_version_str = match.group()
                new_filename = old_filename.replace(old_version_str, selected_version)

                # Find the corresponding file in version_info
                file_entry = next((f for f in version_info["files"] if f["filename"] == new_filename), None)
                if file_entry:
                    new_hash = file_entry["sha256"]
                    updated_line = f"sha256  {new_hash}  {new_filename}\n"
                else:
                    print(f"Error: File {new_filename} not found in version info.")
                    sys.exit(1)
            else:
                print(f"Error: Could not extract version from filename {old_filename}")
                sys.exit(1)
        else:
            updated_line = line
    else:
        updated_line = line
    updated_go_bin_hash_lines.append(updated_line)

with open(go_bin_hash_path, "w") as file:
    file.writelines(updated_go_bin_hash_lines)

print(f"Updated {go_bin_hash_path} with Go version: {selected_version}")
print("Buildroot files updated successfully.")
