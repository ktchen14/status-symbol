let s:border = get(g:, 'status_symbol_jumped_border', ['', '', '«'])
if type(s:border) != v:t_list
  let s:border = ['', '', s:border]
elseif len(s:border) == 2
  call add(s:border, '')
endif

function! status_symbol#jumped#each(i, jump)
  let regexp = '^>\?\s*\(\d\+\)\s\+\(\d\+\)\s\+\(\d\+\)\s\+\(.*\)$'

  if a:jump[0] == '>'
    call status_symbol#jumped#center(a:i)
  endif

  let result = matchlist(a:jump, regexp)

  " If the cursor position is at the head of the jump list it's possible that
  " the output of `jumps` ends in a line consisting of a single '>':
  "   jump line  col file/text
  "    31    45    0 ~/Code/status-symbol/autoload/status_symbol.vim
  "   ..............................................................
  "     1    56    0 ~/Code/status-symbol/autoload/status_symbol.vim
  " >
  " In this case we can find the line and column of the jump using getpos('.')
  " since the jump refers to the cursor position.
  if empty(result) && a:jump ==# '>'
    let cursor = getpos('.')
    return { 'line': cursor[1], 'column': cursor[2], 'file': '.' }
  endif

  let [line, column] = map(result[2:3], 'str2nr(v:val)')

  " It's impossible to determine here with 100% certainty whether the last
  " column in the output of `jumps` refers to either the filename or the text
  " at the jump location, e.g.:
  "   jump line  col file/text
  "    31    45    0 ~/Code/status-symbol/autoload/status_symbol.vim
  "   ..............................................................
  "    23    61    0 return ['·']
  " When `jumps` is run from the command line filenames and text are rendered
  " in different colors. However this information is unavailable to execute().
  "
  " Therefore to determine if a particular jump belongs to a different file we
  " see if the text at the line in question matches what is shown in the last
  " column. We guess that the jump is located in the current file if these two
  " match and we guess that it is located in a different file it not.
  "
  " Obviously this heuristic fails in certain circumstances but should produce
  " an accurate result the vast majority of the time.
  let file = stridx(getline(line), result[4]) > -1 ? '.' : result[4]
  return { 'line': line, 'column': column, 'file': file }
endfunction

function! status_symbol#jumped#list()
  let list = reverse(split(execute('jumps'), '\n')[1:])
  let s:list = map(list, function('status_symbol#jumped#each'))
  return range(len(s:list))
endfunction

function! status_symbol#jumped#subtract(l1, l2)
  return abs(a:l1 - a:l2) . (a:l1 > a:l2 ? '↑' : '↓')
endfunction

function! status_symbol#jumped#decorate(number)
  let center = status_symbol#jumped#center()
  let this = s:list[a:number]

  let output = fnamemodify(this.file, ':t') . ':' . this.line

  if a:number < center && a:number + 1 < len(s:list)
    let last = s:list[a:number + 1]
    if this.file ==# last.file
      let output = status_symbol#jumped#subtract(this.line, last.line)
    endif
  elseif a:number == center
    let output = '·'
  elseif a:number > center && a:number > 0
    let last = s:list[a:number - 1]
    if this.file ==# last.file
      let output = status_symbol#jumped#subtract(this.line, last.line)
    endif
  endif

  return [' ', output, ' ']
endfunction

function! status_symbol#jumped#colorize(atom)
  let prefix = 'StatusSymbolJumped'
  if has_key(a:atom, 'number')
    return prefix . (status_symbol#jumped#center() == a:atom.number ? 'Current' : 'Hidden')
  endif
  return 'StatusSymbolJumpedNormal'
endfunction

function! status_symbol#jumped#center(...)
  if a:0 == 0
    return get(s:, 'center', -1)
  elseif a:0 == 1
    let s:center = a:1
  else
    try
      echoerr 'Too many arguments for function: status_symbol#jumped#center'
    endtry
  endif
endfunction

let s:layout = {}
function! status_symbol#jumped#render(length)
  return status_symbol#ticker#render('jumped', a:length, s:border, s:layout)
endfunction
