local function buffer_path()
	local path = vim.api.nvim_buf_get_name(0)
	return path ~= "" and path or vim.fn.getcwd()
end

local function find_upward(pattern)
	return vim.fs.find(function(name)
		return name:match(pattern) ~= nil
	end, { path = buffer_path(), upward = true })[1]
end

local function current_project()
	return find_upward("%.csproj$")
end

local function workspace_target()
	return find_upward("%.slnx?$") or current_project()
end

local function open_terminal(command, cwd)
	vim.cmd("botright split")
	vim.cmd("resize 15")
	vim.fn.termopen(command, { cwd = cwd })
	vim.cmd("startinsert")
end

local function run_dotnet(arguments, target)
	if not target then
		vim.notify("No .NET solution or project found", vim.log.levels.WARN)
		return
	end

	local command = { "dotnet" }
	vim.list_extend(command, arguments)
	table.insert(command, target)
	open_terminal(command, vim.fs.dirname(target))
end

vim.api.nvim_create_user_command("DotnetBuild", function()
	run_dotnet({ "build" }, workspace_target())
end, { desc = "Build the nearest .NET solution or project" })

vim.api.nvim_create_user_command("DotnetTest", function()
	run_dotnet({ "test" }, workspace_target())
end, { desc = "Test the nearest .NET solution or project" })

vim.api.nvim_create_user_command("DotnetRun", function()
	run_dotnet({ "run", "--project" }, current_project())
end, { desc = "Run the current .NET project" })

vim.api.nvim_create_user_command("DotnetWatch", function()
	run_dotnet({ "watch", "--project" }, current_project())
end, { desc = "Watch the current .NET project" })

vim.keymap.set("n", "<leader>pb", "<cmd>DotnetBuild<cr>", { desc = ".NET: build solution" })
vim.keymap.set("n", "<leader>pt", "<cmd>DotnetTest<cr>", { desc = ".NET: test solution" })
vim.keymap.set("n", "<leader>pr", "<cmd>DotnetRun<cr>", { desc = ".NET: run project" })
vim.keymap.set("n", "<leader>pw", "<cmd>DotnetWatch<cr>", { desc = ".NET: watch project" })

return {
	current_project = current_project,
}
