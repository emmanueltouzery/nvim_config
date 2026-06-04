if exists("b:current_syntax")
    finish
endif

syn spell toplevel

syn match FirstLineGroup /\%1l.*/ contains=@Spell containedin=ShortNoSpell
hi def link FirstLineGroup @label

syn match GitCommitComment '^#.*' contains=BranchPrefix,GitCommitDiffPrefix
hi def link GitCommitComment Comment

syn match BranchPrefix '^# branch: ' contained nextgroup=BranchName
hi def link BranchPrefix Comment

syn match BranchName '\S\+' contained
hi def link BranchName @label

" syn match GitCommitDiffPrefix '^# \ze\S\+\s\+[|]' contained nextgroup=GitCommitFile
syn match GitCommitDiffPrefix '^# \ze.*|' contained nextgroup=GitCommitFile
hi def link GitCommitDiffPrefix Comment

syn match GitCommitFile '\s\+\S\+' contained nextgroup=GitCommitDiffStats
hi def link GitCommitFile @module

syn match GitCommitDiffStats ' |\zs.*' contained
hi def link GitCommitDiffStats @attribute

" syn match BranchName '^# branch: \zs\S\+'
" hi def link BranchName @label

let b:current_syntax = 'mygitcommit'
