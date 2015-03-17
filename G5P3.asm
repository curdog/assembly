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
	byteTemp byte 1 dup(0)
	wordTemp word 1 dup(0)
	priority equ 11				;priority contains 1 byte	(byte 1)
	hold equ 12					;hold contains 1 byte		(byte 2)
	runtime equ 13				;runtime contains a word	(byte 3-4)
	namesize equ 0				;namesize contains 10 bytes	(byte 5-15)
	indexsize equ 15			;size of each data structure index
	program byte 1400 dup(0)
	index byte 1 dup(0)
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
;skipWhiteSpace
;@edi the pointer to the string you need to skip over whitespace
;
skipWhiteSpace PROC
	dec edi
skipWhite:
	inc edi
	movzx eax,byte ptr [edi]
	cmp eax,' '				;check if edi's contents are equal to space
	je skipWhite
	cmp eax,'	'			;check if edi's contents are equal to tab
	je skipWhite
	ret
skipWhiteSpace ENDP

;
;nullParams
;fills the parameter variables with 0s
;
nullParams PROC
	mov eax,30
	nullFill firstParam,eax
	mov eax,30
	nullFill secParam,eax
	mov eax,30
	nullFill thirdParam,eax
	ret
nullParams ENDP

;
;getSecondParam
;retrieves the first parameter of the string stored in edi
;stores the first parameter in the byte variable 'firstParam'
;to set up:
;mov edi, offset str
;@return ebx=1 if success ebx=0 if failure
;@return ecx=1 if not end of string ecx=0 if end of string
;
getSecondParam PROC
	;position edi to the start of the parameter
	mov ebx,1
	mov ecx,1
	dec edi			;decrement to account for first inc
gspskipToFirst:		;set edi to the start of the first letter of the string
	inc edi
	movzx ax,byte ptr [edi]
	cmp ax,' '
	jne gspskipToFirst
	cmp ax,0
	je gspError
	;can start copying the string
	inc edi							;increment edi to the next character, it's a space right now
	mov esi, offset secParam
gspcopy:
	movzx ax,byte ptr [edi]
	mov [esi],ax
	cmp ax,' '
	je gspFin
	cmp ax,0
	je gspEndOfString
	inc edi
	inc esi
	jmp gspcopy
gspError:
	mov ebx,0
	jmp gspFin
gspEndOfString:
	mov ecx,0
gspFin:
	ret
getSecondParam ENDP

;
;getFirstParam
;retrieves the first parameter of the string stored in edi
;stores the result in the variable pointed to by esi
;to set up:
;mov edi, offset str
;mov esi, offset paramVariable
;mov edx, param to get (1,2,or 3)
;@return ebx=1 if success ebx=0 if failure
;@return ecx=1 if not end of the string ecx=0 if end of string
;
getFirstParam PROC
	;position edi to the start of the parameter
	mov ebx,1
	mov ecx,1
gotovar:
	call skipWhiteSpace
	dec edi			;decrement to account for first inc
gfpskipToFirst:		;set edi to the start of the first letter of the string
	inc edi
	movzx ax,byte ptr [edi]
	cmp ax,' '
	jne gfpskipToFirst
	cmp ax,0
	je gfpEndOfString
	;can start copying the string
	call skipWhiteSpace						;skip da white space
	dec edx
	cmp edx,0
	jne gotovar
gfpcopy:
	movzx ax,byte ptr [edi]
	mov [esi],ax
	cmp ax,' '			;compare to space
	je gfpFin
	cmp ax,'	'		;compare to tab
	je gfpFin
	cmp ax,0			;compare to null
	je gfpEndOfString
	inc edi
	inc esi
	jmp gfpcopy
gfpError:
	mov ebx,0
	jmp gfpFin
gfpEndOfString:
	mov ecx,0
gfpFin:
	ret
getFirstParam ENDP

;
;getThirdParam
;retrieves the third parameter of the string stored in edi
;stores the first parameter in the byte variable 'thirdParam'
;to set up:
;mov edi, offset str
;@return ebx=1 if success ebx=0 if failure
;
getThirdParam PROC
	;position edi to the start of the parameter
	mov ebx,1
	dec edi			;decrement to account for first inc
gtpskipToFirst:		;set edi to the start of the first letter of the string
	inc edi
	movzx ax,byte ptr [edi]
	cmp ax,' '
	jne gtpskipToFirst
	cmp ax,0
	je gtpError
	;can start copying the string
	inc edi							;increment edi to the next character, it's a space right now
	mov esi, offset thirdParam
gtpcopy:
	movzx ax,byte ptr [edi]
	mov [esi],ax
	cmp ax,' '
	je gtpFin
	cmp ax,0
	je gtpFin
	inc edi
	inc esi
	jmp gtpcopy
gtpError:
	mov ebx,0
gtpFin:
	ret
getThirdParam ENDP

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
;getOneParam
;retrieves one parameter and stores it in firstParam
;
getOneParam PROC
	mov eax,30
	nullFill firstParam,eax
	mov edi, offset inBuffer
	call skipWhiteSpace			;skip the initial whitespace
	call getFirstParam
	cmp ebx,0
	je firstParamError
	movzx eax,inBuffer[5]
	cmp inBuffer[5],10			;check to see if there was a LF character after the command
	je firstParamError
	jmp firstParamNoError
firstParamError:
	println "Error processing parameters, enter the first parameter"
	mov edx, offset firstParam
	mov ecx, sizeof firstParam
	call ReadString
