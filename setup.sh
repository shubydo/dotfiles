#!/bin/bash

echo "Setting up dotfiles"

# Create symlinks for dot files to desired location ($HOME in this case)
# Ignore certain files and directories like .git

EXCLUDED_FILES=()

echo "Excluded files: $EXCLUDED_FILES"
