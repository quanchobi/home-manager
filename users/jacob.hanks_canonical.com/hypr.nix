{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.niri
  ];

  home.packages = with pkgs; [
    swaybg
    xwayland-satellite
    gnome-calendar
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.posy-cursors;
    name = "Posy_Cursor_Black";
    size = 24;
  };

  gtk = {
    enable = true;
    cursorTheme = {
      package = pkgs.posy-cursors;
      name = "Posy_Cursor_Black";
    };
  };

  services.mako = {
    enable = true;
    settings = {
      font = "IntoneMono Nerd Font Mono";
      background-color = "#2d2d2d";
      text-color = "#ffffff";
      border-color = "#3a3a3a";
      border-radius = 5;
      border-size = 2;
      default-timeout = 5000;
      anchor = "top-center";
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "battery"
          "tray"
        ];

        # "niri/workspaces" = {
        #   format = "{icon}";
        #   format-icons = {
        #     default = "○";
        #     focused = "●";
        #     active = "●";
        #   };
        # };

        "niri/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };

        "clock" = {
          format = "{:%a %d %b %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "  ";
          format-icons = {
            default = [
              "  "
              "  "
              "  "
            ];
          };
          on-click = "pavucontrol";
        };
        "battery" = {
          "states" = {
            "warning" = 30;
            "critical" = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰢝 {capacity}%";
          format-plugged = "󰂅 {capacity}%";
          format-alt = "{time} {icon}";
          format-full = "󰁹 {capacity}%";
          format-icons = [
            "󰁼"
            "󰁿"
            "󰂂"
          ];
        };
      };
    };

    style = ''
      * {
          font-family: "IntoneMono Nerd Font Mono";
          font-size: 13px;
          border: none;
          border-radius: 0;
      }

      window#waybar {
          background: rgba(30, 30, 30, 0.95);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: .5s;
      }

      #workspaces button {
          padding: 0 5px;
          color: #ffffff;
      }

      #workspaces button.focused {
          color: #3584e4;
      }

      #clock, #pulseaudio, #network, #battery, #tray {
          padding: 0 10px;
      }

      #window {
          font-weight: bold;
          padding-left: 10px;
      }
    '';
  };

  programs.swaylock = {
    enable = true;
  };

  programs.fuzzel = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
    settings.window.decorations = "none";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "gtk";
  };

  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.system}.niri-stable;
    settings = {
      cursor.theme = "Posy_Cursor_Black";
      layout = {
        gaps = 8;
        border.enable = false;
        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#FF7E70";
        };
      };
      window-rules = [
        {
          geometry-corner-radius = {
            top-left = 8.0;
            top-right = 8.0;
            bottom-left = 8.0;
            bottom-right = 8.0;
          };
          clip-to-geometry = true;
        }
      ];
      input.keyboard.xkb.layout = "us";
      spawn-at-startup = [
        {
          command = [
            "swaybg"
            "-m"
            "fill"
            "-i"
            "/home/jacob.hanks@canonical.com/Pictures/Backgrounds/purple-floral-wall-textured-background.jpg"
          ];
        }
        {
          command = [
            "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
          ];
        }
      ];

      binds = {
        "XF86AudioRaiseVolume".action.spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "0.05+"
        ];
        "XF86AudioLowerVolume".action.spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "0.05-"
        ];
        "XF86AudioMute".action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ];
        "XF86AudioMicMute".action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SOURCE@"
          "toggle"
        ];
        "XF86MonBrightnessUp".action.spawn = [
          "brightnessctl"
          "set"
          "+10%"
        ];
        "XF86MonBrightnessDown".action.spawn = [
          "brightnessctl"
          "set"
          "-10%"
        ];

        "Mod+T".action.spawn = [
          "kitty"
          "zsh"
        ];
        "Mod+D".action.spawn = [
          "fuzzel"
        ];
        "Mod+B".action.spawn = [
          "firefox"
        ];
        "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];
        "Mod+Alt+L".action.spawn = [
          "swaylock"
        ];
        "Mod+Q".action.close-window = [ ];

        # Navigation
        "Mod+Left".action.focus-column-left = [ ];
        "Mod+Right".action.focus-column-right = [ ];
        "Mod+Down".action.focus-window-down = [ ];
        "Mod+Up".action.focus-window-up = [ ];

        # Vim-style Navigation
        "Mod+H".action.focus-column-left = [ ];
        "Mod+L".action.focus-column-right = [ ];
        "Mod+J".action.focus-window-down = [ ];
        "Mod+K".action.focus-window-up = [ ];

        # Moving Windows (Mod + Ctrl)
        "Mod+Ctrl+Left".action.move-column-left = [ ];
        "Mod+Ctrl+Right".action.move-column-right = [ ];

        "Mod+Ctrl+H".action.move-column-left = [ ];
        "Mod+Ctrl+L".action.move-column-right = [ ];

        "Mod+V".action.toggle-window-floating = [ ];
        "Mod+W".action.toggle-column-tabbed-display = [ ];

        # Workspace switching
        "Mod+Page_Down".action.focus-workspace-down = [ ];
        "Mod+Page_Up".action.focus-workspace-up = [ ];
        "Mod+U".action.focus-workspace-down = [ ];
        "Mod+I".action.focus-workspace-up = [ ];
        "Mod+Ctrl+U".action.move-column-to-workspace-down = [ ];
        "Mod+Ctrl+I".action.move-column-to-workspace-up = [ ];
        "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [ ];
        "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [ ];
        "Mod+Shift+U".action.move-workspace-down = [ ];
        "Mod+Shift+I".action.move-workspace-up = [ ];

        # Layout management
        "Mod+R".action.switch-preset-column-width = [ ];
        "Mod+F".action.maximize-column = [ ];
        "Mod+C".action.center-column = [ ];
        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";
        # "Mod+Shift+Minus".action.set-column-height = "-10%";
        # "Mod+Shift+Equal".action.set-column-height = "+10%";
        "Mod+Comma".action.consume-or-expel-window-left = [ ];
        "Mod+Period".action.consume-or-expel-window-right = [ ];

        # Multi monitor
        "Mod+Shift+Left".action.focus-monitor-left = [ ];
        "Mod+Shift+Down".action.focus-monitor-down = [ ];
        "Mod+Shift+Up".action.focus-monitor-up = [ ];
        "Mod+Shift+Right".action.focus-monitor-right = [ ];
        "Mod+Shift+H".action.focus-monitor-left = [ ];
        "Mod+Shift+J".action.focus-monitor-down = [ ];
        "Mod+Shift+K".action.focus-monitor-up = [ ];
        "Mod+Shift+L".action.focus-monitor-right = [ ];

        # "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [ ];
        # "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [ ];
        # "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [ ];
        # "Mod+Shift+Ctrl+Right".move-column-to-monitor-right = [ ];
        # "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
        # "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
        # "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
        # "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];

        # Screenshots
        "Print".action.screenshot = [ ];
        "Ctrl+Print".action.screenshot-screen = [ ];
        "Alt+Print".action.screenshot-window = [ ];

        # Exit
        "Mod+Shift+E".action.quit = [ ];
      };
    };
  };

  xdg.desktopEntries.niri = {
    name = "Niri";
    comment = "A scrollable-tiling Wayland compositor";
    exec = "niri-session";
    type = "Application";
    categories = [
      "System"
    ];
  };

  xdg.configFile."systemd/user/niri.service".source = "${pkgs.niri}/lib/systemd/user/niri.service";
  xdg.configFile."systemd/user/niri-shutdown.target".source =
    "${pkgs.niri}/lib/systemd/user/niri-shutdown.target";
}
