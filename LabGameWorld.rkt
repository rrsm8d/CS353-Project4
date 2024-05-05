#lang s-exp "adventuredsl.rkt"

(define-verbs all-verbs
  [north (= n) "go north"]
  [south (= s) "go south"]
  [east (= e) "go east"]
  [west (= w) "go west"]
  [out (= leave) "leave"]  
  [get _ (= grab take) "take"]
  [drop _ (= drop leave) "drop"]
  [insert _ (= place insert) "insert"]
  [quit (= exit) "quit"]
  [look (= show) "look"]
  [inventory (=) "check inventory"]
  [help])

; System actions
(define-everywhere global-actions
  ([quit (begin (printf "Ending game.\n") (exit))]
   [look (show-current-place)]
   [inventory (show-inventory)]
   [help (show-help)]))

; Roll a num between 1 and n for randomization
(define (roll-die n)
  (+ (random n) 1))


; +---------------------------------------------------------------------------------------------+
; Interactible items

(define-thing large-door) ; Only needs to track states, open and closed. ('open and #f)

(define-thing red-block
  [get (if (have-thing? red-block)
           "The red-block has already been taken from this pedestal"
           (begin
             (take-thing! red-block)
             "Placed the red-block in your inventory."))]
  [drop (if (have-thing? red-block)
           (begin
             (drop-thing! red-block)
             "The red-block has been dropped.")
           "red-block not in inventory.")])

(define-thing green-block
  [get (if (have-thing? green-block)
           "The green-block has already been taken from this pedestal"
           (begin
             (take-thing! green-block)
             "Placed the green-block in your inventory."))]
  [drop (if (have-thing? green-block)
           (begin
             (drop-thing! green-block)
             "The green-block has been dropped.")
           "green-block not in inventory.")])

(define-thing blue-block
  [get (if (have-thing? blue-block)
           "The blue-block has already been taken from this pedestal"
           (begin
             (take-thing! blue-block)
             "Placed the blue-block in your inventory."))]
  [drop (if (have-thing? blue-block)
           (begin
             (drop-thing! blue-block)
             "The blue-block has been dropped.")
           "blue-block not in inventory.")])

(define-thing pedestal
  [insert (if (and (have-thing? red-block) (have-thing? green-block) (have-thing? blue-block))
              (begin
                (set-thing-state! pedestal 'open)
                (set-thing-state! large-door 'open)
                (delete-thing! red-block)
                (delete-thing! green-block)
                (delete-thing! blue-block)
                "The pedestal reacts to all three blocks, and it slides open, revealing a gold-bar!\nThe door behind you begins to open...")
              (if (eq? (thing-state pedestal) 'open)
                  "It's already open!"
                  "It doesn't seem like you have the ability to open this yet..."))])

(define-thing gold-bar
  [get (if (have-thing? gold-bar)
           "The gold-bar has already been taken from this pedestal"
           (if (eq? (thing-state pedestal) 'open)
               (begin
                 (take-thing! gold-bar)
                 (set-thing-state! large-door #f)
                 "Took the gold bar from the hole. You hear the large door shut.")
               "You are unable to get get the gold bar. The pedestal refuses to open."))]
  [drop (if (have-thing? gold-bar)
           (begin
             (drop-thing! gold-bar)
             (set-thing-state! large-door 'open)
             "The gold-bar has been put back into the hole. The large door has opened once more. Could there be a way to keep it open and take the bar home?")
           "gold-bar not in inventory.")])

(define-thing jar
  [get (if (have-thing? jar)
           "You already found this heavy old jar..."
           (begin
             (if (>= (roll-die 6) 5) ; Randomization for pulling the jar out
                 (begin
                   (take-thing! jar)
                   "With enough luck, you managed to pull the heavy jar out of the pile.")
                 "You failed to pick up the heavy jar. Try again!")))]
  [drop (if (and (have-thing? jar) (have-thing? gold-bar))
           (begin
             (drop-thing! jar)
             (set-thing-state! large-door 'open)
             "Placed the jar in place of the gold-bar. The large door opens once more. Time to get out!")
           "Theres nowhere to put this jar...")])

; +---------------------------------------------------------------------------------------------+
; Places

(define-place green-room
  "The room is colored with green walls and lights. There seems to be something here."
  [green-block]
  ([east west-room]))

(define-place west-room
  "This room is seemingly empty. The path continues west."
  []
  ([west green-room]
  [east central-lab]))

(define-place blue-room
  "The room is colored with blue walls and lights. There seems to be something here."
  [blue-block]
  ([west north-room]))

(define-place north-room
  "You stand in an old and dusty room filled with large broken pottery. The dusty path stretches further east."
  [jar]
  ([east blue-room]
   [south central-lab]))

(define-place red-room
  "The room is colored with red walls and lights. There seems to be something here."
  [red-block]
  ([south east-room]))

(define-place east-room
  "You stand in an empty hallway. A faint red glow emanates to the north."
  []
  ([north red-room]
   [west central-lab]))

(define-place central-lab
  "You stand in the center of a mysterious room. There are branching paths to the north, east, and west. Find a way to open and escape the large door!"
  [pedestal gold-bar large-door]
  ([out (if (eq? (thing-state large-door) 'open) ; Win condition
            (if (have-thing? gold-bar)
                "You escaped with the golden bar! You win!" ; Good ending
                "You escaped without the treasure. You failed!") ; Bad ending
            "The door is tightly sealed.")]
   [west west-room]
   [north north-room]
   [east east-room]))

; Starting place
central-lab