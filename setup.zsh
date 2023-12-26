#!/usr/bin/env zsh

set -euo pipefail

# colors is a function that defines color variables for use in the remaining functions
colors() {
  # shellcheck disable=SC2034  # Unused variables left for readability
  CYAN="36"
  CYAN_BG="46"
  CYAN_BOLD="\033[1;${CYAN}m"
  CYAN_BG_BOLD="\033[1;${CYAN_BG}m"

  MAGENTA="35"
  MAGENTA_BG="45"
  MAGENTA_BOLD="\033[1;${MAGENTA}m"
  MAGENTA_BG_BOLD="\033[1;${MAGENTA_BG}m"

  WARNING_YELLOW="33"
  WARNING_YELLOW_BG="43"
  WARNING_YELLOW_BOLD="\033[1;${WARNING_YELLOW}m"
  WARNING_YELLOW_BG_BOLD="\033[1;${WARNING_YELLOW_BG}m"

  RED="31"
  RED_BG="41"
  RED_BOLD="\033[1;${RED}m"
  RED_BG_BOLD="\033[1;${RED_BG}m"

  GREEN="32"
  GREEN_BG="42"
  GREEN_BOLD="\033[1;${GREEN}m"
  GREEN_BG_BOLD="\033[1;${GREEN_BG}m"

  ENDCOLOR="\033[0m"
}

color_test() {
  colors
   # shellcheck disable=SC2034  # Unused variables left for readability
  for i in {0..255}; do

    echo "----------------------------------"
    echo "i: $i"
    echo "----------------------------------"

    COLOR_BOLD="\033[1;${i}m"
    echo -e "${COLOR_BOLD}colour${i}${ENDCOLOR}"
  done
}

# Create symlinks to dotfiles in home directory
link() {
  # Create symlinks to dotfiles
  # Grab all git tracked files in the current directory that are not on the IGNORE_LIST
  # and create symlinks to them in the home directory
  IGNORE_LIST=(
    ".git"
    ".gitignore"
    ".gitmodules"
    ".DS_Store"
    "setup.sh"
    "README.md"
    "LICENSE"
    "omz_install.sh"
    "iterm"
  )

  FILES=($(git ls-files | grep -v -e "$(printf "%s\n" "${IGNORE_LIST[@]}")"))

  # Add colors to output
  echo -e "${CYAN_BG_BOLD}Creating symlinks to dotfiles in ${HOME} directory${ENDCOLOR}"
  echo "----------------------------------"
  echo "Files to be linked: $FILES"
  echo "----------------------------------"

  # 
  for FILE in "${FILES[@]}"; do
    SOURCE_FILE="$PWD/$FILE"
    DEST_FILE="$HOME/$FILE"

    if [[ "$DRY_RUN" = true ]]; then
      echo "Dry run: Linking $SOURCE_FILE to $DEST_FILE"
    else
      echo "Linking $SOURCE_FILE to $DEST_FILE"
      # prompt user if file already exists
      if [[ "$DRY_RUN" == false && "$PROMPT_BEFORE_OVERWRITE" == true && -f "$DEST_FILE" ]]; then
        
        # read -p "File $DEST_FILE already exists. Overwrite? (y/n) " -n 1 -r
        echo -e "${WARNING_YELLOW_BOLD}File $DEST_FILE already exists. Overwrite? (y/n) ${ENDCOLOR}"
        read -r REPLY

        # if reply is not y or Y, skip this file
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Skipping $FILE"
          continue
        fi
      fi
      ln -sfv "$SOURCE_FILE" "$DEST_FILE"
      echo 
    fi
  done
}

