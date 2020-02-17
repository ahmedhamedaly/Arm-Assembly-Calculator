AREA	AsmTemplate, CODE, READONLY
IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN  EQU 0xE0028010

; getKey
; @PARAMETERS: None
; @RETURNS: R0 -> buttonIndex
;


; handleKey
; @PARAMETERS: R0 -> buttonIndex, R1 -> n, R2 -> prevN, R3 -> prevO
; @RETURNS: None
;
handleKey
  PUSH {R4-R12, LR}

  CMP R0, #23
  BEQ hkAdd
  CMP R0, #22
  BEQ hkSub
  CMP R0, #21
  BEQ hkAddOp
  CMP R0, #20
  BEQ hkSubOp
  CMP R0, #-21
  BEQ hkLastClear
  CMP R0, #-20
  BEQ hkFullClear
  B   hkEnd

hkAdd
  BL  nAdd
  B   hkEnd
hkSub
  BL  nSub
  B   hkEnd
hkAddOp
  BL  addOp
  B   hkEnd
hkSubOp
  BL  SubOp
  B   hkEnd
hkLastClear
  BL  lastClear
  B   hkEnd
hkFullClear
  BL  fullClear
  B   hkEnd

hkEnd
  MOV R0, #0
  POP {R4-R12, PC}

; nAdd
; @PARAMETERS: R1 -> n, R2 -> prevN, R3 -> prevO
; @RETURNS:
;
nAdd
  PUSH {R0, R4-R12, LR}

  ADD R1, R1, #1
  MOV R2, #1
  MOV R3, #1

  POP {R0, R4-R12, LR}
; nSub
; @PARAMETERS:
; @RETURNS:
;
nSub

; addOp
; @PARAMETERS:
; @RETURNS:
;
addOP

; subOp
; @PARAMETERS:
; @RETURNS:
;
subOp

; lastClear
; @PARAMETERS:
; @RETURNS:
;
lastClear

; fullClear
; @PARAMETERS:
; @RETURNS:
;
fullClear

; reverseBits
; @PARAMETERS:
; @RETURNS:
;


; delay
; @PARAMETERS: None
; @RETURNS: None
;
delay
  PUSH {R0, LR}

  LDR	R0, =4000000
  delayLoop	SUBS  R0, R0, #1
  BNE	delayLoop

  POP {R0, PC}

ldr	r1,=IO1DIR
ldr	r2,=0x000f0000	;select P1.19--P1.16
str	r2,[r1]		;make them outputs
ldr	r1,=IO1SET
str	r2,[r1]		;set them to turn the LEDs off
ldr	r2,=IO1CLR
; r1 points to the SET register
; r2 points to the CLEAR register

ldr	r5,=0x00100000	; end when the mask reaches this value
wloop	ldr	r3,=0x00010000	; start with P1.16.
floop	str	r3,[r2]	   	; clear the bit -> turn on the LED

;delay for about a half second
ldr	r4,=4000000
dloop	subs	r4,r4,#1
bne	dloop

str	r3,[r1]		;set the bit -> turn off the LED
mov	r3,r3,lsl #1	;shift up to next bit. P1.16 -> P1.17 etc.
cmp	r3,r5
bne	floop
b	wloop
stop	B	stop

END
