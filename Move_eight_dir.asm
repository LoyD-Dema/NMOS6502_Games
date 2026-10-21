.ORG $8000
.DEFINE JOYPAD $4000  ;000 0 1 1 1 1
.DEFINE SCREEN_START $0200
.DEFINE SPEED #$08
.DEFINE RAW_LEN #$10
.DEFINE RAW_LEN_MIN_ONE #$0F

; Zero page
.DEFINE POS $00
.DEFINE JOY_VALUE $01
.DEFINE NEW_POS $02
.DEFINE FRAME_COUNTER $FF

; Masks
;                4 3 2 1 0
; bitmask  0b000 S R L D U

.DEFINE UP_MASK     #%00000001
.DEFINE DOWN_MASK   #%00000010
.DEFINE LEFT_MASK   #%00000100
.DEFINE RIGHT_MASK  #%00001000

.DEFINE COL_MASK    #%00001111

; Colors
.DEFINE PIXEL_COLOR #$0F


start:
    CLI
    LDA SPEED
    STA FRAME_COUNTER
    
    ; Put a pixel in the middle of the screen
    LDX #$88 ; 136 in decimal
    STX POS
    LDA PIXEL_COLOR
    STA SCREEN_START, X
    

loop:
    JMP loop

handle_input:
    DEC FRAME_COUNTER
    BNE end_handle_input
    LDA SPEED
    STA FRAME_COUNTER

    JSR clearScreen
    
    LDX POS
    STX NEW_POS

    LDA JOYPAD
    STA JOY_VALUE
    AND UP_MASK
    BEQ not_up      ; Skip to check with DOWN
    
    ; Up pressed
    TXA 
    SEC
    SBC RAW_LEN
    TAX
    STX NEW_POS
    
    
not_up:
    LDA JOY_VALUE
    AND DOWN_MASK
    BEQ not_down    ; Skip to check with LEFT

    ; down pressed
    TXA 
    CLC
    ADC RAW_LEN
    TAX
    STX NEW_POS

not_down:
    LDA JOY_VALUE
    AND LEFT_MASK
    BEQ not_left    ; Skip to check with RIGHT
    
    ; left pressed
    TXA             
    AND COL_MASK
    BEQ wrap_to_right
    
    DEX 
    STX NEW_POS
    JMP not_left

wrap_to_right:
    LDA NEW_POS
    CLC
    ADC RAW_LEN_MIN_ONE
    TAX
    STX NEW_POS

not_left:
    LDA JOY_VALUE
    AND RIGHT_MASK
    BEQ not_right   ; Skip to draw

    ; right pressed
    TXA
    AND COL_MASK
    CMP COL_MASK 
    BEQ wrap_to_left
    
    INX
    STX NEW_POS
    JMP not_right
    
wrap_to_left:
    LDA NEW_POS
    SEC
    SBC RAW_LEN_MIN_ONE
    TAX
    STX NEW_POS

not_right:
    JMP draw    

clearScreen:
    LDA #$00
    LDX POS
    STA SCREEN_START, X
    RTS

draw:
    LDA PIXEL_COLOR
    LDX NEW_POS
    STA SCREEN_START, X
    STX POS
    
end_handle_input:
    RTS 

nmi:
    JSR handle_input
    RTI

break:
    RTI
    

    

    
.GOTO $FFFA
.DW nmi    ; nmi interrupt
.DW start  ; reset interrupt
.DW break  ; break interrupt