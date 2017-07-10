" Maintainer: Kaiting Chen <ktchen14@gmail.com>
" Version:    0.1

if exists('g:loaded_status_symbol')
  finish
endif
let g:loaded_status_symbol = 1

set guioptions-=e
set laststatus=2
set showtabline=2
set tabline=%!status_symbol#render(&columns)

augroup StatusSymbol
  autocmd!
  autocmd BufWinEnter,WinEnter,VimEnter * call status_symbol#status#update()

  autocmd ColorScheme * exec 'source ' . expand('<sfile>:h') . '/hilite.vim'

  autocmd BufDelete * call status_symbol#buffed#delete(str2nr(expand('<abuf>')))
  autocmd BufAdd,BufDelete,BufFilePost,VimEnter *
        \ call status_symbol#buffed#disambiguate(status_symbol#buffed#list())
  autocmd BufEnter * call status_symbol#buffed#center(str2nr(expand('<abuf>')))
augroup end
