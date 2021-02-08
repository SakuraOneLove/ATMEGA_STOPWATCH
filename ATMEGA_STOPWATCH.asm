;***������� ���������� ������������ - led_reg***
; 0,1,2 - ���� ������ ��������(����� 8 ���������)
; 3,4,5,6 - ����� �������, ���
;  0000 - "�"
;  0001 - "0"
;  0010 - "1"
;  ....
;  1011 - "9"
; 7 - ��� ���������� ������
;*************************************

;***������� ���������� ������� - key_reg***
; 0 - ��� ���������� ������ �������
; 1 - ��� �����
; 2 - ��� ������ ������� ������� ��� ��� �������
; 3 - ��� ���������� � ������
;******************************************

;***������� ���������� - party_reg ***
; 0 - ������ ��������
; 1 - ������ ��������
; 2 - ������ ��������
; 3 - ��������� ��������
;*************************************

.include "m8515def.inc" ;���� ����������� ��� ATmega8515
.def temp = r16 		;��������� �������
.def party_reg = r19	;������� ����������
.def led_reg = r20 		;��������� �������� ���������� ������������
.def key_reg = r21		;���������� ������ �����������
.def ms_reg = r22		;������� ���������� ��(�� 0 �� 100)
.def sec_reg = r23		;������� ���������� �
.def min_reg = r24		;������� ���������� ���
.def digl = r25 		;������� �� ������� ����� �� 10
.def digh = r26			;������� �� ������� ����� �� 10
.def eel  = r27			;������� ���� ������ EEPROM
.def eeh  = r28			;������� ���� ������ EEPROM
.def eed  = r29			;���� ������ EEPROM
.equ XTAL = 1000000 	;�������� ������� ��
.equ baudrate = 4800
.equ bauddivider = XTAL/(16*baudrate)-1
.org $000
;***������� ����������***
rjmp INIT 		   	;��������� ������
.org $001
rjmp START_PRESSED 	;��������� �������� ���������� INT0(START\LAP)
.org $002
rjmp RES_PRESSED 	;��������� �������� ���������� INT1(RESET)
.org $00D
rjmp STOP_PRESSED	;��������� �������� ���������� INT2(STOP)

;***��������� ����������***
START_PRESSED:
sbrc key_reg, 0	;���������� ���� ��� ������ ������� ����� 0
rjmp CHANGE_PARTY
clr key_reg	; ������������� ������� � 0
ldi key_reg, 1	; ��������� ������ �������
sbr led_reg, (1<<7) ;��������� ������ ����������
rjmp QUIT_SP	;������� �� ����������
CHANGE_PARTY:
ldi temp, 3			;���������� ��������� ������� ���� ����� ������ 4
cp party_reg, temp
brsh STOP_SP		;��������� �� ����� ���� >=
inc party_reg		;����������� ����� ���������
clr temp			;������� ��������� �������
;������ ������ � ������
mov eed, ms_reg		;���������� ���������� � ������ ��
rcall EEWrite		;������
inc eel				;����������� �����
mov eed, sec_reg	;���������� ���������� � ������ �
rcall EEWrite		;������
inc eel				;����������� �����
mov eed, min_reg	;���������� ���������� � ������ ���
rcall EEWrite		;������
inc eel				;����������� �����
rjmp QUIT_SP		;�������
STOP_SP:
sbrc key_reg, 3		; ���� ���������� ��� ���������� � ������
rjmp CLEAN_SP		; ����������
ldi key_reg, 3		; ������������� ����� � �������� ������
sbr key_reg, (1<<3)	; ������������� ��� ���������� � ������
;������ ������ � ������
mov eed, ms_reg		;���������� ���������� � ������ ��
rcall EEWrite		;������
inc eel				;����������� �����
mov eed, sec_reg	;���������� ���������� � ������ �
rcall EEWrite		;������
inc eel				;����������� �����
mov eed, min_reg	;���������� ���������� � ������ ���
rcall EEWrite		;������
inc eel				;����������� �����
;�������� ������
;**������ �� ������**
mov r15, r17		;��������� ���������� ��������
ldi eel, 0			;������������� ������� �����
ldi r17, 12			;��������� ���������� �������� � �������
CH_PR:
rcall EERead		;������ ��������� �� ������
rcall uart_snt		;�������� �� ����
inc	eel				;��������� � ����������
dec r17
brne CH_PR

mov r15, temp		;���������� �������� �������� � �������
clr temp
rjmp QUIT_SP
CLEAN_SP:
clr eel				;������� ������� ���� ������
clr party_reg		;������� ����� ��������� � ������� ���������� �� ������
clr key_reg
clr ms_reg
clr sec_reg
clr min_reg
clr temp
QUIT_SP:
reti

