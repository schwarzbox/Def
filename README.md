# Def

Programming language from LISP/Scheme family.

v0.49


Example

``` scheme
(def n 22)

(def (fibonachi n)
 (if (< n 2)
  (-> n)
  (-> (+ (fibonachi (- n 1)) (fibonachi (- n 2))))
 )
)

(def t (clock))

(show 'Fibonacci' n '|' (fibonachi n) '|' (- (clock) t))
```

Def is written in Lua.

``` scheme
; check predefined functions
(show (predef))

```
