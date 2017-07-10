function! status_symbol#status#buffer_head()
  if !exists('b:status_symbol_buffed_tail')
    return ''
  endif
  let tail = b:status_symbol_buffed_tail
  let path = b:status_symbol_buffed_path
  return path[:-strlen(tail) - 1]
endfunction

function! status_symbol#status#buffer_tail()
  return get(b:, 'status_symbol_buffed_tail', bufname('%'))
endfunction

function! status_symbol#status#render(number)
  let active = winnr() == a:number

  if active
    call status_symbol#update()
  endif

  let hilite = active ? 'StatusLine' : 'StatusLineNC'

  let output = '%#' . hilite . '#'

  let output .= ' ' . a:number . ' > '

  if exists('*fugitive#head') && !empty(fugitive#head())
    let output .= fugitive#head() . ' > '
  endif

  let output .= '%#StatusSymbolBufferHead#'
  let output .= '%{status_symbol#status#buffer_head()}'

  let output .= '%#StatusSymbolBufferTail#'
  let output .= '%{status_symbol#status#buffer_tail()}'

  let output .= '%#' . hilite . '#'

  return output . '%=%l:%c'
endfunction

function! status_symbol#status#update()
  for number in range(1, winnr('$'))
    call setwinvar(number, '&statusline', '%!status_symbol#status#render(' . number . ')')
  endfor
endfunction
