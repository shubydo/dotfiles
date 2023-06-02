#!/usr/bin/env bash

# Parse command line options
while getopts "n" opt; do
  case ${opt} in
    n )
      DRY_RUN=true
      ;;
    \? )
      echo "Usage: $(basename "$0") [-n]"
      exit 1
      ;;
  esac
done

# Create symlinks to dotfiles

# Grab all dotfiles in this directory except for .git and .gitignore 
# remove the leading ./ from the file names
FILES=$(find . -maxdepth 1 -type f -name ".*" ! -name ".git*" ! -name ".DS_Store" ! -name ".gitignore" -exec basename {} \;)

echo "Linking files to home directory..."
echo "----------------------------------"
echo "Files to be linked: $FILES"
echo "----------------------------------"

# Show which files will be linked where if dry run
if [ "$DRY_RUN" = true ]; then
  for FILE in $FILES; do
    SOURCE_FILE="$PWD/$FILE"
		DEST_FILE="$HOME/$FILE"

    echo "Dry run: Linking $SOURCE_FILE to $DEST_FILE"
  done
else
	for FILE in $FILES; do
    SOURCE_FILE="$PWD/$FILE"
		DEST_FILE="$HOME/$FILE"

		echo "Linking $SOURCE_FILE to $DEST_FILE"
		ln -sfnv "$SOURCE_FILE" "$DEST_FILE"
	done
fi