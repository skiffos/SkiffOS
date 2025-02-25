#!/usr/bin/env bash
# SkiffOS tmux workspace manager
# Opens a tmux session with windows for each workspace
set -eo pipefail

# Verify we're in the right directory
if [[ ! -d ./workspaces/ ]]; then
  echo "Error: workspaces directory not found."
  echo "Please run this script from the SkiffOS root directory."
  exit 1
fi

# Get the current directory path (for use in tmux windows)
SKIFF_ROOT_PATH="$(pwd)"

# Session name for tmux
SESSION_NAME="skiff"

# Create main session with root window
echo "Creating tmux session: ${SESSION_NAME}"
tmux new-session -d -s "${SESSION_NAME}" -n "root" "cd ${SKIFF_ROOT_PATH}; bash -i"

# Create a window for each workspace
echo "Creating windows for each workspace..."
for workspace_path in ./workspaces/*; do
  # Get workspace name
  workspace_name="$(basename "${workspace_path}")"
  
  # Skip .config_* directories
  if [[ "${workspace_name}" == .config_* ]]; then
    continue
  fi
  
  # Create a new window for this workspace
  echo "  - Adding window for workspace: ${workspace_name}"
  tmux new-window -t "${SESSION_NAME}" -n "${workspace_name}" \
    "cd ${SKIFF_ROOT_PATH}; unset SKIFF_CONFIG; export SKIFF_WORKSPACE=${workspace_name}; bash -i"
done

# Select the first window and attach to the session
echo "Opening tmux session..."
tmux select-window -t "${SESSION_NAME}:0"
tmux -2 attach-session -t "${SESSION_NAME}"