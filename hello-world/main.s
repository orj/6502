; Zero Page ($00-$FF)
ptr1 = $00 ; 2 bytes
ptr2 = $02 ; 2 bytes

; Stack ($0100 - $01FF)

; Global Data 

; VIA1 Registers
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
; more registers
SR  = $600a
ACR = $600b
PCR = $600c
IFR = $600d
IER = $600e

; Constants
E  = %10000000
RW = %01000000
RS = %00100000 

; LCD Commands
LCD_ClearDisplay = %00000001
LCD_CursorHome = %00000010

; Interrupt Enable Register Bits
IRE_Clear  = %00000000
IRE_Set    = %10000000
IRE_Timer1 = %01000000
IRE_Timer2 = %00100000
IRE_CB1    = %00010000
IRE_CB2    = %00001000
IRE_Shift  = %00000100
IRE_CA1    = %00000010
IRE_CA2    = %00000001

; Interrupt Flag Register Bits
IFR_IRQ    = %10000000
IFR_Timer1 = %01000000
IFR_Timer2 = %00100000
IFR_CB1    = %00010000
IFR_CB2    = %00001000
IFR_Shift  = %00000100
IFR_CA1    = %00000010
IFR_CA2    = %00000001

; Periferal Control Register Bits
; TODO: CB2 3 bits
PCR_CB1_NegActiveEdge    = %00000000
PCR_CB1_PosActiveEdge    = %00010000
; TODO: CA2 3 bits
PCR_CA1_NegActiveEdge    = %00000000
PCR_CA1_PosActiveEdge    = %00000001

    .org $8000
reset:    
    ldx #$ff        ; Initialise the stack
    txs
    cli

    lda #(IRE_Set | IRE_CA1)
    sta IER
    lda #(PCR_CA1_NegActiveEdge)
    sta PCR

    jsr setup_lcd

    lda #LCD_CursorHome
    jsr lcd_instruction

    lda #<message
    ldx #>message
    jsr print_string

halt:
    jmp halt

message:    
    .asciiz "Hello, every1 at                        Itty Bitty Apps!"

; Print a string
; - Parameters
;   - A & X register: The address of the string.
print_string:
    sta ptr1
    stx ptr1+1
    phy
    ; Print the result string
    ldy #0
.print:
    lda (ptr1),y
    beq .exit
    jsr print_char
    iny
    jmp .print
.exit:
    ply
    rts

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


; Non-maskable Interrupt Handler
nmi:
    rti

; Interrupt Request Handler    
irq:
    bit PORTA
    rti

    .org $fffa
    .word nmi   ; $fffa-fffb - Non maskable interupt handler vector
    .word reset ; $fffc-fffd - Reset Vector
    .word irq   ; $fffe-ffff - Interrupt request handler vector
