# Docker Daemon Config

This configuration JSON is merged with any .json files in the
images/docker-daemon.json.merge directory in the pre.sh hook.

## Ulimits

Issue: https://github.com/moby/moby/issues/38814

Docker 23.x changed the default ulimits to infinity. This breaks many
applications like the cups printer daemon.

The default-ulimits are set in the daemon.json to mitigate this issue.
