return {
    'folke/tokyonight.nvim', -- deep blues and nice contrast
    'catppuccin/nvim', -- lighter porple
    'fenetikm/falcon',
    'sainnhe/everforest', -- cold green
    'neg-serg/neg.nvim', -- blue
    'dzfrias/noir.nvim', -- grey on black. very little contrast
    'adigitoleo/vim-mellow',
    'eihigh/vim-aomi-grayscale', -- slate bg with grayscale
    'daschw/leaf.nvim',
    opt = {
        transparent = true,
        styles= {
            underlineStyle = "underline",
            commentStyle = "italic",
            functionStyle = "NONE",
            keywordStyle = "italic",
            statementStyle = "bold",
            typeStyle = "NONE",
            variablebuiltinStyle = "italic",
            transparent = false,
            colors = {},
            overrides = {},
            theme = "auto", -- default, based on vim.o.background, alternatives: "light", "dark"
            contrast = "low", -- default, alternatives: "medium", "high"
        }

    }
}
