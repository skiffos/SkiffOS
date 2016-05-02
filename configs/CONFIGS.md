# Skiff Configurations

A Skiff configuration contains settings for:

 - The Linux kernel
 - Buildroot (overridden settings)
 - System Overlays

Base and final in this directory are applied always at the beginning and end of the process.

# Structure

Here's the file structure:

 - `metadata`: General metadata.
   - `description`: A file with a single-line description of the config pack.
   - `dependencies`: Comma separated config pack dependencies
 - `buildroot`: Buildroot config fragments applied alphabetically
 - `kernel`: Kernel config fragments applied alphabetically
