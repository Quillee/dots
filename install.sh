# install
# curl -L https://nixos.org/nix/install | sh
sh <(curl -L https://nixos.org/nix/install) --daemon

# source
sudo . ~/.nix-profile/etc/profile.d/nix.sh

# install some things system-wide cause nix can't properly setup
# Arch
#
# sudo pacman -Sy yay kitty clang firefox rofi ttf-firacode-nerd ttf-iosevka-nerd
# yay -Sy nerd-fonts-jetbrains-mono-160
#

# echo locale archive env var for nix to know where to look
sudo echo "LOCALE_ARCHIVE=/usr/lib/locale-archive" >> /etc/profile

# install vim-plug
curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

