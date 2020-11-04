AREA	RESET, CODE, READONLY
;	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

;	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN  EQU 0xE0028010

; main
; @PARAMETERS: args[]
; @RETURNS: 0
;
  BL initSerial ; init[serials]

while           ; while (True) {
  BL getKey     ; getKey()
  BL handleKey  ; handleKey(key)
  BL displayN   ; displayN(n)
  B  while      ; }

; getKey
; @PARAMETERS: None
; @RETURNS: R0 -> buttonIndex
;
getKey
  PUSH {R1-R12, LR}

  MOV R0, #0        ; buttonIndex = 0
  LDR R1, =4000000  ; delay = 4000000
  LDR R2, =IO1PIN   ; init[io1pins]
  LDR R3, =0x00F00000 ; maskPins = 0x00F00000

  gkWhile           ; do {
  LDR R4, [R2]      ; load[pins]
  AND R4, R4, R3    ; pins = pins & mask
  CMP R4, R3        ; }
  BEQ gkWhile       ; while (pins == mask)

  MOV R5, R4        ; pressedButton = pins
gkLongW CMP R5, R4  ; while (pressedButton == pins)
  BNE gkPress       ; {
  CMP R6, R1        ; if (delayCounter != delay)
  BEQ gkLong        ; {
  LDR R4, [R2]      ; load[pins]
  AND R4, R4, R3    ; pins = pins & mask
  ADD R6, R6, #1    ; delayCounter++
  B   gkLongW       ; }

gkLong
  MOV R0, R5        ; buttonIndex = pins
  BL  index         ; index(button)
  RSB R0, R0, #0    ; NEG(buttonIndex)
  B   gkEnd         ; }
gkPress
  MOV R0, R5        ; buttonIndex = pins
  BL  index         ; index(button)

  gkEnd
  POP {R1-R12, PC}

; handleKey
; @PARAMETERS: R0 -> buttonIndex, R1 -> n, R2 -> prevN, R3 -> prevO
; @RETURNS: None
;
handleKey
  PUSH {R4-R12, LR}

  CMP R0, #23         ; if (add)
  BNE hkSub           ; {
  BL  nAdd            ; add()
  B   hkEnd           ; }

hkSub  CMP R0, #22    ; else if (sub)
  BNE hkAddOp         ; {
  BL  nSub            ; sub()
  B   hkEnd           ; }

hkAddOp  CMP R0, #21  ; else if (addOp)
  BNE hkSubOp         ; {
  BL  addOp           ; addOp()
  B   hkEnd           ; }

hkSubOp  CMP R0, #20  ; else if (subOp)
  BNE hkLastClear     ; {
  BL  subOp           ; subOp()
  B   hkEnd           ; }

hkLastClear  CMP R0, #-21 ; else if (lastClear)
  BEQ hkFullClear     ; {
  BL  lastClear       ; lastClear()
  B   hkEnd           ; }

hkFullClear  CMP R0, #-20 ; else
  BL  fullClear       ; { fullClear }

hkEnd
  MOV R0, #0          ; buttonIndex = 0

  POP {R4-R12, PC}

; nAdd
; @PARAMETERS: R1 -> n
; @RETURNS:
;
nAdd
  PUSH {R0, R2-R12, LR}

  ADD R1, R1, #1  ; n++

  POP {R0, R2-R12, PC}

; nSub
; @PARAMETERS: R1 -> n
; @RETURNS:
;
nSub
  PUSH {R0, R2-R12, LR}

  SUB R1, R1, #1  ; n--

  POP {R0, R2-R12, PC}

; addOp
; @PARAMETERS: R1 -> n, R2 -> prevN, R3 -> prevO
; @RETURNS:
;
addOp
  PUSH {R0, R4-R12, LR}

  ADD R4, R1, R2  ; temp = n + prevN
  MOV R3, #1  ; prevO = True
  MOV R2, #0  ; prevN = n
  MOV R1, R4  ; n = temp

POP {R0, R4-R12, PC}

