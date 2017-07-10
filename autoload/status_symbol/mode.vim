let s:mode_dict = { 'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', '': 'V-BLOCK', 'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', '': 'S-BLOCK', 't': 'TERMINAL' }

function! status_symbol#mode#render()
  let output = ' ' . get(s:mode_dict, mode(), '      ') . ' '
  let length = strwidth(output)

  if mode() ==# 'n'
    let hilite = 'Normal'
  elseif mode() ==# 'i'
    let hilite = 'Insert'
  elseif mode() ==# 'R'
    let hilite = 'Replace'
  elseif index(['v', 'V', ''], mode()) != -1
    let hilite = 'Visual'
  elseif index(['s', 'S', ''], mode()) != -1
    let hilite = 'Select'
  else
    let hilite = 'Normal'
  endif

  let output = '%#StatusSymbolMode' . hilite . '#' . output
  return [output, length]
endfunction