RES_PRESSED:
clr eel		; ������� ����� �������� ����� EEPROM
clr key_reg ; ������������� ������� � 0
ldi key_reg, (1<<2)	; ������������� 2 ��� � 1
cbr led_reg, 0x7F	; ���������� ��� ���������� ������ ����������(��� �)
;���������� �������� ������� � ������ ���������
clr ms_reg
clr sec_reg
clr min_reg
clr party_reg
reti

STOP_PRESSED:
ldi key_reg, 2	;������������� �����
reti

;***������������ ���������� ����� �� ��� �����***
DIVIDE_NUM:
;������� �������� �������� ����
clr digl
clr digh
subi temp, 10	;��������� 10 �� ��������� �����
brlt NEXTD		;���� ������ 10 ������� �� �����
LOOP:
inc digh	;��������� ����� �����
subi temp, 10	;��������� 10 �� ��������� �����
brge LOOP		;���� >= 10 ���������
NEXTD:
ldi digl,10	;������� 10 � ������� ������ �����
add temp, digl	;��������������� �������� � ��������
mov digl, temp	;������� ������� � ������� ������ �����
inc digl		;����������� �� 1 �.�. ������� ���������� � 1
inc digh
clr temp		;������� ��������� �������
ret

;***������������ ��������� ���������***
SET_NUM:
sbrs led_reg, 7 ; ��������� ��� ���������� ���������
rjmp GO_AWAY    ; ����� ������� �� ������������
out PORTA, led_reg ; �������� ��������� �������
GO_AWAY:
ret

;***������������ �������� 1.125��***
DELAY: 
ldi r17,2
d1: ldi r18,186
d2: dec r18
brne d2
dec r17
brne d1
ret

;***������������ ������ ������ � EEPROM***
EEWrite:	
sbic	EECR,EEWE		; ���� ���������� ������ � ������. �������� � �����
rjmp	EEWrite 		; �� ��� ��� ���� �� ��������� ���� EEWE
 
;cli						; ����� ��������� ����������.
out 	EEARL,R27 		; ��������� ����� ������ ������
out 	EEARH,R28  		; ������� � ������� ���� ������
out 	EEDR,R29 		; � ���� ������, ������� ��� ����� ���������
 
sbi 	EECR,EEMWE		; ������� ��������������
sbi 	EECR,EEWE		; ���������� ����
;sei						; ��������� ����������
ret 					; ������� �� ���������

;***������������ ������ ������ �� EEPROM***
EERead:	
sbic 	EECR,EEWE		; ���� ���� ����� ��������� ������� ������.
rjmp	EERead			; ����� �������� � �����.
out 	EEARL, R27		; ��������� ����� ������ ������
out  	EEARH, R28 		; ��� ������� � ������� �����
sbi 	EECR,EERE 		; ���������� ��� ������
in 		R29, EEDR 		; �������� �� �������� ������ ���������
ret

;***������������ ������������� UART***
uart_init:	
ldi 	temp, low(bauddivider)
out 	UBRRL,temp
ldi 	temp, high(bauddivider)
out 	UBRRH,temp
 
ldi 	temp,0
out 	UCSRA, temp
; ���������� ���������, �����-�������� ��������.
ldi 	temp, (1<<RXEN)|(1<<TXEN)|(0<<RXCIE)|(0<<TXCIE)|(0<<UDRIE)
out 	UCSRB, temp	
 
; ������ ����� - 8 ���, ����� � ������� UCSRC, �� ��� �������� ��� ��������
ldi 	temp, (1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)
out 	UCSRC, temp
ret

; ������������ �������� �����
uart_snt:	
sbis 	UCSRA,UDRE	; ������� ���� ��� ����� ����������
rjmp	uart_snt 	; ���� ���������� - ����� UDRE
 
out		UDR, eed	; ���� ����
ret					; �������

;***������������� ��***
INIT:
clr eel			; ������� ������� �������� ����� ��� ������ EEPROM
clr eeh			; ������� ������� �������� ����� ��� ������ EEPROM
clr eed			; ������� ������� ������ ��� ������ EEPROM
clr party_reg	; ���������� ������� ��������� � �������
clr key_reg		; ������� ������� ������
clr ms_reg		; ������� ��������� ��������
clr sec_reg
clr min_reg
ldi temp,Low(RAMEND) ; ������������� �����
out SPL,temp
ldi temp,High(RAMEND)
out SPH,temp
rcall uart_init		;�������������� ����
ser temp ; �������������
out DDRA,temp ; ����� � �� �����
clr temp ;������������� 2-��� � 3-��� �������
out DDRD,temp ; ����� PD �� ����
ldi temp,0x1C ;��������� ���������������
out PORTD,temp ; ���������� ����� PD
clr temp		; ������������� 1-�� ������
out DDRE, temp	; ����� � �� ����
inc temp		; ���������
out PORTE, temp	; ������������� ����������
ldi temp,(1<<INT0)|(1<<INT1)|(1<<INT2) ;���������� ���������� INT0 � INT1 � INT2
out GICR,temp ; (6 ��� GICR ��� GIMSK)
ldi temp,0x00 ;��������� ����������
out MCUCR,temp ; �� ������� ������
sei ;���������� ���������� ����������

