extern MessageBoxA: proc
extern WriteConsoleA: proc
extern ReadConsoleA : proc
extern GetStdHandle : proc
extern srand : proc
extern rand : proc
extern GetTickCount : proc
extern ExitProcess : proc
extern SetConsoleTextAttribute : proc
extern GetConsoleScreenBufferInfo : proc

.data
West DB 16 DUP (?)
North DB 16 DUP (?)
East DB 16 DUP (?)
Player DB 16 DUP (?)
deckSize DB 52

currentPlayer BYTE 3 ;Starting at West
trickNum BYTE 13
trickStarter BYTE -1

WestCards BYTE 13
NorthCards BYTE 13
EastCards BYTE 13
PlayerCards BYTE 13

WestRound BYTE 0
NorthRound BYTE 0
EastRound BYTE 0
PlayerRound BYTE 0

WestPoints DW 0
NorthPoints DW 0
EastPoints DW 0
PlayerPoints DW 0

HeartsBroken BYTE 0
Deck DB 52 DUP (?)
Rank DB "23456789TJQKA",0
Suit DB "CDSH",0
PlayMessage DB 10,"Play a card:",0
InvalidCardMessage DB "Invalid Card. Try Another Card",0
DoNotHaveMessage DB "You do not have that card",0
CanNotPlayMessage DB "You must play a card of the starting suit",0

Buffer DB 2 DUP (?)
Direction BYTE 0 ; LRSN

consoleOutputHandle QWORD ?
consoleInputHandle QWORD ?
InputBuffer BYTE 2 DUP (?)
InputBufferNum BYTE ?
.code

_main PROC
call _initialize
mainLoop:
call _pass
call _play
inc Direction
jmp mainLoop
ret
call ExitProcess
_main ENDP

_initialize PROC
push rbp
mov rbp,rsp
sub rsp,20h

mov rcx,-11
call GetStdHandle
mov consoleOutputHandle,rax
mov rcx,-10
call GetStdHandle
mov consoleInputHandle,rax
lea rdi,Deck
mov rax,0
movzx rcx,deckSize
rep stosb
lea rdi,Deck
mov bl,2
xor bh,bh
thing:
mov [rdi],bl
add [rdi],bh
inc rdi
inc bl
cmp bl,15
jl thing
mov bl,2
add bh,10h
cmp bh,30h
jng thing
lea rdi,Deck


call GetTickCount
mov rcx,rax
call srand
mov r11,52
xor rbx,rbx
xor r12,r12
shuffleLoop:
	call rand
	div r11
	add rdx,rdi
	mov al,[rbx+rdi]
	xchg al,[rdx]
	mov [rbx+rdi],al
	inc rbx
	cmp r11,rbx
jg shuffleLoop
xor rbx,rbx
inc r12
cmp r12,3
jl shuffleLoop


call _deal

add rsp,20h
pop rbp
ret
_initialize ENDP
_deal PROC
lea rsi, Deck
mov rcx,13
lea rdi, East
rep movsb
mov rcx,13
lea rdi, North
rep movsb
mov rcx,13
lea rdi, West
rep movsb
mov rcx,13
lea rdi, Player
rep movsb


ret
_deal ENDP

_printCard PROC
push rbp			; save frame pointer
sub rsp, 30h			; reserve for return and rbp	
xor rbx,rbx
mov rsi,rcx
mov bl,0Fh
and bl,[rsi]
sub bl,2
;mov dh,Rank+bl

lea rax, Rank
	add rax, rbx
	mov dh,[rax]
xor rbx,rbx
mov bl,0F0h
and bl,[rsi]
shr bl,4
;mov dl,Suit+bh

lea rax, Suit
	add rax, rbx
	mov dl,[rax]
mov Buffer,dh
mov [Buffer+1],dl
mov [Buffer+2],32 ;space


;cmp con
mov rcx,rax
mov rdx, 4 ;RED
call SetConsoleTextAttribute

mov rcx, consoleOutputHandle
lea rdx, Buffer
mov r8, 3
mov r9,0
call WriteConsoleA



add rsp, 30h
pop rbp
ret
_printCard ENDP

_pass PROC
;call _sort
ret
_pass ENDP

_play PROC
mov trickNum, 13
mov ax,02h

jz firstPlayerCheck
mov rcx,13
mov currentPlayer,0
lea rdi,West
repnz scasb
jz firstPlayerCheck
mov rcx,13
mov currentPlayer,1
lea rdi,North
repnz scasb
jz firstPlayerCheck
mov rcx,13
mov currentPlayer,2
lea rdi,East
repnz scasb
jz firstPlayerCheck
mov rcx,13
mov currentPlayer,3
lea rdi,Player
repnz scasb

firstPlayerCheck:
nop
call _printMyCards
playLoop:
call _trick

cmp trickNum,0
jg playLoop
ret
_play ENDP
_trick PROC
call _humanPlay
ret
_trick ENDP
_botPlay PROC
ret
_botPlay ENDP
_humanPlay PROC
call _getCard
mov cl,al
mov currentPlayer,3
call _removeCard
ret
_humanPlay ENDP
_getCard PROC
mov rcx, consoleOutputHandle
lea rdx, PlayMessage
mov r8, 13
mov r9,0
call WriteConsoleA
mov rcx,consoleInputHandle
lea rdx,InputBuffer
mov r8, 2
lea r9,InputBufferNum
call ReadConsoleA
mov rcx, 13
lea rdi,Rank
mov al,[InputBuffer]
REPNZ SCASB
jne invalid
mov bl,3Eh
sub bl,cl
mov rcx, 4
lea rdi,Suit
mov al,[InputBuffer+1]
REPNZ SCASB
jne invalid
shl cl,4
sub bl,cl
mov al,bl

mov rcx, QWORD PTR PlayerCards
lea rdi,Player
REPNZ SCASB
jne doNotHave
ret
invalid:
mov rcx, consoleOutputHandle
lea rdx, InvalidCardMessage
mov r8, 30
mov r9,0
call WriteConsoleA
jmp _getCard
doNotHave:
mov rcx, consoleOutputHandle
lea rdx, DoNotHaveMessage
mov r8, 25
mov r9,0
call WriteConsoleA
jmp _getCard
canNotPlay:
mov rcx, consoleOutputHandle
lea rdx, CanNotPlayMessage
mov r8, 41
mov r9,0
call WriteConsoleA
jmp _getCard
_getCard ENDP
_removeCard PROC
mov al,cl
mov rcx,13
mov bl,currentPlayer
imul bx,16
lea rdi,West
add rdi,rbx
REPNZ SCASB
mov rsi,rdi
dec rdi
xor bl,bl
rep movsb
mov [rdi],0
ret
_removeCard ENDP
_printMyCards PROC
xor r12,r12
xor rdx,rdx ;color
tmp:
lea rcx,Player
add rcx,r12
skipColor:
call _printCard
inc rdx
inc r12
cmp r12,QWORD PTR PlayerCards
jnz tmp
ret
_printMyCards ENDP
_sort PROC

ret
_sort ENDP
END