# setup personal fork of nvim-lua/kickstart.nvim
setup_nvim() {
  REPO_NAME="shubydo/kickstart.nvim"
  REPO_URL="https://github.com/$REPO_NAME.git"
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

# setup_zsh_plugin - setup zsh plugin
setup_ohmyzsh_plugin() {
  local PLUGIN_NAME="$1"
  local PLUGIN_URL="$2"
  local DEST_PATH="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$PLUGIN_NAME"

  if [[ -z "$PLUGIN_NAME" ]]; then
    echo "No plugin name provided"
    exit 1
  fi

  if [[ -z "$PLUGIN_URL" ]]; then
    echo "No plugin URL provided"
    exit 1
  fi


  echo -e "${CYAN_BOLD}Setting up $PLUGIN_NAME plugin${ENDCOLOR}"

  DEST_PATH="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
  if [[ -d "$DEST_PATH" ]]; then
    echo "Existing $PLUGIN_NAME plugin found in $DEST_PATH"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run: git clone $PLUGIN_URL $DEST_PATH"
  else
    echo "Cloning $PLUGIN_NAME plugin"
    git clone "$PLUGIN_URL" "$DEST_PATH"
  fi
}

setup_ohmyzsh_plugins() {
  echo -e "${CYAN_BOLD}Setting up oh-my-zsh plugins${ENDCOLOR}"
  
  setup_ohmyzsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" \
  && setup_ohmyzsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
}

#   setup_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" \
#   && setup_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
# }

setup_ohmyzsh() {
  OMZ_SCRIPT="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  SCRIPT_PATH="omz_install.sh"
  # CUSTOM_OMZ_ZSH_PATH="$HOME/dotfiles/oh-my-zsh"
  CUSTOM_OMZ_ZSH_PATH="$HOME/.oh-my-zsh" # set to ZSH env var to control install location

  echo -e "${CYAN_BOLD}Setting up oh-my-zsh${ENDCOLOR}"

  # Don't let install run if ZSH env var is already set and has value that does not match custom location
  # (ex: .zshrc, or program set externally)
  if [[ "$ZSH" != "$CUSTOM_OMZ_ZSH_PATH" ]]; then
    echo "ZSH not configured as expected!: $ZSH"
    echo "Must be set to $CUSTOM_OMZ_ZSH_PATH"
    exit 1
  fi
  # export ZSH="$CUSTOM_OMZ_ZSH_PATH"

  download() {
    echo -e "Checking if using latest install script: $OMZ_SCRIPT"
    curl -fSsL "$OMZ_SCRIPT" -o "$SCRIPT_PATH" && chmod +x "$SCRIPT_PATH"

    IS_LATEST=$(git diff $SCRIPT_PATH)
    if [[ -z "$IS_LATEST" ]]; then
      echo "Using latest version of script!"
    else
      echo -e "${WARNING_YELLOW_BOLD} script downloaded does not match current version. It is recommended to commit changes before proceeding with install ${ENDCOLOR}:\n"
      echo -e "git add $SCRIPT_PATH && git commit -m 'chore(omz): update install script'"
      exit 1
    fi
  }

  # TODO: handle oh-my-zsh config error from install script: The $ZSH folder already exists (/home/shubydo/.oh-my-zsh).
  # ...$ZSH setting or the $ZSH variable is exported.
  if [[ ! -d "$CUSTOM_OMZ_ZSH_PATH" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "Dry run: 'ZSH=""${CUSTOM_OMZ_ZSH_PATH}"" sh -c ""./${SCRIPT_PATH}"" --unattended'"
    else
      download && ZSH=$CUSTOM_OMZ_ZSH_PATH sh -c ./$SCRIPT_PATH --unattended
    fi
  else
    echo "oh-my-zsh already installed in $CUSTOM_OMZ_ZSH_PATH"
  fi

  # setup_powerlevel10k 
}

setup_powerlevel10k() {
  echo -e "${CYAN_BOLD}Setting up powerlevel10k${ENDCOLOR}"

  THEME_URL="https://github.com/romkatv/powerlevel10k.git"
  DEST_PATH="${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k"
  

  # Clone powerlevel10k theme
  if [[ -d "$DEST_PATH" ]]; then
    echo "Existing powerlevel10k theme found in $DEST_PATH"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run: git clone --depth=1 $THEME_URL $DEST_PATH"
  else
    git clone --depth=1 "$THEME_URL" "$DEST_PATH"
  fi
}

# Display usage information with short and long options
display_usage() {
  echo -e "${CYAN_BOLD}Usage: $0 [-h] [-i] [-d] [-n] [-y]${ENDCOLOR}"
  echo "  Options: "
  echo "  -h, --help        Display this help message"
  echo "  -d, --dry-run     Print what would be done without actually doing it."
  echo "  -i, --interactive Enable prompts before overwriting symlinks"
  echo "  -y, --yes, --no-prompt   Do not prompt before creating or overwriting symlinks"
  echo "  -n, --nvim        Setup nvim config only"
  echo "  -z, --zsh         Setup zsh: oh-my-zsh + theme + plugins"
}

# Set default values for flags
PROMPT_BEFORE_OVERWRITE=true # -i flag
DRY_RUN=false                # - d flag
DRY_RUN_MSG=""

# Setup colors for shell output
colors

# Parse command line options. If --help flag is present, display usage and exit

if [[ "$#" -eq 0 ]]; then
  display_usage
  exit 0
fi

# Parse command line options. If --help flag is present, display usage and exit
# Or if dry run flag is present, print what would be done without actually doing it

# If --help flag is present, display usage no matter what other flags are present
if [[ "$*" == *--help* ]] || [[ "$*" == *-h* ]]; then
  display_usage
  exit 0
fi

# If -y, --yes or any of its other aliases are present, disable prompts
if [[ "$*" == *-y* || "$*" == *--yes* || "$*" == *--no-prompt* ]]; then
  PROMPT_BEFORE_OVERWRITE=false
fi

# If --dry-run flag is present, print what would be done without actually doing it
if [[ "$*" == *--dry-run* ]] || [[ "$*" == *-d* ]]; then
  DRY_RUN=true
  DRY_RUN_MSG="${WARNING_YELLOW_BOLD}Dry run: ${ENDCOLOR}"
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -i | --interactive)
    PROMPT_BEFORE_OVERWRITE=true
    link
    setup_nvim
    setup_ohmyzsh
    setup_ohmyzsh_plugins
    setup_powerlevel10k
    exit 0
    ;;
  -y | --yes | --no-prompt)
    PROMPT_BEFORE_OVERWRITE=false
    link
    setup_nvim
    setup_ohmyzsh
    setup_ohmyzsh_plugins
    setup_powerlevel10k
    exit 0
    ;;
  -n | --nvim)
    link
    setup_nvim
    exit 0
    ;;
  -z | --zsh)
    link
    setup_ohmyzsh
    setup_ohmyzsh_plugins
    setup_powerlevel10k
    exit 0
    ;;
  *)
    echo "Unknown parameter passed: $1"
    display_usage
    exit 1
    ;;
  esac
done
