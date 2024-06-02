; extends

; don't spell-check html color specs
(string
      (string_fragment) @name @string (#match? @string "^#[0-9a-f]{6,8}$")) @nospell

; experimental types concealing
((type_alias_declaration) @conceal (#set! conceal ""))
((type_annotation) @conceal (#set! conceal ""))
((predefined_type) @conceal (#set! conceal ""))
((type_parameters) @conceal (#set! conceal ""))
((type_identifier) @conceal (#set! conceal ""))
((type_arguments) @conceal (#set! conceal ""))
((as_expression "as" @conceal) (#set! conceal ""))
