let g:colorscheme = "cobalt2"
fun! ColorMyPencils()
    let g:gruvbox_contrast_dark = 'hard'
    if exists('+termguicolors')
        let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
        let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    endif
    let g:gruvbox_invert_selection='0'

    set background=dark
    if has('nvim')
        call luaeval('vim.cmd("colorscheme " .. _A[1])', [g:colorscheme])
    else
        " TODO: What the way to use g:colorscheme
        colorscheme cobalt2
    endif

    " highlight ColorColumn ctermbg=0 guibg=grey
    " hi SignColumn guibg=none
    " hi CursorLineNR guibg=None
    " highlight Normal guibg=none
    highlight LineNr guifg=#ff8659
    " highlight LineNr guifg=#aed75f
    highlight LineNr guifg=#5eacd3
    highlight netrwDir guifg=#5eacd3
    highlight qfFileName guifg=#aed75f
    hi TelescopeBorder guifg=#15eacd
endfun
" colo tokyonight
lua require('colorbuddy').colorscheme('cobalt2')
set t_Co=256
call ColorMyPencils()
set termguicolors

" Vim with me
nnoremap <leader>rc :call ColorMyPencils()<CR>
nnoremap <leader>vwb :let g:colorscheme =
