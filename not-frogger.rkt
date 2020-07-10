;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname not-frogger) (read-case-sensitive #t) (teachpacks ((lib "universe.rkt" "teachpack" "2htdp") (lib "image.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "universe.rkt" "teachpack" "2htdp") (lib "image.rkt" "teachpack" "2htdp")) #f)))
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; NOT FROGGER - A frogger-like game implemented in the Racket programming lang
;-------------------------------------------------------------------------------
;
; Use local and "loops functions" (abstractions such as map, foldr, filter,
; etc.) wherever a function may benefit from it, especially for the lists of
; objects. 
;
; - Use the arrow keys to navigate: up, down, left and right. 
; - In the river rows, the player must ride a turtle or a plank at all times. 
; - The player loses if the frog falls into the river.
; - The player loses if the frog leaves the bounds of the screen. 
; - When any entity (vehicle, plank, or turtle) passes off one edge,
;   another is created on the opposite edge.

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; DATA DEFINITIONS
;-------------------------------------------------------------------------------
; A PosInt is a non-negative integer
; A Direction is a KeyEvent
; A Direction is one of: "left", "right", "up", "down"
; (define (template-dir adir)
;   (cond
;     [(key=? adir "left") ...]
;     [(key=? adir "right") ...]
;     [(key=? adir "up") ...]
;     [(key=? adir "down") ...]))

; A Lane is a (make-lane PosInt PosInt)
; INTERP: defines the top and bottom horizontal boundaries of a lane
(define-struct lane (bot top))
; (define (template-lane al)
;   ...(lane-bot al)
;   ...(lane-top al))

; A Frog is a (make-frog Posn Direction Image)
(define-struct frog (posn fdir img))
; (define (template-frog afrg)
;     ...(posn-x (frog-posn afrg))
;     ...(posn-y (frog-posn afrg))
;     ...(frog-fdir afrg)
;     ...(frog-img afrg))

; A Vehicle Direction (VDir) is one of: 1, -1 
; A Vehicle is a (make-vehicle Posn VDir PosInt Image)
(define-struct vehicle (posn vdir speed img))
; (define (template-vehicle vehic)
;     ...(posn-x (vehicle-posn vehic))
;     ...(posn-y (vehicle-posn vehic))
;     ...(vehicle-vdir vehic))
;     ...(vehicle-img vehic))

; A List of Vehicles (LoV) is one of:
; - '()
; - (cons Vehicle LoV)
; (define (template-lov alov)
;   (cond
;     [(empty? alov) ...]
;     [else ...(template-vehicle (first alov))]))

; A World is a (make-world Frog LoV)
; INTERP: The LoV represents the vehicles moving across 
;         the screen and the Frog is the player's character 
(define-struct world (frog vehicles))
; (define (template-world wrld)
;   ...(template-frog (world-frog wrld)
;   ...(template-lov (world-vehicles wrld))))

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; CONSTANTS / DATA EXAMPLE HELPER FUNCTIONS / DATA EXAMPLES
;-------------------------------------------------------------------------------
; Images
(define FRG-STILL-LT (bitmap/file "images/frog_still_left.png"))
(define FRG-STILL-RT (bitmap/file "images/frog_still_right.png"))
(define FRG-STILL-UP (bitmap/file "images/frog_still_up.png"))
(define FRG-STILL-DN (bitmap/file "images/frog_still_down.png"))
(define TRIP-TURT (bitmap/file "images/triplets.png"))
(define TWIN-TURT (bitmap/file "images/twins.png"))
(define RIVR-SLOG (bitmap/file "images/short-log.png"))
(define RIVR-MLOG (bitmap/file "images/medium-log.png"))
(define RIVR-LLOG (bitmap/file "images/long-log.png"))
(define IMG-V1 (bitmap/file "images/car1.png"))
(define IMG-V2 (bitmap/file "images/car2.png"))
(define IMG-V3 (bitmap/file "images/car3.png"))
(define IMG-V4 (bitmap/file "images/truck2.png"))
(define IMG-V5 (bitmap/file "images/truck1.png"))

(define CAR-WIDTH (image-width IMG-V1))
(define CAR-HEIGHT (image-height IMG-V1))
(define TRUCK-WIDTH (image-width IMG-V4))
(define SLOG-WIDTH (image-width RIVR-SLOG))
(define MLOG-WIDTH (image-width RIVR-MLOG))
(define LLOG-WIDTH (image-width RIVR-LLOG))
(define TWIN-WIDTH (image-width TWIN-TURT))
(define TRIP-WIDTH (image-width TRIP-TURT))

; Scaling Factor (must be multiple of 5)
(define SCALE 20)

