" Maintainer: Kaiting Chen <ktchen14@gmail.com>
" Version:    0.1

if exists('g:loaded_status_symbol')
  finish
endif
let g:loaded_status_symbol = 1

if has('guioptions')
  set guioptions-=e
endif
let g:status_symbol_showtabline = &showtabline
set showtabline=2
set tabline=%!status_symbol#render(&columns)

augroup StatusSymbol
  autocmd!

  autocmd BufAdd,BufDelete,BufFilePost * let g:status_symbol_rename = 1

  autocmd ModeChanged *
        \ if v:event.new_mode[0] !=# v:event.old_mode[0] |
        \ redrawtabline |
        \ endif

  autocmd OptionSet showtabline
        \ let g:status_symbol_showtabline = v:option_new |
        \ set showtabline=2
augroup end

hi default link StatusSymbolModeNormal   TabLineSel
hi default link StatusSymbolModeVisual   StatusSymbolModeNormal
hi default link StatusSymbolModeV-Line   StatusSymbolModeVisual
hi default link StatusSymbolModeV-Block  StatusSymbolModeVisual
hi default link StatusSymbolModeSelect   StatusSymbolModeVisual
hi default link StatusSymbolModeS-Line   StatusSymbolModeSelect
hi default link StatusSymbolModeS-Block  StatusSymbolModeSelect
hi default link StatusSymbolModeInsert   StatusSymbolModeNormal
hi default link StatusSymbolModeReplace  StatusSymbolModeInsert
hi default link StatusSymbolModeCommand  StatusSymbolModeNormal
hi default link StatusSymbolModePrompt   StatusSymbolModeCommand
hi default link StatusSymbolModeTerminal StatusSymbolModeInsert

hi default link StatusSymbolActiveBuffer TabLineSel
hi default link StatusSymbolNormalBuffer TabLine
hi default link StatusSymbolHiddenBuffer TabLine
hi default link StatusSymbolBorder       TabLineFill
hi default link StatusSymbolScrollMark   TabLineFill

hi default link StatusSymbolActivePage   TabLineSel
hi default link StatusSymbolNormalPage   TabLine

hi default link StatusSymbolActiveBufferModifiedMark StatusSymbolActiveBuffer
hi default link StatusSymbolActiveBufferReadonlyMark StatusSymbolActiveBuffer
hi default link StatusSymbolNormalBufferModifiedMark StatusSymbolNormalBuffer
hi default link StatusSymbolNormalBufferReadonlyMark StatusSymbolNormalBuffer
hi default link StatusSymbolHiddenBufferModifiedMark StatusSymbolHiddenBuffer
hi default link StatusSymbolHiddenBufferReadonlyMark StatusSymbolHiddenBuffer
