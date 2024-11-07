return {
  "epwalsh/obsidian.nvim",
  version="*",
  lazy = true,
  ft="markdown",
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