; Lanes, Background, and Game Over
(define LANE-WIDTH (* SCALE CAR-WIDTH))
(define LANE-HEIGHT CAR-HEIGHT)
(define NUM-LANES 13)
(define PURPLN (rectangle LANE-WIDTH LANE-HEIGHT 'solid 'purple))
(define GREELN (rectangle LANE-WIDTH LANE-HEIGHT 'solid 'green))
(define RIVER  (rectangle LANE-WIDTH (* 5 LANE-HEIGHT) 'solid 'blue))
(define BG0 (empty-scene LANE-WIDTH (* NUM-LANES LANE-HEIGHT) 'black))
(define BG (overlay/align/offset "middle" "top" RIVER 0 (* -1 LANE-HEIGHT)
             (overlay/align "middle" "top" GREELN
               (overlay/align "middle" "bottom" PURPLN
                (overlay/align "middle" "middle" PURPLN BG0)))))

(define GAME-OVER (overlay (text "GAME OVER" 40 'red) BG0))
(define YOU-WIN (overlay (text "YOU WIN!" 40 'yellow) BG0))
(define START-LANE (make-lane (* (- NUM-LANES  0) LANE-HEIGHT)
                              (* (- NUM-LANES  1) LANE-HEIGHT)))
(define LANE1      (make-lane (* (- NUM-LANES  1) LANE-HEIGHT)
                              (* (- NUM-LANES  2) LANE-HEIGHT)))
(define LANE2      (make-lane (* (- NUM-LANES  2) LANE-HEIGHT)
                              (* (- NUM-LANES  3) LANE-HEIGHT)))
(define LANE3      (make-lane (* (- NUM-LANES  3) LANE-HEIGHT)
                              (* (- NUM-LANES  4) LANE-HEIGHT)))
(define LANE4      (make-lane (* (- NUM-LANES  4) LANE-HEIGHT)
                              (* (- NUM-LANES  5) LANE-HEIGHT)))
(define LANE5      (make-lane (* (- NUM-LANES  5) LANE-HEIGHT)
                              (* (- NUM-LANES  6) LANE-HEIGHT)))
(define MID-LANE   (make-lane (* (- NUM-LANES  6) LANE-HEIGHT)
                              (* (- NUM-LANES  7) LANE-HEIGHT)))
(define RIVLANE1   (make-lane (* (- NUM-LANES  7) LANE-HEIGHT)
                              (* (- NUM-LANES  8) LANE-HEIGHT)))
(define RIVLANE2   (make-lane (* (- NUM-LANES  8) LANE-HEIGHT)
                              (* (- NUM-LANES  9) LANE-HEIGHT)))
(define RIVLANE3   (make-lane (* (- NUM-LANES  9) LANE-HEIGHT)
                              (* (- NUM-LANES 10) LANE-HEIGHT)))
(define RIVLANE4   (make-lane (* (- NUM-LANES 10) LANE-HEIGHT)
                              (* (- NUM-LANES 11) LANE-HEIGHT)))
(define RIVLANE5   (make-lane (* (- NUM-LANES 11) LANE-HEIGHT)
                              (* (- NUM-LANES 12) LANE-HEIGHT)))
(define END-LANE   (make-lane (* (- NUM-LANES 12) LANE-HEIGHT)
                              (* (- NUM-LANES 13) LANE-HEIGHT)))

; midlane : Lane -> PosInt
; determine the vertical midpoint of a Lane
(define (midlane ln)
  (local [; PosInt PosInt -> PosInt
          (define (midpoint posInt1 posInt2)
            (/ (+ posInt1 posInt2) 2))]
    (midpoint (lane-bot ln) (lane-top ln))))
(check-expect (midlane (make-lane 0 100)) 50)
(check-expect (midlane (make-lane 50 50)) 50)

; Frog
(define FROG-WIDTH (image-width FRG-STILL-UP))
(define FROG-OFFSET (* 1/2 FROG-WIDTH))
(define FROG0-X (+ (* 1/2 (image-width BG)) FROG-OFFSET))
(define FROG0-Y (midlane START-LANE))
(define FROG0-POSN (make-posn FROG0-X FROG0-Y))
(define FROG0-FDIR "left")
(define FROG0-IMG FRG-STILL-UP)
(define FROG0 (make-frog FROG0-POSN FROG0-FDIR FROG0-IMG))
(define FROG1 (make-frog FROG0-POSN "down" FRG-STILL-DN))

; Vehicles
(define SPD1 2)
(define SPD2 4)
(define SPD3 6)
(define SPD4 4)
(define SPD5 4)

(define R2L -1)
(define L2R 1)

(define V1-1X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 3/4)))
(define V1-1Y (midlane LANE1))
(define V1-1POSN (make-posn V1-1X V1-1Y))
(define V1-1VDIR R2L)
(define V1-1SPD SPD1)
(define V1-1IMG IMG-V1)
(define L1V1 (make-vehicle V1-1POSN V1-1VDIR V1-1SPD IMG-V1))

(define V1-2X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 1/2)))
(define V1-2Y (midlane LANE1))
(define V1-2POSN (make-posn V1-2X V1-2Y))
(define V1-2VDIR R2L)
(define V1-2SPD SPD1)
(define V1-2IMG IMG-V1)
(define L1V2 (make-vehicle V1-2POSN V1-2VDIR V1-2SPD IMG-V1))

(define V1-3X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 1/4)))
(define V1-3Y (midlane LANE1))
(define V1-3POSN (make-posn V1-3X V1-3Y))
(define V1-3VDIR R2L)
(define V1-3SPD SPD1)
(define V1-3IMG IMG-V1)
(define L1V3 (make-vehicle V1-3POSN V1-3VDIR V1-3SPD IMG-V1))

(define V1-4X (/ CAR-WIDTH 2))
(define V1-4Y (midlane LANE1))
(define V1-4POSN (make-posn V1-4X V1-4Y))
(define V1-4VDIR R2L)
(define V1-4SPD SPD1)
(define V1-4IMG IMG-V1)
(define L1V4 (make-vehicle V1-4POSN V1-4VDIR V1-4SPD IMG-V1))

(define V2-1X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 3/4)))
(define V2-1Y (midlane LANE2))
(define V2-1POSN (make-posn V2-1X V2-1Y))
(define V2-1VDIR L2R)
(define V2-1SPD SPD2)
(define V2-1IMG IMG-V2)
(define L2V1 (make-vehicle V2-1POSN V2-1VDIR V2-1SPD IMG-V2))

(define V2-2X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 1/2)))
(define V2-2Y (midlane LANE2))
(define V2-2POSN (make-posn V2-2X V2-2Y))
(define V2-2VDIR L2R)
(define V2-2SPD SPD2)
(define V2-2IMG IMG-V2)
(define L2V2 (make-vehicle V2-2POSN V2-2VDIR V2-2SPD IMG-V2))

(define V2-3X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 1/4)))
(define V2-3Y (midlane LANE2))
(define V2-3POSN (make-posn V2-3X V2-3Y))
(define V2-3VDIR L2R)
(define V2-3SPD SPD2)
(define V2-3IMG IMG-V2)
(define L2V3 (make-vehicle V2-3POSN V2-3VDIR V2-3SPD IMG-V2))

