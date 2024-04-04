; extends

; don't spell-check git SHAs in my config
(field value:
       (string content: (string_content) @_str (#match? @_str "^[0-9a-f]{7,40}$"))
       @nospell)
