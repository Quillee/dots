return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = true,
        suggestions = 20,
      },
      presets = {
        operators = false,
        motions = false,
        text_objects = false,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },
    window = {
      border = "single",
      position = "bottom",
      margin = { 1, 0, 1, 0 },
      padding = { 1, 2, 1, 2 },
    },
    layout = {
      height = { min = 4, max = 25 },
      width = { min = 20, max = 50 },
      spacing = 3,
      align = "left",
    },
    show_help = true,
    show_keys = true,
    triggers = "auto",
    triggers_blacklist = {
      i = { "j", "k" },
      v = { "j", "k" },
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    
    -- Register leader key groups
    wk.register({
      ["<leader>"] = {
        p = { name = "+project" },
        h = { name = "+harpoon/help/highlight" },
        l = { name = "+telescope/lists" },
        v = { name = "+lsp/vim" },
        g = { name = "+git" },
        m = { name = "+molten" },
        t = { name = "+terminal" },
        u = "Toggle Undotree",
      },
      -- Telescope submappings
      ["<leader>l"] = {
        name = "+telescope",
        c = { name = "+current/commands" },
        d = { name = "+diagnostics/lsp" },
      },
      -- Harpoon submappings
      ["<leader>h"] = {
        name = "+harpoon",
        a = { name = "+add/nav" },
      },
    })
    
    -- Register all the specific mappings with descriptions
    wk.register({
      ["<leader>pv"] = { "<cmd>CHADopen<cr>", "Open file explorer" },
      ["<leader>u"] = { "<cmd>UndotreeToggle<cr>", "Toggle Undotree" },
      
      -- Terminal mappings
      ["<leader>ts"] = { "<cmd>split | terminal<cr>", "Split terminal horizontally" },
      ["<leader>tv"] = { "<cmd>vsplit | terminal<cr>", "Split terminal vertically" },
      ["<leader>tz"] = { "<cmd>terminal<cr>", "Open terminal" },
      
      -- Harpoon mappings
      ["<leader>haa"] = { "Add file to Harpoon" },
      ["<leader>han"] = { "Navigate to next Harpoon file" },
      ["<leader>hap"] = { "Navigate to previous Harpoon file" },
      ["<leader>ht"] = { "Go to terminal 1" },
      ["<leader>hh"] = { "Show buffer local keymaps" },
      
      -- Telescope mappings
      ["<leader>lf"] = { "Find files" },
      ["<leader>ls"] = { "Grep string in files" },
      ["<leader>ll"] = { "Live grep" },
      ["<leader>lb"] = { "Buffers" },
      ["<leader>lcb"] = { "Current buffer fuzzy find" },
      ["<leader>lcl"] = { "Jumplist" },
      ["<leader>lr"] = { "Registers" },
      ["<leader>lu"] = { "Undo history" },
      ["<leader>lo"] = { "Old files (recently opened)" },
      ["<leader>lp"] = { "Resume last picker" },
      ["<leader>lm"] = { "Marks" },
      ["<leader>lk"] = { "Keymaps" },
      ["<leader>lH"] = { "Help tags" },
      ["<leader>lc"] = { "Colorscheme picker" },
      ["<leader>lh"] = { "Search history" },
      ["<leader>lch"] = { "Command history" },
      
      -- LSP Telescope mappings
      ["<leader>ld"] = { "LSP definitions" },
      ["<leader>li"] = { "LSP implementations" },
      ["<leader>lt"] = { "LSP type definitions" },
      ["<leader>lR"] = { "LSP references" },
      ["<leader>lw"] = { "LSP workspace symbols" },
      ["<leader>lds"] = { "LSP document symbols" },
      ["<leader>lD"] = { "Diagnostics" },
      
      -- Git mappings
      ["<leader>gc"] = { "Git buffer commits" },
      ["<leader>gb"] = { "Git branches" },
      ["<leader>gs"] = { "Git status" },
      ["<leader>gt"] = { "Git stash" },
      
      -- LSP mappings
      ["<leader>vws"] = { "Workspace symbol" },
      ["<leader>vd"] = { "Open diagnostic float" },
      ["<leader>vca"] = { "Code action" },
      ["<leader>vrr"] = { "References" },
      ["<leader>vrn"] = { "Rename" },
      ["<leader>vf"] = { "Format file" },
      ["<leader>ho"] = { "Clear search highlight" },
      
      -- Molten mappings
      ["<leader>mi"] = { "Initialize Molten with Python" },
      ["<leader>me"] = { "Evaluate operator" },
      ["<leader>ml"] = { "Evaluate line" },
      ["<leader>mr"] = { "Re-evaluate cell" },
    })
    
    -- Visual mode mappings
    wk.register({
      ["<leader>mve"] = { "Evaluate visual selection" },
    }, { mode = "v" })
  end,
}
