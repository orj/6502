; Zero Page ($00-$FF)

; Stack ($0100 - $01FF)

; Global Data 
value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes

; VIA Ports
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

; Constants
E  = %10000000
RW = %01000000
RS = %00100000 

; LCD Commands
LCD_ClearDisplay = %00000001

    .org $8000
reset:    
    lda #$ff        ; Initialise the stack
    tax
    txs

    jsr setup_lcd

    ldx #0
print:
    lda message,x
    beq .exit
    jsr print_char
    inx
    jmp print
.exit:

    jmp halt

    ; Initialize value to be the number to convert
    lda number
    sta value
    lda number + 1
    sta value + 1

divide:
    ; Initalize the remainer to zero
    lda #0
    sta mod10
    sta mod10 + 1
    clc

    ldx #16
.divloop
    ; Rotate quotient and remainder
    rol value
    rol value + 1
    rol mod10 
    rol mod10 + 1

    ; a,y = dividend - divisor
    sec
    lda mod10
    sbc #10
    tay ; save low byte in Y
    lda mod10 + 1
    sbc #0
    bcc .ignore_result   ; branch if dividend < divisor
; store result
    sty mod10
    sta mod10 + 1
.ignore_result
    dex 
    bne .divloop
    rol value       ; shift in the last bit of the quotient
    rol value + 1   ; 
    
    lda mod10
    clc
    adc #"0"
    jsr print_char

    ; if value != 0, then continue dividing
    lda value
    ora value + 1
    bne divide ; branch if value != 0

halt:
    jmp halt

number:     
    .word 1729

message:    
    .asciiz "Hello, Sarah!"

setup_lcd:
    pha
    lda #%11111111      ; Set all pins on PORTB to output
    sta DDRB

    lda #%11100000      ; Set top 3 pins on PORTA out output
    sta DDRA

    lda #%00111000      ; Set 8-bit mode; 2-line display; 5x8 font
    jsr lcd_instruction
    lda #%00001110      ; Turn on display & cursor, no blink
    jsr lcd_instruction
    
    lda #%00000110      ; Entry mode select
    jsr lcd_instruction
    lda #%00000110      ; Entry mode select; Increment cursor; no shift
    jsr lcd_instruction
    
    lda #LCD_ClearDisplay
    jsr lcd_instruction
    pla
    rts

; Send an LCD configuration instruction.
; - Paramters:
;   - A register: Instruction to send.
lcd_instruction:
    jsr lcd_wait
    sta PORTB
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    lda #E         ; Set enable bit to send instruction
    sta PORTA
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    rts

; Wait for the LCD to not be busy
lcd_wait:
    pha            ; Save A register

    lda DDRB       ; Save DDRB
    pha

    lda #%00000000 ; Set Port B as input
    sta DDRB

read_busy:
    lda #RW         ; Enable reading
    sta PORTA
    lda #(RW | E)   ; Set enable bit
    sta PORTA

    lda PORTB       ; Read the busy and address
    and #%10000000  ; Check for busy flag set
    bne read_busy   ; Loop while the busy flag is set.

    lda #RW         ; Clear enable bit
    sta PORTA

    pla             ; Restore DDRB
    sta DDRB
    pla             ; Restore A register
    rts

; Print a character on the LCD
; - Parameters:
;   - A register: The character to send.
print_char:
    jsr lcd_wait
    sta PORTB
    lda #RS        ; Set RS
    sta PORTA
    lda #(RS | E)  ; Set RS & Enable bit
    sta PORTA
    lda #RS        ; Set RS
    sta PORTA
    rts
    
    .org $fffc
    .word reset
    .word $0000
