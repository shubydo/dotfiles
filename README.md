# dotfiles

Personal dotfiles for zsh, [nvim](https://github.com/shubydo/kickstart.nvim), and more.

## Installation

```bash
Usage: display_usage [-h] [-i] [-d] [-n] [-y] [-z]
  Options: 
  -h, --help                Display this help message
  -d, --dry-run             Print what would be done without actually doing it.
  -i, --interactive         Enable prompts before overwriting symlinks (default)
  -y, --yes, --no-prompt    Do not prompt before creating or overwriting symlinks
  -n, --nvim                Setup nvim config only
  -z, --zsh                 Setup zsh: oh-my-zsh + theme
```


###### Basic Installation
```bash
# Clone the repo and run the setup script and run the setup script
git clone https://github.com/shubydo/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles" # cd into the dotfiles directory

# Run the setup script to create symlinks, install oh-my-zsh, setup nvim, etc.
./setup.zsh -y # or ./setup.zsh --no-prompt
```

###### Dry Run
```bash
# Assuming in the $HOME/dotfiles directory above
./setup.zsh -d # or ./setup.zsh --dry-run
```