(define V2-4X (/ CAR-WIDTH 2))
(define V2-4Y (midlane LANE2))
(define V2-4POSN (make-posn V2-4X V2-4Y))
(define V2-4VDIR L2R)
(define V2-4SPD SPD2)
(define V2-4IMG IMG-V2)
(define L2V4 (make-vehicle V2-4POSN V2-4VDIR V2-4SPD IMG-V2))
                   
(define V3-1X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 3/4)))
(define V3-1Y (midlane LANE3))
(define V3-1POSN (make-posn V3-1X V3-1Y))
(define V3-1VDIR R2L)
(define V3-1SPD SPD3)
(define V3-1IMG IMG-V3)
(define L3V1 (make-vehicle V3-1POSN V3-1VDIR V3-1SPD IMG-V3))

(define V3-2X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 1/2)))
(define V3-2Y (midlane LANE3))
(define V3-2POSN (make-posn V3-2X V3-2Y))
(define V3-2VDIR R2L)
(define V3-2SPD SPD3)
(define V3-2IMG IMG-V3)
(define L3V2 (make-vehicle V3-2POSN V3-2VDIR V3-2SPD IMG-V3))

(define V3-3X (+ (/ CAR-WIDTH 2) (* LANE-WIDTH 1/4)))
(define V3-3Y (midlane LANE3))
(define V3-3POSN (make-posn V3-3X V3-3Y))
(define V3-3VDIR R2L)
(define V3-3SPD SPD3)
(define V3-3IMG IMG-V3)
(define L3V3 (make-vehicle V3-3POSN V3-3VDIR V3-3SPD IMG-V3))

(define V3-4X (/ CAR-WIDTH 2))
(define V3-4Y (midlane LANE3))
(define V3-4POSN (make-posn V3-4X V3-4Y))
(define V3-4VDIR R2L)
(define V3-4SPD SPD3)
(define V3-4IMG IMG-V3)
(define L3V4 (make-vehicle V3-4POSN V3-4VDIR V3-4SPD IMG-V3))
                          
(define V4-1X (+ (/ TRUCK-WIDTH 2) (* LANE-WIDTH 3/4)))
(define V4-1Y (midlane LANE4))
(define V4-1POSN (make-posn V4-1X V4-1Y))
(define V4-1VDIR L2R)
(define V4-1SPD SPD4)
(define V4-1IMG IMG-V4)
(define L4V1 (make-vehicle V4-1POSN V4-1VDIR V4-1SPD IMG-V4))

(define V4-2X (+ (/ TRUCK-WIDTH 2) (* LANE-WIDTH 1/2)))
(define V4-2Y (midlane LANE4))
(define V4-2POSN (make-posn V4-2X V4-2Y))
(define V4-2VDIR L2R)
(define V4-2SPD SPD4)
(define V4-2IMG IMG-V4)
(define L4V2 (make-vehicle V4-2POSN V4-2VDIR V4-2SPD IMG-V4))

(define V4-3X (+ (/ TRUCK-WIDTH 2) (* LANE-WIDTH 1/4)))
(define V4-3Y (midlane LANE4))
(define V4-3POSN (make-posn V4-3X V4-3Y))
(define V4-3VDIR L2R)
(define V4-3SPD SPD4)
(define V4-3IMG IMG-V4)
(define L4V3 (make-vehicle V4-3POSN V4-3VDIR V4-3SPD IMG-V4))

(define V4-4X (/ TRUCK-WIDTH 2))
(define V4-4Y (midlane LANE4))
(define V4-4POSN (make-posn V4-4X V4-4Y))
(define V4-4VDIR L2R)
(define V4-4SPD SPD4)
(define V4-4IMG IMG-V4)
(define L4V4 (make-vehicle V4-4POSN V4-4VDIR V4-4SPD IMG-V4))

(define V5-1X (+ (/ TRUCK-WIDTH 2) (* LANE-WIDTH 3/4)))
(define V5-1Y (midlane LANE5))
(define V5-1POSN (make-posn V5-1X V5-1Y))
(define V5-1VDIR R2L)
(define V5-1SPD SPD5)
(define V5-1IMG IMG-V5)
(define L5V1 (make-vehicle V5-1POSN V5-1VDIR V5-1SPD IMG-V5))

(define V5-2X (+ (/ TRUCK-WIDTH 2) (* LANE-WIDTH 1/2)))
(define V5-2Y (midlane LANE5))
(define V5-2POSN (make-posn V5-2X V5-2Y))
(define V5-2VDIR R2L)
(define V5-2SPD SPD5)
(define V5-2IMG IMG-V5)
(define L5V2 (make-vehicle V5-2POSN V5-2VDIR V5-2SPD IMG-V5))

(define V5-3X (+ (/ TRUCK-WIDTH 2) (* LANE-WIDTH 1/4)))
(define V5-3Y (midlane LANE5))
(define V5-3POSN (make-posn V5-3X V5-3Y))
(define V5-3VDIR R2L)
(define V5-3SPD SPD5)
(define V5-3IMG IMG-V5)
(define L5V3 (make-vehicle V5-3POSN V5-3VDIR V5-3SPD IMG-V5))

(define V5-4X (/ TRUCK-WIDTH 2))
(define V5-4Y (midlane LANE5))
(define V5-4POSN (make-posn V5-4X V5-4Y))
(define V5-4VDIR R2L)
(define V5-4SPD SPD5)
(define V5-4IMG IMG-V5)
(define L5V4 (make-vehicle V5-4POSN V5-4VDIR V5-4SPD IMG-V5))

; triplet turtles R2L
(define R1-1X (+ (/ TRIP-WIDTH 2) (* LANE-WIDTH 3/4)))
(define R1-1Y (midlane RIVLANE1))
(define R1-1POSN (make-posn R1-1X R1-1Y))
(define R1-1VDIR R2L)
(define R1-1SPD SPD1)
(define R1-1IMG TRIP-TURT)
(define R1V1 (make-vehicle R1-1POSN R1-1VDIR R1-1SPD R1-1IMG))