; subOp
; @PARAMETERS: R1 -> n, R2 -> prevN, R3 -> prevO
; @RETURNS: None
;
subOp
  PUSH {R0, R4-R12, LR}

  SUB R4, R1, R2  ; temp = n + prevN
  MOV R3, #1  ; prevO = True
  MOV R2, R1  ; prevN = n
  MOV R1, R4  ; n = temp

POP {R0, R4-R12, PC}

; lastClear
; @PARAMETERS: R2 -> prevN, R3 -> prevO
; @RETURNS: None
;
lastClear
  PUSH {R0-R1, R4-R12, LR}

  MOV R2, #0  ; prevN = 0
  MOV R3, #0  ; prevO = 0

  POP {R0-R1, R4-R12, LR}

; fullClear
; @PARAMETERS: R0 -> buttonIndex, R1 -> n, R2 -> prevN, R3 -> prevO
; @RETURNS: None
;
fullClear
  PUSH {R4-R12, LR}

  MOV R0, #0        ; buttonIndex = 0
  MOV R1, #0        ; n = 0
  MOV R2, #0        ; prevN = 0
  MOV R3, #0        ; prevO = 0
  BL  initSerial    ; led(off)

  POP {R4-R12, PC}

; reverseBits
; @PARAMETERS: R1 -> n
; @RETURNS: R12 -> rev
;
reverseBits
  PUSH {R0, R2-R11, LR}

  MOV R0, #3              	  ; num_of_bits = 3
  AND R2, R1, #0x0000000F			; revN = n & 0x0000000F
  MOV R3, #1                  ; mask = 1
  MOV	R4, #0                  ; rev = 0

rbWhile CMP R2, #0            ; while (n > 0)
  BEQ rbEnd                   ; {
  AND R5, R3, R2              ; bit = n & mask
  CMP r5, #0                  ; if (bit != 0)
  BEQ rbElse                  ; {
  ORR R4, R4, R3, LSL R0      ; result |= 1 << num_of_bits
rbElse                        ; }
  MOV r2, r2, lsr #1          ; n >>= 1
  SUB r0, r0, #1              ; num_of_bits--
  B rbWhile                   ; }

rbEnd
  MOV R12, R4                  ; reversed = result
  POP {R0, R2-R11, PC}

; displayN
; @PARAMETERS: R1 -> n
; @RETURNS: None
;
displayN
  PUSH {R0, R2-R12, LR}

  LDR	R2, =IO1CLR     ; load(io1clr)
  BL reverseBits      ; reverseBits(n)
  LSL R12, R12, #16   ; on = reversedN << 16
  STR R12, [R2]       ; led(on)

POP {R0, R2-R12, PC}

; index
; @PARAMETERS: R0 -> pins
; @RETURNS: R0 -> buttonIndex
;
index
  PUSH {R1-R12, LR}

  LDR R1, =0x00E00000   ; p1.20
  LDR R2, =0x00D00000   ; p1.21
  LDR R3, =0x00B00000   ; p1.22
  LDR R4, =0x00700000   ; p1.23

  CMP R0, R1        ; if (pins == p1.20)
  BNE iTwo          ; {
  MOV R0, #20       ; buttonIndex = 20
  B   iEnd          ; }

iTwo CMP R0, R2     ; if (pins == p1.21)
  BNE iThree        ; {
  MOV R0, #21       ; buttonIndex = 21
  B   iEnd          ; }

iThree CMP R0, R3   ; if (pins == 1.22)
  BNE iFour         ; {
  MOV R0, #22       ; buttonIndex = 22
  B   iEnd          ; }

iFour
  MOV R0, #23       ; else { buttonIndex = 23 }

  iEnd
  POP {R1-R12, PC}

; initSerial
; @PARAMETERS: None
; @RETURNS: None
;
initSerial
  PUSH {R0-R12, LR}

  LDR	R1, =IO1DIR     ; load(io1dir)
  LDR	R2, =0x000f0000	; select P1.19--P1.16
  STR	R2, [R1]	     	; make them outputs
  LDR	R1, =IO1SET     ; load(io1set)
  STR	R2, [R1]		    ; set them to turn the LEDs off

  POP {R0-R12, PC}

END
