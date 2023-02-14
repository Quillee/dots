local _c = require 'user.feline.feline_colors'
local _s = require 'user.feline.feline_components'

require 'feline'.setup {
    default_bg = _c.bg,
    default_fg = _c.fg,
    components = _s.components,
    vi_mode_colors = _s.vi_mode_colors
}
