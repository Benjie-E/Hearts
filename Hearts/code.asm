extern WriteConsoleA: proc
extern ReadConsoleA : proc
extern GetStdHandle : proc
;
extern ExitProcess : proc
extern SetConsoleTextAttribute : proc
extern GetConsoleScreenBufferInfo : proc
extern Sleep : proc

.data
West DB 16 DUP (?)
North DB 16 DUP (?)
East DB 16 DUP (?)
Player DB 16 DUP (?)
DeckSize DB 52

CurrentPlayer BYTE 3 ;Starting at West
TrickNum BYTE 13

WestCards BYTE 13
NorthCards BYTE 13
EastCards BYTE 13
PlayerCards BYTE 13

WestRound BYTE 0
NorthRound BYTE 0
EastRound BYTE 0
PlayerRound BYTE 0

WestPoints BYTE 0
NorthPoints BYTE 0
EastPoints BYTE 0
PlayerPoints BYTE 0

HighCard BYTE 0
HighPlayer BYTE 0
TrickPoints BYTE 0
HeartsBroken BYTE 0

Deck DB 52 DUP (?)
Rank DB "23456789TJQKA",0
Suit DB "CDSH",0
PlayMessage DB "Play a card:",0
InvalidCardMessage DB "Invalid Card. Try Another Card",0
DoNotHaveMessage DB "You do not have that card",0
CanNotPlayMessage DB "You must play a card of the starting suit",0
NewLine DB 13,10,0

WestMessage DB 13,"West Plays:",0
NorthMessage DB "North Plays:",0
EastMessage DB 13,"East Plays:",0

WestName DB 13,"West",0
NorthName DB "North",0
EastName DB 13,"East",0
PlayerName DB 13,13,"You",0

TrickMessage DB " wins the trick!",0

PointsMessage DB " gets ",0
PointsMessage2 DB " points and now has a total of ",0

MoonMessage DB " shot the moon and gets 0 points! Everyone else gets 26 points.",0

PassingPhase DB 0

PassMessage DB "Choose 3 cards to pass ",0
LeftMessage DB "to your Left",0
RightMessage DB "to the Right",0
StraightMessage DB "straight now"

Buffer DB 4 DUP (?)
Direction DB 0 ; LRSN

ConsoleOutputHandle QWORD ?
ConsoleInputHandle QWORD ?
InputBuffer BYTE 2 DUP (?)
InputBufferNum BYTE ?

print MACRO string,length
	mov rcx, ConsoleOutputHandle
	lea rdx, string
	mov r8, length
	mov r9,0
	call WriteConsoleA
ENDM
.code

_main PROC
call _initialize
mainLoop:
call _handInitialize
call _play
inc Direction
jmp mainLoop
call ExitProcess
_main ENDP

_initialize PROC
push rbp
mov rbp,rsp
sub rsp,20h

mov rcx,-11
call GetStdHandle
mov ConsoleOutputHandle,rax
mov rcx,-10
call GetStdHandle
mov ConsoleInputHandle,rax

add rsp,20h
pop rbp
ret
_initialize ENDP
_getRand PROC
push rcx
push rbx
xor rdx,rdx
mov rbx,rcx
rdtsc
xor rdx,rdx
nop
div rbx
mov rax,rdx
pop rbx
pop rcx
ret
_getRand ENDP
_handInitialize PROC
push rbp
mov rbp,rsp
sub rsp,20h

lea rdi,Deck
mov rax,0
movzx rcx,DeckSize
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


mov r11,52
xor rbx,rbx
xor r12,r12
mov rcx,52
shuffleLoop:
	call _getRand
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
cmp r12,10
jl shuffleLoop


call _deal

mov WestCards,13
mov NorthCards,13
mov EastCards,13
mov PlayerCards,13

mov WestRound,0
mov NorthRound,0
mov EastRound,0
mov PlayerRound,0

call _sort
add rsp,20h
pop rbp
ret
_handInitialize ENDP

_deal PROC

lea rsi, Deck
mov rcx,13
lea rdi, West
rep movsb
mov rcx,13
lea rdi, North
rep movsb
mov rcx,13
lea rdi, East
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
mov bl,0Fh
and bl,cl
sub bl,2

lea rax, Rank
	add rax, rbx
	mov dh,[rax]
xor rbx,rbx
mov bl,0F0h
and bl,cl
shr bl,4

lea rax, Suit
	add rax, rbx
	mov dl,[rax]
mov Buffer,dh
mov [Buffer+1],dl
mov [Buffer+2],32 ;space

call _checkIfPlayable
cmp rax,0
je colorSkip
mov rcx,ConsoleOutputHandle
mov rdx, 8F04h ;HIGHLIGHT
call SetConsoleTextAttribute
colorSkip:
print Buffer,3

mov rcx,ConsoleOutputHandle
mov rdx, 07h ;HIGHLIGHT OFF
call SetConsoleTextAttribute

add rsp, 30h
pop rbp
ret
_printCard ENDP

