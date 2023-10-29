return {
  "epwalsh/obsidian.nvim",
  lazy = true,
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "life",
        path = "~/vault/life",
      },
      {
        name = "csc-paradigms",
        path = "~/vault/csc-paradigms",
      },
    },
  },
}

