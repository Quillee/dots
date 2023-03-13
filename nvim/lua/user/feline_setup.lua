--[[
  __      _ _                         _
 / _| ___| (_)_ __   ___   _ ____   _(_)_ __ ___
| |_ / _ \ | | '_ \ / _ \ | '_ \ \ / / | '_ ` _ \
|  _|  __/ | | | | |  __/_| | | \ V /| | | | | | |
|_|  \___|_|_|_| |_|\___(_)_| |_|\_/ |_|_| |_| |_|

	/* IMPORTS */
--]]
--
local highlight = require('highlite').highlight
local is_git_repo = require('feline.providers.git').git_info_exists()
local diag_lookup = require('feline.providers.lsp').diagnostics_exist

--[[/* CONSTANTS */]]

local BUF_ICON =
{ -- {{{
    dbui           = '  ',
    diff           = ' 繁',
    help           = '  ',
    NvimTree       = ' פּ ',
    qf             = '  ',
    undotree       = '  ',
    vista          = '  ',
    vista_kind     = '  ',
    vista_markdown = '  ',
} -- }}}

-- Defined in https://github.com/Iron-E/nvim-highlite
local BLACK      = { '#202020', 235, 'black' }
local GRAY_DARK  = { '#14151B', 236, 'darkgrey' }
--local GRAY_DARKER = {'#505050', 239, 'gray'}
local GRAY_LIGHT = { '#93949A', 250, 'gray' }
local WHITE      = { '#ffffff', 231, 'white' }
local GRAY       = { '#44475c', 204, 'gray' }

local DARK_TAN = { '#E9A22A', 225, 'darktan' }
local TAN = { '#f4c069', 221, 'yellow' }

local RED       = { '#ee4a59', 203, 'red' }
local RED_DARK  = { '#a80000', 124, 'darkred' }
local RED_LIGHT = { '#ff4090', 205, 'red' }

local ORANGE       = { '#ff8900', 208, 'darkyellow' }
local ORANGE_LIGHT = { '#f0af00', 214, 'darkyellow' }

local YELLOW = { '#f0df33', 227, 'yellow' }

local GREEN_DARK  = { '#70d533', 113, 'darkgreen' }
local GREEN       = { '#22ff22', 46, 'green' }
local GREEN_LIGHT = { '#99ff99', 120, 'green' }
local TURQOISE    = { '#2bff99', 48, 'green' }
local BLUE        = { '#7766ff', 63, 'darkblue' }
local CYAN        = { '#33dbc3', 80, 'cyan' }
local ICE         = { '#95c5ff', 111, 'cyan' }
local TEAL        = { '#60afff', 75, 'blue' }

local MAGENTA      = { '#d5508f', 168, 'magenta' }
local MAGENTA_DARK = { '#bb0099', 126, 'darkmagenta' }
local PINK         = { '#ffa6ff', 219, 'magenta' }
local PINK_LIGHT   = { '#ffb7b7', 217, 'white' }
local PURPLE       = { '#cf55f0', 171, 'magenta' }
local PURPLE_LIGHT = { '#af60af', 133, 'darkmagenta' }
local PURPLE_DARK  = { '#341440', 80, 'darkpurple' }

local SIDEBAR = PURPLE_DARK
local MIDBAR = GRAY
local TEXT = GRAY_LIGHT

