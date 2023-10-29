local feline_colors = {
    bg = '#fff',
    fg = '#000',
    yellow = '#e5c07b',
    cyan = '#8abeb7',
    darkblue = '#528bff',
    green = '#98c379',
    orange = '#d19a66',
    violet = '#b294bb',
    magenta = '#ff80ff',
    blue = '#61afef',
    red = '#e88388'
};

local function file_osinfo()
    local os = vim.bo.fileformat:upper()
    local icon
    if os == 'UNIX' then
        icon = ' '
    elseif os == 'MAC' then
        icon = ' '
    else
        icon = ' '
    end
    return icon .. os
end

local function get_filename(component, modifiers)
    -- local filename = vim.fn.expand('%:t')
    local modifiers_str = table.concat(modifiers, ":")
    local filename = vim.fn.expand("%" .. modifiers_str)
    local extension = vim.fn.expand('%:e')
    local modified_str

    local icon = component.icon or
        require'nvim-web-devicons'.get_icon(filename, extension, { default = true })

    if filename == '' then filename = 'unnamed' end

    if vim.bo.modified then
        local modified_icon = component.file_modified_icon or '●'
        modified_str = modified_icon .. ' '
    else
        modified_str = ''
    end

    return icon .. ' ' .. filename .. ' ' .. modified_str
end

function reverse(tbl)
    for i = 1, math.floor(#tbl/2) do
        local j = #tbl - i + 1
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function get_tail(filename)
    return vim.fn.fnamemodify(filename, ":t")
end

function split_filename(filename)
    local nodes = {}
    for parent in string.gmatch(filename, "[^/]+/") do
        table.insert(nodes, parent)
    end
    table.insert(nodes, get_tail(filename))
    return nodes
end

function reverse_filename(filename)
    local parents = split_filename(filename)
    reverse(parents)
    return parents
end

function same_until(first, second)
    for i = 1, #first do
        if first[i] ~= second[i] then
            return i
        end
    end
    return 1
end

function get_unique_filename(filename, other_filenames)
    local rv = ''

    local others_reversed = vim.tbl_map(reverse_filename, other_filenames)
    local filename_reversed = reverse_filename(filename)
    local same_until_map = vim.tbl_map(function(second) return same_until(filename_reversed, second) end, others_reversed)

    local max = 0
    for _, v in ipairs(same_until_map) do
        if v > max then max = v end
    end
    for i = max, 1, -1 do
        rv = rv .. filename_reversed[i]
    end

    return rv
end

function get_current_ufn()
    local buffers = vim.fn.getbufinfo()
    local listed = vim.tbl_filter(function(buffer) return buffer.listed == 1 end, buffers)
    local names = vim.tbl_map(function(buffer) return buffer.name end, listed)
    local current_name = vim.fn.expand("%")
    return get_unique_filename(current_name, names)
end

return {
    get_filename = get_filename,
    file = {
        file_osinfo  = file_osinfo,
        get_current_ufn = get_current_ufn,
        get_unique_filename = get_unique_filename,
        same_until = same_until,
        reverse_filename = reverse_filename,
        split_filename = split_filename,
        reverse = reverse,
        get_tail = get_tail,
        feline_colors = feline_colors,
    },
}

