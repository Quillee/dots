-- globals
local Plug = vim.fn['plug#']
local Call = vim.call

-- plugins
Call('plug#begin', '~/.vim/plugged')
-- Deps
Plug('nvim-lua/plenary.nvim')
-- Quick file search
Plug('nvim-telescope/telescope.nvim')
-- Incremental search
Plug('haya14busa/incsearch.vim')
-- Colorschemes
Plug('tjdevries/colorbuddy.nvim')
Plug('norcalli/nvim-colorizer.lua')
Plug('lalitmee/cobalt2.nvim')
Plug('folke/tokyonight.nvim')
Plug('savq/melange')
Plug('Mofiqul/dracula.nvim')
Plug('glepnir/zephyr-nvim')
-- LSP
Plug('neovim/nvim-lspconfig')
Plug('williamboman/nvim-lsp-installer')
Plug('glepnir/lspsaga.nvim', { ['branch'] = 'main' })
-- Completion
Plug("hrsh7th/nvim-cmp") -- The completion plugin
Plug("hrsh7th/cmp-buffer") -- buffer completions
Plug("hrsh7th/cmp-path") -- path completions
Plug("hrsh7th/cmp-cmdline") -- cmdline completions
Plug("saadparwaiz1/cmp_luasnip") -- snippet completions
Plug('saecki/crates.nvim', { ['tag'] = 'v0.3.0' })
Plug('hrsh7th/cmp-nvim-lsp')
---- Specific lang
------ Zig
-- Plug('zigland/zig.vim')
------ end Zig
---- end Specific lang
-- specific lang
Plug('ray-x/go.nvim')
Plug('ray-x/guihua.lua')
-- Linter & other features
Plug('nvim-treesitter/nvim-treesitter')
-- Markdown viewer
Plug('frabjous/knap')
-- File manager and deps
Plug('ms-jpq/chadtree', {
    ['branch'] = 'chad',
    ['do'] = 'python -m chadtree deps'
})
Plug('ryanoasis/vim-devicons')
-- fuzzy finder
Plug('ibhagwan/fzf-lua')
Plug('ap/vim-css-color')
-- Powerline
Plug('feline-nvim/feline.nvim')
Plug ('nvim-tree/nvim-web-devicons')
-- Git
-- @test are these two the same?
Plug('lewis6991/gitsigns.nvim')
Plug('tpope/vim-fugitive')
-- DB
Plug('tpope/vim-dadbod')
Plug('mbbill/undotree')
-- nvim notify
Plug('rcarriga/nvim-notify')
Call('plug#end')

-- setup plugins
-- will be found under plugins folder.
--   if on windows prepare.ps1 will move the files to correct place
--   @todo: haven't tested it on linux yet
require 'user.setting'
require 'user.keys'
require 'user.colors'
require 'user.feline_setup'
require 'user.lsp'
require 'user.cmp'
