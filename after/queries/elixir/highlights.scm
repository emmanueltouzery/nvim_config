; extends

(sigil
  "~" @string.special
  (sigil_name) @string.special @_sigil_name
  quoted_start: _ @string.special
  (quoted_content) @number
  quoted_end: _ @string.special
  ((sigil_modifiers) @string.special)?
  (#any-of? @_sigil_name "u" "U"))

(sigil
  "~" @string.special
  (sigil_name) @string.special @_sigil_name
  quoted_start: _ @string.special
  (quoted_content) @string
  quoted_end: _ @string.special
  ((sigil_modifiers) @string.special)?
  (#any-of? @_sigil_name "d" "D"))
