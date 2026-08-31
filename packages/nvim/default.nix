{pkgs, ...}: let
  bins = with pkgs; [
    git
    gcc
    gnumake
    unzip
    wget
    curl
    tree-sitter
    ripgrep
    fd
    fzf
    cargo
    lazygit
    lsof
    python3
    luajitPackages.luarocks
    lua51Packages.lua
    libxml2
    imagemagick
    sqlite
    ghostscript_headless
    tectonic
    mermaid-cli

    # lua
    lua-language-server
    stylua

    # nix
    nil
    nixd
    alejandra

    # bash
    shfmt

    # ts
    nodejs
    deno
    bun
    yarn
    pnpm
    prettier
    tailwindcss-language-server
    svelte-language-server
    astro-language-server
    vue-language-server
    vscode-langservers-extracted
    vtsls
    markdownlint-cli2
    marksman
    taplo

    # go
    go
    gopls
    gotools
    gofumpt
    go-tools

    # python
    ruff
    pyright
    poetry
    uv

    # rust
    cargo
    rustc
    rustfmt
    rust-analyzer
    clippy

    # c
    clang-tools
    glib
  ];

  linuxBins = with pkgs;
    if stdenv.isDarwin
    then []
    else [
      # vala
      vala-language-server
      mesonlsp
      blueprint-compiler
      meson
      pkg-config
      ninja
      uncrustify

      # clipboard
      wl-clipboard
      xsel
      xclip
    ];
  nvim-wrapped = pkgs.symlinkJoin {
    name = "nvim-wrapped";
    paths = [pkgs.neovim];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [pkgs.sqlite]}
    '';
  };
in
  pkgs.symlinkJoin {
    name = "nvim";
    paths = [nvim-wrapped] ++ bins ++ linuxBins;
  }
