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
local function vimode_hl()
    return {
        name = vi_mode_utils.get_mode_highlight_name(),
        fg = vi_mode_utils.get_mode_color()
    }
end
local vi_mode = {
    left = {
        provider = '▊',
        hl = vimode_hl,
        right_sep = ' '
    },
    right = {
        provider = '▊',
        hl = vimode_hl,
        left_sep = ' '
    }
}
local file = {
    info = {
        provider = 'file_info',
        hl = {
            fg = _c.blue,
            style = 'bold'
        }
    },
    encoding = {
        provider = 'file_encoding',
        left_sep = ' ',
        hl = {
            fg = _c.violet,
            style = 'bold'
        }
    },
    type = {
        provider = 'file_type'
    },
    os = {
        provider = file_utils.file_osinfo,
        left_sep = ' ',
        hl = {
            fg = _c.violet,
            style = 'bold'
        }
    }
}
local line_percentage = {
    provider = 'line_percentage',
    left_sep = ' ',
    hl = {
        style = 'bold'
    }
}
local scroll_bar = {
    provider = 'scroll_bar',
    left_sep = ' ',
    hl = {
        fg = _c.blue,
        style = 'bold'
    }
}
local lsp = {
        name = {
            provider = 'lsp_client_names',
            left_sep = ' ',
            icon = 'H',
            hl = {
                fg = _c.yellow
            }
        }
    }

local properties = {
    force_inactive = {
        filetypes = {
            'NvimTree',
            'dbui',
            'packer',
            'startify',
            'fugitive',
            'fugitiveblame'
        },
        buftypes = {'terminal'},
        bufnames = {}
    }
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
    properties = properties,
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
                -- position
            },
            inactive = {
                file.os
            }
        }
    }
}

