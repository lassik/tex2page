; last change: 2016-12-17

(scmxlate-cond
  ((eqv? *operating-system* 'unix)
   (scmxlate-insert
     "\":\";exec gosh -- $0 \"$@\"\n")))

(define *scheme-version* 
  (string-append "Gauche " (gauche-version)))

(scmxlate-ignore
  with-output-to-port
  call-with-input-string
  )

(scmxlate-uncall
  require
  )

(scmxlate-rename
  (seconds->date sys-localtime)
  (load disable-load-for-tex2page)
  )

(scmxlate-rename-define
  (*january-number* 0)
  (*anno-domini-at-0* 1900)
  (strftime-like sys-strftime) 
  (nreverse reverse!)
  (nconc append!)
  )

(define (disable-load-for-tex2page f) #f)

(define file-or-directory-modify-seconds
  (lambda (f)
    (sys-stat->mtime (sys-stat f))))

(define date-day (lambda (tm) (slot-ref tm 'mday)))
(define date-hour (lambda (tm) (slot-ref tm 'hour)))
(define date-minute (lambda (tm) (slot-ref tm 'min)))
(define date-month (lambda (tm) (slot-ref tm 'mon)))
(define date-year (lambda (tm) (slot-ref tm 'year)))

(define eof (with-input-from-string "" read-char))

(define andmap
  (lambda (f s)
    (let loop ((s s))
      (if (null? s) #t
          (and (f (car s)) (loop (cdr s)))))))

(define ormap
  (lambda (f s)
    ;Returns true if f is true of some elt in s
    (let loop ((s s))
      (if (null? s) #f
        (or (f (car s)) (loop (cdr s)))))))

(define-macro fluid-let
  (lambda (xvxv . ee)
    (let ((xx (map car xvxv))
          (vv (map cadr xvxv))
          (old-xx (map (lambda (xv)
                         (string->symbol
                          (string-append "%__"
                                         (symbol->string (car xv))))) xvxv))
          (res '%_*_res))
      `(let ,(map (lambda (old-x x) `(,old-x ,x)) old-xx xx)
         ,@(map (lambda (x v)
                  `(set! ,x ,v)) xx vv)
         (let ((,res (begin ,@ee)))
           ,@(map (lambda (x old-x) `(set! ,x ,old-x)) xx old-xx)
           ,res)))))

(define eval1
  (lambda (e)
    (eval e (interaction-environment))))

(define main
  (lambda (args)
    (tex2page
      (and (>= (length args) 2)
           (list-ref args 1)))))