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
  # Grab all git tracked files that are not on the IGNORE_LIST and create symlinks
  # to them in the home directory. Entries are matched exactly (a file name, or a
  # directory prefix for entries ending in "/").
  local -a IGNORE_LIST=(
    ".gitignore"
    ".gitmodules"
    ".DS_Store"
    ".github/"
    "setup.zsh"
    "README.md"
    "LICENSE"
    "omz_install.sh"
    "iterm/"
    "tests/"
  )

  local -a FILES=()
  local FILE ENTRY SKIP
  for FILE in ${(f)"$(git ls-files)"}; do
    SKIP=false
    for ENTRY in "${IGNORE_LIST[@]}"; do
      if [[ "$FILE" == "$ENTRY" || ( "$ENTRY" == */ && "$FILE" == "$ENTRY"* ) ]]; then
        SKIP=true
        break
      fi
    done
    [[ "$SKIP" == true ]] || FILES+=("$FILE")
  done

  echo -e "${CYAN_BG_BOLD}Creating symlinks to dotfiles in ${HOME} directory${ENDCOLOR}"
  echo "----------------------------------"
  echo "Files to be linked: ${FILES[*]}"
  echo "----------------------------------"

  local SOURCE_FILE DEST_FILE BACKUP_FILE REPLY
  for FILE in "${FILES[@]}"; do
    SOURCE_FILE="$DOTFILES_DIR/$FILE"
    DEST_FILE="$HOME/$FILE"

    # Already linked to this repo: nothing to do (makes re-runs idempotent)
    if [[ -L "$DEST_FILE" && "$(readlink "$DEST_FILE")" == "$SOURCE_FILE" ]]; then
      echo "Already linked: $DEST_FILE"
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "Dry run: Linking $SOURCE_FILE to $DEST_FILE"
      continue
    fi

    # Prompt user if something already exists at the destination
    if [[ "$PROMPT_BEFORE_OVERWRITE" == true && ( -e "$DEST_FILE" || -L "$DEST_FILE" ) ]]; then
      echo -e "${WARNING_YELLOW_BOLD}File $DEST_FILE already exists. Overwrite? (y/n) ${ENDCOLOR}"
      read -r REPLY
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping $FILE"
        continue
      fi
    fi

    # Never silently destroy a real (non-symlink) file: back it up first
    if [[ -e "$DEST_FILE" && ! -L "$DEST_FILE" ]]; then
      BACKUP_FILE="$DEST_FILE.bak.$(date +%Y%m%d%H%M%S)"
      echo -e "${WARNING_YELLOW_BOLD}Backing up $DEST_FILE to $BACKUP_FILE${ENDCOLOR}"
      mv "$DEST_FILE" "$BACKUP_FILE"
    fi

    mkdir -p "${DEST_FILE:h}"
    ln -sfv "$SOURCE_FILE" "$DEST_FILE"
  done
}

# setup personal fork of nvim-lua/kickstart.nvim
setup_nvim() {
  REPO_NAME="shubydo/kickstart.nvim"
  REPO_URL="https://github.com/$REPO_NAME.git"
  # clone to custom path to use as separate configuration
  DEST_PATH="$HOME/.config/nvim-kickstart"

  echo -e "${MAGENTA_BOLD}Setting up nvim config\n${REPO_URL}${ENDCOLOR}"
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
  
  setup_ohmyzsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"

  setup_ohmyzsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
}

