return {
  {
    "folke/sidekick.nvim",
    url = "https://github.com/s4mu3lbk/sidekick.nvim",
    keys = {
      {
        "<leader>an",
        function() require("sidekick.cli").toggle({ name = "opencode", new = true }) end,
        desc = "Sidekick New opencode instance",
      },
      {
        "<leader>as",
        function() require("sidekick.cli").select() end,
        desc = "Sidekick Select CLI session",
      },
    },
  },
}
