" Auto Commands example
" function that can be called using :call
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

augroup MEH
    autocmd!
    autocmd BufWritePre * :call TrimWhitespace()
augroup END
