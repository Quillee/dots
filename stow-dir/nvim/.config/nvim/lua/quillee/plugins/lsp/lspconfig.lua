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

		vim.api.nvim_create_autocmd('LspAttach', {
			group = vim.api.nvim_create_augroup('UserLspConfig', {}),
			callback = function(env)
				local opts = { buffer = env.buf, remap = false }
				vim.bo[env.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

				vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
				vim.keymap.set('n', 'gr', function() vim.lsp.buf.references() end, opts)
				vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
				vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
				vim.keymap.set('n', ']d', function() vim.diagnostic.goto_next() end, opts)
				vim.keymap.set('n', '[d', function() vim.diagnostic.goto_prev() end, opts)
				vim.keymap.set('n', '<leader>vd', function() vim.lsp.buf.open_float() end, opts)
				vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
				vim.keymap.set('n', '<leader>vrr', function() vim.lsp.buf.references() end, opts)
				vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
				vim.keymap.set('n', '<leader>vf', function() vim.lsp.buf.format { async = true} end, opts)
				vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, opts)
			end
		})

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
			filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte", "templ" },
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
        lspconfig.gopls.setup({
            capabilities = capabilities,
            filetypes = { 'go' }
        })
        lspconfig.clangd.setup({
            capabilities = capabilities
        })

        -- templ
		require('lspconfig.configs').templ = {
			default_config = {
                cmd = { "templ", "lsp", "-http=localhost:7878", "-log=~/.go/logs/templ-lsp" },
                filetypes = { "templ" },
				root_dir = lspconfig.util.root_pattern("go.mod"),
                settings = {}
			}
		}

		-- Tailwind
		-- Support for tailwind auto completion
		-- install the tailwind server : "sudo npm install -g @tailwindcss/language-server"
		lspconfig.tailwindcss.setup({
			capabilities = capabilities,
            filetypes = { "templ", "html", }
		})
	end,
}
