-- mappings
let opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
-- compe mappings
vim.api.nvim_set_keymap('i', '<Tab>', 'v:lua.tab_complete()', {expr = true})
vim.api.nvim_set_keymap('i', '<S-Tab>', 'v:lua.s_tab_complete()', {expr = true})
vim.api.nvim_set_keymap('s', '<Tab>', 'v:lua.tab_complete()', {expr = true})
vim.api.nvim_set_keymap('s', '<Tab>', 'v:lua.s_tab_complete()', {expr = true})

-- use an on_attach func to only map the following keys
--> after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    -- enable comletion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- mappings
    -- see :help vim.lsp.* for docs on any of the below functions
    local bufopts = { noremap=true, silent=true, buffer=bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implentation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<leader>d', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<leader>f', vim.lsp.buf.formatting, bufopts)
end

vim.opt.compleopt = "menuone,noselect"

-- completion
-- Source plugin
vim.opt.runtimepath = vim.opt.runtimepath + '~/.local/share/nvim/plugins/completion'
vim.opt.runtimepath = vim.opt.runtimepath + '~/.local/share/nvim/plugins/completion/after'
vim.opt.runtimepath = vim.opt.runtimepath + '~/.local/share/nvim/plugins/lsp'

local lsp_flags = {
    -- default for nvim 0.7+
    debounce_text_changes = 150
}
local nvim_lsp = require('lspconfig')
require('compe').setup {
    enabled = true,
    autocomplete = true,
    debug = false,
    min_length = 1,
    preselect = 'always',
    max_abbr_width = 80,
    max_kind_width = 80,
    max_menu_width = 80,
    documentation = {
        border = 'rounded', -- check options later :help nvim_open_win
        winhighlight = 'NormalFloat:CompeDocumentation,FloatBoarder:CompeDocumentationBorder',
        max_width = 60,
        max_height = math.floor(vim.o.lines * 0.3),
        min_height = 1,
    },
    source = {
        path = true,
        buffer = true,
        calc = true,
        nvim_lsp = true,
        nvim_lua = true,
    },
}

-- @todo: :help this
-- not sure what this is doing
local replace_termcode = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

_G.tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return replace_termcode('<C-n>')
    elseif check_back_space() then
        return replace_termcode('<Tab>')
    else
        print('comp')
        return vim.fn['compe#complete'()
    end
end

_G.s_tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return replace_termcode('<C-p>')
    else
        -- if <S-Tab> is not working in your terminal use <C-h>
        return replace_termcode('<S-Tab>')
    end
end

-- capabilities
local cap = vim.lsp.protocol.make_client_capabilities()
-- do I actually want snippets?
cap.textDocument.completion.completionItem.snippetSupport = true
cap.textDocument.completion.completionItem.resolveSupport = {
    properties = {
        'documentation',
        'detail',
        'additionalTextEdits',
    }
}

nvim_lsp['pyright'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = cap,
}
nvim_lsp['tsserver'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = cap,
}
nvim_lsp['rust_analyzer'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = cap,
    settings = {
        ["rust-analyzer"] = {}
    }
}

