export NIXPKGS_ALLOW_UNFREE=1

#
# install packages
nix-env -iA nixpkgs.nushell  \
    nixpkgs.libstdcxx5                    \
    nixpkgs.fnm                           \
    nixpkgs.neovim                        \
    nixpkgs.neovide                       \
    nixpkgs.helix                         \
    nixpkgs.tmux                          \
    nixpkgs.zsh                           \
    nixpkgs.zathura                       \
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
    nixpkgs.flameshot                     \
    nixpkgs.zig                           \
    nixpkgs.zls                           \
    nixpkgs.autojump                      \
    nixpkgs.spotify                       \
    nixpkgs.spicetify-cli                 \
    nixpkgs.arandr                        \
    nixpkgs.unzip                         \
    nixpkgs.gimp                          \
    nixpkgs.stow                          \
    nixpkgs.zsh                           \
    nixpkgs.rofi                          \
    nixpkgs.thefuck

# zsh plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

cd stow-dir & stow stow*;
# copy themes
./zsh/.config/zsh/jovial/installer.sh
cp ./zsh/.config/zshzsh/theme-standalone/* $ZSH_CUSTOM/themes
cd ..