local MODES =
{ -- {{{
    ['c']  = { '', GREEN }, -- COMMAND-LINE
    ['ce'] = { 'NORMAL EX', RED_DARK },
    ['cv'] = { 'EX', RED_LIGHT },
    ['i']  = { '', ICE }, -- EDIT
    ['ic'] = { 'INS-COMPLETE', RED_LIGHT },
    ['n']  = { '', PURPLE_LIGHT }, -- NORMAL
    ['no'] = { 'OPERATOR-PENDING', PURPLE },
    ['r']  = { 'HIT-ENTER', CYAN },
    ['r?'] = { ':CONFIRM', CYAN },
    ['rm'] = { '--MORE', ICE },
    ['R']  = { 'REPLACE', PINK },
    ['Rv'] = { 'VIRTUAL', PINK_LIGHT },
    ['s']  = { 'SELECT', TURQOISE },
    ['S']  = { 'SELECT', TURQOISE },
    ['']  = { 'SELECT', TURQOISE },
    ['t']  = { 'TERMINAL', ORANGE },
    ['v']  = { '', PINK }, -- Visual
    ['V']  = { '', MAGENTA }, -- visual line
    ['']  = { '', MAGENTA_DARK }, -- visual block
    ['!']  = { '', YELLOW }, -- shell

    -- libmodal
    ['BUFFERS'] = TEAL,
    ['TABLES']  = ORANGE_LIGHT,
    ['TABS']    = TAN,
} -- }}}

local LEFT_SEPARATOR = ''
local RIGHT_SEPARATOR = ''

--[[/* HELPERS */]]

--- @return boolean is_not_empty
local function buffer_not_empty()
    return vim.api.nvim_buf_line_count(0) > 1
end

--- @return boolean wide_enough
local function checkwidth()
    return (vim.api.nvim_win_get_width(0) / 2) > 40
end

--- Set buffer variables for file icon and color.
local function set_devicons()
    local icon, color = require('nvim-web-devicons').get_icon(vim.fn.expand '%:t', vim.fn.expand '%:e',
        { default = true })

    if vim.bo.filetype == 'purescript' or vim.bo.filetype == 'haskell' then
        icon = '  '
        vim.b.file_color = PURPLE_LIGHT[1]
    else
        vim.b.file_color = string.format('#%06x', vim.api.nvim_get_hl_by_name(color, true).foreground)
    end

    vim.b.file_icon = icon
end

--- @return string color
local function file_color()
    if not vim.b.file_color then set_devicons() end
    
    return vim.b.file_color
end

--- @return string icon
local function file_icon()
    if not vim.b.file_icon then set_devicons() end

    return vim.b.file_icon
end

local function is_git_enabled()
    return checkwidth() and is_git_repo
end

local function get_next_bg_by_diag(start)
    local sev = vim.diagnostic.severity
    local diag_order = { sev.E, sev.W, sev.I, sev.HINT }
    local diag_color_table = { RED[1], YELLOW[1], BLUE[1], CYAN[1] }

    for i = start, #diag_order do
        if diag_lookup(diag_order[i]) then
            return diag_color_table[i]
        end
    end

    return MIDBAR[1]
end

--[[/* FELINE CONFIG */]]

