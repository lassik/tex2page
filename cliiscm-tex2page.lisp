;last modified 2022-12-15

(cliiscm-insert
  "\":\";exec racket -f $0 -- \"$@\"
  ")

(require mzlib/process)
;(require mzlib/trace)
(require racket/private/more-scheme)

(cliiscm-uncall

  defpackage
  in-package
  tex2page
  trace

  )

(define *operating-system*
  ;change if you need a better OS identifier
  (if (getenv "COMSPEC")
      (let ((term (getenv "TERM")))
        (if (and (string? term) (string=? term "cygwin"))
            ':cygwin ':windows))
      ':unix))

(define *scheme-version*
  (string-append "Racket " (version) " " (symbol->string *operating-system*)))

(define *path-separator*
  (if (eqv? *operating-system* ':windows) #\; #\:))

(define *directory-separator*
  (if (eqv? *operating-system* ':windows) "\\" "/"))

(define *package* false)

(cliiscm-ignore-def

  *tex2page-file-arg*
  list->string
  string->list
  string-append
  string-length
  system

  )

(cliiscm-rename-def

  (char-whitespace-p char-whitespace?)
  (string-to-number string->number)
  (string-trim-blanks string-trim)
  (retrieve-env getenv)
  (system-with-visual system)

  )

(define eval1 eval)

(define (decode-universal-time s)
  (let ((ht (and s (seconds->date s))))
    ;s m h d mo y
    (cond (ht (list false (date-minute ht) (date-hour ht)
                    (date-day ht) (date-month ht) (date-year ht)))
          (else (list false false false
                      false false false
                      false false false)))))

(define (strftime ignore-format d)
  (let ((m (date-minute d))
        (h (date-hour d))
        (dy (date-day d))
        (mo (date-month d))
        (y (date-year d))
        (dow (date-week-day d))
        (dst (date-dst? d))
        (tzsec (date-time-zone-offset d)))
    (let ((tz (and tzsec (/ tzsec 3600))))
      (string-append
        (vector-ref *week-day-names* dow)
        ", "
        (vector-ref *short-month-names* (- mo 1))
        " "
        (number->string dy)
        ", "
        (number->string y)
        (if tz
            (string-append
              ", "
              (let ((h (modulo h 12)))
                (number->string (if (= h 0) 12 h)))
              ":"
              (if (< m 10) "0" "")
              (number->string m)
              " "
              (if (<= 0 h 11) "a" "p")
              "m UTC"
              (if (> tz 0) "+" "−")
              (number->string (abs tz)))
            "")))))

(define (seconds-to-human-time s)
  (strftime "%a, %b %e, %Y, %l:%M %p %Z" (seconds->date s)))

(cliiscm-rename

  (*common-lisp-version* *scheme-version*)
  (nconc append)
  (nreverse reverse)
  (read-from-string string->number)
  (search substring?)
  (string-to-number string->number)
  ;(with-output-to-string cl-with-output-to-string)

  )

(cliiscm-rename

  (gethash table-get)
  (make-hash-table make-table)
  (maphash table-for-each)
  (remhash table-rem)
  (with-output-to-string cl-with-output-to-string)

  )

(cliiscm-defsetf

  (istream*-buffer set!istream*-buffer)
  (cdef*-active set!cdef*-active)
  (cdef*-argpat set!cdef*-argpat)
  (cdef*-catcodes set!cdef*-catcodes)
  (cdef*-expansion set!cdef*-expansion)
  (cdef*-optarg set!cdef*-optarg)
  (counter*-value set!counter*-value)
  (ostream*-hbuffer set!ostream*-hbuffer)
  (table-get table-put!)
  (tdef*-active set!tdef*-active)
  (tdef*-argpat set!tdef*-argpat)
  (tdef*-catcodes set!tdef*-catcodes)
  (tdef*-defer set!tdef*-defer)
  (tdef*-expansion set!tdef*-expansion)
  (tdef*-optarg set!tdef*-optarg)
  (tdef*-prim set!tdef*-prim)
  (tdef*-thunk set!tdef*-thunk)
  (texframe*-aftergroups set!texframe*-aftergroups)
  (texframe*-postludes set!texframe*-postludes)
  (texframe*-catcodes set!texframe*-catcodes)

  )

;(defstruct structname [field | (field default-value)] ...)
;
;creates
;the constructor make-structname
;the predicate structname?
;the accessors structname-field (for each field)
;the setters set!structname-field (for each field)
;
;make-structname can take {field init-value} arguments,
;in which it case it sets field to init-value.  Otherwise,
;it sets field to default-value, if such was provided in
;the defstruct call

(define list-position
  (lambda (x s)
    (let loop ((s s) (i 0))
      (cond ((null? s) false)
            ((eq? (car s) x) i)
            (else (loop (cdr s) (+ i 1)))))))

(defmacro defstruct (s . ff)
  (let ((s-s (symbol->string s)) (n (length ff)))
    (let* ((n+1 (+ n 1))
           (vv (make-vector n+1)))
      (let loop ((i 1) (ff ff))
        (if (< i n+1)
            (let ((f (car ff)))
              (vector-set! vv i (if (pair? f) (cadr f) (not 't)))
              (loop (+ i 1) (cdr ff)))
            0))
      (let* ((ff-without-colons
               (map (lambda (f)
                      (symbol->string (if (pair? f) (car f) f))) ff))
             (ff-with-colons
               (map (lambda (f)
                      (string->symbol (string-append ":" f)))
                    ff-without-colons)))
        `(begin
           (define ,(string->symbol (string-append "make-" s-s))
             (lambda fvfv
               (let ((st (make-vector ,n+1)) (ff ',ff-with-colons))
                 (vector-set! st 0 ',s)
                 ,@(let loop ((i 1) (r '()))
                     (if (>= i n+1) r
                         (loop (+ i 1)
                           (cons `(vector-set! st ,i
                                               ,(vector-ref vv i))
                                 r))))
                 (let loop ((fvfv fvfv))
                   (if (null? fvfv) 0
                       (begin
                         (vector-set! st (+ (list-position (car fvfv) ff) 1)
                                      (cadr fvfv))
                         (loop (cddr fvfv)))))
                 st)))
           ,@(let loop ((i 1) (procs '()))
               (if (>= i n+1) procs
                   (loop (+ i 1)
                     (let* ((f-s (list-ref ff-without-colons (- i 1))))
                       (cons
                         `(define ,(string->symbol
                                     (string-append s-s "-" f-s))
                            (lambda (x) (vector-ref x ,i)))
                         (cons
                           `(define ,(string->symbol
                                       (string-append
                                         "set!" s-s "-" f-s))
                              (lambda (x v) (vector-set! x ,i v)))
                           procs))))))
           (define ,(string->symbol (string-append s-s "?"))
             (lambda (x)
               (and (vector? x) (eq? (vector-ref x 0) ',s)))))))))

#|
(defmacro cl-with-output-to-string (ignore-wots-arg . body)
  `(with-output-to-string (lambda () ,@body)))
|#

(defmacro cl-with-output-to-string (ignore-wots-arg . body)
  (list 'with-output-to-string
        (list* 'lambda '() body)))

(defstruct table (test eqv?) (alist '()))

(define (table-get k tbl . d)
  ;(printf "tbl=~s; k=~s; (d)=~s~%" tbl k d)
  (cond ((lassoc k (table-alist tbl) (table-test tbl))
         => (lambda (c) (vector-ref (cdr c) 0)))
        ((pair? d) (car d))
        (else false)))

(define (table-rem k tbl)
  (table-put! k tbl false))

(define (table-put! k tbl v)
  (let ((al (table-alist tbl)))
    (let ((c (lassoc k al (table-test tbl))))
      (if c (vector-set! (cdr c) 0 v)
          (set!table-alist tbl (cons (cons k (vector v)) al))))))

(define (table-for-each p tbl)
  (for-each
    (lambda (c)
      (p (car c) (vector-ref (cdr c) 0)))
    (table-alist tbl)))

(define (substring? s1 s2)
  ;if s1 is a substring of s2, returns the index in
  ;s2 that s1 starts at.  O/w return false.
  ;
  (let* ((s1-len (string-length s1))
         (s2-len (string-length s2))
         (n-give-up (+ 1 (- s2-len s1-len))))
    (let loop ((i 0))
      (if (< i n-give-up)
          (let loop2 ((j 0) (k i))
            (if (< j s1-len)
                (if (char=? (string-ref s1 j) (string-ref s2 k))
                    (loop2 (+ j 1) (+ k 1))
                    (loop (+ i 1)))
                i))
          false))))

(define (lassoc k al equ?)
  ;(printf "doing lassoc k=~s; al=~s; equ?=~s~%" k al equ?)
  (let loop ((al al))
    (if (null? al) false
        (let ((c (car al)))
          (if (equ? (car c) k) c
              (loop (cdr al)))))))

(defmacro rassoc (k al . z)
  `(scheme-rassoc ,k ,al ,(if (null? z) 'eqv? (cadr z))))

(define (scheme-rassoc k al equ)
  (let loop ((al al))
    (if (null? al) false
        (let ((c (car al)))
          (if (equ (cdr c) k) c
              (loop (cdr al)))))))

(define (write-to-string n . z)
  (if (pair? z)
      (number->string (if (inexact? n) (inexact->exact n) n) 16)
      (number->string n)))

(define (number-to-roman n . upcase?)
  ;adapted from CLISP's format impl
  (set! upcase? (and (pair? upcase?) (car upcase?)))
  ;
  (unless (and (integer? n) (>= n 0))
    (terror 'number-to-roman "Missing number"))
  ;
  (let ((roman-digits
          ; decimal_value, roman_char, lower_decimal_value_used_to_modify
          '((1000 #\m 100) (500 #\d 100) (100 #\c 10) (50 #\l 10)
                           (10 #\x 1) (5 #\v 1) (1 #\i 0)))
        (approp-case (lambda (c)
                       (if upcase? (char-upcase c) c))))
    (let loop ((n n) (dd roman-digits) (s '()))
      (if (null? dd)
          (if (null? s) "0"
              (list->string (reverse s)))
          (let* ((d (car dd))
                 (val (car d))
                 (char (approp-case (cadr d)))
                 (nextval (caddr d)))
            (let loop2 ((q (quotient n val))
                        (r (remainder n val))
                        (s s))
              (if (= q 0)
                  (if (>= r (- val nextval))
                      (loop (remainder r nextval) (cdr dd)
                        (cons char
                              (cons (approp-case (cadr (assv nextval dd)))
                                    s)))
                      (loop r (cdr dd) s))
                  (loop2 (- q 1) r (cons char s)))))))))

#|
(define (nreverse s)
  (let loop ((s s) (r '()))
    (if (null? s) r
        (let ((d (cdr s)))
          (set-cdr! s r)
          (loop d s)))))

(define (nconc l1 l2)
  (cond ((null? l1) l2)
        ((null? l2) l1)
        (else (let loop ((l1 l1))
                (let ((l1.cdr (cdr l1)))
                  (cond ((null? l1.cdr) (set-cdr! l1 l2))
                        (else (loop l1.cdr))))))))
|#

(define (string-index s c)
  ;returns the leftmost index of s where c occurs
  ;
  (let ((n (string-length s)))
    (let loop ((i 0))
      (cond ((>= i n) false)
            ((char=? (string-ref s i) c) i)
            (else (loop (+ i 1)))))))

(define (string-reverse-index s c)
  ;returns the rightmost index of s where c occurs
  ;
  (let loop ((i (- (string-length s) 1)))
    (cond ((< i 0) false)
          ((char=? (string-ref s i) c) i)
          (else (loop (- i 1))))))

(define (read-6hex i)
  (let* ((x (read i))
         (htmlcolor (string-upcase
                      (cond ((symbol? x) (symbol->string x))
                            ((number? x) (number->string x))
                            (else (terror 'atom-to-6hex "Misformed argument."))))))
    (string-append "#" (case (string-length htmlcolor)
                         ((1) "00000")
                         ((2) "0000")
                         ((3) "000")
                         ((4) "00")
                         ((5) "0")
                         (else "")) htmlcolor)))

(cliiscm-postamble)

(tex2page
  (let ((args (current-command-line-arguments)))
    (and (> (vector-length args) 0) (vector-ref args 0))))

(cliiscm-postprocess
  (cliiscm-system "cp my-tex2page.lisp tex2page.rkt")
  (cliiscm-system "chmod +x tex2page.rkt")
  (cliiscm-system "ln -sf tex2page.rkt tex2page")
  (format t "tex2page has been successfully configured for Racket.~%")
  (format t "You may put it in your PATH.~%")
  )
