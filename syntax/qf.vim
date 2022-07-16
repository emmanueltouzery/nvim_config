" the containedin is to prevent conflicts with my ShortNoSpell group which
" sometimes also matches the beginning of paths
syn match qfFileName " \<[a-zA-Z\._/]\+:\d\+\>" containedin=ALL
syn match qfError ""
syn match qfWarning ""
syn match qfInfo ""
syn match qfHint ""

hi def link qfFileName Directory
hi def link qfError DiagnosticError
hi def link qfWarning DiagnosticWarn
hi def link qfInfo DiagnosticInfo
hi def link qfHint DiagnosticHint

let b:current_syntax = 'qf'
