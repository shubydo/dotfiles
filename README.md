# dotfiles

Personal dotfiles for zsh, [nvim](https://github.com/shubydo/kickstart.nvim), and more.

## Installation

```bash
Usage: ./setup.zsh [-h] [-d] [-i | -y] [-l | -n | -z]
  Options:
  -h, --help                Display this help message
  -d, --dry-run             Print what would be done without actually doing it.
  -i, --interactive         Prompt before overwriting existing files (default)
  -y, --yes, --no-prompt    Do not prompt before creating or overwriting symlinks
  -l, --link                Create symlinks only
  -n, --nvim                Setup symlinks + nvim config only
  -z, --zsh                 Setup symlinks + zsh: oh-my-zsh + theme + plugins

  With no -l/-n/-z, everything is set up. Existing files are backed up to <file>.bak.<timestamp>.
```


###### Basic Installation
```bash
# Clone the repo and run the setup script
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

###### After installing
```bash
# Use the global gitignore
git config --global core.excludesfile "$HOME/.gitignore_global"

# Install Homebrew packages (macOS)
brew bundle --global   # reads ~/.Brewfile
```

## Testing

Tests run against a throwaway `$HOME` and never touch the network, so they are safe to run locally:

```bash
zsh tests/run_tests.zsh
```

They also run in CI on Ubuntu and macOS (`.github/workflows/test.yml`).

> **Note:** `.gitignore` is `*`, so new files must be added with `git add -f <file>`.
