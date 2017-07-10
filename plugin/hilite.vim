" GUI color definitions
let s:gui00 = "2b303b"
let s:gui01 = "343d46"
let s:gui02 = "4f5b66"
let s:gui03 = "65737e"
let s:gui04 = "a7adba"
let s:gui05 = "c0c5ce"
let s:gui06 = "dfe1e8"
let s:gui07 = "eff1f5"
let s:gui08 = "bf616a"
let s:gui09 = "d08770"
let s:gui0A = "ebcb8b"
let s:gui0B = "a3be8c"
let s:gui0C = "96b5b4"
let s:gui0D = "8fa1b3"
let s:gui0E = "b48ead"
let s:gui0F = "ab7967"

" Terminal color definitions
let s:cterm00 = "00"
let s:cterm03 = "08"
let s:cterm05 = "07"
let s:cterm07 = "15"
let s:cterm08 = "01"
let s:cterm0A = "03"
let s:cterm0B = "02"
let s:cterm0C = "06"
let s:cterm0D = "04"
let s:cterm0E = "05"
if exists('base16colorspace') && base16colorspace == "256"
  let s:cterm01 = "18"
  let s:cterm02 = "19"
  let s:cterm04 = "20"
  let s:cterm06 = "21"
  let s:cterm09 = "16"
  let s:cterm0F = "17"
else
  let s:cterm01 = "10"
  let s:cterm02 = "11"
  let s:cterm04 = "12"
  let s:cterm06 = "13"
  let s:cterm09 = "09"
  let s:cterm0F = "14"
endif

function <SID>hi(group, fg, bg, attr)
  if !empty(a:fg)
    let fg = printf('%02X', a:fg)
    exec 'hi ' . a:group . ' guifg=#' . s:gui{fg} . ' ctermfg=' . s:cterm{fg}
  endif
  if !empty(a:bg)
    let bg = printf('%02X', a:bg)
    exec 'hi ' . a:group . ' guibg=#' . s:gui{bg} . ' ctermbg=' . s:cterm{bg}
  endif
  if !empty(a:attr)
    exec 'hi ' . a:group . ' gui=' . a:attr . ' cterm=' . a:attr
  endif
endfun

call <SID>hi('StatusSymbolBuffedCurrent',             0x0C, 0x02, '')
call <SID>hi('StatusSymbolBuffedCurrentModifiedMark', 0x0B, 0x02, '')
call <SID>hi('StatusSymbolBuffedCurrentReadonlyMark', 0x09, 0x02, '')
call <SID>hi('StatusSymbolBuffedActive',              0x03, 0x01, '')
call <SID>hi('StatusSymbolBuffedActiveModifiedMark',  0x0B, 0x01, '')
call <SID>hi('StatusSymbolBuffedActiveReadonlyMark',  0x03, 0x01, '')
call <SID>hi('StatusSymbolBuffedHidden',              0x02, 0x01, '')
call <SID>hi('StatusSymbolBuffedHiddenModifiedMark',  0x0B, 0x01, '')
call <SID>hi('StatusSymbolBuffedHiddenReadonlyMark',  0x02, 0x01, '')
call <SID>hi('StatusSymbolBuffedNormal',              0x02, 0x01, '')

call <SID>hi('StatusSymbolTabbedCurrent',             0x0A, 0x03, '')
call <SID>hi('StatusSymbolTabbedHidden',              0x01, 0x03, '')
call <SID>hi('StatusSymbolTabbedNormal',              0x01, 0x03, '')

call <SID>hi('StatusSymbolArguedCurrent', 0x0B, 0x02, '')
call <SID>hi('StatusSymbolArguedHidden', 0x03, 0x01, '')
call <SID>hi('StatusSymbolArguedNormal', 0x02, 0x01, '')

call <SID>hi('StatusSymbolJumpedCurrent', 0x0B, 0x02, '')
call <SID>hi('StatusSymbolJumpedHidden', 0x03, 0x01, '')
call <SID>hi('StatusSymbolJumpedNormal', 0x02, 0x01, '')

call <SID>hi('StatusSymbolEditedCurrent', 0x0B, 0x02, '')
call <SID>hi('StatusSymbolEditedHidden', 0x03, 0x01, '')
call <SID>hi('StatusSymbolEditedNormal', 0x02, 0x01, '')

call <SID>hi('StatusSymbolModeNormal', 0x01, 0x0D, '')
call <SID>hi('StatusSymbolModeInsert', 0x01, 0x0B, '')
call <SID>hi('StatusSymbolModeReplace', 0x01, 0x09, '')
call <SID>hi('StatusSymbolModeVisual', 0x01, 0x0E, '')
call <SID>hi('StatusSymbolModeSelect', 0x01, 0x0A, '')
call <SID>hi('StatusSymbolModeTerminal', 0x01, 0x0C, '')

call <SID>hi('StatusSymbolBufferHead', 0x04, 0x02, '')
call <SID>hi('StatusSymbolBufferTail', 0x0B, 0x02, '')

delfunction <SID>hi
unlet s:gui00 s:gui01 s:gui02 s:gui03 s:gui04 s:gui05 s:gui06 s:gui07 s:gui08 s:gui09 s:gui0A s:gui0B s:gui0C s:gui0D s:gui0E s:gui0F
unlet s:cterm00 s:cterm01 s:cterm02 s:cterm03 s:cterm04 s:cterm05 s:cterm06 s:cterm07 s:cterm08 s:cterm09 s:cterm0A s:cterm0B s:cterm0C s:cterm0D s:cterm0E s:cterm0F
