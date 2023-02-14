local _c = require 'user.feline.feline_colors'
local file_utils = require 'user.lib.file_utils'

local vi_mode_colors = {
    NORMAL = _c.green,
    INSERT = _c.blue,
    VISUAL = _c.violet,
    OP = _c.green,
    BLOCK = _c.blue,
    REPLACE = _c.red,
    ['V-REPLACE'] = _c.red,
    ENTER = _c.cyan,
    MORE = _c.cyan,
    SELECT = _c.orange,
    COMMAND = _c.magenta,
    SHELL = _c.green,
    TERM = _c.blue,
    NONE = _c.yellow
}

local vi_mode_text = {
    n = "",
    i = "", -- "",
    v = "",
    [''] = "",
    V = "",
    c = "",
    no = "UNKNOWN",
    s = "UNKNOWN",
    S = "UNKNOWN",
    ic = "UNKNOWN",
    R = "",
    Rv = "UNKNOWN",
    cv = "UNKWON",
    ce = "UNKNOWN",
    r = "",
    rm = "UNKNOWN",
    t = ""
}

local lsp = require 'feline.providers.lsp'
local vi_mode_utils = require 'feline.providers.vi_mode'
local cursor = require 'feline.providers.cursor'

local vi_mode = {
    left = {
        provider = function()
            return ' ' .. vi_mode_text[vim.fn.mode()] .. ' '
        end,
        hl = function()
            return {
                name = vi_mode_utils.get_mode_highlight_name(),
                fg = _c.fg,
                bg = vi_mode_utils.get_mode_color(),
                style = 'bold'
            }
        end,
        right_sep = ' sep '
    },
    right = {
        provider = '▊',
        hl = function()
            return {
                name = vi_mode_utils.get_mode_highlight_name(),
                fg = vi_mode_utils.get_mode_color()
            }
        end,
        left_sep = ' || '
    }
}

local file = {
    info = {
        provider = file_utils.get_current_ufn,
        hl = {
            fg = _c.blue,
            style = 'bold'
        },
        left_sep = ' '
    },
    encoding = {
        provider = 'file_encoding',
        hl = {
            fg = _c.violet,
            style = 'italic'
        },
        left_sep = ' '
    },
    type = {
        provider = 'file_type'
    },
    os = {
        provider = file_utils.file_osinfo,
        hl = {
            fg = _c.violet,
            style = 'bold'
        },
        left_sep = ' ',
    }
}

local line_percentage = {
    provider = 'line_percentage',
    left_sep = ' ',
    hl = {
        style = 'bold'
    }
}

local position = {
    provider = function()
        pos = cursor.position()
        return ' ' .. pos .. ' '
    end,
    left_sep = ' ',
    hl = function()
        return {
            name = vi_mode_utils.get_mode_highlight_name(),
            fg = _c.bg,
            bg = vi_mode_utils.get_mode_color(),
            style = 'bold'
        }
    end
}

local scroll_bar = {
    provider = 'scroll_bar',
    hl = {
        fg = _c.blue,
        style = 'bold'
    },
    left_sep = ' '
}

local diag = {
    err = {
        provider = 'diagnostic_errors',
        enabled = function()
            return lsp.diagnostic_exists('Error')
        end,
        hl = {
            fg = _c.red
        }
    },
    warn = {
        provider = 'diagnostic_warnings',
        enabled = function()
            return lsp.diagnostic_exists('Warn')
        end,
        hl = {
            fg = _c.yellow
        }
    },
    hint = {
        provider = 'diagnostic_hints',
        enabled = function()
            return lsp.diagnostic_exists('Hint')
        end,
        hl = {
            fg = _c.cyan
        }
    },
    info = {
        provider = 'diagnostic_info',
        enabled = function()
            return lsp.diagnostics_exist('Info')
        end,
        hl = {
            fg = _c.blue
        }
    }
}
local lsp = {
    name = {
        provider = 'lsp_client_names',
        left_sep = ' ',
        icon = ' ',
        hl = {
            fg = _c.yellow
        }
    }
}
local git = {
    branch = {
        provider = 'git_branch',
        icon = ' ',
        left_sep = ' ',
        hl = {
            fg = _c.violet,
            style = 'bold'
        },
    },
    add = {
        provider = 'git_diff_added',
        icon = "",
        hl = {
            fg = _c.green
        }
    },
    change = {
        provider = 'git_diff_changed',
        icon = "",
        hl = {
            fg = _c.orange
        }
    },
    remove = {
        provider = 'git_diff_removed',
        icon = "",
        hl = {
            fg = _c.red
        }
    }
}

return {
    vi_mode_colors = vi_mode_colors,
    comp = {
        left = {
            active = {
                vi_mode.left,
                file.info,
                lsp.name,
                diag.err,
                diag.warn,
                diag.hint,
                diag.info
            },
            inactive = {
                file.info
            }
        },
        mid = {
            active = {},
            inactive = {}
        },
        right = {
            active = {
                git.add,
                git.change,
                git.remove,
                file.os,
                git.branch,
                scroll_bar,
                line_percentage,
                vi_mode.right,
                position
            },
            inactive = {
                file.os
            }
        }
    }
}

