local default_colorscheme = "slate"

function color_me(color)
    color = color or default_colorscheme
    -- vim.cmd.colorscheme(color)
    local status_ok, _ = pcall(vim.cmd, "colorscheme " .. color)
     if not status_ok then
         vim.notify("colorscheme " .. color .. " not found!")
         return
     end

    -- transparent bg
    -- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

end
color_me()

--local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
-- if not status_ok then
  -- vim.notify("colorscheme " .. colorscheme .. " not found!")
  -- return
-- end

