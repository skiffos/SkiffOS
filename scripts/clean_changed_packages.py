#!/usr/bin/env python3
"""Clean the packages a Buildroot config change affects.

Buildroot never removes a deselected package's files and never rebuilds a
package whose options or optional dependencies changed; its manual asks for a
full rebuild instead. This compares the previous and the new .config and, for
each affected package, removes the files it installed into target, staging and
host and deletes its build directory, so the next build reinstalls it from the
new config or leaves it out.

A package is affected when a changed symbol belongs to it (the longest package
symbol that prefixes the changed symbol) or when it directly depends on such a
package in the previous configuration, so that a package which detected an
optional library at configure time is rebuilt without it. The dependency graph
comes from `make show-info` saved at the previous configure.

A config file a symbol names, such as the kernel config SkiffOS merges into a
fixed path, is compared by content. Buildroot reconfigures the package that
reads it but not the packages built against it, such as out-of-tree kernel
modules, so those reverse dependencies are cleaned.

A root overlay directory that left BR2_ROOTFS_OVERLAY has its files removed
from target as well, since Buildroot copies overlays without recording them.

A file another unaffected package or a kept overlay also installed is kept.
Only build output is touched; the download cache and the config are not.

Usage: clean_changed_packages.py OUTPUT_DIR OLD_CONFIG NEW_CONFIG OLD_SHOW_INFO
       CONFIG_FILE_DIGESTS
"""

import hashlib
import json
import os
import sys

# Kconfig packages whose symbols do not start with their package symbol.
SYMBOL_ALIASES = {
    "BR2_LINUX_KERNEL": "linux",
    "BR2_TARGET_UBOOT": "uboot",
    "BR2_TARGET_ARM_TRUSTED_FIRMWARE": "arm-trusted-firmware",
}


def read_config(path):
    values = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("BR2_") and "=" in line:
                key, value = line.split("=", 1)
                values[key] = value
    return values


def package_symbol(name):
    if name.startswith("host-"):
        return "BR2_PACKAGE_HOST_" + name[5:].upper().replace("-", "_")
    return "BR2_PACKAGE_" + name.upper().replace("-", "_")


def config_file_digests(config):
    # Hash the files that config-file symbols name by absolute path; relative
    # paths are Buildroot's own defaults and change only with Buildroot.
    digests = {}
    for key, value in config.items():
        if not (key.endswith("CONFIG_FILE") or key.endswith("CONFIG_FILES")
                or key.endswith("_CONFIG_FRAGMENT_FILES")):
            continue
        h = hashlib.sha256()
        for path in value.strip('"').split():
            if os.path.isabs(path) and os.path.isfile(path):
                with open(path, "rb") as f:
                    h.update(f.read())
        digests[key] = h.hexdigest()
    return digests


def owner_of(symbol, symbols):
    # symbols maps a package symbol to its package name; the longest symbol
    # that is the changed symbol or a prefix of it ending at "_" owns it.
    key = symbol
    while key:
        if key in symbols:
            return symbols[key]
        cut = key.rfind("_")
        if cut <= len("BR2_PACKAGE"):
            return None
        key = key[:cut]
    return None


def read_file_lists(output):
    # Each list maps a package to the files it installed, relative to a root.
    lists = {
        "packages-file-list.txt": os.path.join(output, "target"),
        "packages-file-list-staging.txt": os.path.join(output, "staging"),
        "packages-file-list-host.txt": os.path.join(output, "host"),
    }
    result = []
    for name, root in lists.items():
        path = os.path.join(output, "build", name)
        if not os.path.exists(path):
            continue
        entries = []
        with open(path) as f:
            for line in f:
                pkg, _, rel = line.rstrip("\n").partition(",")
                if rel:
                    entries.append((pkg, rel))
        result.append((path, os.path.realpath(root), entries))
    return result


def remove_file(root, rel):
    path = os.path.normpath(os.path.join(root, rel))
    if not path.startswith(root + os.sep):
        return False
    if not (os.path.lexists(path) and not os.path.isdir(path)):
        return False
    os.unlink(path)
    parent = os.path.dirname(path)
    while parent != root and parent.startswith(root + os.sep):
        try:
            os.rmdir(parent)
        except OSError:
            break
        parent = os.path.dirname(parent)
    return True


