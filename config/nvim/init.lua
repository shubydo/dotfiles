-- Install packer.nvim if not already installed
local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system({ 'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path })
end

-- Plugins
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim' -- Package manager
  use 'neovim/nvim-lspconfig' -- LSP configurations
  use 'hrsh7th/nvim-compe' -- Autocompletion
  use 'hoob3rt/lualine.nvim' -- Status line
  use 'kyazdani42/nvim-tree.lua' -- File explorer
  use 'nvim-telescope/telescope.nvim' -- Fuzzy finder
  use 'norcalli/nvim-colorizer.lua' -- Colorize hex codes
  use 'windwp/nvim-autopairs' -- Auto-close pairs
  use 'tpope/vim-commentary' -- Toggle comments
  use 'jiangmiao/auto-pairs' -- Auto-close pairs
  use 'preservim/nerdtree' -- File explorer
  use 'kyazdani42/nvim-web-devicons' -- Icons
  use 'vim-airline/vim-airline' -- Status line
  use 'vim-airline/vim-airline-themes' -- Status line themes
  use 'navarasu/onedark.nvim' -- Color scheme
  use 'github/copilot.vim'
end)

-- General settings
-- vim.opt.nocompatible = true
-- vim.opt.compatible = false
-- vim.opt.noswapfile = true

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.wrap = false



-- Keybindings
vim.api.nvim_set_keymap('n', '<C-p>', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-f>', ':Telescope live_grep<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>r', ':NvimTreeRefresh<CR>', { noremap = true, silent = true })

-- Create a highlight group for the suggestion from Copilot
vim.cmd('hi def CopilotSuggestion guifg=#808080 ctermfg=244')
vim.cmd('colorscheme onedark')

-- Create keybindings for accepting or rejecting the suggestions
vim.api.nvim_set_keymap('i', '<C-Space>', '<Plug>(copilot_accept_current)', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-Enter>', '<Plug>(copilot_reject_current)', { noremap = true, silent = true })
