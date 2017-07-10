let s:show_tabbed = get(g:, 'status_symbol_show_tabbed', 2)

let g:status_symbol_main_ticker = 'buffed'

function! status_symbol#render(length)
  let [mode_output, mode_length] = status_symbol#mode#render()

  let tabbed_length = (a:length - mode_length) * 10 / 100
  if s:show_tabbed == 2 || s:show_tabbed == 1 && tabpagenr('$') > 1
    let [tabbed_output, tabbed_length] = status_symbol#tabbed#render(tabbed_length)
  else
    let [tabbed_output, tabbed_length] = ['', 0]
  endif

  let main_length = a:length - mode_length - tabbed_length
  let [main_output, main_length] = status_symbol#{g:status_symbol_main_ticker}#render(main_length)

  return mode_output . main_output . '%=' . tabbed_output
endfunction

let s:change_record = {}
" function! status_symbol#ticker#detect_change_in(expr)
"   let result = eval(a:expr)
"   if !has_key(s:change_record, a:expr) || s:change_record[a:expr] !=# result
"     let change = v:true
"   endif
"   let s:change_record[a:expr] = result
"   return get(l:, 'change', v:false)
" endfunction

function! status_symbol#detect_change()
  let mode = mode()
  if !exists('s:mode') || s:mode !=# mode
    let s:mode = mode
    return 'mode'
  endif
  let s:mode = mode

  if g:status_symbol_main_ticker ==# 'argued'
    let argidx = argidx()
    if !exists('s:argidx') || s:argidx != argidx
      let s:argidx = argidx
      return 'argidx'
    endif
    let s:argidx = argidx

    let argc = argc()
    if !exists('s:argc') || s:argc != argc
      let s:argc = argc
      return 'argc'
    endif
    let s:argc = argc

    let arglistid = arglistid()
    if !exists('s:arglistid') || s:arglistid != arglistid
      let s:arglistid = arglistid
      return 'arglistid'
    endif
    let s:arglistid = arglistid
  elseif g:status_symbol_main_ticker ==# 'jumped'
    let jumps = execute('jumps')
    if !exists('s:jumps') || s:jumps !=# jumps
      let s:jumps = jumps
      return 'jumps'
    endif
    let s:jumps = jumps
  elseif g:status_symbol_main_ticker ==# 'edited'
    let changes = execute('changes')
    if !exists('s:changes') || s:changes !=# changes
      let s:changes = changes
      return 'changes'
    endif
    let s:changes = changes
  endif

  return ''
endfunction

function! status_symbol#update()
  if status_symbol#detect_change()
    set tabline=
    set tabline=%!status_symbol#render(&columns)
  endif
endfunction

function! status_symbol#set_main_ticker(domain)
  let g:status_symbol_main_ticker = a:domain
  set tabline=
  set tabline=%!status_symbol#render(&columns)
endfunction