(define R1-2X (+ (/ TRIP-WIDTH 2) (* LANE-WIDTH 1/2)))
(define R1-2Y (midlane RIVLANE1))
(define R1-2POSN (make-posn R1-2X R1-2Y))
(define R1-2VDIR R2L)
(define R1-2SPD SPD1)
(define R1-2IMG TRIP-TURT)
(define R1V2 (make-vehicle R1-2POSN R1-2VDIR R1-2SPD R1-2IMG))

(define R1-3X (+ (/ TRIP-WIDTH 2) (* LANE-WIDTH 1/4)))
(define R1-3Y (midlane RIVLANE1))
(define R1-3POSN (make-posn R1-3X R1-3Y))
(define R1-3VDIR R2L)
(define R1-3SPD SPD1)
(define R1-3IMG TRIP-TURT)
(define R1V3 (make-vehicle R1-3POSN R1-3VDIR R1-3SPD R1-3IMG))

(define R1-4X (/ TRIP-WIDTH 2))
(define R1-4Y (midlane RIVLANE1))
(define R1-4POSN (make-posn R1-4X R1-4Y))
(define R1-4VDIR R2L)
(define R1-4SPD SPD1)
(define R1-4IMG TRIP-TURT)
(define R1V4 (make-vehicle R1-4POSN R1-4VDIR R1-4SPD R1-4IMG))

; short log L2R
(define R2-1X (+ (/ SLOG-WIDTH 2) (* LANE-WIDTH 3/4)))
(define R2-1Y (midlane RIVLANE2))
(define R2-1POSN (make-posn R2-1X R2-1Y))
(define R2-1VDIR L2R)
(define R2-1SPD SPD2)
(define R2-1IMG RIVR-SLOG)
(define R2V1 (make-vehicle R2-1POSN R2-1VDIR R2-1SPD R2-1IMG))

(define R2-2X (+ (/ SLOG-WIDTH 2) (* LANE-WIDTH 1/2)))
(define R2-2Y (midlane RIVLANE2))
(define R2-2POSN (make-posn R2-2X R2-2Y))
(define R2-2VDIR L2R)
(define R2-2SPD SPD2)
(define R2-2IMG RIVR-SLOG)
(define R2V2 (make-vehicle R2-2POSN R2-2VDIR R2-2SPD R2-2IMG))

(define R2-3X (+ (/ SLOG-WIDTH 2) (* LANE-WIDTH 1/4)))
(define R2-3Y (midlane RIVLANE2))
(define R2-3POSN (make-posn R2-3X R2-3Y))
(define R2-3VDIR L2R)
(define R2-3SPD SPD2)
(define R2-3IMG RIVR-SLOG)
(define R2V3 (make-vehicle R2-3POSN R2-3VDIR R2-3SPD R2-3IMG))

(define R2-4X (/ SLOG-WIDTH 2))
(define R2-4Y (midlane RIVLANE2))
(define R2-4POSN (make-posn R2-4X R2-4Y))
(define R2-4VDIR L2R)
(define R2-4SPD SPD2)
(define R2-4IMG RIVR-SLOG)
(define R2V4 (make-vehicle R2-4POSN R2-4VDIR R2-4SPD R2-4IMG))

; long log L2R
(define R3-1X (+ (/ LLOG-WIDTH 2) (* LANE-WIDTH 3/4)))
(define R3-1Y (midlane RIVLANE3))
(define R3-1POSN (make-posn R3-1X R3-1Y))
(define R3-1VDIR L2R)
(define R3-1SPD SPD3)
(define R3-1IMG RIVR-LLOG)
(define R3V1 (make-vehicle R3-1POSN R3-1VDIR R3-1SPD R3-1IMG))

(define R3-2X (+ (/ LLOG-WIDTH 2) (* LANE-WIDTH 1/2)))
(define R3-2Y (midlane RIVLANE3))
(define R3-2POSN (make-posn R3-2X R3-2Y))
(define R3-2VDIR L2R)
(define R3-2SPD SPD3)
(define R3-2IMG RIVR-LLOG)
(define R3V2 (make-vehicle R3-2POSN R3-2VDIR R3-2SPD R3-2IMG))

(define R3-3X (+ (/ LLOG-WIDTH 2) (* LANE-WIDTH 1/2)))
(define R3-3Y (midlane RIVLANE3))
(define R3-3POSN (make-posn R3-3X R3-3Y))
(define R3-3VDIR L2R)
(define R3-3SPD SPD3)
(define R3-3IMG RIVR-LLOG)
(define R3V3 (make-vehicle R3-3POSN R3-3VDIR R3-3SPD R3-3IMG))

(define R3-4X (/ LLOG-WIDTH 2))
(define R3-4Y (midlane RIVLANE3))
(define R3-4POSN (make-posn R3-4X R3-4Y))
(define R3-4VDIR L2R)
(define R3-4SPD SPD3)
(define R3-4IMG RIVR-LLOG)
(define R3V4 (make-vehicle R3-4POSN R3-4VDIR R3-4SPD R3-4IMG))

; twin turtles R2L
(define R4-1X (+ (/ TWIN-WIDTH 2) (* LANE-WIDTH 3/4)))
(define R4-1Y (midlane RIVLANE4))
(define R4-1POSN (make-posn R4-1X R4-1Y))
(define R4-1VDIR R2L)
(define R4-1SPD SPD4)
(define R4-1IMG TWIN-TURT)
(define R4V1 (make-vehicle R4-1POSN R4-1VDIR R4-1SPD R4-1IMG))

(define R4-2X (+ (/ TWIN-WIDTH 2) (* LANE-WIDTH 1/2)))
(define R4-2Y (midlane RIVLANE4))
(define R4-2POSN (make-posn R4-2X R4-2Y))
(define R4-2VDIR R2L)
(define R4-2SPD SPD4)
(define R4-2IMG TWIN-TURT)
(define R4V2 (make-vehicle R4-2POSN R4-2VDIR R4-2SPD R4-2IMG))

