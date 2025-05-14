" dadbod sql output
" assume JSON when i see quoted stuff

" afraid of false positives for the {} (and then complications.. after a
" number, after null, after a string...)
" the problem is that we don't have only JSON but also SQL output

if exists("b:current_syntax")
    finish
endif
syn match JsonKey '"\w\+"\ze:' nextgroup=JsonColon
hi def link JsonKey @property.json

" a little more complicated to handle skipping \" within the string
" syn region start/end/skip is not ok because i want to differentiate json
" string and property
syn match JsonString '"\(\\"\|[^"]\)\+"\ze[^:]' nextgroup=JsonComma
hi def link JsonString @string.json

syn match JsonColon ':' contained
hi def link JsonColon @punctuation.delimiter.json

syn match JsonComma ',' contained
hi def link JsonComma @punctuation.delimiter.json

" ideally should have \zs after the first \W but somehow it breaks the regex.
" no issue, normally it's a space before the string anyway.
syn match JsonNull /\v\Wnull\ze\W/
hi def link JsonNull @constant.builtin.json

syn match JsonBoolean /\v\W(true|false)\ze\W/
hi def link JsonBoolean @boolean.json

let b:current_syntax = 'dbout'
