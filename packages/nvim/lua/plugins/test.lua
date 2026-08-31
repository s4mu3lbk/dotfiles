return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "thenbe/neotest-playwright",
      dependencies = { "nvim-telescope/telescope.nvim" },
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require("neotest-playwright").adapter({
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
            get_playwright_config = function()
              local cwd = vim.uv.cwd()
              for _, name in ipairs({ "playwright.config.ts", "playwright.config.js", "playwright.config.mjs" }) do
                local path = cwd .. "/" .. name
                if vim.uv.fs_stat(path) then
                  return path
                end
              end
              return cwd .. "/playwright.config.ts"
            end,
          },
        })
      )
      opts.consumers = opts.consumers or {}
      opts.consumers.playwright = require("neotest-playwright.consumers").consumers
    end,
    keys = {
      {
        "<leader>tA",
        function()
          require("neotest").playwright.attachment()
        end,
        desc = "Test Attachment (Playwright)",
      },
    },
  },
}
