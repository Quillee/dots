" highlight Normal guibg=none
call plug#begin('~/.vim/plugged')
" Deps
Plug 'nvim-lua/plenary.nvim'
" Quick file search
Plug 'nvim-telescope/telescope.nvim'
" Incremental search
Plug 'haya14busa/incsearch.vim'
" Colorschemes
Plug 'tjdevries/colorbuddy.nvim'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'lalitmee/cobalt2.nvim'
Plug 'folke/tokyonight.nvim'
Plug 'savq/melange'
" LSP
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer'
Plug 'glepnir/lspsaga.nvim', { 'branch': 'main' }
" Linter & other features
Plug 'nvim-treesitter/nvim-treesitter'
" Markdown viewer
Plug 'frabjous/knap'
" File manager and deps
Plug 'ms-jpq/chadtree', { 'branch': 'chad', 'do': 'python -m chadtree deps' }
Plug 'ryanoasis/vim-devicons'
" fuzzy finder
Plug 'ibhagwan/fzf-lua'
" Powerline

Plug 'feline-nvim/feline.nvim'
" Git
" @test are these two the same?
Plug 'lewis6991/gitsigns.nvim'
Plug 'tpope/vim-fugitive'
" DB
Plug 'tpope/vim-dadbod'
Plug 'mbbill/undotree'
" nvim notify
Plug 'rcarriga/nvim-notify'
call plug#end()

" Colors
colo tokyonight
lua require('colorbuddy').colorscheme('cobalt2')
set t_Co=256


" feline setup
lua << END
require('feline').setup()
END

" Leader
let mapleader = " "

" Auto Commands example
" function that can be called using :call
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

augroup MEH
    autocmd!
    autocmd BufWritePre * :call TrimWhitespace()
augroup END

