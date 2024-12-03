#!env python3
import os
import re
import requests
import subprocess
from bs4 import BeautifulSoup

# Step 0: switch to root of repo
git_root = subprocess.check_output(
    ['git', 'rev-parse', '--show-toplevel'],
    universal_newlines=True
).strip()
os.chdir(git_root)

# Step 1: Determine the Go version from the file `./package/go/go.mk`
go_version = None
with open('./package/go/go.mk', 'r') as file:
    for line in file:
        match = re.match(r'^GO_VERSION\s*=\s*(\S+)', line)
        if match:
            go_version = match.group(1)
            break

if not go_version:
    print("Go version not found in go.mk file.")
    exit(1)

# Step 2: Download the latest version release description page
url = 'https://go.dev/doc/devel/release'
response = requests.get(url)
if response.status_code != 200:
    print("Failed to download release description page.")
    exit(1)

# Step 3: Extract the version description for the current Go version
soup = BeautifulSoup(response.text, 'html.parser')
version_div = soup.find(id = f'go{go_version}')
if not version_div:
    print(f"Version description for Go {go_version} not found.")
    exit(1)
version_description = ' '.join(version_div.text.split())
version_description = re.sub(f'See the Go {go_version} milestone on our issue tracker for details\.', '', version_description)
version_description = version_description.strip()

# Step 4: Write the commit message following the format shown above
# commit_message = f"""package/go: security bump to version {go_version}
commit_message = f"""package/go: bump to version {go_version}

{version_description}

https://go.dev/doc/devel/release#go{go_version}
https://github.com/golang/go/issues?q=milestone%3AGo{go_version}+label%3ACherryPickApproved

Signed-off-by: Christian Stewart <christian@aperture.us>
"""

print(commit_message.strip())
