return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"Issafalcon/lsp-overloads.nvim",
	},
	config = function()
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_nvim_lsp.default_capabilities()

		local signs = { Error = " 󰞏", Warn = "󰒡 ", Hint = "󰅏 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(env)
				local opts = { buffer = env.buf, remap = false }
				vim.bo[env.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

				vim.keymap.set("n", "gd", function()
					vim.lsp.buf.definition()
				end, opts)
				vim.keymap.set("n", "gr", function()
					vim.lsp.buf.references()
				end, opts)
				vim.keymap.set("n", "K", function()
					vim.lsp.buf.hover()
				end, opts)
				vim.keymap.set("n", "<leader>vws", function()
					vim.lsp.buf.workspace_symbol()
				end, opts)
				vim.keymap.set("n", "]d", function()
					vim.diagnostic.goto_next()
				end, opts)
				vim.keymap.set("n", "[d", function()
					vim.diagnostic.goto_prev()
				end, opts)
				vim.keymap.set("n", "<leader>vd", function()
					vim.lsp.buf.open_float()
				end, opts)
				vim.keymap.set("n", "<leader>vca", function()
					vim.lsp.buf.code_action()
				end, opts)
				vim.keymap.set("n", "<leader>vrr", function()
					vim.lsp.buf.references()
				end, opts)
				vim.keymap.set("n", "<leader>vrn", function()
					vim.lsp.buf.rename()
				end, opts)
				vim.keymap.set("n", "<leader>vf", function()
					vim.lsp.buf.format({ async = true })
				end, opts)
				vim.keymap.set("n", "<leader>ho", vim.cmd.noh, opts)
			end,
		})

		-- Managing language servers individually
		-- jedi-language-server
		vim.lsp.config("jedi_language_server", {
			capabilities = capabilities,
		})
		-- ruff for Python linting
		vim.lsp.config("ruff", {
			capabilities = capabilities,
		})
		-- ts_ls
		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
		})
		-- rust_analyzer
		vim.lsp.config("rust_analyzer", {
			capabilities = capabilities,
			settings = {
				["rust-analyzer"] = {},
			},
		})
		vim.lsp.config("ocamllsp", {
			capabilities = capabilities,
		})

		-- html
		vim.lsp.config("html", {
			capabilities = capabilities,
		})
        vim.lsp.config("GitHubCopilot", {
            capabilities = capabilities,
        })
		-- configure emmet language server
		vim.lsp.config("emmet_ls", {
			capabilities = capabilities,
			filetypes = {
				"html",
				"typescriptreact",
				"javascriptreact",
				"css",
				"sass",
				"scss",
				"less",
				"svelte",
				"templ",
			},
		})
		-- configure eslint language server
		vim.lsp.config("eslint", {
			capabilities = capabilities,
			filetypes = { "typescriptreact", "javascriptreact", "svelte" },
		})

		-- Lua LS
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = {
							vim.fn.expand("$VIMRUNTIME/lua"),
							vim.fn.stdpath("config") .. "/lua",
						},
						checkThirdParty = false,
					},
					telemetry = {
						enable = false,
					},
				},
			},
		})

		vim.lsp.config("zls", {})

		-- CSS LS
		vim.lsp.config("cssls", {
			capabilities = capabilities,
		})
		vim.lsp.config("gopls", {
			capabilities = capabilities,
			filetypes = { "go" },
		})
		vim.lsp.config("clangd", {
			capabilities = capabilities,
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
			root_pattern = {
				"Makefile",
				".clangd",
				".clang-tidy",
				".clang-format",
				"compile_commands.json",
				"compile_flags.txt",
				"configure.ac",
				".git"
			},
			single_file_support = true,
		})

		vim.lsp.config("templ", {
			capabilities = capabilities,
			filetypes = { "templ" },
		})

		-- Tailwind
		vim.lsp.config("tailwindcss", {
			capabilities = capabilities,
			filetypes = { "templ", "html", "typescriptreact" },
			settings = {
				tailwindCSS = {
					experimental = {
						classRegex = {
							{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
							{ "cx\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" }
						}
					}
				}
			},
		})
		-- htmx custom server
		vim.lsp.config("htmx", {
			cmd = { "htmx-lsp" },
			filetypes = { "templ", "html", "htmx" },
			capabilities = capabilities,
		})
	end,
}
