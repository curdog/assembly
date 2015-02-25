TITLE Assembly Program 1  by Group 3

; Description:    Assembly Program 1
; Class:          CSC
; Members:        Sean Curtis, Max Conroy, John Kirshner
; Revision date:  2/23

Include Irvine32.inc
.386
.model flat, stdcall
ExitProcess PROTO, dwExistCode:DWORD
.data
STACKDATASIZE equ 4
CR equ 0Dh
LF equ 0Ah
buffersize equ 41

dstack dword 8 DUP(0)
tempstack dword 8 DUP(0)				;for rolling
buffer byte buffersize dup(0)
promptMenu byte "Enter an input to add onto the stack",LF,CR,
	"+ - * /: relative mathematical operations",LF,CR,
	"X: exchange top two elements of the stack",LF,CR,
	"N: negate top element of stack",LF,CR,
	"U: roll the stack up",LF,CR,
	"D: roll stack down",LF,CR,
	"V: view all 8 elements of the stack",LF,CR,
	"C: clear the stack",LF,CR,
	"Q: quit the program",LF,CR,0

promptInvalid byte "Invalid input",LF,CR,0
promptError byte "Error processing request",LF,CR,0
charred dword 0
shead dword -1
.code

;
;main procedure
;
main PROC
;start loop
Begin:
	mov edx, offset promptMenu
	call WriteString					;display the input menu

	mov edx, OFFSET buffer
	mov ecx, sizeof buffer
	call ReadString	
	mov charred,eax						;get user input in eax
	movzx eax, buffer[0]
	cmp eax,'q'
	je Fin
	cmp eax,'Q'
	je Fin

	call checkOp		;test to see if it was a valid input

	cmp ebx,2			;check to see if there was an invalid input
	je ShowInvalid
	cmp ebx,1
	je PushNumber			;check for number
	jmp Begin			;continue the loop until user exists
ShowInvalid:
	mov edx, offset promptInvalid
	call WriteString
	jmp Begin
PushNumber:
	call pushs
	jmp Begin
Fin:
	INVOKE ExitProcess,0
main ENDP

;
;pop procedure
;result in eax
;
popfunc PROC
	push ebx

	cmp shead,0
	jl ERROR						;check if shead is 0 then error if its less then
	mov eax, shead					;have to use eax because of imul
	dec shead						;remember to decrement
	imul eax,STACKDATASIZE
	mov ebx,dstack[eax]				;store at temp register
	mov dstack[eax],0				;clear contents of stack that we popped
	mov eax,ebx						;will return eax
	jmp Cont
ERROR: nop
	call dispError
Cont:
	pop ebx
	ret
popfunc ENDP

;
;push MACRO
;push in eax
;
pushs PROC
	push edi
	push eax
	mov eax,shead
	inc eax
;check size
	cmp eax, 8
	jge ERROR
	mov shead,eax
	imul eax, STACKDATASIZE
	mov edi,eax
	pop eax
	mov dstack[edi], eax
	pop edi
	clc
	jmp ENDQ
ERROR: nop
	pop eax
	pop edi
	stc
ENDQ:nop
	ret
pushs ENDP

;
;add function
;
adds PROC
	push eax
	push ebx
	push edi

	;check if there are at least two items in the stack
	cmp shead,1
	jl AddsFin
	call popfunc
	mov ebx,eax
	call popfunc
	add eax, ebx
	call pushs

AddsFin:
	pop edi
	pop ebx
	pop eax
	ret
adds ENDP

;
;subs macro
;
subs PROC
	push eax
	push ebx
	push edi

	;check if there are at least two items in the stack
	cmp shead,1
	jl SubsFin
	call popfunc
	mov ebx,eax
	call popfunc
	sub eax, ebx
	call pushs

SubsFin:
	pop edi
	pop ebx
	pop eax
	ret
subs ENDP

;
;div macro
;
divs PROC
	push eax
	push ebx
	push ecx
	push edx
	push edi

	;check if there are at least two items in the stack
	cmp shead,1
	jl DivsFin
	;ready for idiv
	mov edx, 0
	call popfunc
	mov ecx,eax
	call popfunc
	mov ebx,eax
	mov eax, ecx
	idiv ebx
	call pushs

DivsFin:
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
divs ENDP

;
;mul macro
;
muls PROC
	push eax
	push ebx
	push ecx
	push edx
	push edi

	;check if there are at least two items in the stack
	cmp shead,1
	jl MulsFin
	;ready for imul
	call popfunc
	mov edx,eax
	call popfunc
	imul eax,edx
	call pushs
	
MulsFin:
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
muls ENDP

;
;exch macro
;
exchs PROC
	push eax
	push ebx
	push ecx
	
	mov eax,0
	call popfunc
	mov ebx,eax
	call popfunc
	mov ecx,eax
	mov eax,ebx
	call pushs
	mov eax,ecx
	call pushs

