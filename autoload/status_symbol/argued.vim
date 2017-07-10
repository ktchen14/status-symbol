let s:border = get(g:, 'status_symbol_argued_border', ['', '', '|'])
if type(s:border) != v:t_list
  let s:border = ['', '', s:border]
elseif len(s:border) == 2
  call add(s:border, '')
endif

function! status_symbol#argued#list()
  return range(argc())
endfunction

function! status_symbol#argued#decorate(number)
  return [' ', argv(a:number), ' ']
endfunction

function! status_symbol#argued#colorize(atom)
  let prefix = 'StatusSymbolArgued'
  if has_key(a:atom, 'number')
    return prefix . (status_symbol#argued#center() == a:atom.number ? 'Current' : 'Hidden')
  endif
  return 'StatusSymbolArguedNormal'
endfunction

function! status_symbol#argued#center()
  return argidx()
endfunction

function! status_symbol#argued#detect_change()
  if status_symbol#ticker#detect_change_in('argidx()')
    return 'argidx'
  endif
  if status_symbol#ticker#detect_change_in('argc()')
    return 'argc'
  endif
  if status_symbol#ticker#detect_change_in('arglistid()')
    return 'arglistid'
  endif
  return ''
endfunction

let s:layout = {}
function! status_symbol#argued#render(length)
  return status_symbol#ticker#render('argued', a:length, s:border, s:layout)
endfunction
