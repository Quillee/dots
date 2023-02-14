--[[
  __      _ _                         _
 / _| ___| (_)_ __   ___   _ ____   _(_)_ __ ___
| |_ / _ \ | | '_ \ / _ \ | '_ \ \ / / | '_ ` _ \
|  _|  __/ | | | | |  __/_| | | \ V /| | | | | | |
|_|  \___|_|_|_| |_|\___(_)_| |_|\_/ |_|_| |_| |_|

	/* IMPORTS */
--]]

local highlight = require('highlite').highlight

--[[/* CONSTANTS */]]

local BUF_ICON =
{ -- {{{
	dbui     = '  ',
	diff     = ' 繁',
	help     = '  ',
	NvimTree = ' פּ ',
	qf       = '  ',
	undotree = '  ',
	vista    = '  ',
	vista_kind = '  ',
	vista_markdown = '  ',
} -- }}}

-- Defined in https://github.com/Iron-E/nvim-highlite
local BLACK       = {'#202020', 235, 'black'}
local GRAY        = {'#808080', 244, 'gray'}
local GRAY_DARK   = {'#353535', 236, 'darkgrey'}
--local GRAY_DARKER = {'#505050', 239, 'gray'}
local GRAY_LIGHT  = {'#c0c0c0', 250, 'gray'}
local WHITE       = {'#ffffff', 231, 'white'}

local TAN = {'#f4c069', 221, 'yellow'}

local RED       = {'#ee4a59', 203, 'red'}
local RED_DARK  = {'#a80000', 124, 'darkred'}
local RED_LIGHT = {'#ff4090', 205, 'red'}

local ORANGE       = {'#ff8900', 208, 'darkyellow'}
local ORANGE_LIGHT = {'#f0af00', 214, 'darkyellow'}

local YELLOW = {'#f0df33', 227, 'yellow'}

local GREEN_DARK  = {'#70d533', 113, 'darkgreen'}
local GREEN       = {'#22ff22', 46,  'green'}
local GREEN_LIGHT = {'#99ff99', 120, 'green'}
local TURQOISE    = {'#2bff99', 48,  'green'}
local BLUE = {'#7766ff', 63,  'darkblue'}
local CYAN = {'#33dbc3', 80,  'cyan'}
local ICE  = {'#95c5ff', 111, 'cyan'}
local TEAL = {'#60afff', 75,  'blue'}

local MAGENTA      = {'#d5508f', 168, 'magenta'}
local MAGENTA_DARK = {'#bb0099', 126, 'darkmagenta'}
local PINK         = {'#ffa6ff', 219, 'magenta'}
local PINK_LIGHT   = {'#ffb7b7', 217, 'white'}
local PURPLE       = {'#cf55f0', 171, 'magenta'}
local PURPLE_LIGHT = {'#af60af', 133, 'darkmagenta'}

local SIDEBAR = BLACK
local MIDBAR = GRAY_DARK
local TEXT = GRAY_LIGHT

