;***Регистр управления индикаторами - led_reg***
; 0,1,2 - биты выбора сегмента(всего 8 сегментов)
; 3,4,5,6 - выбор символа, где
;  0000 - "Р"
;  0001 - "0"
;  0010 - "1"
;  ....
;  1011 - "9"
; 7 - бит разрешения работы
;*************************************

;***Регистр управления ключами - key_reg***
; 0 - бит разрешения начала отсчета
; 1 - бит паузы
; 2 - бит начала отсчета сначала для все игроков
; 3 - бит готовности к сбросу
;******************************************

;***Регистр участников - party_reg ***
; 0 - первый участник
; 1 - второй участник
; 2 - третий участник
; 3 - четвертый участник
;*************************************

.include "m8515def.inc" ;файл определений для ATmega8515
.def temp = r16 		;временный регистр
.def party_reg = r19	;регистр участников
.def led_reg = r20 		;состояние регистра управления индикаторами
.def key_reg = r21		;разрешение работы секундомера
.def ms_reg = r22		;счетчик количества мс(от 0 до 100)
.def sec_reg = r23		;счетчик количества с
.def min_reg = r24		;счетчик количества мин
.def digl = r25 		;остаток от деления числа на 10
.def digh = r26			;частное от деления числа на 10
.org $000
;***Векторы прерываний***
rjmp INIT ;обработка сброса
;.org $001
rjmp START_PRESSED ;обработка внешнего прерывания INT0(START\LAP)
;.org $002
rjmp RES_PRESSED ;обработка внешнего прерывания INT1(RESET)

;***Обработка прерываний***
START_PRESSED:
sbrc key_reg, 0	;пропускаем если бит начала отсчета равен 0
rjmp CHANGE_PARTY
clr key_reg	; устанавливаем регистр в 0
ldi key_reg, 1	; разрешаем начало отсчета
sbr led_reg, (1<<7) ;разрешаем работу индикатора
rjmp QUIT_SP	;выходим из прерывания
CHANGE_PARTY:
ldi temp, 3			;пропускаем следующую команду если номер игрока 4
cp party_reg, temp
brsh STOP_SP		;переходим по метке если >=	
inc party_reg		;увеличиваем номер участника
clr temp
rjmp QUIT_SP		;выходим
STOP_SP:
sbrc key_reg, 3		; если установлен бит готовности к сбросу
rjmp CLEAN_SP		; сбрасываем
;ldi temp, 4			;пропускаем следующую команду если выполнено пятое нажатие
;cp party_reg, temp
;breq CLEAN_SP
ldi key_reg, 3		; устанавливаем паузу и передаем данные
sbr key_reg, (1<<3)	; устанавливаем бит готовности к сбросу
;передаем данные
clr temp
rjmp QUIT_SP
CLEAN_SP:
clr party_reg		;очищаем номер участника и ожидаем разрешения на отсчет
clr key_reg
clr ms_reg
clr sec_reg
clr min_reg
clr temp
QUIT_SP:
reti
RES_PRESSED:
clr key_reg ; устанавливаем регистр в 0
ldi key_reg, (1<<2)	; устанавливаем 2 бит в 1
cbr led_reg, 0x7F	; сбрасываем бит разрешения работы индикатора(лог и)
;сбрасываем регистры времени и номера участника
clr ms_reg
clr sec_reg
clr min_reg
clr party_reg
reti

;***Подпрограмма разложения числа на две цифры***
DIVIDE_NUM:
;очищаем регистры хранения цифр
clr digl
clr digh
subi temp, 10	;вычитание 10 из исходного числа
brlt NEXTD		;если меньше 10 выходим по метке
LOOP:
inc digh	;инкремент левой цифры
subi temp, 10	;вычитание 10 из исходного числа
brge LOOP		;если >= 10 повторяем
NEXTD:
ldi digl,10	;заносим 10 в регистр правой цифры
add temp, digl	;восстанавливаем значение в регистре
mov digl, temp	;заносим остаток в регистр правой цифры
inc digl		;увеличиваем на 1 т.к. символы начинаются с 1
inc digh
clr temp		;очищаем временный регистр
ret

;***Подпрограмма индикации сегментов***
SET_NUM:
sbrs led_reg, 7 ; Проверяем бит разрешения индикации
rjmp GO_AWAY    ; Иначе выходим из подпрограммы
out PORTA, led_reg ; Зажигаем выбранный сегмент
GO_AWAY:
ret

;***Подпрограмма задержки 1.125мс***
DELAY: 
ldi r17,2
d1: ldi r18,186
d2: dec r18
brne d2
dec r17
brne d1
ret