_checkIfPlayable PROC ;;Need to fix for hearts and first card 2C
push rbp
push rdi
push rcx
sub rsp, 10h
xor rax,rax
cmp PassingPhase,1
je canPlay
mov dl,HighCard
and dl,0F0h
cmp dl,80h ; first card of round
je twoOfClubs
and cl, 0F0h
cmp dl,40h
je heartsBrokenCheck ;first card of trick
cmp cl,dl
je canPlay ;same suit
movzx rdx, CurrentPlayer 
lea r9, WestCards 
add r9,rdx
xor rcx,rcx
mov cl,[r9] ;amount of cards in hand
lea rdi,West
imul rdx,16
add rdi,rdx
mov dl,0f0h
and dl, HighCard
playableLoop:
mov dh,0f0h
and dh,BYTE PTR [rdi]
cmp dl,dh
je playableReturn
inc rdi
loop playableLoop
jmp canPlay
playableReturn:
add rsp, 10h
pop rcx
pop rdi
pop rbp
ret
canPlay:
inc rax
jmp playableReturn
twoOfClubs:
cmp cl,02h
je canPlay
jmp playableReturn
heartsBrokenCheck:
cmp cl,30h
jne canPlay
cmp HeartsBroken,0
je playableReturn
jmp canPlay
_checkIfPlayable ENDP
_addCardToPlayer PROC ;(player,card)
lea rdi,West
mov rax,rcx
imul ax,16
add rdi,rax
mov al, 0ffh
mov rcx,16
repnz scasb
dec rdi
mov [rdi],dl
ret
_addCardToPlayer ENDP
_pass PROC
call _sort
mov PassingPhase,1
cmp Direction,3
je passSkip
call _printMyCards
print PassMessage,23
mov rax, 13
mul Direction
movzx rsi, LeftMessage
print [rsi],12
print NewLine,2
cmp Direction,0
je LeftPass
cmp Direction,0
je RightPass
cmp Direction,0
je StraightPass
call _getCard
mov dl,al
mov cl,2
call _addCardToPlayer
call _getCard
call _getCard
passSkip:
mov PassingPhase,0
ret
LeftPass:
RightPass:
StraightPass:
_pass ENDP

_play PROC
mov HeartsBroken,0
mov TrickNum, 13
mov ax,02h

mov rcx,13
mov CurrentPlayer,0
lea rdi,West
repnz scasb
jz firstPlayerCheck
mov rcx,13
mov CurrentPlayer,1
lea rdi,North
repnz scasb
jz firstPlayerCheck
mov rcx,13
mov CurrentPlayer,2
lea rdi,East
repnz scasb
jz firstPlayerCheck
mov rcx,13
mov CurrentPlayer,3
lea rdi,Player
repnz scasb

firstPlayerCheck:
mov TrickNum,13
mov HighCard,80h
playLoop:
call _trick
xor rcx,rcx
mov cl,HighPlayer
mov dl,TrickPoints
mov CurrentPlayer,cl
lea rdi,WestRound
add rdi, rcx
add [rdi],dl

call _endOfTrickPrint
dec TrickNum
cmp TrickNum,0
jg playLoop
call _endOfRound
ret
_play ENDP

_endOfRound PROC
xor rcx,rcx
cmp WestRound,26
je shootTheMoon
inc rcx
cmp NorthRound,26
je shootTheMoon
inc rcx
cmp EastRound,26
je shootTheMoon
inc rcx
cmp PlayerRound,26
je shootTheMoon

xor rbx,rbx
xor rax,rax
endOfRoundLoop:
lea rdx, WestName
mov al,6
mul bl
add rdx,rax
print [rdx],5

print PointsMessage, 6

mov rcx,1
lea rdi,Buffer
lea rsi,WestRound
add rsi,rbx
xor ax,ax
mov al,[rsi]

lea rsi,WestPoints
add rsi,rbx
add [rsi],al

mov dh,10
div dh
add al,30h
mov [Buffer+0],al

mov al,ah
xor ah,ah

inc rcx
div dh
add ah,30h
mov [Buffer+1],ah

print Buffer,2
print PointsMessage2,31

mov al,[rsi]
mov dh,10
div dh
add al,30h
mov [Buffer+0],al

mov al,ah
xor ah,ah

div dh
mov al,ah
add ah,30h
mov [Buffer+1],ah

xor ah,ah

div dh
add ah,30h
mov [Buffer+2],ah
print Buffer, 3
print NewLine, 2
inc rbx
cmp rbx,4
jl endOfRoundLoop
xor rax,rax
ret
shootTheMoon:
lea rdx, WestName
mov al,6
mul cl
add rdx,rax
print [rdx],5

print MoonMessage,63

print NewLine,2
xor rax,rax
ret
_endOfRound ENDP
_endOfTrickPrint PROC ;(player,points)

lea rdx, WestName
mov al,6
mul cl
add rdx,rax
print [rdx],5