exit_exchange:
	pop ecx
	pop ebx
	pop eax
	ret
exchs ENDP

;
;neg macro
;
negs PROC
push eax
mov eax,0
call popfunc
neg eax
call pushs
pop eax
ret
negs ENDP

;
;roll up procedure
;
rollu PROC
pushad
mov esi,0
mov edx,0

rollit:
	mov eax,dstack[esi]
	mov dstack[esi],edx
	mov edx,eax
	add esi, sizeof sdword
	cmp esi,STACKDATASIZE*sizeof sdword
	je onemore
	jmp rollit
	
onemore:
	mov esi,0
	mov dstack[esi],edx

popad
ret
rollu ENDP

;
;roll down
;
rolld PROC
	push eax
	push ebx
	push ecx
	push edx
	push esi
	
	call popfunc		;pop the top element of the stack off to put into the first stack
	push eax			;temporarily push the contents of the top of the stack into the stack
	mov edx,shead		;the index will be in edx
ShiftDown:
	imul edx,STACKDATASIZE				;calculate the offset
	mov ebx,eax							;copy the contents into ebx so you can copy the offset as well
	sub ebx,STACKDATASIZE				;subtract the offset value for the next stack value
	mov ebx,dstack[ebx]
	mov dstack[eax],ebx					;exchange the top elements
	dec edx
	cmp edx,1
	jge ShiftDown
	pop ecx				;pull the temp stack data from the stack
	mov dstack[0],ecx

RolldFin:
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
rolld ENDP

;
;view stack macro
;prints out the contents of the stack
;
views PROC
	push eax
	push esi

	mov esi,0
PopStack:
	mov eax, esi
	imul eax,STACKDATASIZE		;calculate for the next esi result in eax
	mov eax,dstack[eax]			;grab the contents at the index specified
	call WriteInt				;display the contents of the stack
	call Crlf
	inc esi
	cmp esi,8					;are we at the end of the stack
	jl PopStack

	pop esi
	pop eax
	ret
views ENDP

;
;clear stack macro
;
clears PROC
	push eax
	push esi

	mov esi,0
ClrStack:
	mov eax,esi
	imul eax,STACKDATASIZE		;calculate for the next esi result in eax
	mov dstack[eax],0			;grab the contents at the index specified
	inc esi
	cmp esi,8					;are we at the end of the stack
	jl ClrStack
	mov shead,-1				;reset the stack index

	pop esi
	pop eax
	ret
clears ENDP

;
;stahp procedure
;empty procedure for a placeholder for the exit function
;
stahp PROC
stahp ENDP

;
;dispError
;displays that an error was encountered during processing
;
dispError PROC
	push edx
	mov edx,offset promptError
	call WriteString
	pop edx
dispError ENDP


;ckEqual
;checks to see if a value, in eax, is equal to the value inputted
ckEqual MACRO char, func
  LOCAL nit
  cmp eax,char
  jnz nit
  call func
  call main
  nit:
ENDM

;check if an ascii value is a valid operation
;valid operations: +,-,*,/,X,N,U,D,V,C,Q
;input is in eax
;@return value in eax if value is digit, 2 in ebx if not a number
checkOp PROC
push edi
 ;get top of buffer
  mov edi,0
  movzx eax, buffer[edi]
;check for '+'
  ckEqual '+', adds
;check for '-'
  ckEqual '-', subs
;check for *
  ckEqual '*', muls
;check for /
  ckEqual '/', divs
;check for 'X' or 'x'
  ckEqual 'X', exchs
  ckEqual 'x', exchs
;check for 'N' or 'n'
  ckEqual 'N', negs
  ckEqual 'n', negs
;check for 'U' or 'u'
  ckEqual 'U', rollu
  ckEqual 'u', rollu
;check for 'D' or 'd'
  ckEqual 'D', rolld
  ckEqual 'd', rolld
;check for 'V' or 'v'
  ckEqual 'V', views
  ckEqual 'v', views
;check for 'C' or 'c'
  ckEqual 'C', clears
  ckEqual 'c', clears

  push edx
 ;check digit
  mov edi, 0
  mov edx, 0
PNLOOP: nop
  mov eax,0
  mov al, buffer[edi]
  mov ecx, eax
  
  ;check for number col
  and ecx, 30h
  cmp ecx, 30h
  jg invalid
  
  ;check for number row
  and eax, 0Fh
  cmp eax, 9
  jg invalid

  ;arrrrr there be a digit!
  mov ebx, 1

  ;shift and add
  imul edx, 10
  add edx,eax
  inc edi
  cmp edi, charred
  jl PNLOOP
  mov eax, edx
  pop edx
  jmp fin
invalid:
  mov ebx,2
  jmp fin
valid:
  mov ebx,0
fin:
  
  call WriteInt
  pop edi
  ret
checkOp ENDP

END main
