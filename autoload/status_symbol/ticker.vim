let s:scroll_mark = get(g:, 'status_symbol_scroll_mark', ['◀', '▶'])
if type(s:scroll_mark) != v:t_list
  let s:scroll_mark = [s:scroll_mark, s:scroll_mark]
endif

function! status_symbol#ticker#atom_size(atom)
  " if type(a:atom) == v:t_dict
  "   if !has_key(a:atom, 'size')
  "     let a:atom.size = strwidth(a:atom.text)
  "   endif
  "   return a:atom.size
  " endif
  " return strwidth(string(a:atom))
  let a:atom.width = strwidth(a:atom.text)
  return a:atom.width
endfunction

function! status_symbol#ticker#scroll(atom_list, on, length, margin, layout)
  " If only one margin was given then use it for both sides
  let margin = type(a:margin) == v:t_list ? a:margin : [a:margin, a:margin]

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
  " To associate +1 to the left side and -1 to the right side we can do:
  "   !side - side
  "
  " In cases where we need to represent a center we'll use 2 to preserve this
  " symmetry between left and right.

  " Designate one side as the near side to be aligned against the margin (the
  " near side isn't necessarily the shorter side). Scrolling feels most
  " natural when we use the side opposite the one we're approaching from,
  " defaulting to the left.
  let near = a:on <= get(a:layout, 'center', a:on) ? 0 : 1

  " Get the lengths of the left, right, and center sections
  let length_of = [0, 0, 0]
  " This needs to be set to 0 so that if the first atom doesn't have a number
  " it is associated with the left
  let side = 0
  for atom in a:atom_list
    let size = status_symbol#ticker#atom_size(atom)
    " Inherit the previous side for atoms without a number
    if has_key(atom, 'number')
      let side = atom.number < a:on ? 0 :
               \ atom.number > a:on ? 1 :
               \ 2
    elseif side == 2
      " But if it immediately follows the center atom count it with the right
      let side = 1
    endif
    let length_of[side] += size
  endfor

  let excess = a:length - length_of[2]

  " margin and safety are the respective lengths to leave on each side (near
  " and not near)
  let [margin, safety] = map(copy(margin), 'excess * v:val / 100')
  if has_key(a:layout, a:on)
    let margin = max([a:layout[a:on][near], margin])
    if excess - margin < safety
      let [near, margin] = [!near, safety]
    endif
  endif

  let cursor = { 'atom': [0, 0], 'trim': [0, 0] }

  while length_of[0] + length_of[1] > excess
    " To get the proper alignment we need to reduce the near side while the
    " margin condition is in effect:
    "   length_of[near] > margin
    " Then we need to reduce the atom_list so long as the length condition is
    " in effect
    "   length_of[0] + length_of[1] > excess
    " However if the length requirement has been met at any time (even while
    " the margin condition still holds) we need to stop.
    "
    " Simply put: we need to reduce the atom_list while the length of both
    " sides exceeds the available excess. To choose which side to reduce from
    " we use the near side if its length exceeds the margin, otherwise we use
    " the !near side.
    if length_of[near] <= margin
      let [side, threshold] = [!near, length_of[0] + length_of[1] - excess]
    else
      let [side, threshold] = [near, length_of[near] - margin]
    endif

    " let atom = a:atom_list[cursor.atom[side] * (!side - side)]
    if status_symbol#ticker#atom_size(a:atom_list[-side]) <= threshold
      let length_of[side] -= status_symbol#ticker#atom_size(remove(a:atom_list, -side))
      let cursor.atom[side] += 1
    else
      let atom = a:atom_list[-side]
      let atom.text = strcharpart(atom.text, 1 - side, strchars(atom.text) - 1)
      " Invalidate atom size if necessary
      let length_of[side] -= 1
      let cursor.trim[side] += 1
    endif
  endwhile

  " Since a:layout can't be reassigned clear it out and repopulate it with the
  " layout information from this iteration
  call filter(a:layout, 'v:false')
  let a:layout.length = length_of[0] + length_of[2] + length_of[1]
  let left = 0
  for atom in a:atom_list
    if has_key(atom, 'number') && !has_key(a:layout, atom.number)
      if exists('molecule_number') && exists('molecule_length')
        let a:layout[molecule_number] = [a:layout[molecule_number],
              \ a:layout.length - a:layout[molecule_number] - molecule_length]
      endif
      let molecule_number = atom.number
      let molecule_length = status_symbol#ticker#atom_size(atom)
      let a:layout[atom.number] = left
    elseif has_key(atom, 'number')
      let molecule_length += status_symbol#ticker#atom_size(atom)
    endif

    let left += status_symbol#ticker#atom_size(atom)
  endfor
  if exists('molecule_number') && exists('molecule_length')
    let a:layout[molecule_number] = [a:layout[molecule_number],
          \ a:layout.length - a:layout[molecule_number] - molecule_length]
  endif
  let a:layout.center = a:on

  if cursor.atom[0] > 0 || cursor.trim[0] > 0
    let a:atom_list[0].text = substitute(a:atom_list[0].text, '^.', s:scroll_mark[0], '')
  endif

  if cursor.atom[1] > 0 || cursor.trim[1] > 0
    let a:atom_list[-1].text = substitute(a:atom_list[-1].text, '.$', s:scroll_mark[1], '')
  endif

  return a:layout.length
endfunction

function! status_symbol#ticker#render(domain, length, border, layout)
  let molecule_list = []

  if !empty(a:border[0])
    call add(molecule_list, a:border[0])
  endif

  let number_list = status_symbol#{a:domain}#list()
  for i in range(len(number_list))
    let molecule = { 'number': number_list[i] }
    let molecule.atom_list = status_symbol#{a:domain}#decorate(molecule.number)
    if !empty(a:border[2]) && i > 0
      call add(molecule_list, a:border[2])
    endif
    call add(molecule_list, extend(molecule, { 'i': i }))
  endfor

  if !empty(a:border[1])
    call add(molecule_list, a:border[1])
  endif

  call filter(molecule_list, '!empty(v:val)')

  let atom_list = []
  for molecule in molecule_list
    if type(molecule) == v:t_dict
      if has_key(molecule, 'atom_list')
        for atom in molecule.atom_list
          let mole = copy(molecule)
          unlet mole.atom_list
          if type(atom) == v:t_dict
            call add(atom_list, extend(mole, atom))
          else
            call add(atom_list, extend(mole, { 'text': atom }))
          endif
        endfor
      else
        call add(atom_list, molecule)
      endif
    else
      call add(atom_list, { 'text': molecule })
    endif
  endfor

  let on = status_symbol#{a:domain}#center()
  let length = status_symbol#ticker#scroll(atom_list, on, a:length, 20, a:layout)

  " Get the 'normal' highlight group by calling colorize() on an empty dict
  let normal = status_symbol#{a:domain}#colorize({})

  " According to the vim documentation for statusline and tabline when using
  " '%' items:
  "   Up to 80 items can be specified.  *E541*
  " Do our best to avoid this by not outputting consecutive %#...#s with the
  " same highlight group.
  let output = '%#' . normal . '#'
  let hilite_last = normal
  for atom in atom_list
    let hilite = status_symbol#{a:domain}#colorize(atom)
    if !empty(hilite) && hilite !=# hilite_last
      let hilite_last = hilite
      let output .= '%#' . hilite . '#'
    endif
    let output .= atom.text
  endfor

  return [output . '%#' . normal . '#', a:layout.length]
endfunction
