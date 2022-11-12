# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

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
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable network manager applet
  programs.nm-applet.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the MATE Desktop Environment.
  services.xserver.displayManager.defaultSession = "mate";
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.tiny = {
        enable = true;
	extraConfig = '' 
	      /* GTK UI CSS */
	      static const gchar *style =
	      "window {"
	            "background-image: url(\"/etc/nixos/background.jpg\");"
	            "background-position: center;"
	      "}"
	      "window * {"
	          "font: 28px \"tewi2a\";"
	          "-gtk-dpi: 131;"
	      "}"
	      "#prompt_box {"
	          "background-color: #414141;"
	          "margin: 200px 650px 200px 650px;"
	          "padding: 25px 0 25px 0;"
	          "border-right: 15px solid #e2a76d;"
	      "}"
	      "label {"
	          "color: #e2a76d;"
	          "margin-right: 25px;"
	      "}"
	      "entry {"
	          "color: #e2a76d;"
	          "background-color: #414141;"
	          "caret-color: #e2a76d;"
	          "box-shadow: 2px 2px #414141 inset;"
	      "}"
	      "#message_label {"
	          "color: red;"
	      "}";
	      /* GTK UI XML*/
	      static const gchar *ui =
	      "<?xml version='1.0' encoding='UTF-8'?>"
	      "<interface>"
	        "<requires lib='gtk+' version='3.20'/>"
	        "<object class='GtkWindow' id='login_window'>"
	          "<property name='name'>login_window</property>"
	          "<property name='can_focus'>False</property>"
	          "<property name='resizable'>False</property>"
	          "<property name='accept_focus'>False</property>"
	          "<property name='decorated'>False</property>"
	          "<child>"
	            "<placeholder/>"
	          "</child>"
	          "<child>"
	            "<object class='GtkBox' id='login_box'>"
	              "<property name='name'>login_box</property>"
	              "<property name='visible'>True</property>"
	              "<property name='can_focus'>False</property>"
	              "<property name='valign'>center</property>"
	              "<property name='vexpand'>True</property>"
	              "<property name='orientation'>vertical</property>"
	              "<child>"
	                "<object class='GtkBox' id='prompt_box'>"
	                  "<property name='name'>prompt_box</property>"
	                  "<property name='visible'>True</property>"
	                  "<property name='can_focus'>False</property>"
	                  "<property name='spacing'>15</property>"
	                  "<property name='homogeneous'>True</property>"
	                  "<child>"
	                    "<object class='GtkLabel' id='prompt_label'>"
	                      "<property name='name'>prompt_label</property>"
	                      "<property name='visible'>True</property>"
	                      "<property name='can_focus'>False</property>"
	                      "<property name='halign'>end</property>"
	                    "</object>"
	                    "<packing>"
	                      "<property name='expand'>False</property>"
	                      "<property name='fill'>True</property>"
	                      "<property name='position'>0</property>"
	                    "</packing>"
	                  "</child>"
	                  "<child>"
	                    "<object class='GtkEntry' id='prompt_entry'>"
	                      "<property name='name'>prompt_entry</property>"
	                      "<property name='visible'>True</property>"
	                      "<property name='can_focus'>True</property>"
	                      "<property name='halign'>start</property>"
	                      "<property name='has_frame'>False</property>"
	                      "<property name='max_width_chars'>15</property>"
	                      "<property name='primary_icon_activatable'>False</property>"
	                      "<property name='secondary_icon_activatable'>False</property>"
	                      "<signal name='activate' handler='login_cb' swapped='no'/>"
	                    "</object>"
	                    "<packing>"
	                      "<property name='expand'>False</property>"
	                      "<property name='fill'>True</property>"
	                      "<property name='position'>1</property>"
	                    "</packing>"
	                  "</child>"
	                "</object>"
	                "<packing>"
	                  "<property name='expand'>False</property>"
	                  "<property name='fill'>True</property>"
	                  "<property name='position'>0</property>"
	                "</packing>"
	              "</child>"
	              "<child>"
	                "<object class='GtkLabel' id='message_label'>"
	                  "<property name='name'>message_label</property>"
	                  "<property name='visible'>True</property>"
	                  "<property name='can_focus'>False</property>"
	                  "<property name='halign'>center</property>"
	                  "<property name='width_chars'>25</property>"
	                  "<property name='max_width_chars'>50</property>"
	                "</object>"
	                "<packing>"
	                  "<property name='expand'>False</property>"
	                  "<property name='fill'>True</property>"
	                  "<property name='position'>1</property>"
	                "</packing>"
	              "</child>"
	            "</object>"
	          "</child>"
	        "</object>"
	      "</interface>";
       '';

    };
  };

  services.xserver.desktopManager.mate.enable = true;
  services.xserver.windowManager.i3= {
    enable= true;
    package = pkgs.i3-gaps;
    extraPackages= with pkgs; [
      dmenu
      i3status
      i3lock
      i3-gaps
    ];
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = true;
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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kohaku = {
    isNormalUser = true;
    description = "kohaku";
    extraGroups = [ "networkmanager" "wheel" ];
    password = "new_kohaku";
    shell  = pkgs.zsh;
    packages = with pkgs; [
      firefox
      discord
      spotify
      nerdfonts
      spicetify-cli
      blueman
    #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      wget
      unstable.neovim
      neovide
      git
      eww
      dconf
      gnome.dconf-editor
      rofi
      kitty
      neofetch
      htop
      arandr
      _1password-gui
      cinnamon.nemo
      steam
      zsh
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.zsh = {
      enable = true;
      zsh-autoenv = {
          enable = true;
      };
      autosuggestions = {
          enable = true;
      };
      ohMyZsh = {
          enable = true;
	  theme  = "half-life";
      };
  };

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
  system.stateVersion = "22.05"; # Did you read the comment?

}