local MODES =
{ -- {{{
	['c']  = {'COMMAND-LINE',      RED},
	['ce'] = {'NORMAL EX',         RED_DARK},
	['cv'] = {'EX',                RED_LIGHT},
	['i']  = {'INSERT',            GREEN},
	['ic'] = {'INS-COMPLETE',      GREEN_LIGHT},
	['n']  = {'NORMAL',            PURPLE_LIGHT},
	['no'] = {'OPERATOR-PENDING',  PURPLE},
	['r']  = {'HIT-ENTER',         CYAN},
	['r?'] = {':CONFIRM',          CYAN},
	['rm'] = {'--MORE',            ICE},
	['R']  = {'REPLACE',           PINK},
	['Rv'] = {'VIRTUAL',           PINK_LIGHT},
	['s']  = {'SELECT',            TURQOISE},
	['S']  = {'SELECT',            TURQOISE},
	[''] = {'SELECT',            TURQOISE},
	['t']  = {'TERMINAL',          ORANGE},
	['v']  = {'',            BLUE},
	['V']  = {'VISUAL LINE',       BLUE},
	[''] = {'VISUAL BLOCK',      BLUE},
	['!']  = {'SHELL',             YELLOW},

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
	local icon, color = require('nvim-web-devicons').get_icon(vim.fn.expand '%:t', vim.fn.expand '%:e', {default = true})
	vim.b.file_icon = icon
	vim.b.file_color = string.format('#%06x', vim.api.nvim_get_hl_by_name(color, true).foreground)
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

--[[/* FELINE CONFIG */]]

vim.api.nvim_set_hl(0, 'FelineViMode', {})
require('feline').setup(
{
	colors = {bg = MIDBAR[1]},
	components =
	{ -- {{{
		active =
		{
			{ -- Left {{{
				{
					icon = '▊ ',
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

						highlight('FelineViMode', {fg = mode_color, style = 'bold'})

						return mode_name..' '
					end,
					right_sep = function()
						return
						{
							hl = {fg = SIDEBAR[1], bg = file_color()},
							str = RIGHT_SEPARATOR,
						}
					end,
				},

				{
					hl = function() return {fg = SIDEBAR[1], bg = file_color()} end,
					provider  = function() return ' '..file_icon()..' ' end,
					right_sep = function()
						return
						{
							hl = {fg = SIDEBAR[1], bg = file_color()},
							str = LEFT_SEPARATOR,
						}
					end,
				},

				{
					colored_icon = false,
					enabled = buffer_not_empty,
					file_modified_icon = '',
					hl = {fg = TEXT[1], bg = SIDEBAR[1], style = 'bold'},
					icon = '',
					left_sep =
					{
						hl = {bg = SIDEBAR[1]},
						str = ' ',
					},
					provider  = 'file_info',
					right_sep =
					{
						hl = {bg = SIDEBAR[1]},
						str = ' ',
					},
					type = 'relative-short',
				},

				{
					enabled = buffer_not_empty,
					hl = {fg = TEXT[1], bg = SIDEBAR[1], style = 'bold'},
					provider  = 'file_size',
					right_sep =
					{
						hl = {bg = SIDEBAR[1]},
						str = ' ',
					},
				},

				{
					hl = {fg = SIDEBAR[1], bg = GREEN_DARK[1], style = 'bold'},
					icon = '  ',
					left_sep =
					{
						always_visible = true,
						hl = {fg = SIDEBAR[1], bg = GREEN_DARK[1]},
						str = RIGHT_SEPARATOR,
					},
					provider = 'git_branch',
				},

				{
					hl = {bg = MIDBAR[1]},
					left_sep =
					{
						always_visible = true,
						hl = {fg = MIDBAR[1], bg = GREEN_DARK[1]},
						str = ' '..LEFT_SEPARATOR,
					},
					provider = '',
				},

				{
					enabled = checkwidth,
					hl = {fg = GREEN_LIGHT[1], bg = MIDBAR[1]},
					icon = '',
					provider = 'git_diff_added',
				},

				{
					enabled = checkwidth,
					hl = {fg = GRAY_LIGHT[1], bg = MIDBAR[1]},
					icon = '',
					provider = 'git_diff_ignored',
				},

				{
					enabled = checkwidth,
					hl = {fg = ORANGE_LIGHT[1], bg = MIDBAR[1]},
					icon = '',
					provider = 'git_diff_changed',
				},

				{
					enabled = checkwidth,
					hl = {fg = RED_LIGHT[1], bg = MIDBAR[1]},
					icon = '',
					provider = 'git_diff_removed',
				},

				{
					hl = {fg = RED[1], bg = MIDBAR[1]},
					icon = ' Ⓧ ',
					provider = 'diagnostic_errors',
				},

				{
					hl = {fg = YELLOW[1], bg = MIDBAR[1]},
					icon = ' ⚠️ ',
					provider = 'diagnostic_warnings',
				},

				{
					hl = {fg = WHITE[1], bg = MIDBAR[1]},
					icon = ' ⓘ ',
					provider = 'diagnostic_info',
				},

				{
					hl = {fg = MAGENTA[1], bg = MIDBAR[1]},
					icon = ' 💡',
					provider = 'diagnostic_hints',
				},
			}, -- }}}

			{}, -- Middle

			{ -- Right {{{
				{
					hl = {fg = TEXT[1], bg = SIDEBAR[1]},
					left_sep =
					{
						hl = {fg = MIDBAR[1], bg = SIDEBAR[1]},
						str = RIGHT_SEPARATOR..' ',
					},
					provider = 'file_encoding',
					right_sep =
					{
						hl = {bg = SIDEBAR[1]},
						str = ' ',
					},
				},

				{
					hl = function() return {fg = BLACK[1], bg = file_color(), style = 'bold'} end,
					left_sep = function() return
						{
							hl = {fg = file_color(), bg = SIDEBAR[1]},
							str = LEFT_SEPARATOR,
						}
					end,
					provider = 'file_type',
					right_sep = function() return
						{
							hl = {fg = file_color(), bg = SIDEBAR[1]},
							str = RIGHT_SEPARATOR..' ',
						}
					end,
				},

				{
					enabled = buffer_not_empty,
					hl = {fg = TEXT[1], bg = SIDEBAR[1]},
					provider = function()
						return ' '..(vim.api.nvim_win_get_cursor(0)[2] + 1)
					end,
				},

				{
					hl = {fg = WHITE[1], bg = MAGENTA_DARK[1]},
					left_sep =
					{
						hl = {fg = MAGENTA_DARK[1], bg = SIDEBAR[1]},
						str = ' '..LEFT_SEPARATOR,
					},
					provider = 'line_percentage',
					right_sep =
					{
						hl = {bg = MAGENTA_DARK[1]},
						str = ' ',
					},
				},

				{
					hl = {fg = GRAY[1], bg = MAGENTA_DARK[1]},
					provider = 'scroll_bar',
				},
			}, -- }}}
		},

		inactive =
		{
			{ -- Left {{{
				{
					hl = {fg = BLACK[1], bg = PURPLE[1], style = 'bold'},
					left_sep =
					{
						hl = {bg = PURPLE[1]},
						str = ' ',
					},
					provider = 'file_type',
				},
				{
					hl = {bg = PURPLE[1]},
					provider = ' ',
					right_sep =
					{
						hl = {fg = PURPLE[1], bg = MIDBAR[1]},
						str = RIGHT_SEPARATOR,
					},
				},
			}, -- }}}

			{{ -- Right {{{
				hl = {fg = BLACK[1], bg = PURPLE[1], style = 'bold'},
				left_sep =
				{
					hl = {fg = PURPLE[1], bg = MIDBAR[1]},
					str = LEFT_SEPARATOR,
				},
				provider = function(_, win_id) return BUF_ICON[vim.bo[vim.api.nvim_win_get_buf(win_id or 0)].filetype] or '' end,
			}}, -- }}}
		},
	}, -- }}}

	force_inactive =
	{ -- {{{
		bufnames = {},
		buftypes = {'help', 'prompt', 'terminal'},
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
