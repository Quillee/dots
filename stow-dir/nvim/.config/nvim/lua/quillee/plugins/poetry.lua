return {
  "karloskar/poetry-nvim",
  lazy = true,
  config = function()
    require("lazy").load({ plugins = { "poetry-nvim" } })
  end,
}