;***Инициализация МК***
INIT:
clr party_reg	; записываем первого участника в регистр
clr key_reg		; очищаем регистр кнопок
clr ms_reg		; очищаем временные регистры
clr sec_reg
clr min_reg
ldi temp,Low(RAMEND) ; Инициализация стека
out SPL,temp
ldi temp,High(RAMEND)
out SPH,temp
ser temp ; инициализация
out DDRA,temp ; порта А на вывод
clr temp ;инициализация 2-ого и 3-ого выводов
out DDRD,temp ; порта PD на ввод
ldi temp,0x1C ;включение ‘подтягивающих’
out PORTD,temp ; резисторов порта PD
ldi temp,(1<<INT0)|(1<<INT1) ;разрешение прерывания INT0 и INT1
out GICR,temp ; (6 бит GICR или GIMSK)
ldi temp,0x00 ;обработка прерывания
out MCUCR,temp ; по низкому уровню
sei ;глобальное разрешение прерываний

MAIN:
ldi led_reg, 0x80	;10000000 включен только бит разрешения
rcall SET_NUM	; устанавливаем символ P
rcall DELAY		; задержка
;****Установка номера участника****
mov led_reg, party_reg	;заносим номер участника
inc led_reg			;сдвигаем номер в символах(будет P1 вместо PP)
inc led_reg
lsl led_reg		;сдвигаем 3 раза
lsl led_reg
lsl led_reg
inc led_reg 	;выставляем 2 сегмент
sbr led_reg, (1<<7)	;разрешаем отображение символов
rcall SET_NUM	; устанавливаем символ 1
rcall DELAY		; задержка
;****Выводим минуты****
;*****Левая цифра******
mov temp, min_reg	;загружаем количество минут во временный регистр
rcall DIVIDE_NUM
mov led_reg, digh	;загружаем частное от деления в регистр
lsl led_reg		;сдвигаем 3 раза
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;разрешаем отображение символов
ldi temp, 0x02		;устанавливаем третий сегмент
add led_reg, temp
rcall SET_NUM	; устанавливаем символ
rcall DELAY		; задержка
;******Правая цифра*****
mov led_reg, digl	;загружаем остаток от деления в регистр
lsl led_reg		;сдвигаем 3 раза
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;разрешаем отображение символов
ldi temp, 0x03		;устанавливаем четвертый сегмент
add led_reg, temp
rcall SET_NUM	; устанавливаем символ
rcall DELAY		; задержка
;****Выводим секунды****
;*****Левая цифра******
mov temp, sec_reg	;загружаем количество секунд во временный регистр
rcall DIVIDE_NUM
mov led_reg, digh	;загружаем частное от деления в регистр
lsl led_reg		;сдвигаем 3 раза
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;разрешаем отображение символов
ldi temp, 0x04		;устанавливаем третий сегмент
add led_reg, temp
rcall SET_NUM	; устанавливаем символ
rcall DELAY		; задержка
;******Правая цифра*****
mov led_reg, digl	;загружаем остаток от деления в регистр
lsl led_reg		;сдвигаем 3 раза
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;разрешаем отображение символов
ldi temp, 0x05		;устанавливаем четвертый сегмент
add led_reg, temp
rcall SET_NUM	; устанавливаем символ
rcall DELAY		; задержка
;****Выводим миллисекунды****
;*****Левая цифра******
mov temp, ms_reg	;загружаем количество мс во временный регистр
rcall DIVIDE_NUM
mov led_reg, digh	;загружаем частное от деления в регистр
lsl led_reg		;сдвигаем 3 раза
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;разрешаем отображение символов
ldi temp, 0x06		;устанавливаем третий сегмент
add led_reg, temp
rcall SET_NUM	; устанавливаем символ
rcall DELAY		; задержка
;******Правая цифра*****
mov led_reg, digl	;загружаем остаток от деления в регистр
lsl led_reg		;сдвигаем 3 раза
lsl led_reg
lsl led_reg
sbr led_reg, (1<<7)	;разрешаем отображение символов
ldi temp, 0x07		;устанавливаем четвертый сегмент
add led_reg, temp
rcall SET_NUM	; устанавливаем символ
rcall DELAY		; задержка
;***Считаем время***
COUNT:
sbrc key_reg, 1 ; проверяем, что не установлена пауза(0)
rjmp MAIN
sbrs key_reg, 0	; проверяем, что разрешено начало отсчета(1)
rjmp MAIN
ldi temp, 100	;загружаем предельное значение мс
inc ms_reg		;считаем миллисекунды
cpse ms_reg, temp	;пропускаем следующую команду если не равны
rjmp NEXT
clr ms_reg		;обнуляем регистр мс
ldi temp, 60	;загружаем предельное значение с
inc sec_reg ;считаем секунды
cpse sec_reg, temp	;пропускаем следующую команду если не равны
rjmp NEXT
clr sec_reg	;очищаем регистр с
ldi temp, 60	;загружаем предельное значение мин
inc min_reg ;считаем минуты
cpse min_reg, temp	;пропускаем следующую команду если не равны
rjmp NEXT
clr min_reg	;при превышении счета в 60 минут происходит обнуление минут
NEXT:
rjmp MAIN
