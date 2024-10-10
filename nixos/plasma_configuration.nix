# Edit this configuration file to define what should be installed on

{ config, pkgs, ... }:

let
  unstable = import
    (builtins.fetchTarball  https://github.com/nixos/nixpkgs/tarball/nixos-unstable)
    {config = config.nixpkgs.config;};

    in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-10cf08bc-30d3-4f8e-8f28-b1e0335fc175".device = "/dev/disk/by-uuid/10cf08bc-30d3-4f8e-8f28-b1e0335fc175";
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver = {
  	enable = true;
	# displayManager = {
	# 	session = [
	# 	  {
	# 		manage = "desktop";
	# 		name = "plasma6+i3";
	# 		start = ''exec env kdewm=${pkgs.i3-gaps}/bin/i3 ${pkgs.plasma-workspace}/bin/startplasma-x11'';
	# 	   }
	# 	];
	#        };
  };
  services.displayManager.sddm.enable = true;
  # services.displayManager.defaultSession = "plasma6+i3";

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager = {
	  plasma6.enable = true;
  };

  # Enable bluetooth services
  hardware = {
    bluetooth = {
        enable = true;
        # Needed this to properly display battery
        # percentage for my cheap bluetooth earbuds
        settings.General.Experimental = true;
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell=pkgs.fish;
  users.users.kohaku = {
    isNormalUser = true;
    description = "kohaku";
    extraGroups = [ "networkmanager" "wheel" ];
    password = "new_kohaku";
    shell = pkgs.fish;
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.partitionmanager
      discord
      tidal-hifi
      tidal-dl
      nerdfonts
      zig
      go
      fnm
      pyenv
      tmux
    ];
  };
  # Global packages
   environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      wget
      unstable.neovim
      neovide
      git
      rofi
      kitty
      neofetch
      btop
      arandr
      _1password-gui
      steam

      gcc
      premake5
      cmake
      gnumake

      i3
      i3status
      i3lock
      i3blocks
      i3-gaps

      feh
      wmctrl
      fzf
      thefuck
      autojump
      bat
      stow
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
# Did you read the comment?
  system.stateVersion = "24.05"; 
}
