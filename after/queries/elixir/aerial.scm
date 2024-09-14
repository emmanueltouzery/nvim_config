; extends

(do_block
  (call
    target: (identifier) @identifier @name
    (#any-of? @identifier "query" "mutation" "subscription")) @symbol
  (#set! "kind" "Function")) @symbol
