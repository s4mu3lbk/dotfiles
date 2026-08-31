local js_filetypes = { "javascript", "typescript" }

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, "js-debug-adapter")
    end,
  },
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      if not dap.adapters["pwa-node"] then
        dap.adapters["pwa-node"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = {
              LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
              "${port}",
            },
          },
        }
      end

      require("dap.ext.vscode").type_to_filetypes["pwa-node"] = js_filetypes

      local playwright_configs = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Playwright (current file)",
          program = "${workspaceFolder}/node_modules/@playwright/test/cli.js",
          args = { "test", "${relativeFile}", "--project=chromium", "--headed", "--timeout=0", "--retries=0" },
          cwd = "${workspaceFolder}",
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Playwright (current file, all projects)",
          program = "${workspaceFolder}/node_modules/@playwright/test/cli.js",
          args = { "test", "${relativeFile}", "--headed", "--timeout=0", "--retries=0" },
          cwd = "${workspaceFolder}",
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
        },
      }

      for _, ft in ipairs(js_filetypes) do
        local configs = dap.configurations[ft] or {}
        local existing = {}
        for _, c in ipairs(configs) do
          existing[c.name] = true
        end
        for _, c in ipairs(playwright_configs) do
          if not existing[c.name] then
            table.insert(configs, c)
          end
        end
        dap.configurations[ft] = configs
      end
    end,
  },
}
