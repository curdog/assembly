 TITLE Group 5 Exam 1 Program
;Exam 1 group 5 program
;
;
Include Irvine32.inc

.386
.model flat
.stack 4096

.data
  buffsize byte 80
  buffer byte 80 dup (0) 
  
  

  promptbeg byte "Enter numbers separated by spaces Q to exit: ",0
  prompterrc byte "Bad char ", 0
  promptend byte "End of Program.  Sum: ",0
  accum dword 0
  charred dword 0
.code
main PROC
;loop start
LOOPT: 
;friendly message
  mov edx, offset promptbeg
  call WriteString
  mov edi, 0
;read input
  mov edx, OFFSET buffer
  mov ecx, sizeof buffer
  call ReadString
;jump quit
  mov ebx, eax
  mov charred, eax
  mov eax,0
  sahf
  cmp ebx,1
  je QCHE
  jmp SLOOP
  QCHE:
  cmp buffer[edi],'Q'
  je ENDL
 
  
SLOOP:
mov eax,0
;more data
MDLOOP:
mov ebx,0
PNLOOP: nop
  mov edi,eax
  
  cmp buffer[edi], ' '
  je ADDAC
  push eax
  mov eax,0
  mov al, buffer[edi]
  mov ecx, eax
  
  ;check for number col
  and ecx, 30h
  cmp ecx, 30h
  jne Error
  
  ;check for number row
  and eax, 0Fh
  cmp eax, 9
  jg Error

  ;shift and add
  imul ebx, 10
  add ebx,eax
  ;restore index
  pop eax
  inc eax
  cmp eax, charred
  jl PNLOOP
jmp ADDAC
Error:
pop eax
mov edx, offset prompterrc
call WriteString
ADDAC:
;add into acc
add accum,ebx
inc eax ;skip space or bad data
cmp eax, charred
jl MDLOOP

;clear array
  mov edi, 0
CLRA: nop
  mov buffer[edi],0
  add edi,1
  cmp edi, 80
  jne CLRA
;quit
jmp LOOPT
ENDL: nop

mov edx, offset promptend
call WriteString

mov eax,accum
call WriteInt

TITLE Assembly Program 1  by Group 3

; Description:    Assembly Program 1
; Class:          CSC
; Members:        Sean Curtis, Max Conroy, John Kirshner
; Revision date:  2/2

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
shead dword 0
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

.code

;
;main procedure
;
main PROC
;title/desc
	call Clrscr
;start loop
Begin:
	mov edx, offset promptMenu
	call WriteString
	
  mov edx, OFFSET buffer
  mov ecx, sizeof buffer
	call ReadString		;get input in eax
	call checkOp		;test to see if it was a valid input
	cmp eax,'q'
	je Fin
	cmp eax,'Q'
	je Fin
	cmp ebx,0			;check to see if there was an invalid input
	je ShowInvalid
	jmp Begin			;continue the loop until user exists
ShowInvalid:
	mov eax, offset promptInvalid
	call WriteString
	jmp Begin

;keep the program open so user has the time to 
;think about what he has done. 
Fin:
	call Crlf
	call WaitMsg
	mov edx, offset buffer
	mov ecx, sizeof buffer
	call ReadString
	INVOKE ExitProcess,0
main ENDP

;
;pop procedure
;result in eax
;
popfunc PROC 
	cmp shead, 0
	push edi
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
	ret
ERROR: nop
	pop edi
	;setc
	ret
popfunc ENDP

;push MACRO
;push in eax
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

	call popfunc
	mov ebx,eax
	call popfunc
	add eax, ebx
	call pushs

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

	call popfunc
	mov ebx,eax
	call popfunc
	sub eax, ebx
	call pushs

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
	push edi

	call popfunc
	mov ebx,eax
	call popfunc
	idiv eax
	call pushs

	pop edi
	pop ebx
	pop eax
	ret
divs ENDP

;
;mul macro
;
muls PROC

muls ENDP

;
;exch macro
;
exchs PROC

exchs ENDP

;
;neg macro
;
negs PROC

negs ENDP

;
;roll up macro
;
rollu PROC

rollu ENDP

;
;roll down
;
rolld PROC

rolld ENDP

;
;view stack macro
;
views PROC

views ENDP

;
;clear stack macro
;
clears PROC

clears ENDP

;
;stahp procedure
;
stahp PROC

stahp ENDP


;ckEqual
;checks to see if a value, in eax, is equal to the value inputted
ckEqual MACRO char, func
  LOCAL nit
  cmp eax,char
  jnz nit
  call func
  ;jmp fin
  nit:
ENDM

;check if an ascii value is a valid operation
;valid operations: +,-,*,/,X,N,U,D,V,C,Q
;input is in eax
;@return 1 in ebx if value is digit, otherwise 0
checkOp PROC
  mov ecx,0
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
;check for 'Q' or 'q'
  ckEqual 'Q', stahp
  ckEqual 'q', stahp
;check to see if the zero bit was set at any point
  cmp ecx,64h
  jz  valid
invalid:
  mov ebx,0
  jmp fin
valid:
  mov ebx,1
fin:
  ret
checkOp ENDP

END main
call Crlf
call WaitMsg

exit
main ENDP
END main
