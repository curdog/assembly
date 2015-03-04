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
	CR equ 0Dh
	LF equ 0Ah
	cmdQuit byte "quit",0
	cmdHelp byte "help",0
	cmdLoad byte "load",0
	cmdRun byte "run",0
	cmdKill byte "kill",0
	cmdShow byte "show",0
	cmdStep byte "step",0
	cmdChange byte "change",0
	inBuffer byte 30 dup(0)
	helpMenu byte "Here are commands ,their parameters, and what they do",CR,LF,
		"Quit: quits the program",CR,LF,
		"Help: displays this help prmopt",CR,LF,
		"Load <name> <priority> <run_time>: loads a program into memory",CR,LF,
		"Run <name>: runs a program that has been loaded into memory",CR,LF,0
	helpMenu2 byte "Hold <name>: holds up a program's processing, can continue later",CR,LF,
		"Kill <name>: kills a program that is in hold mode",CR,LF,
		"Show: shows processes and their status",CR,LF,
		"Step <n>: steps n cycles to further jobs",CR,LF,
		"Change <name> <priority>: changes the priority of a process",CR,LF,0
	errorMsg byte "An error occured while processing your request",CR,LF,0
	errorMsgInput byte "You have entered an invalid command",CR,LF,0
.code
;macros

;
;print
;takes in a string literal and prints it out
;@text a string literal to pass
;
print MACRO text
	LOCAL str
	.data
	str byte text,0
	.code
	mov edx, offset str
	call WriteString
ENDM

;
;println
;takes in a string literal and prints it out along with a CR and LF
;@text a string literal to pass
;
println MACRO text
	LOCAL str
	.data
	str byte text,0Dh,0Ah,0
	.code
	mov edx, offset str
	call WriteString
ENDM

;
;normStr
;converts all characters in the string to lowercase
;
normStr MACRO str
	push edi
mov edi, edx
	dec edi			;decrement because the first instruction is increment
normCont:
	inc edi
	cmp byte ptr [edi],'Z'			;compare to 'Z'
	jg normCont			;is a lower case letter, or the ascii values that don't get manipulated, regardless, no action
	cmp byte ptr [edi],'A'			;compare to 'A'
	jge normMask		;is an uppercase letter and needs masked
	cmp byte ptr [edi],0			;is a null terminator 
	je normFin
	jmp normCont		;you aren't finished processing the string and need to continue
normMask:
	add byte ptr [edi],' '
	jmp normCont
normFin:
	pop edi
ENDM

;
;cmpString macro
;compares two strings zf = 0 equal zf = 1 not equal
;strings must be null term
; esi - str1 base
; edi - str2 base
;WARNING: function contains multiple exit points
cmpString PROC
	pushad
Start:	nop
	mov al, [esi]
	mov ah, [edi]
	cmp ah, al		;compare chars
	jne NotEqu		;quit early NOTE: will quit if one is NULL and other not
	cmp ah, NULL		;end of string and equal
	je Equal		
	inc esi
	inc edi
	jmp Start
	
NotEqu: nop 			;equal case
	popad
	;sez
	ret
	
Equal:	nop			;not equal case
	popad
	;clz
	ret
	
cmpString ENDP

;
;switchCmd
;a switch case like statement that compares the
;input buffer to valid commands
;
switchCmd PROC
	;check for exit
switchCmd ENDP

;
;exitProgram
;exits the program
;put into a function because of check equality macro
;
exitProgram PROC
	INVOKE ExitProcess,0
exitProgram ENDP


;
;dispHelp procedure
;prints out the help menu
;shows each job, their parameters, and their purpose
;
dispHelp PROC
	push edx
	mov edx,offset helpMenu
	call WriteString
	mov edx,offset helpMenu2
	call WriteString
	pop edx
	ret
dispHelp ENDP

;
;dispErrorMsg
;displays a general purpose error message
;
dispErrorMsg PROC
	push edx
	mov edx,offset errorMsg
	call WriteString
	pop edx
	ret
dispErrorMsg ENDP

;
;main procedure
;
main PROC
MainStart:
	call dispHelp
	mov edx, OFFSET inBuffer		;set everything up for ReadString
	mov ecx, sizeof inBuffer
	call ReadString
	normStr inBuffer				;normalize the inBuffer to all lowercase letters
	mov edx, offset inBuffer
	call WriteString
	call Crlf
	jmp MainStart					;infinite loop until user types 'quit'
main ENDP

END main
