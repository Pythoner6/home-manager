{ config, pkgs, specialArgs, ... }: let 
  inherit (specialArgs) zenburn username;
in rec {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  fonts.fontconfig.enable = true;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    git
    file
    #libsForQt5.kgpg
    ripgrep
    kubectl
    talosctl
    xxd
    #pinentry-gnome
    gnomeExtensions.windownavigator
    gnomeExtensions.gsconnect
    (pkgs.writeShellScriptBin "toggle-vpn" ''
      name='Homelab (strongswan)'
      nmcli connection show "$name" | grep VPN.VPN-STATE | grep -q '5 - VPN connected'
      if [[ $? == 0 ]]; then
        nmcli connection down "$name"
      else
        nmcli connection up "$name"
      fi
    '')
    (pkgs.nerdfonts.override { fonts = [ "SourceCodePro" ]; })
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/joseph/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.shellAliases = {
    vi = "nvim";
    k = "kubectl";
    t = "talosctl";
    hm = "home-manager";
  };

  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = ["scale-monitor-framebuffer"];
      edge-tiling = true;
    };
    "org/gnome/desktop/input-sources" = {
      xkb-options = ["terminate:ctrl_alt_bksp" "caps:escape"];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/Console" = {
      custom-font = "SauceCodePro Nerd Font Mono 10";
      theme = "night";
      use-system-font = false;
    };
    "org/gnome/shell" = {
      enabled-extensions=["windowsNavigator@gnome-shell-extensions.gcampax.github.com" "gsconnect@andyholmes.github.io"];
      disabled-extensions=[];
      favorite-apps=["org.mozilla.firefox.desktop" "org.gnome.Nautilus.desktop" "org.gnome.Console.desktop"];
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  programs.bash = {
    enable = true;
    initExtra = let 
      completionForAlias = alias: let
        target = builtins.getAttr alias home.shellAliases;
      in ''
        _completion_loader ${target}
        eval "$(complete -p ${target} | sed 's/${target}$/${alias}/')"
      '';
      aliasCompletions = map completionForAlias [ "vi" "k" "t" "hm" ];
    in ''
      ${builtins.concatStringsSep "\n" aliasCompletions}
    '';
  };

  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
      pcsc-shared = true;
      disable-application = "piv";
    };
    package = pkgs.gnupg.overrideAttrs (finalAttrs: prevAttrs: {
      patches = prevAttrs.patches ++ [ ./gnupg.patch ];
    });
  };
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentryFlavor = "gnome3";
  };

  programs.nixvim = {
    enable = true;
    extraPlugins = [ zenburn ];
    colorscheme = "zenburn";
    globals.mapleader = " ";
    options = {
      expandtab = true;
      number = true;
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      mouse = "";
    };
    plugins = {
      nvim-cmp = {
        enable = true;
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
        ];
      };
      lualine.enable = true;
      lspkind.enable = true;
      telescope.enable = true;
      trouble.enable = true;
      gitgutter.enable = true;
      diffview.enable = true;
      cmp-nvim-lsp.enable = true;
      dap = {
        enable = true;
        extensions = {
          dap-go.enable = true;
          dap-ui.enable = true;
        };
      };
      lsp = {
        enable = true;
        keymaps = {
          diagnostic = {
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };
          lspBuf = {
            "gd" = "definition";
            "gD" = "references";
            "gt" = "type_definition";
            "gi" = "implementation";
            "K" = "hover";
          };
        };
        servers = {
          nixd.enable = true;
          gopls.enable = true;
          rust-analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
        };
      };
    };
  };
}