vim.api.nvim_set_hl(0, 'FelineViMode', {})
require('feline').setup(
    {
        colors = { bg = MIDBAR[1] },
        components =
        { -- {{{
            active =
            {
                { -- Left {{{
                    {
                        icon = ' ',
                        hl = 'FelineViMode',
                        provider = function() -- auto change color according the vim mode
                            local mode_color, mode_name

                            if vim.g.libmodalActiveModeName then
                                mode_name = vim.g.libmodalActiveModeName
                                mode_color = MODES[mode_name]
                            else
                                local current_mode = MODES[vim.api.nvim_get_mode().mode]

                                mode_name = current_mode[1]
                                mode_color = current_mode[2]
                            end

                            highlight('FelineViMode', { fg = mode_color, bg = MIDBAR, style = 'bold' })

                            return mode_name .. ' '
                        end,
                        right_sep = function()
                            return {
                                hl = { fg = MIDBAR[1], bg = file_color() },
                                str = RIGHT_SEPARATOR,
                            }
                        end,
                    },

                    {
                        hl        = function() return { fg = SIDEBAR[1], bg = file_color() } end,
                        provider  = function() return ' ' .. file_icon() .. ' ' end,
                        right_sep = function()
                            return {
                                hl = { fg = file_color(), bg = file_color() },
                                str = ' ',
                            }
                        end,
                    },

                    {
                        colored_icon       = true,
                        enabled            = buffer_not_empty,
                        icon               = '',
                        file_modified_icon = function() return '' end,
                        hl                 = function() return { fg = SIDEBAR[1], bg = file_color() } end,
                        provider           = 'file_info',
                        type               = 'unique-short',
                    },

                    {

                        provider  = function() return ' ' end,
                        hl        = function() return { fg = SIDEBAR[1], bg = file_color() } end,
                        right_sep = function()
                            return {
                                hl = { fg = file_color(), bg = get_next_bg_by_diag(1) },
                                str = RIGHT_SEPARATOR,
                            }
                        end,
                    },

                    -- do I care about file size all the time?
                    -- {
                    -- 	enabled = buffer_not_empty,
                    -- 	hl = {fg = TEXT[1], bg = file_color(), style = 'bold'},
                    -- 	provider  = 'file_size',
                    -- 	right_sep =
                    -- 	{
                    -- 		hl = {bg = SIDEBAR[1]},
                    -- 		str = ' ',
                    -- 	},
                    -- },

                    {
                        hl = { fg = SIDEBAR[1], bg = GREEN_DARK[1], style = 'bold' },
                        icon = '  ',
                        left_sep = {
                            hl = { fg = SIDEBAR[1], bg = GREEN_DARK[1] },
                            str = RIGHT_SEPARATOR,
                        },
                        enabled = is_git_enabled,
                        provider = 'git_branch',
                    },

                    {
                        enabled = is_git_enabled,
                        hl = { fg = GREEN_LIGHT[1], bg = MIDBAR[1] },
                        icon = '  ',
                        provider = 'git_diff_added',
                    },

                    {
                        enabled = is_git_enabled,
                        hl = { fg = ORANGE_LIGHT[1], bg = MIDBAR[1] },
                        icon = '  ',
                        provider = 'git_diff_changed',
                    },

                    {
                        enabled = is_git_enabled,
                        hl = { fg = RED_LIGHT[1], bg = MIDBAR[1] },
                        icon = '  ',
                        provider = 'git_diff_removed',
                    },

                    {
                        hl = { fg = MIDBAR[1], bg = RED[1] },
                        icon = ' ﲍ ', -- ' Ⓧ ',
                        provider = 'diagnostic_errors',
                        -- left_sep = function()
                        --     return {
                        --         hl = { fg = MIDBAR[1], bg = RED[1] },
                        --         str = RIGHT_SEPARATOR,
                        --     }
                        -- end,
                        right_sep = function()
                            return {
                                hl = { fg = RED[1], bg = get_next_bg_by_diag(2) },
                                str = RIGHT_SEPARATOR,
                            }
                        end,
                    },

                    {
                        hl = { fg = MIDBAR[1], bg = YELLOW[1] },
                        icon = ' 裂 ',
                        provider = 'diagnostic_warnings',
                        -- left_sep = {
                        --     hl = { fg = MIDBAR[1], bg = YELLOW[1] },
                        --     str = RIGHT_SEPARATOR,
                        -- },
                        right_sep = function()
                            return {
                                hl = { fg = YELLOW[1], bg = get_next_bg_by_diag(3) },
                                str = RIGHT_SEPARATOR,
                            }
                        end,
                    },

                    {
                        hl = { fg = MIDBAR[1], bg = BLUE[1] },
                        icon = '  ',
                        provider = 'diagnostic_info',
                        left_sep = {
                            hl = { fg = MIDBAR[1], bg = BLUE[1] },
                            str = RIGHT_SEPARATOR,
                        },
                        right_sep = function()
                            return {
                                hl = { fg = BLUE[1], bg = get_next_bg_by_diag(4) },
                                str = RIGHT_SEPARATOR,
                            }
                        end,
                    },

                    {
                        hl = { fg = MIDBAR[1], bg = CYAN[1] },
                        icon = '  ',
                        provider = 'diagnostic_hints',
                        -- left_sep = {
                        --     hl = { fg = MIDBAR[1], bg = CYAN[1] },
                        --     str = RIGHT_SEPARATOR,
                        -- },
                        right_sep = {
                            hl = { fg = CYAN[1], bg = MIDBAR[1] },
                            str = RIGHT_SEPARATOR,
                        },
                    },

                    {
                        hl = { fg = TEXT[1], bg = MIDBAR[1] },
                        right_sep = {
                            hl = { bg = MIDBAR[1] },
                            str = ' ',
                        },
                    },
                }, -- }}}

                { -- Middle {{{
                },

                { -- Right {{{
                    {
                        hl = { fg = TEXT[1], bg = SIDEBAR[1] },
                        left_sep =
                        {
                            hl = { fg = MIDBAR[1], bg = SIDEBAR[1] },
                            str = ' ',
                        },
                        provider = 'file_encoding',
                        right_sep =
                        {
                            hl = { bg = SIDEBAR[1] },
                            str = ' ',
                        },
                    },

                    {
                        hl = { fg = TEXT[1], bg = SIDEBAR[1], style = 'bold' },
                        left_sep = {
                            hl = { fg = TEXT[1], bg = SIDEBAR[1] },
                            str = ' ',
                        },
                        right_sep = {
                            hl = { fg = TEXT[1], bg = SIDEBAR[1] },
                            str = ' ',
                        },
                        provider = 'search_count',
                    },

                    {
                        enabled = buffer_not_empty,
                        left_sep = {
                            str = LEFT_SEPARATOR,
                            hl = { fg = DARK_TAN[1], bg = SIDEBAR[1] }
                        },
                        hl = { fg = BLACK[1], bg = DARK_TAN[1] },
                        provider = function()
                            return (vim.api.nvim_win_get_cursor(0)[1] + 1) .. ' ' ..
                                (vim.api.nvim_win_get_cursor(0)[2] + 1) .. ' '
                        end,
                    },

                    {
                        hl = { fg = BLACK[1], bg = DARK_TAN[1] },
                        provider = 'line_percentage',
                        left_sep = {
                            hl = { bg = DARK_TAN[1], fg = BLACK[1] },
                            str = ' ',
                        },
                        right_sep = {
                            hl = { bg = DARK_TAN[1], fg = BLACK[1] },
                            str = ' ',
                        },
                    },

                    {
                        hl = { fg = BLACK[1], bg = DARK_TAN[1] },
                        provider = 'scroll_bar',
                    },
                }, -- }}}
            },

            inactive =
            {
                { -- Left {{{
                    {
                        hl = { fg = BLACK[1], bg = PURPLE[1], style = 'bold' },
                        left_sep =
                        {
                            hl = { bg = PURPLE[1] },
                            str = ' ',
                        },
                        provider = 'file_type',
                    },
                    {
                        hl = { bg = PURPLE[1] },
                        provider = ' ',
                        right_sep =
                        {
                            hl = { fg = PURPLE[1], bg = MIDBAR[1] },
                            str = RIGHT_SEPARATOR,
                        },
                    },
                }, -- }}}

                { { -- Right {{{
                    hl = { fg = BLACK[1], bg = PURPLE[1], style = 'bold' },
                    left_sep =
                    {
                        hl = { fg = PURPLE[1], bg = MIDBAR[1] },
                        str = LEFT_SEPARATOR,
                    },
                    provider = function(_, win_id) return BUF_ICON[
                            vim.bo[vim.api.nvim_win_get_buf(win_id or 0)].filetype] or ''
                    end,
                } }, -- }}}
            },
        }, -- }}}

        force_inactive =
        { -- {{{
            bufnames = {},
            buftypes = { 'help', 'prompt', 'terminal' },
            filetypes =
            {
                'dbui',
                'diff',
                'help',
                'NvimTree',
                'qf',
                'undotree',
                'vista',
                'vista_kind',
                'vista_markdown',
            },
        }, -- }}}
    })
