return {
  {
    "yetone/avante.nvim",
    enabled = false,
    event = "VeryLazy",
    version = false,
    build = "make BUILD_FROM_SOURCE=true",
    opts = {
      provider = "kimi",
      providers = {
        kimi = {
          __inherited_from = "openai",
          endpoint = "https://api.moonshot.cn/v1",
          model = "kimi-k2-0711-preview",
          api_key_name = "KIMI_API_KEY",
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 32768,
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-tree/nvim-web-devicons",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
          },
        },
      },
    },
  },
}
