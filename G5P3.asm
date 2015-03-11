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
	flag byte 1 dup(0)
	inBuffer byte 30 dup(0)
	firstParam byte 30 dup(0)
	secParam byte 30 dup(0)
	thirdParam byte 30 dup(0)
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
	;mov edi,edx
	mov edi, offset str
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
	add byte ptr [edi],' '			;convert character to lower case
	jmp normCont
normFin:
	pop edi
ENDM
;
;cmpStrFunc
;compares two strings, and if they are equal then executes the function passed to the macro
;Note: second string is a string literal
;@str1 the first string to compare
;@str2 the second string to compare
;@func the function that is to be executed if they come out equal
;
cmpStrFunc MACRO str1,str2,func
	LOCAL text
	LOCAL notEqual			;label doesn't work if you don't declare it as a local variable
	.data
	text byte str2,0		;truncate string literal with a 0
	.code
	mov edi, offset text
	mov esi, offset str1
	call cmpString
	cmp eax,1
	jne notEqual
	mov flag,1				;the function was executed, so set the flag
	call func
notEqual:
	nop
ENDM
;
;nullFill
;fills an array with 0s
;@arr the array to fill
;@size the size of the array
;
nullFill MACRO arr,sizeOfData
	LOCAL loop1
	push edi
	mov edi,0
loop1:
	mov arr[edi],0
	inc edi
	dec sizeOfData
	cmp sizeOfData,0
	jne loop1
	pop edi
ENDM

;
;PROCEDURES
;

;
;getFirstParam
;retrieves the first parameter of the string stored in edi
;stores the first parameter in the byte variable 'firstParam'
;to set up:
;mov edi, offset str
;@return eax=1 if success eax=0 if failure
;
getFirstParam PROC
	LOCAL skipToFirst
	;position edi to the start of the parameter
	mov eax,1
	dec edi			;decrement to account for first inc
gfpskipToFirst:		;set edi to the start of the first letter of the string
	inc edi
	movzx ax,byte ptr [edi]
	cmp ax,' '
	jne gfpskipToFirst
	cmp ax,0
	je gfpError
	;can start copying the string
	inc edi							;increment edi to the next character, it's a space right now
	mov esi, offset firstParam
gfpcopy:
	movzx ax,byte ptr [edi]
	mov [esi],ax
	cmp ax,' '
	je gfpFin
	cmp ax,0
	je gfpFin
	inc edi
	inc esi
	jmp gfpcopy
gfpError:
	mov eax,0
gfpFin:
	ret
getFirstParam ENDP

;
;cmpString procedure
;NOTE: I moved around cmp ah,NULL & cmp ah,al switch them to do an absolute compare
;compares two strings for equality
;@return eax=1 if equal, eax=0 if not equal
;strings must be null terminated
;esi - offset str1
;edi - offset str2
cmpString PROC
Start:	nop
	mov al, byte ptr [esi]
	mov ah, byte ptr [edi]
	cmp ah, NULL		;end of string and equal
	je Equal
	cmp ah, al			;compare chars
	jne NotEqu			;quit early NOTE: will quit if one is NULL and other not		
	inc esi
	inc edi
	jmp Start
	
NotEqu: nop 			;not equal case 
	mov eax,0
	jmp cmpStringFin
Equal:	nop				;equal case
	mov eax,1
cmpStringFin:
	ret
	
cmpString ENDP

;
;switchCmd
;a switch case like statement that compares the
;inBuffer to valid commands
;
switchCmd PROC
	mov flag,0
	cmpStrFunc inBuffer,"quit",exitProgram		;check for exit
	cmpStrFunc inBuffer,"help",dispHelp			;check for help
	cmpStrFunc inBuffer,"load",cmdLoad			;check for load
	cmpStrFunc inBuffer,"run",cmdRun			;check for run
	cmpStrFunc inBuffer,"kill",cmdKill			;check for kill
	cmpStrFunc inBuffer,"show",cmdShow			;check for show
	cmpStrFunc inBuffer,"step",cmdStep			;check for step
	cmpStrFunc inBuffer,"change",cmdChange		;check for change
	cmpStrFunc inbuffer,"hold",cmdHold			;check for hold
	cmp flag,0
	jne switchCmdFin							;falls through if none of the commands were executed
	println "Invalid command entered, enter 'help' for a list of available commands"
switchCmdFin:
	ret
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
;cmdLoad
;needs 3 parameters <name> <priority> <load_time>
;
cmdLoad PROC
	mov eax,30
	nullFill firstParam,eax
	mov edi,offset inBuffer
	call getFirstParam				;retrieve the first parameter
	;mov edx,offset firstParam
	;call WriteString
	ret
cmdLoad ENDP

;
;cmdHold
;needs 1 parameter <name>
;
cmdHold PROC
	println "cmdHold placeholder"
	ret
cmdHold ENDP

;
;cmdRun
;needs 1 parameter <name>
;
cmdRun PROC
	println "cmdRun placeholder"
	ret
cmdRun ENDP

;
;cmdKill
;needs 1 parameter <name>
;
cmdKill PROC
	println "cmdKill placeholder"
	ret
cmdKill ENDP

;
;cmdShow
;0 parameters
;
cmdShow PROC
	println "cmdShow placeholder"
	ret
cmdShow ENDP

;
;cmdStep
;needs 1 parameter <n>
;
cmdStep PROC
	println "cmdStep placeholder"
	ret
cmdStep ENDP

;
;cmdChange
;needs 2 parameters <name> <priority>
;
cmdChange PROC
	println "cmdChange placeholder"
	ret
cmdChange ENDP

;
;main procedure
;
main PROC
MainStart:
	print ":"						;prompt the user for entry
	mov edx, OFFSET inBuffer		;set everything up for ReadString
	mov ecx, sizeof inBuffer
	call ReadString
	normStr inBuffer				;normalize the inBuffer to all lowercase letters
	call switchCmd					;check for the input of a command
	jmp MainStart					;infinite loop until user types 'quit'
main ENDP

END main
