#!env python3

import os
import re
import sys
import requests
import subprocess
from github import Github


def drop_version_prefix(site, version):
    version_pattern = re.compile(r"\(call (.+),(.+),(.+),(.+)\)")
    version_match = version_pattern.search(site)
    old_version_dl = version_match.group(4)

    # if we add a "v" prefix to the download filename, strip it from VERSION
    if old_version_dl.startswith("v") and version.startswith("v"):
        version = version[1:]

    return version

def add_version_prefix(site, version):
    version_pattern = re.compile(r"\(call (.+),(.+),(.+),(.+)\)")
    version_match = version_pattern.search(site)
    old_version_dl = version_match.group(4)

    # if we add a "v" prefix to the download filename, strip it from VERSION
    if old_version_dl.startswith("v") and not version.startswith("v"):
        version = "v" + version

    return version

def get_package_info(package_name):
    mk_path = f"./package/{package_name}/{package_name}.mk"
    with open(mk_path, "r") as mk_file:
        mk_content = mk_file.read()
        package_name_upper = package_name.upper().replace("-", "_")
        version_pattern = re.compile(rf"{package_name_upper}_VERSION\s*=\s*(.+)")
        site_pattern = re.compile(rf"{package_name_upper}_SITE\s*=\s*(.+)")

        version = version_pattern.search(mk_content).group(1)
        site = site_pattern.search(mk_content).group(1)
        version = add_version_prefix(site, version)

    return version, site


def get_latest_version(site, force_version=None):
    github_pattern = re.compile(r"call github,(.+),(.+),")
    github_match = github_pattern.search(site)
    if not github_match:
        print("This script only works on GitHub packages.")
        os.exit(1)

    github_repo = github_match.group(1) + "/" + github_match.group(2)

    latest_version = force_version
    if not latest_version:
        gh = Github()
        repo = gh.get_repo(github_repo)
        latest_release = repo.get_latest_release()
        latest_version = latest_release.tag_name

    return github_repo, latest_version


def update_mk_file(package_name, site, new_version):
    mk_path = f"./package/{package_name}/{package_name}.mk"
    package_name_upper = package_name.upper().replace("-", "_")
    with open(mk_path, "r") as mk_file:
        mk_content = mk_file.read()

    new_version = drop_version_prefix(site, new_version)
    site_pattern = re.compile(rf"{package_name_upper}_SITE\s*=\s*(.+)")
    site = site_pattern.search(mk_content).group(1)

    version_pattern = re.compile(
        rf"{package_name.upper().replace('-', '_')}_VERSION\s*=\s*(.+)"
    )
    new_mk_content = version_pattern.sub(
        rf"{package_name.upper().replace('-', '_')}_VERSION = {new_version}", mk_content
    )

    with open(mk_path, "w") as mk_file:
        mk_file.write(new_mk_content)


def download_and_update_hash(package_name, site, github_repo, new_version):
    hash_path = f"./package/{package_name}/{package_name}.hash"
    with open(hash_path, "r") as hash_file:
        hash_content = hash_file.read()

    new_version = drop_version_prefix(site, new_version)
    tar_path = f"dl/{package_name}/{package_name}-{new_version}.tar.gz"

    tar_dir = os.path.dirname(tar_path)
    if not os.path.exists(tar_dir):
        os.makedirs(tar_dir)

    # tar_url = f"https://github.com/{github_repo}/archive/refs/tags/{new_version}.tar.gz"
    tar_url = f"https://github.com/{github_repo}/archive/v{new_version}/{package_name}-{new_version}.tar.gz"
    tar_file = requests.get(tar_url)
    with open(tar_path, "wb") as f:
        f.write(tar_file.content)

    sha256_hash = os.popen(f"sha256sum {tar_path}").read().split()[0]

    # os.remove(f"{package_name}-{new_version}.tar.gz")

    hash_pattern = re.compile(r"sha256\s+(\w+)\s+" + package_name + r"-(.+?).tar.gz")
    new_hash_content = hash_pattern.sub(
        rf"sha256  {sha256_hash}  {package_name}-{new_version}.tar.gz", hash_content
    )

    with open(hash_path, "w") as hash_file:
        hash_file.write(new_hash_content)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python update_buildroot_package.py <package_name>")
        sys.exit(1)

    package_name = sys.argv[1]
    force_version = None
    if len(sys.argv) >= 3:
        force_version = sys.argv[2]

    current_version, site = get_package_info(package_name)
    print(f"Package version: {current_version}")
    print(f"Package site: {site}")

    github_repo, latest_version = get_latest_version(site, force_version)
    print(f"Looked up latest version: {latest_version}")

    if current_version == latest_version:
        print(
            f"The package {package_name} is already at the latest version {latest_version}."
        )
    else:
        print(
            f"Updating {package_name} from version {current_version} to {latest_version}..."
        )

        # Step 8: Edit the mk file to update the version number
        update_mk_file(package_name, site, latest_version)

        # Step 9: Update the hash line in the hash file
        download_and_update_hash(package_name, site, github_repo, latest_version)

        print(f"Successfully updated {package_name} to version {latest_version}.")

    print(f"https://github.com/{github_repo}/releases/tag/{latest_version}")
