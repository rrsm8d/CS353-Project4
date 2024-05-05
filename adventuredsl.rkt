#lang racket
; Credit to Matthew Flat, allowing the use and modification of their domain specific language
; Link: https://queue.acm.org/detail.cfm?id=2068896
(provide define-verbs
         define-thing
         define-place
         define-everywhere
         
         show-current-place
         show-inventory
         show-help

         have-thing?
         take-thing!
         drop-thing!
         delete-thing!
         thing-state
         set-thing-state!

         inv
         
         (except-out (all-from-out racket) #%module-begin)
         (rename-out [module-begin #%module-begin]))

; +---------------------------------------------------------------------------------------------+
; Overall module:

(define-syntax module-begin
  (syntax-rules (define-verbs define-everywhere)
    [(_ (define-verbs all-verbs cmd ...)
        (define-everywhere global-actions act ...)
        decl ...
        id)
     (#%module-begin
      (define-verbs all-verbs cmd ...)
      (define-everywhere global-actions act ...)
      decl ...
      (start-game (check-type id "place")
                  all-verbs
                  global-actions))]))

; +---------------------------------------------------------------------------------------------+
; Model:

;; Elements of the world:
(struct verb (aliases ; Name
              desc ; Description
              transitive?)) ; transtivity (transitive verbs are followed up by a thing or place)

(struct thing (name ; symbol
               [state #:mutable] ; can change the state to be whatever. Like 'open
               actions)) ; usable actions that the thing can do

(struct place (desc ; Description of the place
               [things #:mutable] ; all the items present in the place
               actions)) ; usable actions while in the place. 

(define names (make-hash))
(define elements (make-hash))

(define (record-element! name val)
  (hash-set! names name val)
  (hash-set! elements val name))

(define (name->element name) (hash-ref names name #f))
(define (element->name obj) (hash-ref elements obj #f))

; +---------------------------------------------------------------------------------------------+
; Simple type layer:

(begin-for-syntax 
 (struct typed (id type) 
   #:property prop:procedure (lambda (self stx) (typed-id self))
   #:omit-define-syntaxes))

(define-syntax (check-type stx)
  (syntax-case stx ()
    [(check-type id type)
     (let ([v (and (identifier? #'id)
                   (syntax-local-value #'id (lambda () #f)))])
       (unless (and (typed? v)
                    (equal? (syntax-e #'type) (typed-type v)))
         (raise-syntax-error
          #f
          (format "not defined as ~a" (syntax-e #'type))
          #'id))
       #'id)]))

; +---------------------------------------------------------------------------------------------+
; Macros for constructing and registering elements:

(define-syntax-rule (define-verbs all-id
                      [id spec ...] ...) ; All the verbs to be defined in the world
  (begin ; Start making the verbs from all the verbs
    (define-one-verb id spec ...) ...
    (record-element! 'id id) ...
    (define all-id (list id ...))))

(define-syntax define-one-verb ; Create the variable with verb type
  (syntax-rules (= _)
    [(define-one-verb id (= alias ...) desc)
     (begin
       (define gen-id (verb (list 'id 'alias ...) desc #f))
       (define-syntax id (typed #'gen-id "intransitive verb")))]
    [(define-one-verb id _ (= alias ...) desc)
     (begin
       (define gen-id (verb (list 'id 'alias ...) desc #t))
       (define-syntax id (typed #'gen-id "transitive verb")))]
    [(define-one-verb id)
     (define-one-verb id (=) (symbol->string 'id))]
    [(define-one-verb id _)
     (define-one-verb id _ (=) (symbol->string 'id))]))

(define-syntax-rule (define-thing id  ; Create the thing/item
                      [vrb expr] ...)
  (begin
    (define gen-id 
      (thing 'id #f (list (cons (check-type vrb "transitive verb")
                                (lambda () expr)) ...)))
    (define-syntax id (typed #'gen-id "thing"))
    (record-element! 'id id)))


(define-syntax-rule (define-place id ; Create the place
                      desc
                      (thng ...)
                      ([vrb expr] ...))
  (begin
    (define gen-id
      (place desc
             (list (check-type thng "thing") ...)
             (list (cons (check-type vrb "intransitive verb")
                         (lambda () expr))
                   ...)))
    (define-syntax id (typed #'gen-id "place"))
    (record-element! 'id id)))


(define-syntax-rule (define-everywhere id ([vrb expr] ...)) ; Global actions
  (define id (list (cons (check-type vrb "intransitive verb")
                         (lambda () expr))
                   ...)))

; +---------------------------------------------------------------------------------------------+
; Game state tracker

; created on startup:
(define all-verbs null) ; list of verbs
(define global-actions null) ; list of verb--thunk pairs


(define inv null) ; list of items

(define current-place #f) ; current location


(define (have-thing? t) ; Does it exist in inventory?
  (memq t inv))

(define (take-thing! t) ; Add item to inventory
  (set-place-things! current-place (remq t (place-things current-place)))
  (set! inv (cons t inv)))

(define (drop-thing! t) ; Remove item from inventory and put in place
  (set-place-things! current-place (cons t (place-things current-place)))
  (set! inv (remq t inv)))

(define (delete-thing! t) ; Remove item from inventory and the game world. 
  (set! inv (remq t inv)))

; +---------------------------------------------------------------------------------------------+
; Game execution

; Show place and also run any addtional command
(define (do-place)
  (show-current-place)
  (do-verb))

; Print the description of the current place, and list all items in the place
(define (show-current-place)
  (printf "~a\n" (place-desc current-place))
  (for-each (lambda (thing)
              (printf "You can sense there's a ~a here.\n" (thing-name thing)))
            (place-things current-place)))

; Run a command
(define (do-verb)
  (printf "> ")
  (flush-output)
  (let* ([line (read-line)] ; Get input from user
         [input (if (eof-object? line)
                    '(quit)
                    (let ([port (open-input-string line)])
                      (for/list ([v (in-port read port)]) v)))])
    (if (and (list? input) (andmap symbol? input) (<= 1 (length input) 2))
        (let ([vrb (car input)]) ; #t
            (let ([response
                   (cond 
                    [(= 2 (length input))
                     (handle-transitive-verb vrb (cadr input))] ; Run associated command
                    [(= 1 (length input))
                     (handle-intransitive-verb vrb)])]) ; Run associated command
              (let ([result (response)])
                (cond
                 [(place? result) ; Move to next area and print its details
                  (set! current-place result)
                  (do-place)]
                 [(string? result)
                  (printf "~a\n" result)
                  (do-verb)]
                 [else (do-verb)]))))
          (begin ; #f
            (printf "Invalid command. Please check the documentation.")
            (do-verb)))))

; Handle an intransitive-verb command:
(define (handle-intransitive-verb vrb)
  (or
   (find-verb vrb (place-actions current-place))
   (find-verb vrb global-actions)
   (using-verb
    vrb all-verbs
    (lambda (verb)
      (lambda ()
        (if (verb-transitive? verb)
            (format "~a ____" (string-titlecase (verb-desc verb)))
            (format "You cannot ~a here." (verb-desc verb))))))
   (lambda ()
     (format "Invalid command: ~a." vrb))))

; Handle a transitive-verb command:
(define (handle-transitive-verb vrb obj)
  (or (using-verb
       vrb all-verbs
       (lambda (verb)
         (and
          (verb-transitive? verb)
          (cond
           [(ormap (lambda (thing)
                     (and (eq? (thing-name thing) obj)
                          thing))
                   (append (place-things current-place)
                           inv))
            => (lambda (thing)
                 (or (find-verb vrb (thing-actions thing))
                     (lambda ()
                       (format "You cannot ~a ~a."
                               (verb-desc verb) obj))))]
           [else
            (lambda ()
              (format "There's no ~a here to ~a." obj
                      (verb-desc verb)))]))))
      (lambda ()
        (format "Invalid commands: ~a ~a." vrb obj))))

; inventory command
(define (show-inventory)
  (printf "===ITEMS LIST===")
  (if (null? inv)
      (printf "\nEmpty")
      (for-each (lambda (thing)
                  (printf "\n ~a" (thing-name thing))) inv)
      )
  (printf "\n"))

; Check if the verb exists, and return it's thunk if so
(define (find-verb cmd actions)
  (ormap (lambda (a)
           (and (memq cmd (verb-aliases (car a)))
                (cdr a)))
         actions))

; Check if verb exists, and run the success-k function if so
(define (using-verb cmd verbs success-k)
  (ormap (lambda (vrb)
           (and (memq cmd (verb-aliases vrb))
                (success-k vrb)))
         verbs))

; Display the game instructions
(define (show-help)
  (printf "Enter `look` to describe and inspect the current area\n")
  (printf "Enter `inventory` to check your inventory\n")
  (printf "Enter `quit` to quit\n")
  (printf "Enter `insert ___` to insert the three cubes into the pedestal, once they are all obtained\n")
  (printf "Enter `drop ___` to drop an item in the area\n")
  (printf "Enter `get ___` to pick up an item\n")
  (printf "Enter `out` to exit the large door when it opens\n")
  (printf "Enter `north/east/south/west` to navigate the area\n"))

; +---------------------------------------------------------------------------------------------+
; Start:

(define (start-game in-place
                    in-all-verbs
                    in-global-actions)
  (set! current-place in-place)
  (set! all-verbs in-all-verbs)
  (set! global-actions in-global-actions)
  (do-place))
