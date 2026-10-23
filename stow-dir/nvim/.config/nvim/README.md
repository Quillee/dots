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

## .NET and Angular

Opening a C#, Razor, or Angular file installs and starts the configured tooling through Lazy and Mason.

- Roslyn provides C#/Razor completion, diagnostics, navigation, formatting, inlay hints, and code lenses.
- Angular Language Service provides template and TypeScript awareness.
- `netcoredbg` and `nvim-dap` provide C# debugging. Use `F5`, `F10`, `F11`, and `Shift-F11` to control a session.
- `<leader>pb`, `<leader>pt`, `<leader>pr`, and `<leader>pw` build, test, run, and watch the nearest .NET workspace.
- `<leader>db`, `<leader>dr`, `<leader>ds`, and `<leader>dt` control breakpoints, the REPL, scopes, and termination.

Open Neovim from the repository root so Roslyn can select the solution and project commands can resolve the current service.
