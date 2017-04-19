" :p is guaranteed to append a directory separator to getcwd()
let s:dirsep = fnamemodify(getcwd(), ':p')[-1:]

" Map of mode() letter to name
let s:mode_to_name = {
      \ 'n': 'Normal', 'v': 'Visual', 'V': 'V-Line', '': 'V-Block',
      \ 's': 'Select', 'S': 'S-Line', '': 'S-Block', 'i': 'Insert',
      \ 'R': 'Replace', 'c': 'Command', 'r': 'Prompt', 't': 'Terminal',
      \ }

let s:modified_mark = '⁺'
let s:readonly_mark = '⁻'
let s:scroll_mark = [' ◀ ', ' ▶ ']
let s:border = '|'

let s:center = bufnr('$')
let s:near = 0
let s:margin = [{}, {}]

let g:status_symbol_rename = v:true

" Emit an atom with the specified text and highlight to the stream. Return the
" size (i.e. strwidth()) of the atom.
"
" The atom is prepended to the stream when side = 0 and appended to the stream
" when side = 1.
function! s:emit(stream, text, hilite, side = 1) abort
  let size = strwidth(a:text)
  let atom = {'text': a:text, 'size': size, 'hilite': a:hilite}
  call insert(a:stream, atom, a:side * len(a:stream))
  return size
endfunction

" Return the name of the buffer with the specified number
function! s:name(number)
  if getbufvar(a:number, '&buftype') ==# 'quickfix'
    return '[Quickfix List]'
  endif
  if getbufvar(a:number, '&buftype') ==# 'help'
    return '[Help]'
  endif
  let text = strtrans(getbufvar(a:number, 'status_symbol_name', ''))
  if empty(text)
    return '[No Name]'
  endif
  return text
endfunction

" Return v:true if a mark should be shown when the buffer number belongs to a
" modified buffer (this function is only called when the buffer is &modified).
function! s:mark_modified(number)
  return index(['nofile', 'acwrite'], getbufvar(a:number, '&buftype')) == -1
endfunction

" Return v:true if a mark should be shown when the buffer number belongs to a
" readonly buffer (this function is only called when the buffer is &readonly).
function! s:mark_readonly(number)
  return getbufvar(a:number, '&buftype') !=# 'help'
endfunction

" Emit each atom to render the numbered buffer to the stream. Return the size
" of the entire emission.
"
" The buffer will be prepended to the stream when side = 0 and appended to the
" stream when side = 1.
function! s:emit_buffer(stream, number, side = 1) abort
  if !buflisted(a:number) && a:number != bufnr() | return 0 | endif

  let [stream, size] = [[], 0]

  if a:number == bufnr()
    let hilite = 'ActiveBuffer'
  elseif bufwinnr(a:number) > 0
    let hilite = 'NormalBuffer'
  else
    let hilite = 'HiddenBuffer'
  endif

  let size += s:emit(stream, ' ', hilite)
  let size += s:emit(stream, s:name(a:number), hilite)

  " Emit a mark if the buffer is readonly or modified. If the buffer is both
  " readonly and modified, then show the modified mark but highlight it like a
  " readonly mark.
  let modified = getbufvar(a:number, '&modified') && s:mark_modified(a:number)
  let readonly = getbufvar(a:number, '&readonly') && s:mark_readonly(a:number)
  if modified && readonly
    let size += s:emit(stream, s:modified_mark, hilite . 'ReadonlyMark')
  elseif modified
    let size += s:emit(stream, s:modified_mark, hilite . 'ModifiedMark')
  elseif readonly
    let size += s:emit(stream, s:readonly_mark, hilite . 'ReadonlyMark')
  endif

  let size += s:emit(stream, ' ', hilite)

  " Record the buffer number in each atom
  call foreach(stream, 'let v:val.number = a:number')

  if !empty(a:stream)
    let size += s:emit([stream, a:stream][a:side], s:border, 'Border')
  endif
  call extend(a:stream, stream, a:side * len(a:stream))

  return size
endfunction