(define R4-3X (+ (/ TWIN-WIDTH 2) (* LANE-WIDTH 1/4)))
(define R4-3Y (midlane RIVLANE4))
(define R4-3POSN (make-posn R4-3X R4-3Y))
(define R4-3VDIR R2L)
(define R4-3SPD SPD4)
(define R4-3IMG TWIN-TURT)
(define R4V3 (make-vehicle R4-3POSN R4-3VDIR R4-3SPD R4-3IMG))

(define R4-4X (/ TWIN-WIDTH 2))
(define R4-4Y (midlane RIVLANE4))
(define R4-4POSN (make-posn R4-4X R4-4Y))
(define R4-4VDIR R2L)
(define R4-4SPD SPD4)
(define R4-4IMG TWIN-TURT)
(define R4V4 (make-vehicle R4-4POSN R4-4VDIR R4-4SPD R4-4IMG))

; medium log L2R
(define R5-1X (+ (/ MLOG-WIDTH 2) (* LANE-WIDTH 3/4)))
(define R5-1Y (midlane RIVLANE5))
(define R5-1POSN (make-posn R5-1X R5-1Y))
(define R5-1VDIR L2R)
(define R5-1SPD SPD5)
(define R5-1IMG RIVR-MLOG)
(define R5V1 (make-vehicle R5-1POSN R5-1VDIR R5-1SPD R5-1IMG))

(define R5-2X (+ (/ MLOG-WIDTH 2) (* LANE-WIDTH 1/2)))
(define R5-2Y (midlane RIVLANE5))
(define R5-2POSN (make-posn R5-2X R5-2Y))
(define R5-2VDIR L2R)
(define R5-2SPD SPD5)
(define R5-2IMG RIVR-MLOG)
(define R5V2 (make-vehicle R5-2POSN R5-2VDIR R5-2SPD R5-2IMG))

(define R5-3X (+ (/ MLOG-WIDTH 2) (* LANE-WIDTH 1/4)))
(define R5-3Y (midlane RIVLANE5))
(define R5-3POSN (make-posn R5-3X R5-3Y))
(define R5-3VDIR L2R)
(define R5-3SPD SPD5)
(define R5-3IMG RIVR-MLOG)
(define R5V3 (make-vehicle R5-3POSN R5-3VDIR R5-3SPD R5-3IMG))

(define R5-4X (/ MLOG-WIDTH 2))
(define R5-4Y (midlane RIVLANE5))
(define R5-4POSN (make-posn R5-4X R5-4Y))
(define R5-4VDIR L2R)
(define R5-4SPD SPD5)
(define R5-4IMG RIVR-MLOG)
(define R5V4 (make-vehicle R5-4POSN R5-4VDIR R5-4SPD R5-4IMG))

; LoV example
(define ALL-VEHICS
(list L1V1 L1V2 L1V3 L1V4
      L2V1 L2V2 L2V3 L2V4
      L3V1 L3V2 L3V3 L3V4
      L4V1 L4V2 L4V3 L4V4
      L5V1 L5V2 L5V3 L5V4
      R1V1 R1V2 R1V3 R1V4
      R2V1 R2V2 R2V3 R2V4
      R3V1 R3V2 R3V3 R3V4
      R4V1 R4V2 R4V3 R4V4
      R5V1 R5V2 R5V3 R5V4))

; World example
(define WORLD0 (make-world FROG0 ALL-VEHICS))

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; INDEX OF FUNCTIONS
; - draw-world
; - key-handler
; - move-world
; - collision?
; - show-end
; - main
;-------------------------------------------------------------------------------
; draw-world : World -> Image
; draw the current state of the game
(define (draw-world wrld)
  (local [(define frg-img (frog-img (world-frog wrld)))
          (define frgx (posn-x (frog-posn (world-frog wrld))))
          (define frgy (posn-y (frog-posn (world-frog wrld))))
          ; LoV -> Image 
          (define (draw-vehicles alov)
            (local [; Vehicle Image -> Image
                    (define (put vehic img) 
                      (place-image (vehicle-img vehic) 
                      (posn-x (vehicle-posn vehic))
                      (posn-y (vehicle-posn vehic)) img))]
                    (foldr put BG alov)))]
          (place-image frg-img frgx frgy
                       (draw-vehicles (world-vehicles wrld)))))

(check-expect (draw-world WORLD0)
(place-image FROG0-IMG FROG0-X FROG0-Y 
(place-image IMG-V1 V1-1X V1-1Y 
  (place-image IMG-V1 V1-2X V1-2Y 
    (place-image IMG-V1 V1-3X V1-3Y 
      (place-image IMG-V1 V1-4X V1-4Y 
        (place-image IMG-V2 V2-1X V2-1Y 
          (place-image IMG-V2 V2-2X V2-2Y 
            (place-image IMG-V2 V2-3X V2-3Y 
              (place-image IMG-V2 V2-4X V2-4Y 
                (place-image IMG-V3 V3-1X V3-1Y 
                (place-image IMG-V3 V3-2X V3-2Y 
                (place-image IMG-V3 V3-3X V3-3Y 
                (place-image IMG-V3 V3-4X V3-4Y                 
                  (place-image IMG-V4 V4-1X V4-1Y
                  (place-image IMG-V4 V4-2X V4-2Y
                  (place-image IMG-V4 V4-3X V4-3Y
                  (place-image IMG-V4 V4-4X V4-4Y                  
                    (place-image IMG-V5 V5-1X V5-1Y
                    (place-image IMG-V5 V5-2X V5-2Y
                    (place-image IMG-V5 V5-3X V5-3Y
                    (place-image IMG-V5 V5-4X V5-4Y
                      (place-image R1-1IMG R1-1X R1-1Y
                      (place-image R1-2IMG R1-2X R1-2Y
                      (place-image R1-3IMG R1-3X R1-3Y
                      (place-image R1-4IMG R1-4X R1-4Y
                        (place-image R2-1IMG R2-1X R2-1Y
                        (place-image R2-2IMG R2-2X R2-2Y
                        (place-image R2-3IMG R2-3X R2-3Y
                        (place-image R2-4IMG R2-4X R2-4Y
                          (place-image R3-1IMG R3-1X R3-1Y
                          (place-image R3-1IMG R3-2X R3-2Y
                          (place-image R3-1IMG R3-3X R3-3Y
                          (place-image R3-1IMG R3-4X R3-4Y
                            (place-image R4-1IMG R4-1X R4-1Y
                            (place-image R4-2IMG R4-2X R4-2Y
                            (place-image R4-3IMG R4-3X R4-3Y
                            (place-image R4-4IMG R4-4X R4-4Y
                              (place-image R5-1IMG R5-1X R5-1Y
                              (place-image R5-2IMG R5-2X R5-2Y
                              (place-image R5-3IMG R5-3X R5-3Y
                              (place-image R5-4IMG R5-4X R5-4Y BG)))))))))))))))
                                                                 )))))))))))))))
                                                                 ))))))))))))