firstParamNoError:
	ret
getOneParam ENDP

;
;cmdLoad
;needs 3 parameters <name> <priority> <run_time>
;
cmdLoad PROC
	.code
	println "Load command entered"
	;clear the parameter variables
	call nullParams					;fill the parameters with 0s
	;get and error check the parameter variables from the inBuffer
	mov edi,offset inBuffer
	call getFirstParam				;retrieve the first parameter
	cmp firstParam,0
	je firstParamError
	cmp ecx,0
	je secParamError
	call getSecondParam				;retrieve the second parameter
	cmp ebx,0
	je secParamError
	cmp ecx,0
	je thirdParamError
	call getThirdParam				;retrieve the third parameter
	cmp ebx,0
	je thirdParamError
	jmp noParamError
firstParamError:
	println "Error processing parameters, enter first parameter"
	mov edx,offset firstParam
	mov ecx,sizeof firstParam
	call ReadString
secParamError:
	println "Error processing parameters, enter second parameter"
	mov edx, offset secParam
	mov ecx, sizeof secParam
	call ReadString
thirdParamError:
	println "Error processing parameters, enter third parameter"
	mov edx, offset thirdParam
	mov ecx, sizeof thirdParam
	call ReadString
noParamError:
	mov edx,offset firstParam
	call WriteString
	println " "
	mov edx,offset secParam
	call WriteString
	println " "
	mov edx,offset thirdParam
	call WriteString
	call Crlf
	;;;start processing load command
	movzx edi,program					;move the program data location into edi
	sub edi,indexsize

	jmp skiptocycle
	;find the next blank entry to input program data
nextBlankEntry:
	add edi,indexsize					;go to the next program data location
	movzx eax,byte ptr [edi]
	cmp eax,0
	jne nextBlankEntry

skiptocycle:
	mov edi,0
cycle:
	movzx eax,firstParam[edi]
	inc edi
	cmp edi,10
	jle cycle
	ret
cmdLoad ENDP

;
;cmdHold
;needs 1 parameter <name>
;
cmdHold PROC
	println "Hold command entered"
	call getOneParam
	;start processing hold command
	mov edx,offset firstParam
	call WriteString
	call Crlf
	ret
cmdHold ENDP

;
;cmdRun
;needs 1 parameter <name>
;
cmdRun PROC
	println "Run command entered"
	;gotta repeat the getOneParam procedure because run is 3 letters long
	mov eax,30
	nullFill firstParam,eax
	mov edi, offset inBuffer
	call getFirstParam
	cmp ebx,0
	je firstParamError
	cmp firstParam[4],0			;check to see if there was a null character at the end of the command
	je firstParamError
	jmp firstParamNoError
firstParamError:
	println "Error processing parameters, enter the first parameter"
	mov edx, offset firstParam
	mov ecx, sizeof firstParam
	call ReadString
firstParamNoError:
	println "No errors in processing parameters"
	;display the parameter
	mov edx, offset firstParam
	call WriteString
	call Crlf
	;start processing data for run command
	ret
cmdRun ENDP

;
;cmdKill
;needs 1 parameter <name>
;
cmdKill PROC
	mov eax,30
	nullFill firstParam,eax
	println "Kill command entered"
	call getOneParam
	;display the parameters
	mov edx,offset firstParam
	call WriteString
	call Crlf
	ret
cmdKill ENDP

;
;cmdShow
;0 parameters
;
cmdShow PROC
	println "Show command entered"
	mov index,0
	;process name
	;process priority
	;process hold
	;process run_time

	;jump back up to next program entry if not done
	jmp cmdShowDone
noEntries:
	println "There are no entries for jobs"
cmdShowDone:
	ret
cmdShow ENDP

;
;cmdStep
;needs 1 parameter <n>
;
cmdStep PROC
	mov eax,30
	nullFill firstParam,eax
	println "Step command entered"
	call getOneParam
	;display the parameter
	mov edx,offset firstParam
	call WriteString
	call Crlf
	ret
cmdStep ENDP

;
;cmdChange
;needs 2 parameters <name> <priority>
;
cmdChange PROC
	println "Change command entered"
	call nullParams
	;get the first parameter
	mov edi, offset inBuffer
	mov esi, offset firstParam
	mov edx, 1
	call getFirstParam
	cmp ebx,0
	je firstParamError

	;get the second parameter
	mov edi, offset inBuffer
	mov esi, offset secParam
	mov edx, 2
	call getFirstParam
	cmp ebx,0
	je secondParamError
	jmp cmdChangePrint

	cmp ebx,0
	je firstParamError
	cmp firstParam[6],0			;check to see if there was a null character after the command
	je firstParamError
	call getSecondParam
	cmp ebx,0
	je secondParamError
	jmp firstParamNoError
firstParamError:
	println "Error processing parameters, enter the first parameter"
	mov edx, offset firstParam
	mov ecx, sizeof firstParam
	call ReadString
secondParamError:
	println "Error processing parameters, enter the second parameter"
	mov edx, offset secParam
	mov ecx, sizeof secParam
	call ReadString
firstParamNoError:
	println "No errors in processing parameters"
	;display the parameters
cmdChangePrint:
	mov edx, offset firstParam
	call WriteString
	call Crlf
	mov edx, offset secParam
	call WriteString
	call Crlf
	ret
cmdChange ENDP

;
;main procedure
;
main PROC
	println "Welcome to the diddly doodley OS simulator"
	println "Type help to display a list of commands and what they do"
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
