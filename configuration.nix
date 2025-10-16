{ config, pkgs, lib, inputs, ... }:

{
  # Import hardware configuration
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        device = "nodev";  # Use efi only, no MBR
        
        # GRUB theming
        theme = null;
        fontSize = 16;
        
        # Additional kernel parameters via GRUB
        extraConfig = ''
          set timeout=5
          set default=0
        '';
      };
      efi.canTouchEfiVariables = true;
    };
    
    kernelParams = [ "zswap.enabled=1" "zswap.compressor=zstd" "zswap.max_pool_percent=25" "nowatchdog" ];

    # Latest stable kernel
    kernelPackages = pkgs.linuxPackages_latest;
    
    # Kernel modules for WiFi and Bluetooth
    initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];

    # Memory and swap optimization for laptop
    kernel.sysctl = {
        # Reduce swap usage - keep RAM available for cache (0=never, 100=aggressive)
        "vm.swappiness" = 10;
        
        # Allow overcommit to prevent OOM kills
        "vm.overcommit_memory" = 1;
    };
    
    # LUKS configuration
    initrd.luks.devices."cryptroot" = {
      # Allow TRIM commands for SSD performance
      allowDiscards = true;
      # Bypass dm-crypt internal queue for better SSD performance
      bypassWorkqueues = true;
    };
  };

  # Network configuration
  networking = {
    hostName = "nixos-laptop";
    
    # NetworkManager for convenient WiFi management
    networkmanager = {
      enable = true;
      # Disable WiFi power saving for stability
      wifi.powersave = false;
    };
    
    # Disable dhcpcd in favor of NetworkManager
    useDHCP = false;
    
    # Firewall configuration
    firewall = {
      enable = true;
      allowPing = true;
    };
  };

  # Time zone and localization
  time.timeZone = "Europe/Riga";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };

  # Power management for laptop
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  # Services for power management
  services = {
    # Sound server (Pipewire)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    
    # Printing support
    printing.enable = true;
    
    # GNOME Keyring for secure credential storage
    gnome.gnome-keyring.enable = true;
  };

  # GNOME desktop environment
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # GNOME configuration
  environment.gnome.excludePackages = with pkgs; [
    gnome-maps
    gnome-calendar
  ];
  
  # Desktop Portal
  xdg.portal.enable = true;

  # Audio configuration
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Bluetooth hardware
  hardware.bluetooth.enable = true;

  # User configuration
  users.users.rovert = {
    isNormalUser = true;
    description = "rovert";
    extraGroups = [ 
      "wheel"          # sudo access
      "networkmanager" # network management
      "audio"          # audio devices
      "video"          # video devices
      "storage"        # storage devices
      "optical"        # optical drives
      "scanner"        # scanners
      "lp"             # printers
      "input"          # input devices
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    neovim
    curl
    wget
    
    # System tools
    btop
    ncdu
    
    # Multimedia
    mpv
    vlc
    mpv
    
    # Archives
    p7zip
    unrar
    
    # Terminal
    kitty
    
    # GNOME utilities
    gnome-tweaks        # Customize GNOME appearance
    gnome-shell-extensions  # Extensions for GNOME
    dconf-editor        # GNOME settings editor
  ];

  # Fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      dejavu_fonts
      font-awesome
      
      # JetBrains Mono Nerd Font
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];
    
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "DejaVu Serif" ];
        sansSerif = [ "DejaVu Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" "DejaVu Sans Mono" ];
      };
    };
  };

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "25.05";

  
  # Ensure critical partitions are available early in boot
  fileSystems."/var/log".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;

  # Enable periodic TRIM for SSD health
  services.fstrim.enable = true;
}