" Truncate stream from the specified side to reduce its size by the specified
" amount.
function! s:truncate(stream, amount, side) abort
  let amount = a:amount

  " Remove each atom that's larger than the amount
  while a:stream[-a:side].size <= amount
    let amount -= remove(a:stream, -a:side).size
  endwhile

  " No builtin function exists in Vim to reduce a string by a specific number
  " of display cells. To simulate this, we'll remove characters from the atom
  " until its size (i.e. strwidth()) has been reduced by the correct amount.
  "
  " Each character occupies 0 (e.g. a combining character), 1, or 2 (i.e. an
  " East Asian fullwidth character) display cells. As no character's size
  " exceeds 2, to ensure that we don't remove more characters than needed, on
  " each iteration we'll remove a number of characters (and their subsequent
  " combining characters) equal to half the number of display cells we intend
  " to remove.
  let atom = a:stream[-a:side]
  while amount > 0
    let half = max([amount / 2, 1])

    let length = strchars(atom.text, v:true) - half
    let text = strcharpart(atom.text, !a:side * half, length, v:true)
    let size = strwidth(text)
    let amount -= atom.size - size

    let [atom.text, atom.size] = [text, size]
  endwhile

  " If we have to remove a wide character when amount = 1, the result will be
  " 1 display cell too short. If this case, pad the atom's text.
  if amount < 0
    let size = atom.size - amount
    let text = printf("%*S", (!a:side - a:side) * size, atom.text)
    let [atom.text, atom.size] = [text, strwidth(text)]
  endif
endfunction

function! s:rename() abort
  let [roster, origin] = [{}, {}]

  for buffer in filter(getbufinfo({'buflisted': 1}), '!empty(v:val.name)')
    " Record the canonicalized path of the buffer relative to ~ or .
    let name = fnamemodify(buffer.name, ':p:~:.')
    let origin[buffer.bufnr] = name

    " Set name to be the last component of path. A trailing directory
    " seperator is not considered to be its own component and is kept in the
    " name, i.e.:
    "   /a/b/ => b/
    " Making this different from basename() and fnamemodify(..., ':t')
    let name = name[strridx(name, s:dirsep, strlen(name) - 2) + 1:]
    call setbufvar(buffer.bufnr, 'status_symbol_name', name)
    let roster[name] = add(get(roster, name, []), buffer.bufnr)
  endfor

  " Disambiguate files by successively adding trailing path segments
  while !empty(filter(roster, 'len(v:val) > 1'))
    let rename = keys(roster)[0]
    for number in remove(roster, rename)
      let name = origin[number]
      if name !=# rename
        let i = strridx(name, s:dirsep, strlen(name) - strlen(rename) - 2)
        let name = name[i + 1:]
        call setbufvar(number, 'status_symbol_name', name)
      endif
      let roster[name] = add(get(roster, name, []), number)
    endfor
  endwhile
endfunction