; key-handler : World KeyEvent -> World
; hande KeyEvents
(define (key-handler wrld akey)
  (local [(define frg (world-frog wrld))
          (define vehics (world-vehicles wrld))
          ; Frog -> Frog
          (define (move-frog frg akey)
            (local [(define frgp (frog-posn frg))
              (define frgx (posn-x frgp))
              (define frgy (posn-y frgp))
              (define (in-range? frg akey)
                (cond 
                  [(key=? "left" akey) (> (- frgx FROG-WIDTH) 0)]
                  [(key=? "right" akey) (< (+ frgx FROG-WIDTH) LANE-WIDTH)]
                  [(key=? "up" akey) (>= (- frgy LANE-HEIGHT) 
                                         (midlane END-LANE))]
                  [(key=? "down" akey) (<= (+ frgy LANE-HEIGHT) 
                                           (midlane START-LANE))]
                  [else #false]))]
              ; move the frog only if it is within the screen boundary
              (if (not (in-range? frg akey)) frg
                  (cond
                    [(key=? akey "left")
                     (make-frog (make-posn (- frgx FROG-WIDTH) frgy)
                                "left" FRG-STILL-LT)]
                    [(key=? akey "right")
                     (make-frog (make-posn (+ frgx FROG-WIDTH) frgy) 
                                "right" FRG-STILL-RT)]
                    [(key=? akey "up")
                     (make-frog (make-posn frgx (- frgy LANE-HEIGHT)) 
                                "up" FRG-STILL-UP)]
                    [(key=? akey "down") 
                     (make-frog (make-posn frgx (+ frgy LANE-HEIGHT))
                                "down" FRG-STILL-DN)]))))]
    (make-world (move-frog frg akey) vehics)))

(define LFROG-TEST
        (make-frog (make-posn (- FROG0-X FROG-WIDTH) FROG0-Y)
                   "left" FRG-STILL-LT))
(define RFROG-TEST
        (make-frog (make-posn (+ FROG0-X FROG-WIDTH) FROG0-Y)
                   "right" FRG-STILL-RT))
(define FAR-LEFT-FRG
        (make-frog (make-posn FROG-WIDTH FROG0-Y)
                   "left" FRG-STILL-LT))
(define FAR-RIGHT-FRG
        (make-frog (make-posn (- LANE-WIDTH FROG-WIDTH) FROG0-Y)
                   "right" FRG-STILL-RT))
(define UFROG-TEST
        (make-frog (make-posn FROG0-X (- FROG0-Y LANE-HEIGHT))
                   "up" FRG-STILL-UP))
(define TOP-FRG
        (make-frog (make-posn FROG0-X LANE-HEIGHT)
                   "up" FRG-STILL-UP))
(define BOTT-FRG
        (make-frog (make-posn FROG0-X (+ FROG0-Y LANE-HEIGHT))
                   "down" FRG-STILL-DN))

(check-expect (key-handler WORLD0 "left")
              (make-world LFROG-TEST ALL-VEHICS))
(check-expect (key-handler (make-world FAR-LEFT-FRG ALL-VEHICS) "left")
              (make-world FAR-LEFT-FRG ALL-VEHICS))
(check-expect (key-handler WORLD0 "right")
              (make-world RFROG-TEST ALL-VEHICS))
(check-expect (key-handler (make-world FAR-RIGHT-FRG ALL-VEHICS) "right")
              (make-world FAR-RIGHT-FRG ALL-VEHICS))
(check-expect (key-handler WORLD0 "up")
              (make-world UFROG-TEST ALL-VEHICS))
(check-expect (key-handler (make-world TOP-FRG ALL-VEHICS) "up")
              (make-world TOP-FRG ALL-VEHICS))
(check-expect (key-handler (make-world UFROG-TEST ALL-VEHICS) "down")
              (make-world FROG1 ALL-VEHICS))
(check-expect (key-handler (make-world BOTT-FRG ALL-VEHICS) "down")
              (make-world BOTT-FRG ALL-VEHICS))
(check-expect (key-handler WORLD0 " ") WORLD0)

; move-world : World -> World
; moves the the vehicles in the world
; moves the frog if it is in the river on a plank or turtle
(define (move-world awrld)
  (local 
    [(define vehics (world-vehicles awrld))    
     (define (move-vehic vehic)
       (local 
         [(define vx (posn-x (vehicle-posn vehic)))
          (define vy (posn-y (vehicle-posn vehic)))
          (define vdir (vehicle-vdir vehic))
          (define vspd (vehicle-speed vehic))
          (define vimg (vehicle-img vehic))
          (define imgw (image-width vimg))
          (define vdelta (+ (* vdir vspd) (* 0.5 imgw)))
          (define (get-new-x void) 
            (- (modulo (+ vx vdelta) (+ (image-width BG) imgw 1))
               (* 0.5 imgw)))]
       (make-vehicle (make-posn (get-new-x "") vy) vdir vspd vimg)))
    
     (define (move-frog void)
       (local 
         [(define frg (world-frog awrld))
          (define frgx (posn-x (frog-posn frg)))
          (define frgy (posn-y (frog-posn frg)))
          (define (in-river? void) (< frgy (midlane MID-LANE)))
          (define (get-carrier void)
            (local
              [(define (get-carr alov)
                 (local 
                   [(define (carrying? vehic)
                      (local 
                        [(define vx (posn-x (vehicle-posn vehic)))
                         (define vy (posn-y (vehicle-posn vehic)))
                         (define vimg (vehicle-img vehic))
                         (define imgw (image-width vimg))]
                         (>= (+ vx (* 1/2 imgw) 1) frgx (- vx (* 1/2 imgw) 1))))]
                 (cond
                   [(carrying? (first alov)) (first alov)]
                   [else (get-carr (rest alov))])))
               (define (get-lane-vehics alov mdln)
                 (filter (lambda (v) (= (posn-y (vehicle-posn v)) mdln)) alov))]
            (get-carr (get-lane-vehics vehics frgy))))]
       (if (in-river? "") 
           (local 
             [(define fdir (frog-fdir frg))
              (define fimg (frog-img frg))
              (define fcarr (get-carrier ""))
              (define fspd (vehicle-speed fcarr))
              (define cdelta (* fspd (vehicle-vdir fcarr)))]
           (make-frog (make-posn (+ frgx cdelta) frgy) fdir fimg))
           frg)))]
  (make-world (move-frog (world-frog awrld)) (map move-vehic vehics))))

(define TEST-WORLD1 
  (make-world (make-frog (make-posn FROG0-X (midlane RIVLANE5))
                         FROG0-FDIR FROG0-IMG) ALL-VEHICS))

(check-expect (move-world TEST-WORLD1) 
(make-world (make-frog (make-posn (+ FROG0-X R5-2SPD) (midlane RIVLANE5))
                       FROG0-FDIR FROG0-IMG)
(list
(make-vehicle (make-posn (- V1-1X V1-1SPD) V1-1Y) V1-1VDIR V1-1SPD IMG-V1)
(make-vehicle (make-posn (- V1-2X V1-1SPD) V1-2Y) V1-2VDIR V1-2SPD IMG-V1)
(make-vehicle (make-posn (- V1-3X V1-1SPD) V1-3Y) V1-3VDIR V1-3SPD IMG-V1)
(make-vehicle (make-posn (- V1-4X V1-1SPD) V1-4Y) V1-4VDIR V1-4SPD IMG-V1)
(make-vehicle (make-posn (+ V2-1X V2-1SPD) V2-1Y) V2-1VDIR V2-1SPD IMG-V2)
(make-vehicle (make-posn (+ V2-2X V2-1SPD) V2-2Y) V2-2VDIR V2-2SPD IMG-V2)
(make-vehicle (make-posn (+ V2-3X V2-1SPD) V2-3Y) V2-3VDIR V2-3SPD IMG-V2)
(make-vehicle (make-posn (+ V2-4X V2-1SPD) V2-4Y) V2-4VDIR V2-4SPD IMG-V2)
(make-vehicle (make-posn (- V3-1X V3-1SPD) V3-1Y) V3-1VDIR V3-1SPD IMG-V3)
(make-vehicle (make-posn (- V3-2X V3-1SPD) V3-2Y) V3-2VDIR V3-2SPD IMG-V3)
(make-vehicle (make-posn (- V3-3X V3-1SPD) V3-3Y) V3-3VDIR V3-3SPD IMG-V3)
(make-vehicle (make-posn (- V3-4X V3-1SPD) V3-4Y) V3-4VDIR V3-4SPD IMG-V3)
(make-vehicle (make-posn (+ V4-1X V4-1SPD) V4-1Y) V4-1VDIR V4-1SPD IMG-V4)
(make-vehicle (make-posn (+ V4-2X V4-1SPD) V4-2Y) V4-2VDIR V4-2SPD IMG-V4)
(make-vehicle (make-posn (+ V4-3X V4-1SPD) V4-3Y) V4-3VDIR V4-3SPD IMG-V4)
(make-vehicle (make-posn (+ V4-4X V4-1SPD) V4-4Y) V4-4VDIR V4-4SPD IMG-V4)
(make-vehicle (make-posn (- V5-1X V5-1SPD) V5-1Y) V5-1VDIR V5-1SPD IMG-V5)
(make-vehicle (make-posn (- V5-2X V5-1SPD) V5-2Y) V5-2VDIR V5-2SPD IMG-V5)
(make-vehicle (make-posn (- V5-3X V5-1SPD) V5-3Y) V5-3VDIR V5-3SPD IMG-V5)
(make-vehicle (make-posn (- V5-4X V5-1SPD) V5-4Y) V5-4VDIR V5-4SPD IMG-V5)
(make-vehicle (make-posn (- R1-1X R1-1SPD) R1-1Y) R1-1VDIR R1-1SPD R1-1IMG)
(make-vehicle (make-posn (- R1-2X R1-2SPD) R1-2Y) R1-2VDIR R1-2SPD R1-2IMG)
(make-vehicle (make-posn (- R1-3X R1-3SPD) R1-3Y) R1-3VDIR R1-3SPD R1-3IMG)
(make-vehicle (make-posn (- R1-4X R1-4SPD) R1-4Y) R1-4VDIR R1-4SPD R1-4IMG)
(make-vehicle (make-posn (+ R2-1X R2-1SPD) R2-1Y) R2-1VDIR R2-1SPD R2-1IMG)
(make-vehicle (make-posn (+ R2-2X R2-2SPD) R2-2Y) R2-2VDIR R2-2SPD R2-2IMG)
(make-vehicle (make-posn (+ R2-3X R2-3SPD) R2-3Y) R2-3VDIR R2-3SPD R2-3IMG)
(make-vehicle (make-posn (+ R2-4X R2-4SPD) R2-4Y) R2-4VDIR R2-4SPD R2-4IMG)
(make-vehicle (make-posn (+ R3-1X R3-1SPD) R3-1Y) R3-1VDIR R3-1SPD R3-1IMG)
(make-vehicle (make-posn (+ R3-2X R3-2SPD) R3-2Y) R3-2VDIR R3-2SPD R3-2IMG)
(make-vehicle (make-posn (+ R3-3X R3-3SPD) R3-3Y) R3-3VDIR R3-3SPD R3-3IMG)
(make-vehicle (make-posn (+ R3-4X R3-4SPD) R3-4Y) R3-4VDIR R3-4SPD R3-4IMG)
(make-vehicle (make-posn (- R4-1X R4-1SPD) R4-1Y) R4-1VDIR R4-1SPD R4-1IMG)
(make-vehicle (make-posn (- R4-2X R4-2SPD) R4-2Y) R4-2VDIR R4-2SPD R4-2IMG)
(make-vehicle (make-posn (- R4-3X R4-3SPD) R4-3Y) R4-3VDIR R4-3SPD R4-3IMG)
(make-vehicle (make-posn (- R4-4X R4-4SPD) R4-4Y) R4-4VDIR R4-4SPD R4-4IMG)
(make-vehicle (make-posn (+ R5-1X R5-1SPD) R5-1Y) R5-1VDIR R5-1SPD R5-1IMG)
(make-vehicle (make-posn (+ R5-2X R5-2SPD) R5-2Y) R5-2VDIR R5-2SPD R5-2IMG)
(make-vehicle (make-posn (+ R5-3X R5-3SPD) R5-3Y) R5-3VDIR R5-3SPD R5-3IMG)
(make-vehicle (make-posn (+ R5-4X R5-4SPD) R5-4Y) R5-4VDIR R5-4SPD R5-4IMG))))

; collision? : World -> Boolean
; detect whether a game-ending collision has occured
(define (collision? wrld)
  (local [; Frog LoV -> Boolean
          (define (coll? frg alov0)
            (local [(define frgp (frog-posn frg))
                    (define frgx (posn-x frgp))
                    (define frgy (posn-y frgp))
                    ; Number Vehicle -> Boolean
                    (define (hv? vehic)
                      (>= (+ (posn-x (vehicle-posn vehic)) 
                          (* 1/2 (image-width (vehicle-img vehic))) 1)
                          frgx
                          (- (posn-x (vehicle-posn vehic)) 
                             (* 1/2 (image-width (vehicle-img vehic))) 1)))
                    ; LoV Number -> LoV
                    (define (get-lane-vehics alov1 mdln)
                      (filter (lambda (v) (= (posn-y (vehicle-posn v))
                                             mdln)) alov1))
                    (define NOLOGIC (append 
                                    (get-lane-vehics alov0 (midlane LANE1))
                                    (get-lane-vehics alov0 (midlane LANE2))
                                    (get-lane-vehics alov0 (midlane LANE3))
                                    (get-lane-vehics alov0 (midlane LANE4))
                                    (get-lane-vehics alov0 (midlane LANE5))))
                    (define NCLOGIC (append 
                                    (get-lane-vehics alov0 (midlane RIVLANE1))
                                    (get-lane-vehics alov0 (midlane RIVLANE2))
                                    (get-lane-vehics alov0 (midlane RIVLANE3))
                                    (get-lane-vehics alov0 (midlane RIVLANE4))
                                    (get-lane-vehics alov0 (midlane RIVLANE5))))]
            (or (ormap hv? (get-lane-vehics NOLOGIC frgy)) #false
                (if (< frgy (midlane MID-LANE)) 
                    (or (not (ormap hv? (get-lane-vehics NCLOGIC frgy)))
                        (> (+ frgx (image-width FROG0-IMG)) (image-width BG))
                        (< (- frgx (image-width FROG0-IMG)) 0))
                    #false)
                (= frgy (midlane END-LANE)))))]
    (coll? (world-frog wrld) (world-vehicles wrld))))
    
(define TEST-WORLD (make-world FROG0 ALL-VEHICS))    
(check-expect (collision? TEST-WORLD) #false)
(check-expect (collision? (make-world (make-frog V1-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #true)
(check-expect (collision? (make-world (make-frog V2-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #true)
(check-expect (collision? (make-world (make-frog V3-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #true)
(check-expect (collision? (make-world (make-frog V4-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #true)
(check-expect (collision? (make-world (make-frog V5-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #true)
(check-expect (collision? (make-world (make-frog R1-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #false)
(check-expect (collision? (make-world (make-frog R2-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #false)
(check-expect (collision? (make-world (make-frog R3-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #false)
(check-expect (collision? (make-world (make-frog R4-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #false)
(check-expect (collision? (make-world (make-frog R5-1POSN FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #false)
(check-expect (collision? (make-world (make-frog (make-posn
                                                   (+ TWIN-WIDTH R5-1X) R5-1Y)
                                                   FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #true)
(check-expect 
  (collision? 
    (make-world (make-frog (make-posn -1 (midlane RIVLANE1))
                           FROG0-FDIR FROG0-IMG) ALL-VEHICS)) #true)
(check-expect 
  (collision? 
    (make-world (make-frog
                (make-posn (+ 1 (image-width BG)) (midlane RIVLANE1))
                FROG0-FDIR FROG0-IMG) ALL-VEHICS)) #true)
(check-expect (collision? (make-world (make-frog (make-posn FROG0-X 
                                                            (midlane END-LANE))
                                                 FROG0-FDIR FROG0-IMG) 
                                      ALL-VEHICS)) #true)


; show-end : World -> Image
; show the appropriate Image at the end of the game
(define (show-end wrld)
  (if (= (posn-y (frog-posn (world-frog wrld))) (midlane END-LANE)) 
      YOU-WIN GAME-OVER))

(define WIN-FROG (make-frog (make-posn FROG0-X (midlane END-LANE))
                            FROG0-FDIR FROG0-IMG))
(check-expect (show-end TEST-WORLD) GAME-OVER)
(check-expect (show-end (make-world WIN-FROG ALL-VEHICS)) YOU-WIN)

(define (main wrld)
  (big-bang wrld 
    [to-draw draw-world]
    [on-key key-handler]
    [on-tick move-world]
    [stop-when collision? show-end]))

(main WORLD0)
;-------------------------------------------------------------------------------
