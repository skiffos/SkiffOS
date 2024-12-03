#!/usr/bin/env python3

import feedparser
import re


def get_latest_stable_kernel_version_and_date():
    # URL of the kernel.org RSS feed
    rss_url = "https://www.kernel.org/feeds/kdist.xml"

    # Parse the RSS feed
    feed = feedparser.parse(rss_url)

    # Iterate through the feed entries
    for entry in feed.entries:
        # Split the entry ID by commas
        id_parts = entry.id.split(",")

        # Check if the second part of the ID is 'stable'
        if id_parts[1] == "stable":
            # Extract the kernel version and release date from the ID
            kernel_version = id_parts[2]
            release_date = id_parts[3]
            return kernel_version, release_date


def update_files(kernel_version, release_date):
    # Update configs-base/pre/buildroot/kernel
    with open("configs-base/pre/buildroot/kernel", "r") as kernel_file:
        kernel_contents = kernel_file.read()

    # Extract the old kernel version from the configs-base/pre/buildroot/kernel file
    old_kernel_version = re.search(
        r'BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="(\d+\.\d+\.\d+)"', kernel_contents
    ).group(1)

    # Replace the kernel version in the configs-base/pre/buildroot/kernel file using a regular expression
    kernel_contents = re.sub(
        r'BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="\d+\.\d+\.\d+"',
        f'BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="{kernel_version}"',
        kernel_contents,
    )

    # Update the major version in BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_6_1
    kernel_version_parts = kernel_version.split(".")
    major_version_parts = kernel_version_parts[:2]
    major_version = ".".join(major_version_parts)
    if major_version in ["6.12", "6.13", "6.14", "6.15", "6.17"]:
        # Note: Buildroot supports at most 6_11
        major_version = "6.11"
    kernel_contents = re.sub(
        r"BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_\d+_\d+",
        f'BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_{major_version.replace(".", "_")}',
        kernel_contents,
    )
    kernel_contents = re.sub(
        r"BR2_KERNEL_HEADERS_\d+_\d+",
        f'BR2_KERNEL_HEADERS_{major_version.replace(".", "_")}',
        kernel_contents,
    )

    with open("configs-base/pre/buildroot/kernel", "w") as kernel_file:
        kernel_file.write(kernel_contents)

    # Update README.md
    with open("README.md", "r") as readme_file:
        readme_contents = readme_file.read()

    # Replace only the exact old kernel version mentioned in the README.md file
    readme_contents = readme_contents.replace(
        f"✔ {old_kernel_version}", f"✔ {kernel_version}"
    )

    with open("README.md", "w") as readme_file:
        readme_file.write(readme_contents)

    return old_kernel_version


# Get the latest stable kernel version and release date
latest_stable_kernel_version, release_date = get_latest_stable_kernel_version_and_date()

# Update the files with the latest stable kernel version and release date
old_version = update_files(latest_stable_kernel_version, release_date)

print("The latest stable kernel version is:", latest_stable_kernel_version)
print("The release date is:", release_date)
print("The old version was:", old_version)
if old_version is latest_stable_kernel_version:
    print("No changes.")
else:
    print("The files have been updated successfully.\n")
    print("git add configs-base/pre README.md")
    print(
        'git commit -n -sm "configs-base: update kernel to {}"'.format(
            latest_stable_kernel_version
        )
    )
