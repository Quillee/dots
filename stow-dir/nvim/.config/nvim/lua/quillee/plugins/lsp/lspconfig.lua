local symbol_map = {
    -- kind
    Text = '',
    Method = 'm',
    Function = '',
    Constructor = '',
    Field = '',
    Variable = '',
    Class = '',
    Interface = '',
    Module = '',
    Property = '',
    Unit = '',
    Value = '',
    Enum = '',
    Keyword = '',
    Snippet = '',
    Color = '',
    File = '',
    Reference = '',
    Folder = '',
    EnumMember = '',
    Constant = '',
    Struct = '',
    Event = '',
    Operator = '',
    TypeParameter = '',
    -- menu
    buffer = '',
    nvim_lsp = 'λ', -- '',
    luasnip = '',
    nvim_lua = '',
    latex_symbols = '',
    path = '🖫'
}

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		local lspconfig = require("lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_nvim_lsp.default_capabilities()

		local signs = { Error = 'ﲍ ', Warn = '裂', Hint = ' ', Info = ' ' }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end
		-- Managing language servers individually
		-- pyright
		lspconfig.pyright.setup({
			capabilities = capabilities,
		})
		-- tsserver
		lspconfig.tsserver.setup({
			capabilities = capabilities,
		})
		-- rust_analyzer
		lspconfig.rust_analyzer.setup({
			capabilities = capabilities,
			-- Server-specific settings. See `:help lspconfig-setup`
			settings = {
				["rust-analyzer"] = {},
			},
		})

		-- html
		lspconfig.html.setup({
			capabilities = capabilities,
		})
		-- configure emmet language server
		lspconfig.emmet_ls.setup({
			capabilities = capabilities,
			filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
		})

		-- Lua LS
		lspconfig.lua_ls.setup({
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		})

		-- CSS LS
		lspconfig.cssls.setup({
			capabilities = capabilities,
		})

		-- Tailwind
		-- Support for tailwind auto completion
		-- install the tailwind server : "sudo npm install -g @tailwindcss/language-server"
		lspconfig.tailwindcss.setup({
			capabilities = capabilities,
		})
	end,
}