def overlay_files(dirs):
    files = set()
    for top in dirs:
        for dirpath, dirnames, filenames in os.walk(top):
            for name in filenames + [d for d in dirnames
                                     if os.path.islink(os.path.join(dirpath, d))]:
                files.add(os.path.relpath(os.path.join(dirpath, name), top))
    return files


def clean_overlays(output, old, new, kept_files):
    def dirs(config):
        return config.get("BR2_ROOTFS_OVERLAY", '""').strip('"').split()
    removed = [d for d in dirs(old) if d not in dirs(new)]
    if not removed:
        return 0
    root = os.path.realpath(os.path.join(output, "target"))
    keep = overlay_files(dirs(new)) | kept_files
    count = 0
    for rel in sorted(overlay_files(removed) - keep):
        count += remove_file(root, rel)
    print("Config change removed %d files of dropped root overlays:" % count)
    for d in removed:
        print("  " + d)
    return count


def remove_tree(path):
    for dirpath, dirnames, filenames in os.walk(path, topdown=False):
        for name in filenames:
            os.unlink(os.path.join(dirpath, name))
        for name in dirnames:
            full = os.path.join(dirpath, name)
            if os.path.islink(full):
                os.unlink(full)
            else:
                os.rmdir(full)
    os.rmdir(path)


def main(output, old_config, new_config, old_show_info, digests_path):
    new = read_config(new_config)
    digests = config_file_digests(new)
    old_digests = {}
    if os.path.exists(digests_path):
        with open(digests_path) as f:
            old_digests = json.load(f)
    clean(output, old_config, new, old_show_info, old_digests, digests)
    with open(digests_path, "w") as f:
        json.dump(digests, f, indent=1, sort_keys=True)


def clean(output, old_config, new, old_show_info, old_digests, digests):
    if not (os.path.exists(old_config) and os.path.exists(old_show_info)):
        return
    old = read_config(old_config)
    changed = [k for k in set(old) | set(new) if old.get(k) != new.get(k)]
    rewritten = [k for k in digests
                 if k in old_digests and old_digests[k] != digests[k]]
    if not (changed or rewritten):
        return

    with open(old_show_info) as f:
        info = json.load(f)
    symbols = {package_symbol(name): name for name in info}
    symbols.update({k: v for k, v in SYMBOL_ALIASES.items() if v in info})

    owners = {owner_of(sym, symbols) for sym in changed} - {None}
    reconfigured = {owner_of(sym, symbols) for sym in rewritten} - {None}
    affected = set(owners)
    for name in owners | reconfigured:
        affected.update(info[name].get("reverse_dependencies", []))
    affected = {name for name in affected if not info[name].get("virtual")}

    file_lists = read_file_lists(output)
    target_files = {os.path.normpath(rel) for path, _, entries in file_lists
                    if path.endswith("packages-file-list.txt")
                    for pkg, rel in entries if pkg not in affected}
    clean_overlays(output, old, new, target_files)
    if not affected:
        return

    removed_files = 0
    for list_path, root, entries in file_lists:
        kept_owners = {}
        for pkg, rel in entries:
            if pkg not in affected:
                kept_owners[rel] = pkg
        for pkg, rel in entries:
            if pkg in affected and rel not in kept_owners:
                removed_files += remove_file(root, rel)
        with open(list_path, "w") as f:
            for pkg, rel in entries:
                if pkg not in affected:
                    f.write(pkg + "," + rel + "\n")

    for name in sorted(affected):
        build_dir = info[name].get("build_dir")
        if build_dir:
            path = os.path.join(output, build_dir.rstrip("/"))
            if os.path.isdir(path):
                remove_tree(path)

    print("Config change cleaned %d packages (%d files) for a rebuild:"
          % (len(affected), removed_files))
    print("  " + " ".join(sorted(affected)))


if __name__ == "__main__":
    if len(sys.argv) != 6:
        sys.exit(__doc__.strip().split("\n\n")[-1])
    main(*sys.argv[1:])
