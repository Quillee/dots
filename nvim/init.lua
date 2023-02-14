-- globals
local Plug = vim.fn['plug#']
local Call = vim.call

-- plugins
Call('plug#begin', '~/.vim/plugged')
-- Deps
Plug('nvim-lua/plenary.nvim')
-- Comments
Plug('tpope/vim-commentary')
Plug('nvim-telescope/telescope.nvim')
Plug('nvim-telescope/telescope-fzy-native.nvim')
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
Plug('VonHeikemen/lsp-zero.nvim')
    -- lsp support
    Plug('neovim/nvim-lspconfig')
    Plug('williamboman/mason.nvim')
    Plug('williamboman/mason-lspconfig.nvim')

    -- auto completion
    Plug("hrsh7th/nvim-cmp") -- The completion plugin
    Plug('onsails/lspkind.nvim') -- lsp kind stuff
    Plug('jose-elias-alvarez/null-ls.nvim')
    Plug('glepnir/lspsaga.nvim', { ['branch'] = 'main' })
    Plug('hrsh7th/cmp-nvim-lsp')
    Plug("hrsh7th/cmp-buffer") -- buffer completions
    Plug("hrsh7th/cmp-path") -- path completions
    Plug("hrsh7th/cmp-cmdline") -- cmdline completions
    Plug("saadparwaiz1/cmp_luasnip") -- snippet completions

    -- snippets
    Plug("L3MON4D3/LuaSnip")
    Plug("rafamadriz/friendly-snippets")
-- debugger support
Plug('mfussenegger/nvim-dap')
---- Specific lang
    -- Rust
    Plug('saecki/crates.nvim', { ['tag'] = 'v0.3.0' })
    -- end rust
    ------ Zig
    -- Plug('zigland/zig.vim')
    ------ end Zig
    Plug('ray-x/go.nvim')
    Plug('mattn/emmet-vim')
---- end Specific lang
Plug('ray-x/guihua.lua')
-- Linter & other features
Plug('nvim-treesitter/nvim-treesitter')
-- Plug('nvim-treesitter/playground')
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
Plug('theprimeagen/harpoon')
-- Powerline
Plug('feline-nvim/feline.nvim')
Plug ('nvim-tree/nvim-web-devicons')
-- Git
Plug('lewis6991/gitsigns.nvim')
-- @test are these two the same?
Plug('lewis6991/gitsigns.nvim')
Plug('tpope/vim-fugitive')
-- DB
Plug('tpope/vim-dadbod')
Plug('mbbill/undotree')
-- nvim notify
Plug('rcarriga/nvim-notify')
Call('plug#end')

-- user scripts
require 'user.setting'
require 'user.keys'
require 'user.colors'

-- plugins that depend on user scripts
require 'user.feline_setup'

-- setup for plugins
require 'colorizer'.setup()
