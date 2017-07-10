let s:border = get(g:, 'status_symbol_edited_border', ['', '', '«'])
if type(s:border) != v:t_list
  let s:border = ['', '', s:border]
elseif len(s:border) == 2
  call add(s:border, '')
endif

function! status_symbol#edited#each(i, edit)
  let regexp = '^>\?\s*\(\d\+\)\s\+\(\d\+\)\s\+\(\d\+\)\s\+\(.*\)$'

  if a:edit[0] == '>'
    call status_symbol#edited#center(a:i)
  endif

  let result = matchlist(a:edit, regexp)

  " If the cursor position is at the head of the change list it's possible that
  " the output of `changes` ends in a line consisting of a single '>':
  "   jump line  col file/text
  "    31    45    0 ~/Code/status-symbol/autoload/status_symbol.vim
  "   ..............................................................
  "     1    56    0 ~/Code/status-symbol/autoload/status_symbol.vim
  " >
  " In this case we can find the line and column of the jump using getpos('.')
  " since the jump refers to the cursor position.
  if empty(result) && a:edit ==# '>'
    let cursor = getpos('.')
    return { 'line': cursor[1], 'column': cursor[2] }
  endif

  let [line, column] = map(result[2:3], 'str2nr(v:val)')

  return { 'line': line, 'column': column }
endfunction

function! status_symbol#edited#list()
  let list = reverse(split(execute('changes'), '\n')[1:])
  let s:list = map(list, function('status_symbol#edited#each'))
  return range(len(s:list))
endfunction

function! status_symbol#edited#subtract(l1, l2)
  return abs(a:l1 - a:l2) . (a:l1 > a:l2 ? '↑' : '↓')
endfunction

function! status_symbol#edited#decorate(number)
  let center = status_symbol#edited#center()
  let this = s:list[a:number]

  let output = this.line

  if a:number < center && a:number + 1 < len(s:list)
    let last = s:list[a:number + 1]
    let output = status_symbol#edited#subtract(this.line, last.line)
  elseif a:number == center
    let output = '·'
  elseif a:number > center && a:number > 0
    let last = s:list[a:number - 1]
    let output = status_symbol#edited#subtract(this.line, last.line)
  endif

  return [' ', output, ' ']
endfunction

function! status_symbol#edited#colorize(atom)
  let prefix = 'StatusSymbolJumped'
  if has_key(a:atom, 'number')
    return prefix . (status_symbol#edited#center() == a:atom.number ? 'Current' : 'Hidden')
  endif
  return 'StatusSymbolJumpedNormal'
endfunction

function! status_symbol#edited#center(...)
  if a:0 == 0
    return get(s:, 'center', -1)
  elseif a:0 == 1
    let s:center = a:1
  else
    try
      echoerr 'Too many arguments for function: status_symbol#edited#center'
    endtry
  endif
endfunction

let s:layout = {}
function! status_symbol#edited#render(length)
  return status_symbol#ticker#render('edited', a:length, s:border, s:layout)
endfunction
