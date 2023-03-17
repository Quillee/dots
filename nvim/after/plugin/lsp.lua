local lsp = require 'lsp-zero'

lsp.preset('recommended')

lsp.ensure_installed({
    'rust_analyzer',
    'zls',
    'sumneko_lua',
    'clangd',
    'tsserver',
    'eslint',
    'rnix'
})

--   פּ ﯟ   some other good icons
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

local cmp = require 'cmp'
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    ['<C-y']  = cmp.mapping.confirm({ select = true }),
    ['<C-x>'] = cmp.mapping.complete(),
})
local lua_snip = require 'luasnip'

lsp.set_preferences {
    sign_icons = {
        error = 'ﲍ', -- '', -- '',  -- '',
        warn = '裂', -- '', -- '',
        hint = '',
        info = '' -- ''
    }
}

lsp.setup_nvim_cmp({
    mapping = cmp_mappings,
    sources = {
        { name = 'path' },
        { name = 'buffer', keyword_length = 2 },
        { name = 'nvim_lsp', keyword_length = 2 },
        { name = 'luasnip', keyword_length = 3 }
    },
    completion = {
        competeopt = 'menu,menuone,noinsert,noselect'
    },
    documentation = {
        max_height = 15,
        max_width = 65,
        border = 'rounded',
        col_offset = 0,
        side_padding = 1,
        winhighlight = 'Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None',
        zindex = 1001
    },
    snippet = {
        expand = function(args)
            lua_snip.lsp_expand(args.body)
        end
    },
    formatting = {
        fields = { 'kind', 'abbr', 'menu' },
        format = function(entry, vim_item)
            vim_item.kind = symbol_map[vim_item.kind]
            vim_item.menu = symbol_map[entry.source.name]
            return vim_item
        end
    },
})

-- attaches on every buffer, so if LSP isn't configured for current buffer,
--  it'll use the defaults of nvim
lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }

    vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set('n', ']d', function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set('n', '[d', function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set('n', '<leader>vd', function() vim.lsp.buf.open_float() end, opts)
    vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set('n', '<leader>vrr', function() vim.lsp.buf.references() end, opts)
    vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, opts)
end)

lsp.setup()

vim.diagnostic.config({ virtual_text = true })
