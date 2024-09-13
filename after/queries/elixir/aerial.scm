; extends

(do_block
  (call
    target: (identifier) @identifier @name
    (#eq? @identifier "query")) @symbol
  (#set! "kind" "Function")) @symbol

(do_block
  (call
    target: (identifier) @identifier @name
    (#eq? @identifier "mutation")) @symbol
  (#set! "kind" "Function")) @symbol

(do_block
  (call
    target: (identifier) @identifier @name
    (#eq? @identifier "subscription")) @symbol
  (#set! "kind" "Function")) @symbol
