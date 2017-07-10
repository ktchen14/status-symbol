let s:modified_mark = get(g:, 'status_symbol_modified_mark', '⁺')
let s:readonly_mark = get(g:, 'status_symbol_readonly_mark', '⁻')

let s:border = get(g:, 'status_symbol_buffed_border', ['', '', '|'])
if type(s:border) != v:t_list
  let s:border = ['', '', s:border]
elseif len(s:border) == 2
  call add(s:border, '')
endif

let s:noname = get(g:, 'status_symbol_buffed_noname', '[No Name]')

" Mark buffer as deleted so as to appear unlisted (mostly for the purposes of
" disambiguation). This is necessary since BufDelete fires before a buffer is
" removed from the buffer list. We don't actually have to reset this after the
" deletion since buffer numbers are guaranteed to be unique for the lifetime
" of the vim session.
function! status_symbol#buffed#delete(buffer)
  " When :e is executed in a new buffer (created with :enew) BufDelete is
  " executed but the buffer number is unchanged. We have to hack around this
  " by not masking a to-be-deleted unnamed buffer.
  if bufname(a:buffer) | let s:mask = a:buffer | endif
endfunction

function! status_symbol#buffed#islisted(buffer)
  if !buflisted(a:buffer) || a:buffer == get(s:, 'mask', -1)
    return v:false
  endif
  " Quickfix buffers are not unlisted by default
  return getbufvar(a:buffer, '&buftype') !=? 'quickfix'
endfunction

" Return a list of buffer numbers of listed buffers
function! status_symbol#buffed#list()
  return filter(range(1, bufnr('$')), 'status_symbol#buffed#islisted(v:val)')
endfunction

" :p is guaranteed to append a directory separator to getcwd()
let s:dirsep = fnamemodify(getcwd(), ':p')[-1:]

" Return the canonicalized path of the specified buffer number, reduced if
" possible relative to ~ or ., according to:
"   fnamemodify(bufname(a:buffer), ':p:~:.')
" And memoize the result in a buffer variable
function! status_symbol#buffed#path(buffer)
  let path = getbufvar(a:buffer, 'status_symbol_buffed_path')
  if empty(path) && !empty(bufname(a:buffer))
    let path = fnamemodify(bufname(a:buffer), ':p:~:.')
    call setbufvar(a:buffer, 'status_symbol_buffed_path', path)
  endif
  return path
endfunction

" Return the tail of the specified buffer number and set it as a buffer
" variable if it is not already set
function! status_symbol#buffed#tail(buffer)
  let tail = getbufvar(a:buffer, 'status_symbol_buffed_tail')
  if empty(tail) && !empty(bufname(a:buffer))
    " Set tail to be the last component of path. A trailing directory
    " seperator is not considered to be its own component and is kept in the
    " tail, i.e.:
    "   /a/b/ => b/
    " Making this different from basename and fnamemodify(path, ':t')
    let path = status_symbol#buffed#path(a:buffer)
    let i = strridx(path, s:dirsep, strlen(path) - 2)
    let tail = path[i + 1:]
    call setbufvar(a:buffer, 'status_symbol_buffed_tail', tail)
  endif
  return tail
  " status_symbol_buffed_tail should be updated for each buffer when
  " BufAdd, BufDelete, BufFilePost - these will require disambiguate
  " cd - and this also reset buffer_path and require disambiguate
  " BufFilePost needs to reset buffer_path
endfunction

function! status_symbol#buffed#disambiguate(buffer_list)
  let ambiguous = {}

  for buffer in filter(a:buffer_list, '!empty(bufname(v:val))')
    " Set tail to be the last component of path. A trailing directory
    " seperator is not considered to be its own component and is kept in the
    " tail, i.e.:
    "   /a/b/ => b/
    " Making this different from basename and fnamemodify(path, ':t')
    let path = status_symbol#buffed#path(buffer)
    let i = strridx(path, s:dirsep, strlen(path) - 2)
    let tail = path[i + 1:]
    call setbufvar(buffer, 'status_symbol_buffed_tail', tail)
    let ambiguous[tail] = get(ambiguous, tail, []) + [buffer]
  endfor

  " Disambiguate files by successively adding trailing path segments
  while len(filter(ambiguous, 'len(v:val) > 1'))
    for tail in keys(ambiguous)
      for buffer in remove(ambiguous, tail)
        let path = status_symbol#buffed#path(buffer)
        let tail = status_symbol#buffed#tail(buffer)
        if tail !=# path
          let i = strridx(path, s:dirsep, strlen(path) - strlen(tail) - 2)
          let tail = path[i + 1:]
          call setbufvar(buffer, 'status_symbol_buffed_tail', tail)
        endif
        let ambiguous[tail] = get(ambiguous, tail, []) + [buffer]
      endfor
    endfor
  endwhile
endfunction

" Return v:true if a mark should be shown when the buffer number belongs to a
" modified buffer (this function is only called when the buffer is &modified).
" By default scratch buffers are excluded.
function! status_symbol#buffed#show_modified(buffer)
  return index(['nofile', 'acwrite'], getbufvar(a:buffer, '&buftype')) == -1
endfunction

" Return v:true if a mark should be shown when the buffer number belongs to a
" readonly buffer (this function is only called when the buffer is &readonly).
function! status_symbol#buffed#show_readonly(buffer)
  return v:true
endfunction

function! status_symbol#buffed#decorate(number)
  let output = [' ']

  let text = strtrans(status_symbol#buffed#tail(a:number))
  if empty(text)
    let text = s:noname
  endif
  call add(output, text)

  if getbufvar(a:number, '&readonly') &&
        \ status_symbol#buffed#show_readonly(a:number)
    call add(output, { 'text': s:readonly_mark })
  endif

  if getbufvar(a:number, '&modified') &&
        \ status_symbol#buffed#show_modified(a:number)
    call add(output, { 'text': s:modified_mark })
  endif

  return output + [' ']
endfunction

function! status_symbol#buffed#colorize(atom)
  if has_key(a:atom, 'number')
    if winbufnr(0) == a:atom.number
      let hilite = 'Current'
    elseif bufwinnr(a:atom.number) > 0
      let hilite = 'Active'
    else
      let hilite = 'Hidden'
    endif

    if has_key(a:atom, 'text')
      if a:atom.text == s:modified_mark
        let hilite .= 'ModifiedMark'
      elseif a:atom.text == s:readonly_mark
        let hilite .= 'ReadonlyMark'
      endif
    endif

    return 'StatusSymbolBuffed' . hilite
  endif

  return 'StatusSymbolBuffedNormal'
endfunction

function! status_symbol#buffed#center(...)
  if a:0 == 0
    return get(s:, 'center', winbufnr(0))
  elseif a:0 == 1
    if status_symbol#buffed#islisted(a:1)
      let s:center = a:1
    endif
  else
    try
      echoerr 'Too many arguments for function: status_symbol#buffed#center'
    endtry
  endif
endfunction

let s:layout = {}
function! status_symbol#buffed#render(length)
  return status_symbol#ticker#render('buffed', a:length, s:border, s:layout)
endfunction
