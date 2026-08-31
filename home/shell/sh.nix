{
  pkgs,
  config,
  lib,
  ...
}:
let
  aliases = {
    "db" = "distrobox";
    "tree" = "eza --tree";
    "nv" = "nvim";
    "vim" = "nvim";
    "ls" = "lsd";

    "ll" = "lsd -l";
    "l" = "lsd";

    ":q" = "exit";
    "q" = "exit";

    "gs" = "git status";
    "gb" = "git branch";
    "gch" = "git checkout";
    "gc" = "git commit";
    "ga" = "git add";
    "gr" = "git reset --soft HEAD~1";

    "del" = "gio trash";
    "oc" = "opencode";
  };
in
{
  options.shellAliases =
    with lib;
    mkOption {
      type = types.attrsOf types.str;
      default = { };
    };

  config.programs = {
    fish = {
      shellAliases = aliases // config.shellAliases;
      enable = true;

      interactiveShellInit = ''
        if test -f ${config.sops.secrets.openai_api_key.path}
          set -gx OPENAI_API_KEY (cat ${config.sops.secrets.openai_api_key.path})
        end
        if test -f ${config.sops.secrets.gemini_api_key.path}
          set -gx GEMINI_API_KEY (cat ${config.sops.secrets.gemini_api_key.path})
        end
        if test -f ${config.sops.secrets.gemini_api_key.path}
          set -gx GOOGLE_GENERATIVE_AI_API_KEY (cat ${config.sops.secrets.gemini_api_key.path})
        end
        if test -f ${config.sops.secrets.kimi_api_key.path}
          set -gx KIMI_API_KEY (cat ${config.sops.secrets.kimi_api_key.path})
        end
        if test -f ${config.sops.secrets.figma_api_key.path}
          set -gx FIGMA_API_KEY (cat ${config.sops.secrets.figma_api_key.path})
        end
        if test -f ${config.sops.secrets.bw_session.path}
          set -gx BW_SESSION (cat ${config.sops.secrets.bw_session.path})
        end
        if test -f ${config.sops.secrets.bitbucket_api_token.path}
          set -gx BITBUCKET_API_TOKEN (cat ${config.sops.secrets.bitbucket_api_token.path})
        end
      '';

      shellAbbrs = {
        gco = "git checkout";
        npu = "nix-prefetch-url";
      };

      plugins = [
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
        {
          name = "z";
          src = pkgs.fetchFromGitHub {
            owner = "jethrokuan";
            repo = "z";
            rev = "ddeb28a7b6a1f0ec6dae40c636e5ca4908ad160a";
            sha256 = "0c5i7sdrsp0q3vbziqzdyqn4fmp235ax4mn4zslrswvn8g3fvdyh";
          };
        }
        # oh-my-fish plugins are stored in their own repositories, which
        # makes them simple to import into home-manager.
        {
          name = "fasd";
          src = pkgs.fetchFromGitHub {
            owner = "oh-my-fish";
            repo = "plugin-fasd";
            rev = "38a5b6b6011106092009549e52249c6d6f501fba";
            sha256 = "06v37hqy5yrv5a6ssd1p3cjd9y3hnp19d3ab7dag56fs1qmgyhbs";
          };
        }
      ];
    };

    nushell = {
      shellAliases = aliases // config.shellAliases;
      enable = true;
      environmentVariables = {
        PROMPT_INDICATOR_VI_INSERT = "  ";
        PROMPT_INDICATOR_VI_NORMAL = "∙ ";
        PROMPT_COMMAND = "";
        PROMPT_COMMAND_RIGHT = "";
        NIXPKGS_ALLOW_UNFREE = "1";
        NIXPKGS_ALLOW_INSECURE = "1";
        SHELL = "${pkgs.nushell}/bin/nu";
        EDITOR = config.home.sessionVariables.EDITOR;
        VISUAL = config.home.sessionVariables.VISUAL;
        KIMI_SHELL_PATH = "$HOME/.local/bin/kimi-shell-wrapper";
      };
      extraConfig =
        let
          conf = builtins.toJSON {
            show_banner = false;
            edit_mode = "vi";

            ls.clickable_links = true;
            rm.always_trash = true;

            table = {
              mode = "compact"; # compact thin rounded
              index_mode = "always"; # always never auto
              header_on_separator = false;
            };

            cursor_shape = {
              vi_insert = "line";
              vi_normal = "block";
            };

            display_errors = {
              exit_code = false;
            };

            menus = [
              {
                name = "completion_menu";
                only_buffer_difference = false;
                marker = "? ";
                type = {
                  layout = "columnar"; # list, description
                  columns = 4;
                  col_padding = 2;
                };
                style = {
                  text = "magenta";
                  selected_text = "blue_reverse";
                  description_text = "yellow";
                };
              }
            ];
          };
          completions =
            let
              completion = name: ''
                source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu
              '';
            in
            names:
            builtins.foldl' (prev: str: ''
              ${prev}
              ${str}'') "" (map completion names);
          # nu
        in
        ''
          $env.config = ${conf};
          ${completions [
            "git"
            "nix"
          ]}

          source ${pkgs.nu_scripts}/share/nu_scripts/modules/formats/from-env.nu

          const path = "~/.nushellrc.nu"
          const null = "/dev/null"
          source (if ($path | path exists) {
              $path
          } else {
              $null
          })
        '';
      extraEnv =
        # nu
        ''
          $env.PATH = ($env.PATH | append "${config.home.homeDirectory}/.local/bin")
          $env.OPENAI_API_KEY = (open ${config.sops.secrets.openai_api_key.path} | str trim)
          $env.GEMINI_API_KEY = (open ${config.sops.secrets.gemini_api_key.path} | str trim)
          $env.GOOGLE_GENERATIVE_AI_API_KEY  = (open ${config.sops.secrets.gemini_api_key.path} | str trim)
          $env.KIMI_API_KEY = (open ${config.sops.secrets.kimi_api_key.path} | str trim)
          $env.FIGMA_API_KEY = (open ${config.sops.secrets.figma_api_key.path} | str trim)
          $env.BW_SESSION = (open ${config.sops.secrets.bw_session.path} | str trim)
          $env.BITBUCKET_API_TOKEN = (open ${config.sops.secrets.bitbucket_api_token.path} | str trim)
        '';
    };

    bash = {
      shellAliases = aliases // config.shellAliases;
      enable = true;
      initExtra = ''
        SHELL=${pkgs.bashInteractive}/bin/bash
        if [ -f "${config.sops.secrets.openai_api_key.path}" ]; then
          export OPENAI_API_KEY="$(cat ${config.sops.secrets.openai_api_key.path})"
        fi
        if [ -f "${config.sops.secrets.gemini_api_key.path}" ]; then
          export GEMINI_API_KEY="$(cat ${config.sops.secrets.gemini_api_key.path})"
        fi
        if [ -f "${config.sops.secrets.gemini_api_key.path}" ]; then
          export GOOGLE_GENERATIVE_AI_API_KEY="$(cat ${config.sops.secrets.gemini_api_key.path})"
        fi
        if [ -f "${config.sops.secrets.kimi_api_key.path}" ]; then
          export KIMI_API_KEY="$(cat ${config.sops.secrets.kimi_api_key.path})"
        fi
        if [ -f "${config.sops.secrets.figma_api_key.path}" ]; then
          export FIGMA_API_KEY="$(cat ${config.sops.secrets.figma_api_key.path})"
        fi
        if [ -f "${config.sops.secrets.bw_session.path}" ]; then
          export BW_SESSION="$(cat ${config.sops.secrets.bw_session.path})"
        fi
        if [ -f "${config.sops.secrets.bitbucket_api_token.path}" ]; then
          export BITBUCKET_API_TOKEN="$(cat ${config.sops.secrets.bitbucket_api_token.path})"
        fi
      '';
    };

    nix-index = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };
  };
}
