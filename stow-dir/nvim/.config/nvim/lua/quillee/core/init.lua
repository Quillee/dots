-- apply all colors before feline setups -_-
vim.cmd 'set t_8f=^[[38;2;%lu;%lu;%lum'
vim.cmd 'set t_8b=^[[48;2;%lu;%lu;%lum'
vim.cmd 'set t_Co=256'
vim.cmd 'set termguicolors'

require("quillee.core.keymaps")
require("quillee.core.lazy")
require("quillee.core.settings")

