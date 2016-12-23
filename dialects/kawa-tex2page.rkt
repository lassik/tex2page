; last change: 2016-12-14

;don't know how to make shell-magic line for 
;Kawa, so we'll assume user will do explicit
;load

(scmxlate-ignore 
  ;get-arg1 
  ;main
  )

;(scmxlate-uncall main)

(define *scheme-version* "Kawa 1.6.99")

(define *operating-system* 'unix)

(define getenv (lambda (ev) #f))

(scmxlate-uncall 
  require
  )

(define eof
  (call-with-input-string "" read))

(define file-or-directory-modify-seconds
  (lambda (f) #f))


(define ormap
  (lambda (f s)
    ;Returns true if f is true of some elt in s
    (let loop ((s s))
      (if (null? s) #f
        (or (f (car s)) (loop (cdr s)))))))

(define append!
  (lambda (s1 s2)
    ;appends s1 and s2 destructively (s1 may be modified)
    (if (null? s1) s2
      (let loop ((r1 s1))
        (if (null? r1) (error 'append! s1 s2)
          (let ((r2 (cdr r1)))
            (if (null? r2)
                (begin
                  (set-cdr! r1 s2)
                  s1)
                (loop r2))))))))

(define seconds-to-human-time
  (lambda (secs) ""))

(define current-seconds
  (lambda () 
    #f))