setup_ohmyzsh() {
  OMZ_SCRIPT="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  SCRIPT_PATH="omz_install.sh"
  # CUSTOM_OMZ_ZSH_PATH="$HOME/dotfiles/oh-my-zsh"
  CUSTOM_OMZ_ZSH_PATH="$HOME/.oh-my-zsh" # set to ZSH env var to control install location

  echo -e "${CYAN_BOLD}Setting up oh-my-zsh${ENDCOLOR}"

  # Don't let install run if ZSH env var is already set and has value that does not match custom location
  # (ex: .zshrc, or program set externally)
  if [[ "${ZSH:-$CUSTOM_OMZ_ZSH_PATH}" != "$CUSTOM_OMZ_ZSH_PATH" ]]; then
    echo "ZSH not configured as expected!: ${ZSH:-}"
    echo "Must be set to $CUSTOM_OMZ_ZSH_PATH"
    exit 1
  fi
  # export ZSH="$CUSTOM_OMZ_ZSH_PATH"

  download() {
    echo -e "Checking if using latest install script: $OMZ_SCRIPT"
    curl -fSsL "$OMZ_SCRIPT" -o "$SCRIPT_PATH" && chmod +x "$SCRIPT_PATH"

    IS_LATEST=$(git diff "$SCRIPT_PATH")
    if [[ -z "$IS_LATEST" ]]; then
      echo "Using latest version of script!"
    else
      echo -e "${WARNING_YELLOW_BOLD} script downloaded does not match current version. It is recommended to commit changes before proceeding with install ${ENDCOLOR}:\n"
      echo -e "git add $SCRIPT_PATH && git commit -m 'chore(omz): update install script'"
      exit 1
    fi
  }

  if [[ ! -d "$CUSTOM_OMZ_ZSH_PATH" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "Dry run: ZSH=${CUSTOM_OMZ_ZSH_PATH} sh ./${SCRIPT_PATH} --unattended --keep-zshrc"
    else
      # --keep-zshrc: the installer would otherwise move our symlinked ~/.zshrc aside
      # and replace it with its template.
      download && ZSH="$CUSTOM_OMZ_ZSH_PATH" sh "./$SCRIPT_PATH" --unattended --keep-zshrc
    fi
  else
    echo "oh-my-zsh already installed in $CUSTOM_OMZ_ZSH_PATH"
  fi

  # setup_powerlevel10k 
}

setup_powerlevel10k() {
  echo -e "${CYAN_BOLD}Setting up powerlevel10k${ENDCOLOR}"

  THEME_URL="https://github.com/romkatv/powerlevel10k.git"
  DEST_PATH="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/themes/powerlevel10k"
  

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
  echo -e "${CYAN_BOLD}Usage: $0 [-h] [-d] [-i | -y] [-l | -n | -z]${ENDCOLOR}"
  echo "  Options: "
  echo "  -h, --help                Display this help message"
  echo "  -d, --dry-run             Print what would be done without actually doing it."
  echo "  -i, --interactive         Prompt before overwriting existing files (default)"
  echo "  -y, --yes, --no-prompt    Do not prompt before creating or overwriting symlinks"
  echo "  -l, --link                Create symlinks only"
  echo "  -n, --nvim                Setup symlinks + nvim config only"
  echo "  -z, --zsh                 Setup symlinks + zsh: oh-my-zsh + theme + plugins"
  echo ""
  echo "  With no -l/-n/-z, everything is set up. Existing files are backed up to <file>.bak.<timestamp>."
}

# Always operate from the repo root so git ls-files / relative paths work from anywhere
DOTFILES_DIR="${0:A:h}"
cd "$DOTFILES_DIR"

# Set default values for flags
PROMPT_BEFORE_OVERWRITE=true # -i / -y
DRY_RUN=false                # -d
MODE=all                     # -l / -n / -z

# Setup colors for shell output
colors

if [[ "$#" -eq 0 ]]; then
  display_usage
  exit 0
fi

# Parse all flags first, then act, so flag order does not matter (e.g. -d -y == -y -d)
while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -h | --help) display_usage; exit 0 ;;
  -d | --dry-run) DRY_RUN=true ;;
  -i | --interactive) PROMPT_BEFORE_OVERWRITE=true ;;
  -y | --yes | --no-prompt) PROMPT_BEFORE_OVERWRITE=false ;;
  -l | --link) MODE=link ;;
  -n | --nvim) MODE=nvim ;;
  -z | --zsh) MODE=zsh ;;
  *)
    echo "Unknown parameter passed: $1"
    display_usage
    exit 1
    ;;
  esac
  shift
done

[[ "$DRY_RUN" == true ]] && echo -e "${WARNING_YELLOW_BOLD}Dry run: no changes will be made${ENDCOLOR}"

link
case "$MODE" in
link) ;;
nvim) setup_nvim ;;
zsh)
  setup_ohmyzsh
  setup_ohmyzsh_plugins
  setup_powerlevel10k
  ;;
all)
  setup_nvim
  setup_ohmyzsh
  setup_ohmyzsh_plugins
  setup_powerlevel10k
  ;;
esac