print TrickMessage,16
print NewLine,2

ret
_endOfTrickPrint ENDP
_trick PROC
cmp HighCard,80h
je firstCardTrick
mov HighCard,40h
firstCardTrick:
mov TrickPoints,0
mov rcx,4
trickLoop:
cmp CurrentPlayer,3
jng trickNotOver
mov CurrentPlayer,0
trickNotOver:
je trickEqual

call _botPlay
trickEnd:
inc CurrentPlayer
loop trickLoop
ret
trickEqual:
;mov HighCard
call _humanPlay
jmp trickEnd
_trick ENDP
_botPrint PROC
push rcx
mov bl,cl
lea rdx, WestMessage
mov rax,13
mul CurrentPlayer
add rdx,rax
print [rdx],12
mov cl,bl
call _printCard

print NewLine,2
pop rcx
ret
_botPrint ENDP
_botPlay PROC
push rbp
push rcx
sub rsp,20h
mov rcx,500
call Sleep ;SLEEP

lea rdi,West
movzx rax,CurrentPlayer
imul ax,16
add rdi,rax
botLoop:
mov cl,[rdi]
call _checkIfPlayable
inc rdi
cmp rax,1
jne botLoop
call _removeCard
call _botPrint
call _addToTrick

add rsp,20h
pop rcx
pop rbp
ret
_botPlay ENDP
_humanPlay PROC
push rbp
push rcx
sub rsp,20h

mov rcx,1000
call Sleep ;SLEEP

call _printMyCards
call _getCard
mov cl,al
call _removeCard
mov cl,al
call _addToTrick

add rsp,20h
pop rcx
pop rbp
ret
_humanPlay ENDP
_addToTrick PROC
cmp HighCard,40h
je firstCardAdd
mov al,cl
and al,30h
mov bl,HighCard
and bl,30h
cmp al, bl
jne worse
cmp cl,HighCard
jl worse
firstCardAdd:
mov al,CurrentPlayer
mov HighPlayer, al
mov HighCard, cl
worse:
cmp cl,30h
jl pointSkip
inc TrickPoints
inc HeartsBroken
pointSkip:
cmp cl,2Ch ;Queen of Spades
jne queenSkip
add TrickPoints,13
queenSkip:

ret
_addToTrick ENDP
_getCard PROC
print PlayMessage,13
mov rcx,ConsoleInputHandle
lea rdx,InputBuffer
mov r8, 4
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
mov cl,al
call _checkIfPlayable
cmp al,0
je canNotPlay
mov al,cl
movzx rcx, PlayerCards
lea rdi,Player
REPNZ SCASB
jne doNotHave
ret
invalid:
print InvalidCardMessage,30
print NewLine,2
jmp _getCard
doNotHave:
print DoNotHaveMessage,25
print NewLine,2
jmp _getCard
canNotPlay:
print CanNotPlayMessage,41
print NewLine,2
jmp _getCard
_getCard ENDP
_removeCard PROC
push rbp
push rcx
sub rsp,20h
mov al,cl
mov rcx,13
xor rbx,rbx
mov bl,CurrentPlayer
imul rbx,16
lea rdi,West
add rdi,rbx
REPNZ SCASB ;;; breaks on this
mov rsi,rdi
dec rdi
xor bl,bl
rep movsb
xor cl,cl
mov [rdi], cl
lea rbx,WestCards
movzx rcx, CurrentPlayer
add rbx, rcx
dec BYTE PTR [rbx]
add rsp,20h
pop rcx
pop rbp
ret
_removeCard ENDP
_printMyCards PROC
xor r12,r12
tmp:
lea rcx,Player
add rcx,r12
mov cl,[rcx]
call _printCard
inc rdx
inc r12
movzx r9,PlayerCards
cmp r12, r9
jnz tmp
print NewLine,2
ret
_printMyCards ENDP
_sort PROC
    mov bl, 12      ; Outer loop iteration count
OuterLoop:
	lea rsi,Player

    mov cl, bl       ; Inner loop iteration count
InnerLoop:
    lodsb
    mov dl, [rsi]
    cmp al, dl
    jbe Skip
    mov [rsi-1], dl   ; Swap these 2 elements
    mov [rsi], al
Skip:
    dec cl
    jnz InnerLoop

    dec bl
    jnz OuterLoop


ret
_sort ENDP
_passShuffle PROC
xor r9,r9
passShuffleOuterLoop:
lea rdi,West
mov r11,13
xor rbx,rbx
xor r12,r12
mov rcx,r11
passShuffleLoop:
	call _getRand
	div r11
	add rdx,rdi
	mov al,[rbx+rdi]
	xchg al,[rdx]
	mov [rbx+rdi],al
	inc rbx
	cmp r11,rbx
jg passShuffleLoop
xor rbx,rbx
inc r12
cmp r12,10
jl passShuffleLoop
inc r9
add rdi,10h
cmp r9,3
jl passShuffleOuterLoop
ret
_passShuffle ENDP
END