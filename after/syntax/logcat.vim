" logcat with threadtime

if exists("b:current_syntax")
    finish
endif
" Define colors
hi def LogF_color ctermfg=white guifg=white ctermbg=red guibg=red gui=bold cterm=bold
hi def LogE_color ctermfg=red guifg=red gui=bold cterm=bold
hi def LogW_color ctermfg=brown guifg=brown gui=bold cterm=bold
hi def LogI_color ctermfg=darkgreen guifg=darkgreen gui=bold cterm=bold
hi def LogD_color ctermfg=blue guifg=blue gui=bold cterm=bold
hi def LogV_color ctermfg=gray guifg=gray gui=bold cterm=bold
syn match LogF '\sF\s' nextgroup=Module
syn match LogE '\sE\s' nextgroup=Module
syn match LogW '\sW\s' nextgroup=Module
syn match LogI '\sI\s' nextgroup=Module
syn match LogD '\sD\s' nextgroup=Module
syn match LogV '\sV\s' nextgroup=Module
syn match Module '\zs\(\(\w\|\.\)\+\)\ze:' contained
syn match Date '\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d'


hi def link LogF RedrawDebugRecompose
hi def link LogE Error
hi def link LogW WarningMsg
hi def link LogI NotifInfo
hi def link LogD Debug
hi def link LogV @comment
hi def link Module @keyword
hi def link Date @comment

let b:current_syntax = 'logcat'