MAIN:
ldi led_reg, 0x80	;10000000 ������� ������ ��� ����������
rcall SET_NUM	; ������������� ������ P
rcall DELAY		; ��������
;****��������� ������ ���������****
mov led_reg, party_reg	;������� ����� ���������
inc led_reg			;�������� ����� � ��������(����� P1 ������ PP)
inc led_reg
lsl led_reg		;�������� 3 ����
lsl led_reg
lsl led_reg
inc led_reg 	;���������� 2 �������
sbr led_reg, (1<<7)	;��������� ����������� ��������
rcall SET_NUM	; ������������� ������ 1
rcall DELAY		; ��������
;****������� ������****
;*****����� �����******
mov temp, min_reg	;��������� ���������� ����� �� ��������� �������
rcall DIVIDE_NUM
mov led_reg, digh	;��������� ������� �� ������� � �������
lsl led_reg		;�������� 3 ����
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;��������� ����������� ��������
ldi temp, 0x02		;������������� ������ �������
add led_reg, temp
rcall SET_NUM	; ������������� ������
rcall DELAY		; ��������
;******������ �����*****
mov led_reg, digl	;��������� ������� �� ������� � �������
lsl led_reg		;�������� 3 ����
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;��������� ����������� ��������
ldi temp, 0x03		;������������� ��������� �������
add led_reg, temp
rcall SET_NUM	; ������������� ������
rcall DELAY		; ��������
;****������� �������****
;*****����� �����******
mov temp, sec_reg	;��������� ���������� ������ �� ��������� �������
rcall DIVIDE_NUM
mov led_reg, digh	;��������� ������� �� ������� � �������
lsl led_reg		;�������� 3 ����
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;��������� ����������� ��������
ldi temp, 0x04		;������������� ������ �������
add led_reg, temp
rcall SET_NUM	; ������������� ������
rcall DELAY		; ��������
;******������ �����*****
mov led_reg, digl	;��������� ������� �� ������� � �������
lsl led_reg		;�������� 3 ����
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;��������� ����������� ��������
ldi temp, 0x05		;������������� ��������� �������
add led_reg, temp
rcall SET_NUM	; ������������� ������
rcall DELAY		; ��������
;****������� ������������****
;*****����� �����******
mov temp, ms_reg	;��������� ���������� �� �� ��������� �������
rcall DIVIDE_NUM
mov led_reg, digh	;��������� ������� �� ������� � �������
lsl led_reg		;�������� 3 ����
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;��������� ����������� ��������
ldi temp, 0x06		;������������� ������ �������
add led_reg, temp
rcall SET_NUM	; ������������� ������
rcall DELAY		; ��������
;******������ �����*****
mov led_reg, digl	;��������� ������� �� ������� � �������
lsl led_reg		;�������� 3 ����
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;��������� ����������� ��������
ldi temp, 0x07		;������������� ��������� �������
add led_reg, temp
rcall SET_NUM	; ������������� ������
rcall DELAY		; ��������
;***������� �����***
COUNT:
sbrc key_reg, 1 ; ���������, ��� �� ����������� �����(0)
rjmp MAIN
sbrs key_reg, 0	; ���������, ��� ��������� ������ �������(1)
rjmp MAIN
ldi temp, 100	;��������� ���������� �������� ��
inc ms_reg		;������� ������������
cpse ms_reg, temp	;���������� ��������� ������� ���� �� �����
rjmp NEXT
clr ms_reg		;�������� ������� ��
ldi temp, 60	;��������� ���������� �������� �
inc sec_reg ;������� �������
cpse sec_reg, temp	;���������� ��������� ������� ���� �� �����
rjmp NEXT
clr sec_reg	;������� ������� �
ldi temp, 60	;��������� ���������� �������� ���
inc min_reg ;������� ������
cpse min_reg, temp	;���������� ��������� ������� ���� �� �����
rjmp NEXT
clr min_reg	;��� ���������� ����� � 60 ����� ���������� ��������� �����
NEXT:
rjmp MAIN
