#!env python3
import sys
import re
import pyperclip

def reformat_vulnerabilities(input_data):
    cve_pattern = r"This is (CVE-\d{4}-\d+)"
    title_pattern = r"^\s*(.+):\s+(.+)$"

    cve_list = []
    titles = []

    for line in input_data.splitlines():
        cve_match = re.search(cve_pattern, line)
        title_match = re.search(title_pattern, line)

        if cve_match:
            cve_list.append(cve_match.group(1))
        elif title_match:
            titles.append(title_match.group(1) + ": " + title_match.group(2))

    reformatted = []
    for cve, title in zip(cve_list, titles):
        reformatted.append(f"{cve}: {title}")

    return "\n".join(reformatted)

if __name__ == "__main__":
    # input_data = sys.stdin.read()
    input_data = pyperclip.paste()
    reformatted_data = reformat_vulnerabilities(input_data)
    print(reformatted_data)

