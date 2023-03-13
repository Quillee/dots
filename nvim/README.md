# Simple NEOVIM setup

## fzf requirements

1. download the following:
    1. fd
    1. ripgrep
    1. fzf (this might not actually be required 🤔)
1. then if you're still running into problems, go to `~/.vim/plugged/telescope-fzf-native.nvim/` and run `make`

## Plugins

vim-plug is simple so here's the command to set it up

sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
