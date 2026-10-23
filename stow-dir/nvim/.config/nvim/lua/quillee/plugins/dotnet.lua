local function target_path(project)
	if not project then
		vim.notify("No .csproj found for the current buffer", vim.log.levels.ERROR)
		return require("dap").ABORT
	end

	vim.fn.system({ "dotnet", "build", project, "--nologo" })
	if vim.v.shell_error ~= 0 then
		vim.notify("dotnet build failed", vim.log.levels.ERROR)
		return require("dap").ABORT
	end

	local output = vim.fn.system({ "dotnet", "msbuild", project, "-getProperty:TargetPath", "--nologo" })
	if vim.v.shell_error ~= 0 then
		vim.notify("Unable to resolve .NET build output", vim.log.levels.ERROR)
		return require("dap").ABORT
	end

	return vim.trim(output)
end

return {
	{
		"seblyng/roslyn.nvim",
		ft = { "cs", "razor" },
		opts = {},
		config = function(_, opts)
			require("roslyn").setup(opts)

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("DotnetRoslyn", { clear = true }),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if not client or client.name ~= "roslyn" then
						return
					end

					vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
					vim.lsp.codelens.enable(true, { bufnr = args.buf })
				end,
			})
		end,
	},
	{
		"mfussenegger/nvim-dap",
		ft = { "cs" },
		config = function()
			local dap = require("dap")

			dap.adapters.coreclr = {
				type = "executable",
				command = "netcoredbg",
				args = { "--interpreter=vscode" },
			}

			dap.configurations.cs = {
				{
					type = "coreclr",
					name = "Launch current .NET project",
					request = "launch",
					program = function()
						return target_path(require("quillee.core.dotnet").current_project())
					end,
					cwd = function()
						local project = require("quillee.core.dotnet").current_project()
						return project and vim.fs.dirname(project) or vim.fn.getcwd()
					end,
				},
			}

			vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: start/continue" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
			vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "Debug: step out" })
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
			vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Debug: toggle REPL" })
			vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: terminate" })
			vim.keymap.set("n", "<leader>ds", function()
				require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes)
			end, { desc = "Debug: scopes" })
		end,
	},
}
