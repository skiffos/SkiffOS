# Configuration Overrides

You can place Skiff configuration files in this directory as local overrides,
which will be applied as the final configuration in the config chain.

For example, you can add some temporary packages to your system:

overrides/buildroot/vlc:

```
BR2_PACKAGE_VLC=y
```

Additionally, you can add workspace-specific overrides:

overrides/workspaces/myworkspace/buildroot/kodi:

```
BR2_PACKAGE_KODI=y
```

These will be applied only to "myworkspace."
