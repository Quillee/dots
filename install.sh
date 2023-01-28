# install
curl -L https://nixos.org/nix/install | sh

# source
. ~/.nix-profile/etc/profile.d/nix.sh

# install some things system-wide cause nix can't properly setup
# Arch
#
# sudo pacman -Sy yay kitty clang firefox rofi ttf-firacode-nerd ttf-iosevka-nerd
# yay -Sy nerd-fonts-jetbrains-mono-160
#

# echo locale archive env var for nix to know where to look
echo "LOCALE_ARCHIVE=/usr/lib/locale-archive" >> /etc/profile


# install packages
nix-env -iA nixpkgs.nushell  \
    nixpkgs.libstdcxx5                    \
    nixpkgs.nodejs                        \
    nixpkgs.neovim                        \
    nixpkgs.neovide                       \
    nixpkgs.helix                         \
    nixpkgs.tmux                          \
    nixpkgs.zsh                           \
    nixpkgs.zathura                       \
    nixpkgs.awesome                       \
    nixpkgs.antibody                      \
    nixpkgs.fzf                           \
    nixpkgs.yarn                          \
    nixpkgs.ripgrep                       \
    nixpkgs.bat                           \
    nixpkgs.direnv                        \
    nixpkgs.lua                           \
    nixpkgs.sumneko-lua-language-server   \
    nixpkgs.rnix-lsp                      \
    nixpkgs.rust                          \
    nixpkgs.cargo                         \
    nixpkgs.eww                           \
    nixpkgs.flameshot                     \
    nixpkgs.zig                           \
    nixpkgs.zls                           \
    nixpkgs.autojump                      \
    nixpkgs.spotify                       \
    nixpkgs.spicetify-cli                 \
    nixpkgs.nerdfonts                     \
    nixpkgs.arandr                        \
    nixpkgs.unzip                         \
    nixpkgs.thefuck

# install vim-plug
curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# copy neovim
cp ./nvim ~/.config

# zsh plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# copy themes
./zsh/jovial/installer.sh
cp ./zsh/theme-standalone/* $ZSH_CUSTOM/themes
cp ./zsh/.zshrc ~

# copy kitty config
cp ./kitty ~/.config

# copy helix
cp ./helix ~/.config


# copy tmux
cp ./tmux ~/.config

