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
		local dotnet_path = vim.fn.resolve(vim.fn.exepath("dotnet"))
		local dotnet_dir = vim.fs.dirname(dotnet_path)
		local homebrew_dotnet_root = vim.fs.joinpath(vim.fs.dirname(dotnet_dir), "libexec")
		local dotnet_root = vim.env.DOTNET_ROOT
		if not dotnet_root or dotnet_root == "" then
			if vim.uv.fs_stat(vim.fs.joinpath(dotnet_dir, "shared")) then
				dotnet_root = dotnet_dir
			elseif vim.uv.fs_stat(vim.fs.joinpath(homebrew_dotnet_root, "shared")) then
				dotnet_root = homebrew_dotnet_root
			end
		end
		local roslyn_dll = vim.fn.glob(
			vim.fn.stdpath("data") .. "/mason/packages/roslyn-language-server/.store/**/Microsoft.CodeAnalysis.LanguageServer.dll",
			false,
			true
		)[1]

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

		-- Managing language servers individually. Fuck jedi :)
		-- jedi-language-server
		-- vim.lsp.config("jedi_language_server", {
		-- 	capabilities = capabilities,
		-- })
        -- pyrefly
		vim.lsp.config('pyrefly', {
			capabilities = capabilities,
            cmd = { 'uvx', 'pyrefly', 'lsp' },
		})
		-- ruff-lsp for Python linting
		vim.lsp.config('ruff', {
			capabilities = capabilities,
		})
		-- ts_ls
		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
			filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
			settings = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = true,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
					format = {
						indentSize = 2,
						tabSize = 2,
						convertTabsToSpaces = true,
					},
					suggest = {
						completeFunctionCalls = true,
						includeCompletionsWithSnippetText = true,
						includeAutomaticOptionalChainCompletions = true,
					},
				},
				javascript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = true,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
					format = {
						indentSize = 2,
						tabSize = 2,
						convertTabsToSpaces = true,
					},
					suggest = {
						completeFunctionCalls = true,
						includeCompletionsWithSnippetText = true,
						includeAutomaticOptionalChainCompletions = true,
					},
				},
			},
			init_options = {
				preferences = {
					includePackageJsonAutoImports = "auto",
					importModuleSpecifierPreference = "shortest",
					includeCompletionsForModuleExports = true,
					includeCompletionsWithClassMemberSnippets = true,
					includeCompletionsWithObjectLiteralMethodSnippets = true,
					generateReturnInDocTemplate = true,
					renameShorthandProperties = true,
					includeCompletionsWithSnippetText = true,
				},
			},
			single_file_support = true,
		})
		vim.lsp.config("angularls", {
			capabilities = capabilities,
		})
		vim.lsp.config("roslyn", {
			capabilities = capabilities,
			cmd = roslyn_dll and { dotnet_path, roslyn_dll, "--stdio" } or nil,
			cmd_env = {
				DOTNET_ROOT = dotnet_root,
			},
			settings = {
				["csharp|background_analysis"] = {
					dotnet_analyzer_diagnostics_scope = "fullSolution",
					dotnet_compiler_diagnostics_scope = "fullSolution",
				},
				["csharp|code_lens"] = {
					dotnet_enable_references_code_lens = true,
					dotnet_enable_tests_code_lens = true,
				},
				["csharp|completion"] = {
					dotnet_show_completion_items_from_unimported_namespaces = true,
					dotnet_show_name_completion_suggestions = true,
				},
				["csharp|formatting"] = {
					dotnet_organize_imports_on_format = true,
				},
				["csharp|inlay_hints"] = {
					csharp_enable_inlay_hints_for_implicit_object_creation = true,
					csharp_enable_inlay_hints_for_implicit_variable_types = true,
					csharp_enable_inlay_hints_for_lambda_parameter_types = true,
					csharp_enable_inlay_hints_for_types = true,
					dotnet_enable_inlay_hints_for_indexer_parameters = true,
					dotnet_enable_inlay_hints_for_literal_parameters = true,
					dotnet_enable_inlay_hints_for_object_creation_parameters = true,
					dotnet_enable_inlay_hints_for_other_parameters = true,
					dotnet_enable_inlay_hints_for_parameters = true,
				},
				["csharp|symbol_search"] = {
					dotnet_search_reference_assemblies = true,
				},
			},
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
        -- vim.lsp.config("GitHubCopilot", {
        --     capabilities = capabilities,
        -- })
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

		vim.lsp.config("zls", {

		    capabilities=capabilities,
		    settings={
			build_on_save=true,
		    }
		})

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
