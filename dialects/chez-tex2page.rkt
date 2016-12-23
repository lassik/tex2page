; last change: 2016-12-14

(scmxlate-eval
 (define *chez-name*
   (if (eqv? *dialect* 'petite)
       "petite"
       "scheme" ;or "chez"?
       )))

(scmxlate-cond

 ((eqv? *operating-system* 'unix)
  (scmxlate-insert
    "#! /usr/local/bin/"
    *chez-name*
    " --script
"
    ))

 ((eqv? *operating-system* 'windows)
  (scmxlate-insert
   (string-append
    "\":\";dosify=$(echo $0|sed -e 's,^//\\(.\\)/,\\1:/,')
\":\";echo \"(define arg-one \\\"$1\\\")(load \\\"$dosify\\\")(exit)\"|exec "
    *chez-name*
    ";exit
")))
 )

(scmxlate-cond
 ((eqv? *dialect* 'petite)
  ;(define *scheme-version* "Petite Chez Scheme")
  (define *scheme-version* (scheme-version))
  )
 ((eqv? *dialect* 'chez)
  (define *scheme-version* "Chez Scheme")))

(scmxlate-uncall
 require
 trace
 )

(scmxlate-rename
 (eof #!eof)
 (get-char t2p-get-char)
 (error petite-error))

;(define get-arg1
;  (lambda ()
;    (and (top-level-bound? 'arg-one) arg-one)))

(scmxlate-cond
 ((eqv? *operating-system* 'unix-doesnt-work)
  (define file-or-directory-modify-seconds
    (lambda (f)
      (let* ((x (process
                 (string-append "stat -c \"%Y\" " f)))
             (n (read (car x))))
        (close-input-port (car x))
        (close-output-port (cadr x))
        n))))
 (else
  (define file-or-directory-modify-seconds
    (lambda (f) #f))))

(define petite-error
  (lambda args
    (apply error #f args)))

(define read-line
  (lambda (i)
    (let ((c (peek-char i)))
      (if (eof-object? c) c
          (let loop ((r '()))
            (let ((c (read-char i)))
              (if (or (eof-object? c) (char=? c #\newline))
                  (list->string (reverse! r))
                  (loop (cons c r)))))))))

(scmxlate-include "seconds-to-date.scm")

(define call-with-input-string
  (lambda (s p)
    (let* ((i (open-input-string s))
           (v (p i)))
      (close-input-port i)
      v)))

;(define seconds-to-human-time
;  (lambda (secs)
;    ""))

(define (current-seconds)
  (time-second (current-time)))

(define set-start-time
  (lambda ()
    (let* ((dat (date-and-time))
           (mo (substring dat 4 7))
           (dy (string->number (substring dat 8 10)))
           (hr (string->number (substring dat 11 13)))
           (mi (string->number (substring dat 14 16)))
           (yr (string->number (substring dat 20 24))))
      (set! mo
        (cdr (assoc mo
                    '(("Jan" . 1) ("Feb" . 2) ("Mar" . 3) ("Apr" . 4)
                      ("May" . 5) ("Jun" . 6) ("Jul" . 7) ("Aug" . 8)
                      ("Sep" . 9) ("Oct" . 10) ("Nov" . 11) ("Dec" . 12)))))
      (tex-def-count "\\time" (+ (* 60 hr) mi) #t)
      (tex-def-count "\\day" dy #t)
      (tex-def-count "\\month" mo #t)
      (tex-def-count "\\year" yr #t))))

(scmxlate-cond
 ((eqv? *operating-system* 'windows)
  (define *ghostscript* "d:\\aladdin\\gs6.0\\bin\\gswin32c")
  ))

(scmxlate-ignore main)

(scmxlate-postamble)

(let ((pa (command-line-arguments)))
  (tex2page (car pa)))