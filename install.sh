# install
curl -L https://nixos.org/nix/install | sh

# source
. ~/.nix-profile/etc/profile.d/nix.sh

# install packages
nix-env -iA nixpkgs.nushell  \
	nixpkgs.neovim   \
	nixpkgs.tmux     \
	nixpkgs.zsh      \
	nixpkgs.antibody \
	nixpkgs.fzf      \
	nixpkgs.yarn     \
	nixpkgs.ripgrep  \
	nixpkgs.bat      \
	nixpkgs.direnv   \
	nixpkgs.lua      \
    nixpkgs.clang    \
    nixpkgs.rust     \
    nixpkgs.zig

# install vim-plug
curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# change shell to zsh
command -v zsh | sudo tee -a /etc/shells

# default to zsh
sudo chsh -s $(which zsh) $USER

# zsh plugins
antibody bundle < ./zsh/.zsh_plugins.txt > ~/.config/zsh/.zsh_plugins.sh
