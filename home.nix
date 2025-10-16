{ config, pkgs, lib, ... }:

{
  # User information
  home = {
    username = "rovert";
    homeDirectory = "/home/rovert";
    stateVersion = "25.05";
    
    # User packages (many Rust CLI tools for better UX)
    packages = with pkgs; [
      # Development essentials
      python3
      rustc
      cargo
      gcc
      gnumake
      pkg-config
      
      # Modern text editors
      neovim
      helix                  # Modern editor written in Rust
      
      # CLI utilities (Rust replacements for traditional tools)
      bat                    # cat with syntax highlighting
      eza                    # ls replacement, modern and colorful
      fd                     # find replacement, faster and user-friendly
      ripgrep                # grep replacement, very fast
      fzf                    # fuzzy finder
      zoxide                 # cd replacement with smart navigation
      starship               # cross-shell prompt
      atuin                  # shell history sync & search (Rust)
      delta                  # git diff viewer with syntax highlighting (Rust)
      du-dust                # du replacement for disk space (Rust)
      dua                    # interactive disk usage analyzer (Rust)
      sd                     # sed replacement (Rust)
      grex                   # generates regex patterns from examples (Rust)
      tokei                  # count lines of code (Rust)
      hyperfine              # command benchmarking tool (Rust)
      procs                  # ps replacement (Rust)
      bottom                 # system monitor like top/htop (Rust)
      
      # Git tools
      gh                     # GitHub CLI
      git-cliff              # changelog generator from git history (Rust)
      gitui                  # blazingly fast git UI (Rust)
      
      # Development utilities
      just                   # command runner (Rust)
      
      # Multimedia
      mpv                    # video player
      imagemagick            # image manipulation
      ffmpeg                 # multimedia framework
      
      # System utilities
      btop                   # system monitor
      fastfetch              # system info display
      curl                   # HTTP client
      wget                   # download manager
      jq                     # JSON processor
      yq                     # YAML/JSON processor
      
      # Additional useful tools
      nix-search-cli         # search nixpkgs from CLI
      direnv                 # environment per directory
      watchexec              # run commands on file changes (Rust)
      
      # Fonts
      nerd-fonts.jetbrains-mono  # JetBrains Mono with Nerd Font icons
    ];
    
    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "librewolf";
      TERMINAL = "kitty";
      
      # Development settings
      RUST_BACKTRACE = "1";
      PYTHONDONTWRITEBYTECODE = "1";
      
      # Improve performance
      CARGO_INCREMENTAL = "0";
    };
  };

  # Configured programs and services
  programs = {
    # Home Manager enables itself
    home-manager.enable = true;
    
    # Git configuration
    git = {
      enable = true;
      userName = "rovert";
      userEmail = "your-email@example.com";  # Update with your email
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        
        # Use delta for better diffs
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        delta.navigate = true;
      };
    };
    
    # Fish shell configuration
    fish = {
      enable = true;
      interactiveShellInit = ''
        # Initialize starship prompt
        starship init fish | source
        
        # Initialize zoxide for smart navigation
        zoxide init fish | source
        
        # Initialize atuin for better history
        atuin init fish | source
        
        # Use exa icons by default
        set -gx fish_greeting
      '';
      
      shellAliases = {
        # File operations
        ll = "eza -lh";
        la = "eza -lah";
        ls = "eza --icons";
        cat = "bat";
        
        # Navigation
        cd = "z";
        
        # Search and find
        find = "fd";
        grep = "rg";
        
        # System monitoring
        top = "bottom";
        du = "du-dust";
        
        # Git shortcuts
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gd = "git diff";
        gl = "git log --oneline -10";
        
        # NixOS specific
        rebuild = "sudo nixos-rebuild switch --flake .";
        upgrade = "sudo nixos-rebuild switch --upgrade-all --flake .";
        clean = "sudo nix-collect-garbage -d";
        flake-update = "nix flake update";
        search = "nix search nixpkgs";
      };
      
      functions = {
        # Quick directory creation and navigation
        mkcd = "mkdir -p $argv && cd $argv";
        
        # Git clone and cd
        gcl = "git clone $argv[1] && cd (basename $argv[1] .git)";
        
        # Nix shell helper
        ns = "nix shell $argv -c $SHELL";
      };
    };
    
    # Starship prompt configuration
    starship = {
      enable = true;
      settings = {
        format = "$username$hostname$directory$git_branch$git_status$nodejs$rust$python$fill$cmd_duration$time$line_break$character";
        
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
        };
        
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };
        
        git_branch.symbol = "🌱 ";
        
        nodejs.disabled = false;
        rust.disabled = false;
        python.disabled = false;
        
        cmd_duration.min_time = 500;
        cmd_duration.format = "[$duration]($style) ";
      };
    };
    
    # Kitty terminal
    kitty = {
      enable = true;
      settings = {
        font_family = "JetBrains Mono";
        font_size = 12;
        background_opacity = "0.9";
        
        # Catppuccin theme colors
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        
        # Window settings
        window_padding_width = 10;
        window_margin_width = 0;
        
        # Performance
        enable_audio_bell = false;
      };
    };
    
    # Librewolf configuration
    librewolf = {
      enable = true;
      profiles.default = {
        isDefault = true;
        settings = {
          "browser.startup.homepage" = "about:home";
          "browser.search.defaultenginename" = "DuckDuckGo";
          "privacy.trackingprotection.enabled" = true;
        };
      };
    };
    
    # VS Code configuration
    vscode = {
      enable = true;
      userSettings = {
        # Editor settings
        "editor.fontFamily" = "JetBrains Mono";
        "editor.fontSize" = 12;
        "editor.formatOnSave" = true;
        
        # Nix settings
        "nix.enableLanguageServer" = true;
        "nix.linterType" = "statix";
      };
      
      extensions = with pkgs.vscode-extensions; [
        # Nix development
        bbenoist.nix
        jnoortheen.nix-ide
        
        # Rust development
        rust-lang.rust-analyzer
        
        # Python
        ms-python.python
        ms-python.vscode-pylance
        
        # Web development
        bradlc.vscode-tailwindcss
        dbaeumer.vscode-eslint
        
        # Utilities
        eamodio.gitlens
        gruntfuggly.todo-tree
        ms-vscode-remote.remote-ssh
      ];
    };
    
    # Direnv for environment variables per directory
    direnv = {
      enable = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };
    
    # Atuin shell history
    atuin = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        show_preview = true;
        previewHeight = 4;
        filter_mode = "directory";  # Filter history by directory
      };
    };
  };

  # Services configuration
  services = {
    # Display server management
    gpg-agent = {
      enable = true;
      pinentryFlavor = "gtk2";
      defaultCacheTtl = 34560000;
    };
    
    # Optional: Automatic light/dark theme switching
    redshift = {
      enable = false;  # Set to true if you want automatic brightness adjustment
      latitude = 55.7558;   # Update with your location (Moscow by default)
      longitude = 37.6176;
      temperature = {
        day = 6500;
        night = 3500;
      };
    };
  };

  # GTK theme configuration
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    
    cursorTheme = {
      name = "Breeze-Dark";
      size = 24;
    };
  };

  # Qt theme for consistency with GTK
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
  };

  # XDG configuration
  xdg = {
    enable = true;
    
    # MIME type associations
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "text/plain" = "nvim.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "image/jpeg" = "mpv.desktop";
        "image/png" = "mpv.desktop";
        "video/mp4" = "mpv.desktop";
      };
    };
    
    # XDG user directories
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      publicShare = "$HOME/.local/share/Public";
    };
  };

  # Dotfiles configuration (optional)
  home.file.".config/starship.toml".text = lib.mkIf config.programs.starship.enable ''
    # Starship config is managed via programs.starship.settings
  '';

  # Enable fontconfig
  fonts.fontconfig.enable = true;
}
