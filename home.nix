{ config, pkgs, specialArgs, ... }: let 
  inherit (specialArgs) zenburn username pkgs-unstable;
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
  home.packages = (with pkgs-unstable; [
    ghostty
  ]) ++ (with pkgs; [
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
    wl-clipboard
    (prismlauncher.override {
      jdks = [ jdk21 ];
    })
    git
    nix-output-monitor
    lazygit
    file
    #libsForQt5.kgpg
    ripgrep
    kubectl
    talosctl
    xxd
    unzip
    #gns3-gui
    #pinentry-gnome
    gnomeExtensions.windownavigator
    gnomeExtensions.gsconnect
    gnomeExtensions.hibernate-status-button
    gnomeExtensions.steal-my-focus-window
    qemu_kvm
    (writeShellScriptBin "toggle-vpn" ''
      name='Homelab (strongswan)'
      nmcli connection show "$name" | grep VPN.VPN-STATE | grep -q '5 - VPN connected'
      if [[ $? == 0 ]]; then
        nmcli connection down "$name"
      else
        nmcli connection up "$name"
      fi
    '')
    #(nerdfonts.override { fonts = [ "SourceCodePro" ]; })
    nerd-fonts.sauce-code-pro
    helix
  ]);

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
      show-battery-percentage = true;
    };
    "org/gnome/Console" = {
      custom-font = "SauceCodePro Nerd Font Mono 10";
      theme = "night";
      use-system-font = false;
    };
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-battery-type = "suspend";
      sleep-inactive-battery-timeout = 900;
      sleep-inactive-ac-type = "suspend";
      sleep-inactive-ac-timeout = 900;
      power-saver-profile-on-low-battery = true;
    };
    "org/gnome/shell" = {
      disabled-extensions = [];
      enabled-extensions = [
        "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
        "gsconnect@andyholmes.github.io"
        "hibernate-status@dromi"
        "steal-my-focus-window@steal-my-focus-window"
      ];
      favorite-apps = [
        "org.mozilla.firefox.desktop"
        "org.gnome.Nautilus.desktop"
        "org.gnome.Console.desktop"
      ];
    };
    "org/gnome/shell/extensions/hibernate-status-button" = {
      show-suspend-then-hibernate = false;
      show-hybrid-sleep = false;
      show-suspend = false;
      show-hibernate = true;
      show-hibernate-dialog = true;
      show-shutdown = true;
      show-restart = true;
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
    config = {
      global = {
        hide_env_diff = true;
      };
    };
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
    pinentry.package = pkgs.pinentry-qt;
    #pinentryPackage = pkgs.pinentry-tty;
    #pinentryFlavor = "gnome3";
  };

  programs.nixvim = {
    enable = true;
    extraPlugins = [ 
      zenburn 
      (pkgs.fetchFromGitHub {
        owner = "apple";
        repo = "pkl-neovim";
        rev = "a0ae099c7eb926150ee0a126b1dd78086edbe3fc";
        hash = "sha256-Lv5WZCthqP2wtJy35D/WCE+5OBnUmw3E4ETnL95IuCw=";
      })
      pkgs.vimPlugins.lazygit-nvim
      #(pkgs.vimPlugins.lazygit-nvim.overrideAttrs (prev: final: {
      #  patches = [./lazygit.nvim.patch];
      #}))
    ];
    extraConfigLua = let 
      lazyGitConfig = pkgs.writeText "lazygit.yaml" ''
        git:
          paging:
            colorArg: always
            pager: ${pkgs.delta}/bin/delta --dark --syntax-theme zenburn --paging=never
          autoFetch: false
          overrideGpg: false
        gui:
          theme:
            activeBorderColor:
            - "#6fbf6f"
            - bold
            selectedLineBgColor:
            - "#434443"
            - bold
            unstagedChangesColor:
            - "#cc6363"
            optionsTextColor:
            - "#6c6c9c"
      '';
    in ''
      do
        vim.g.lazygit_use_custom_config_file_path = 1
        vim.g.lazygit_config_file_path = '${lazyGitConfig}'
      end
    '';
    colorscheme = "zenburn";
    globals.mapleader = " ";
    opts = {
      expandtab = true;
      number = true;
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      mouse = "";
      scrolloff = 15;
    };
    keymaps = [
      {
        mode = "n";
        key = "<Leader>g";
        action = "<cmd>LazyGitCurrentFile<CR>";
      }
      {
        mode = "i";
        key = "<C-p>";
        action.__raw = ''
          function()
            vim.lsp.buf.signature_help()
          end
        '';
      }
      {
        mode = "i";
        key = "<Tab>";
        options = { silent = true; expr = true; remap = true; };
        action.__raw = ''
          function()
            local luasnip = require'luasnip' 
            if luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
            end
          end
        '';
      }
      {
        mode = "i";
        key = "<S-Tab>";
        options.silent = true;
        action = "<cmd>lua require'luasnip'.jump(-1)<Cr>";
      }
      {
        mode = "s";
        key = "<Tab>";
        options.silent = true;
        action = "<cmd>lua require'luasnip'.jump(1)<Cr>";
      }
      {
        mode = "s";
        key = "<S-Tab>";
        options.silent = true;
        action = "<cmd>lua require'luasnip'.jump(-1)<Cr>";
      }
    ];
    plugins = {
      neogit = {
        enable = true;
      };
      rust-tools = {
        serverPackage = null;
      };
      luasnip = {
        enable = true;
      };
      web-devicons.enable = true;
      treesitter = {
        enable = true;
        grammarPackages = pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars ++ [
          (pkgs.tree-sitter.buildGrammar {
            language = "pkl";
            version = "0.16.0";
            src = pkgs.fetchFromGitHub {
              owner = "apple";
              repo = "tree-sitter-pkl";
              rev = "main";
              hash = "sha256-6cO968oEF+pcPGm4jiIC3layFzQf6eQa4m6iOReeo4w=";
            };
          })
          (pkgs.tree-sitter.buildGrammar {
            language = "cue";
            version = "dev";
            src = pkgs.fetchFromGitHub {
              owner = "eonpatapon";
              repo = "tree-sitter-cue";
              rev = "8a5f273bfa281c66354da562f2307c2d394b6c81";
              hash = "sha256-uV7Tl41PCU+8uJa693km5xvysvbptbT7LvGyYIelspk=";
            };
          })
        ];
      };
      toggleterm = {
        enable = true;
        settings = {
          open_mapping = "[[<C-\\>]]";
          terminalMappings = true;
          insertMappings = false;
          direction = "tab";
        };
      };
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "git_files";
          "<leader>fo" = "oldfiles";
          "<leader>fb" = "buffers";
          "<leader>fg" = "live_grep";
        };
      };
      cmp.enable = true;
      cmp.settings = {
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-j>" = "cmp.mapping.select_next_item()";
          "<C-k>" = "cmp.mapping.select_prev_item()";
          "<C-e>" = "cmp.mapping.close()";
          #"<CR>" = "cmp.mapping.confirm({ select = false })";
          "<CR>" = ''
            function(fallback)
              if not cmp.visible() or not cmp.get_selected_entry() or cmp.get_selected_entry().source.name == 'nvim_lsp_signature_help' then
                fallback()
              else
                cmp.confirm({ select = false })
              end
            end
          '';
          #"<Tab>" = ''
          #  function(fallback)
          #    if cmp.visible() then
          #      cmp.select_next_item()
          #    else
          #      fallback()
          #    end
          #  end
          #'';
        };
        completion = {
          autocomplete = ["TextChanged"];
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "nvim_lsp_signature_help"; }
          { name = "luasnip"; }
        ];
        snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
      };
      lualine.enable = true;
      lspkind.enable = true;
      trouble.enable = true;
      gitgutter.enable = true;
      diffview.enable = true;
      cmp-nvim-lsp.enable = true;
      dap.enable = true;
      dap-go.enable = true;
      dap-ui.enable = true;
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
          rust_analyzer = {
            enable = true;
            #installLanguageServer = false;
            installCargo = false;
            installRustc = false;
          };
        };
      };
    };
  };
}
