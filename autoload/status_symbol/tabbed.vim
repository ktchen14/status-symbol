let s:border = get(g:, 'status_symbol_tabbed_border', [' ', ' ', ' '])
if type(s:border) != v:t_list
  let s:border = ['', '', s:border]
elseif len(s:border) == 2
  call add(s:border, '')
endif

function! status_symbol#tabbed#list()
  return range(1, tabpagenr('$'))
endfunction

function! status_symbol#tabbed#decorate(number)
  return [string(a:number)]
endfunction

function! status_symbol#tabbed#colorize(atom)
  let prefix = 'StatusSymbolTabbed'
  if has_key(a:atom, 'number')
    return prefix . (status_symbol#tabbed#center() == a:atom.number ? 'Current' : 'Hidden')
  endif
  return 'StatusSymbolTabbedNormal'
endfunction

function! status_symbol#tabbed#center()
  return tabpagenr()
endfunction

let s:layout = {}
function! status_symbol#tabbed#render(length)
  return status_symbol#ticker#render('tabbed', a:length, s:border, s:layout)
endfunction