function! s:ticker(size) abort
  " Skip this altogether if we don't have enough room to even scroll
  if a:size < strwidth(s:scroll_mark[0]) + strwidth(s:scroll_mark[1])
    return ''
  endif

  " Rename each buffer if we must
  if g:status_symbol_rename
    let g:status_symbol_rename = s:rename()
  endif

  " We'll let 0 represent the left side and 1 represent the right side. This
  " allows us to convert from one side to the other using !. According to the
  " vim documentation:
  "   For '!' |TRUE| becomes |FALSE|, |FALSE| becomes |TRUE| (one).
  " So this behavior appears to be guaranteed.
  "
  " In addition this simplifies most of the shortening operations. To remove
  " an atom from either side:
  "   L: remove(list,  0) -> remove(list, -side)
  "   R: remove(list, -1) -> remove(list, -side)
  "
  " The operation to remove a character from either side:
  "   L: strcharpart(text, 1, strchars(atom.text) - 1)
  "   R: strcharpart(text, 0, strchars(atom.text) - 1)
  " Can be simplified to:
  "   strcharpart(text, !side, strchars(atom.text) - 1)
  "
  " And to associate -1 to the left side and +1 to the right side we can do:
  "   side - !side

  " Decide the side to be aligned. To feel natural, choose the side opposite
  " the approach side.
  let center = bufnr()
  let near = center < s:center ? 0 : center > s:center ? 1 : s:near
  call extend(s:, { 'center': center, 'near': near })

  " Calculate the margin. Reuse the buffer's margin from the last invocation,
  " but capped to be no less than some absolute margin.
  let margin = max([a:size / 5, get(s:margin[near], center, 0)])

  let stream = []
  let size = [0, 0, s:emit_buffer(stream, center)]

  " Create a list of buffers to render for each side around the active buffer
  " (the left side is reversed).
  let IsListed = {_, i -> buflisted(i) || i == center}
  let roster = [filter(reverse(range(1, center - 1)), IsListed),
        \ filter(range(center + 1, bufnr('$')), IsListed)]

  " Render the !near side until the stream will have to be truncated
  while size[!near] + size[2] < a:size && !empty(roster[!near])
    let size[!near] += s:emit_buffer(stream, remove(roster[!near], 0), !near)
  endwhile

  " Then, render the near side until the stream's size exceeds the threshold
  " by margin
  while size[0] + size[1] + size[2] < a:size + margin && !empty(roster[near])
    let size[near] += s:emit_buffer(stream, remove(roster[near], 0), near)
  endwhile

  " Truncate the stream on the near side to no less than the margin. Then, if
  " we have to remove more, take it from the !near side.
  let excess = max([size[0] + size[1] + size[2] - a:size, 0])
  let near_excess = min([excess, max([size[near] - margin, 0])])
  call s:truncate(stream, near_excess, near)
  call s:truncate(stream, excess - near_excess, !near)

  " Emit a scroll mark on each side with excess buffers or text
  let truncate = insert([excess - near_excess], near_excess, near)
  for side in filter([0, 1], '!empty(roster[v:val]) || truncate[v:val]')
    call s:truncate(stream, strwidth(s:scroll_mark[side]), side)
    call s:emit(stream, s:scroll_mark[side], 'ScrollMark', side)
  endfor

  " Record the closest occurrence of each buffer, on each side, in the stream
  let s:margin = [{}, {}]
  let left = 0
  for atom in stream
    if has_key(atom, 'number')
      let s:margin[1][atom.number] = a:size - left - atom.size
      if !has_key(s:margin[0], atom.number)
        let s:margin[0][atom.number] = left
      endif
    endif
    let left += atom.size
  endfor

"   let margin = 0
"   for number in filter(range(1, bufnr('$')), 'bufexists(v:val)')
"     let margin = get(s:margin[0], number, margin)
"     let s:margin[0][number] = margin
"   endfor

"   let margin = 0
"   for number in filter(reverse(range(1, bufnr('$'))), 'bufexists(v:val)')
"     let margin = get(s:margin[1], number, margin)
"     let s:margin[1][number] = margin
"   endfor

  let output = ''
  for atom in stream
    let output .= '%#StatusSymbol' . atom.hilite . '#' . atom.text
  endfor
  return output
endfunction

function! status_symbol#render(size)
  let name = get(s:mode_to_name, mode(), 'Normal')
  let text = ' ' . toupper(name) . ' '
  let prefix = '%#StatusSymbolMode' . name . '#' . text
  let size = strwidth(text)

  let show = g:status_symbol_showtabline
  if show == 0 || show == 1 && tabpagenr('$') < 2
    let suffix = ''
  else
    let suffix = '%='
    for i in range(1, tabpagenr('$'))
      let hilite = (i == tabpagenr() ? 'Active' : 'Normal') . 'Page'
      let text = ' ' . i . ' '
      let suffix .= '%#StatusSymbol' . hilite . '#%' . i . 'T' . text . '%T'
      let size += strwidth(text)
    endfor
  endif

  let result = [prefix, s:ticker(a:size - size), suffix]
  return join(result, '%*')
endfunction
