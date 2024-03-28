# SHELL := zsh

all: install_homebrew setup_shell

# install homebrew
install_homebrew: # install homebrew
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

uninstall_nvim_config:	
	# Linux / Macos (unix)
	rm -rfv ~/.config/nvim
	rm -rfv ~/.local/share/nvim


# Set up zsh as the default shell
setup_shell:# Set up zsh as the default shell
	@echo "Changing shell to zsh"
	chsh -s $(which zsh)

# Install oh-my-zsh
setup_oh_my_zsh: setup_shell
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

	# Install plugins
	  
uninstall:
	@echo -e "unlink dotfiles from $HOME"
	find /Users/shubydo -type l -lname "*/dotfiles/*" -exec unlink -v {} +



help: 
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


.PHONY: setup_shell install_oh_my_zsh install_homebrew run_setup help
