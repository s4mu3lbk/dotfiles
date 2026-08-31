return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    dependencies = {
      {
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {},
          picker = {
            actions = {
              opencode_send = function(...)
                return require("opencode").snacks_picker_send(...)
              end,
            },
            win = {
              input = {
                keys = {
                  ["<C-s>"] = { "opencode_send", mode = { "n", "i" } },
                },
              },
            },
          },
        },
      },
    },
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          -- IMPORTANT: Prevent the plugin from ever auto-starting an embedded
          -- terminal. You already run opencode in tmux.
          start = false,
          stop = false,
          toggle = false,

          -- OPTIONAL: If auto-discovery fails, hardcode the URL.
          -- opencode picks a random port when run with --port; you can pin it:
          -- url = "http://localhost:4096",
        },
      }

      vim.o.autoread = true

      -- Ask / Select
      vim.keymap.set({ "n", "x" }, "<leader>oa", function()
        require("opencode").ask("@this: ", { submit = true })
      end, { desc = "Ask opencode…" })

      vim.keymap.set({ "n", "x" }, "<leader>os", function()
        require("opencode").select()
      end, { desc = "Select opencode…" })

      vim.keymap.set({ "n", "t" }, "<leader>ot", function()
        require("opencode").toggle()
      end, { desc = "Toggle opencode" })

      -- Operator: send motion/text object to the tmux opencode
      vim.keymap.set({ "n", "x" }, "<leader>go", function()
        return require("opencode").operator("@this ")
      end, { desc = "Add range to opencode", expr = true })

      vim.keymap.set("n", "<leader>goo", function()
        return require("opencode").operator("@this ") .. "_"
      end, { desc = "Add line to opencode", expr = true })

      -- Scroll opencode (sends commands to the connected server)
      vim.keymap.set("n", "<leader>ou", function()
        require("opencode").command("session.half.page.up")
      end, { desc = "Scroll opencode up" })

      vim.keymap.set("n", "<leader>od", function()
        require("opencode").command("session.half.page.down")
      end, { desc = "Scroll opencode down" })

      vim.keymap.set("n", "<leader>on", function()
        require("opencode").command("session.new")
      end, { desc = "New opencode session" })

      vim.keymap.set("n", "<leader>oi", function()
        require("opencode").command("session.interrupt")
      end, { desc = "Interrupt opencode" })

      vim.keymap.set("n", "<leader>oy", function()
        require("opencode").command("session.undo")
      end, { desc = "Undo opencode action" })
    end,
  },
}
