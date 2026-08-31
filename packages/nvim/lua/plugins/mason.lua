return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vue_ls = { mason = false },
        vtsls = { mason = false },
        marksman = { mason = false },
        jsonls = { mason = false },
        taplo = { mason = false },
        nil_ls = { mason = false },
        nixd = { mason = false },
        rust_analyzer = { mason = false },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {},
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = false,
    },
  },
}
