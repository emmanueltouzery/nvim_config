; extends

; don't spell-check html color specs
(string
      (string_content) @name @string (#match? @string "^#[0-9a-f]{6,8}$")) @nospell
