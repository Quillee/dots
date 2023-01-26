# use nix if available
if [ -e /home/win/.nix-profile/etc/profile.d/nix.sh ]; then . /home/win/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

# source all plugins
source ~/.config/zsh/.zsh_plugins.sh

ZSH_THEME="geometry"

