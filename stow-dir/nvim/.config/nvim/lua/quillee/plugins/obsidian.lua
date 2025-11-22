return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = function()
    local workspaces = {}
    
    -- Check if vault directories exist before adding them
    local vault_paths = {
      { name = "life", path = "~/vault/life" },
      { name = "csc-paradigms", path = "~/vault/csc-paradigms" },
    }
    
    for _, vault in ipairs(vault_paths) do
      local expanded_path = vim.fn.expand(vault.path)
      if vim.fn.isdirectory(expanded_path) == 1 then
        table.insert(workspaces, vault)
      end
    end
    
    -- If no vaults found, use current directory as fallback
    if #workspaces == 0 then
      workspaces = {
        {
          name = "fallback",
          path = ".",
        },
      }
    end
    
    return {
      workspaces = workspaces,
      -- Don't auto-detect workspaces in every directory
      detect_cwd = false,
      -- Disable features that might cause errors
      daily_notes = {
        folder = "daily",
        date_format = "%Y-%m-%d",
      },
      completion = {
        nvim_cmp = false,
      },
      -- Don't create missing directories
      ensure_installed = false,
      disable_frontmatter = false,
      -- Optional: Configure UI
      ui = {
        enable = true,
        checkboxes = {
          [" "] = { char = "☐", hl_group = "ObsidianTodo" },
          ["x"] = { char = "✔", hl_group = "ObsidianDone" },
        },
      },
      -- Handle missing workspace gracefully
      callbacks = {
        -- Don't error if workspace doesn't exist
        enter_note = function(client, note)
          vim.cmd("setlocal conceallevel=2")
        end,
      },
    }
  end,
}

