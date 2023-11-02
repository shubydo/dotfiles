#!/usr/bin/env bash

# colors is a function that defines color variables for use in the remaining functions
colors() {
	CYAN="36"
	CYAN_BG="46"
	MAGENTA="35"
	MAGENTA_BG="45"
	CYAN_BOLD="\033[1;${CYAN}m"
	CYAN_BG_BOLD="\033[1;${CYAN_BG}m"
	MAGENTA_BOLD="\033[1;${MAGENTA}m"
	MAGENTA_BG_BOLD="\033[1;${MAGENTA_BG}m"
	ENDCOLOR="\033[0m"
}


# Create symlinks to dotfiles in home directory
link() {
	# Create symlinks to dotfiles
	# Grab all git tracked files in the current directory that are not on the IGNORE_LIST
	# and create symlinks to them in the home directory
	IGNORE_LIST="README.md .gitignore"
	FILES=$(git ls-files | grep -v -e "$IGNORE_LIST")
	
	# Add colors to output
	echo -e "${CYAN_BOLD}Creating symlinks to dotfiles in ${HOME} directory${ENDCOLOR}"
	echo "----------------------------------"
	echo "Files to be linked: $FILES"
	echo "----------------------------------"
	
	for FILE in $FILES; do
	  SOURCE_FILE="$PWD/$FILE"
	  DEST_FILE="$HOME/$FILE"
	   
	  if [[ "$DRY_RUN" = true ]]; then
	     echo "Dry run: Linking $SOURCE_FILE to $DEST_FILE"
	  else
	     echo "Linking $SOURCE_FILE to $DEST_FILE"
	     # prompt user if file already exists
	     if [[ "$DRY_RUN" == false && "$PROMPT_BEFORE_OVERWRITE" == true && -f "$DEST_FILE" ]]; then
		read -p "File $DEST_FILE already exists. Overwrite? (y/n) " -n 1 -r
	       echo
	       if [[ $REPLY =~ ^[Yy]$ ]]; then
		 rm -fv "$DEST_FILE"
	       else
		 echo "Skipping $DEST_FILE"
		 continue
	       fi
	     fi
	     ln -sfv "$SOURCE_FILE" "$DEST_FILE"
	  fi
	done
}

# setup personal fork of nvim-lua/kickstart.nvim 
setup_nvim() {
  REPO_NAME="shubydo/kickstart.nvim"
  REPO_URL="https://github.com/$REPO_NAME"
  DEST_PATH="$HOME/.config/nvim"
  
  echo -e "${MAGENTA_BOLD}Setting up nvim config${ENDCOLOR}" 

  if [[ ! -d "$DEST_PATH" ]]; then
    echo "No existing nvim config found in $DEST_PATH"
    if [[ "$DRY_RUN" == true ]]; then
      echo "Dry run: git clone $REPO_URL $DEST_PATH"
    else
      git clone "$REPO_URL" "$DEST_PATH"
    fi
  else
    echo "Existing nvim config found"
    if [[ "$DRY_RUN" == true ]]; then
      echo "Dry run: git -C $DEST_PATH pull"
    else
    	git -C "$DEST_PATH" pull
    fi
  fi  
}

# setup_spaceship() {
# 	echo "Setting up spaceship prompt"
# 
# 	git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
# 	
# 	# Symlink spaceship.zsh-theme to your oh-my-zsh custom themes directory:
# 	if [[ "$DRY_RUN" == true ]]; then
# 	  echo "Dry run: ln -sf $ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme $ZSH_CUSTOM/themes/spaceship.zsh-theme"
# 	else 	
# 	  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
# 	fi
# }



display_usage() {
  echo "Usage: setup.sh [-h] [-i] [-d] [-y]"
  echo "  -h  Print this help message"
  echo "  -i  Interactive: prompt before creating symlinks to dotfiles in home directory"
  echo "  -d  Dry run: print what would be done without actually doing it"
  echo "  -y  Do not prompt before creating or overwriting symlinks" 
  echo "  -n  nvim: setup nvim config only"
} 

DRY_RUN=false # -n flag
PROMPT_BEFORE_OVERWRITE=true # -y flag
colors

# Parse command line options and print usage if -h is passed
[[ $# -eq 0 ]] && display_usage
while getopts "hydin" OPTION; do
  case "$OPTION" in
    h)
      display_usage
      exit 0
      ;;
    y)
      DRY_RUN=false
      PROMPT_BEFORE_OVERWRITE=false
      link
      setup_nvim
 #      setup_spaceship
      exit 0
      ;;
    i)
      link
      setup_nvim
#       setup_spaceship
      exit 0
      ;;
    d | --dry-run)
	DRY_RUN=true
	link
	setup_nvim
	exit 0
	;;
    n)
	setup_nvim
	exit 0
	;;
    *)
      display_usage
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
