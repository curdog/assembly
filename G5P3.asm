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
	tempAddress dword 1 dup(0)	;temprory variable for holding the address of something
	priority equ 11				;priority contains 1 byte	(byte 1)
	hold equ 12					;hold contains 1 byte		(byte 2)
	runtime equ 13				;runtime contains a word	(byte 3-4)
	name equ 0					;namesize contains 10 bytes	(byte 5-15)
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
	push edx
	mov edx, offset str
	call WriteString
	pop edx
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
	push edx
	mov edx, offset str
	call WriteString
	pop edx
ENDM
;
;toLowerCase
;converts all characters in the string to lowercase
;
toLowerCase MACRO str
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
;toPower
;takes the first parameter and sets it to the power of the second parameter
;@base the number to perform the power operation on
;@exp the exponent
;@return eax = the result
;
toPower MACRO base,exp
toPowerLoop:
	mul base,base
	dec exp
	cmp exp,0
	je toPowerLoop
	mov eax,base
ENDM

;
;PROCEDURES
;

;
;strToByte
;converts a string stored in edi to a byte variable
;@setup
;mov edi,offset string
;@return eax = the byte variable
;
strToByte PROC
	mov ebx,0
strToByteLoop:
	movzx ax,byte ptr[edi]
	and ax,20h
	;toPower 10,ax
	movzx ecx,ax
	imul eax,ecx
	add ebx,eax
	cmp byte ptr[edi],0
	jne strToByteLoop
	ret
strToByte ENDP

; -----------------------------------------------
; Convert to Decimal
;@start up
;mov edi offset str
;@return number is in eax
cvtdec PROC
	pushad
	;mov number,0
	mov eax,0
	mov ecx,0
	mov edx,0
	;mov edi, bufferIndex
	mov ebx,10
cvdL1:
	;mov dl,buffer[edi]
	mov dl,byte ptr [edi]
	cmp edx,0
	je cdvext
	cmp edx,'0'
	jl cdvext
	cmp edx,'9'
	jg cdvext
	; remove the 30h from the register to get the real number
	and edx,0FH
	mov ecx,edx
	imul ebx
	add eax,ecx		;add result into eax
	inc edi
	jmp cvdL1
cdvext:
	;mov number,eax
	;mov bufferIndex, edi
	popad
	ret
cvtdec ENDP

;
;nextIndex
;moves the index variable to the next program index
;
nextIndex PROC
	add index,indexsize
	ret
nextIndex ENDP

;
;isDigit
;checks the string stored in edi to see if it has a digit value
;@set up:
;	mov edi, offset string
;@return eax=1 if string is a digit eax=0 if string is not a digit
;
isDigit1 PROC
	mov eax,1		;will go to 0 if the character is not detected as a digit
	dec edi			;set up so the auto increment doesn't increment to next
goThroughString:
	inc edi
	movzx bx,byte ptr [edi]
	cmp bx,0
	je isDigitDone
	cmp bx,'0'			;compare to ascii 0
	jl isNotADigit
	cmp bx,'9'			;compare to ascii 9
	jg isNotADigit
	jmp goThroughString
isNotADigit:
	mov eax,0
isDigitDone:
	ret
isDigit1 ENDP

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
;dispParams
;
dispParams PROC
	mov edx,offset firstParam
	call WriteString
	println " "
	mov edx,offset secParam
	call WriteString
	println " "
	mov edx,offset thirdParam
	call WriteString
	call Crlf
	ret
dispParams ENDP

;
;getParams
;retrieves the first parameter of the string stored in edi
;stores the result in the variable pointed to by esi
;@set up:
;	mov edi, offset str
;	mov esi, offset paramVariable
;	mov edx, param to get (1,2,or 3)
;@return ebx=1 if success ebx=0 if failure
;@return ecx=1 if not end of the string ecx=0 if end of string
;
getParams PROC
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
	cmp ax,' '			;compare to space
	je gfpFin
	cmp ax,'	'		;compare to tab
	je gfpFin
	cmp ax,0			;compare to null
	je gfpEndOfString
	mov [esi],ax		;copy the contents
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
getParams ENDP

;
;cmpString procedure
;NOTE: I moved around cmp ah,NULL & cmp ah,al switch them to do an absolute compare
;compares two strings for equality
;@return eax=1 if equal, eax=0 if not equal
;strings must be null terminated
;esi - offset str1
;edi - offset str2
cmpString PROC
push esi
push edi
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
Equal:	nop		  ;equal case
	mov eax,1
cmpStringFin:
	pop edi
	pop esi	
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
;cpyString
;copies a string starting in edi to another variable in esi
;@set up:
;mov edi,offset source
;mov esi,offset target
;
cpyString PROC
	push eax
cpyStringLoop:
	movzx eax,byte ptr[edi]			;move the contents of the source into eax
	mov [esi],eax					;copy the contents into the target
	inc edi
	inc esi
	cmp eax,0						;check for the null character
	jne cpyStringLoop				;jump back if the null character isn't encountered
cpyStringDone:
	pop eax
	ret
cpyString ENDP

;
;strLength1
;takes a string value in edi and returns in eax the value of the length of the string
;@setup:
;mov edi,offset str
;@return:
;eax contains the length of the string, including the null character
strLength1 PROC
	push ebx
	mov eax,0		;setup for counting
strLengthLoop:
	movzx ebx,byte ptr[edi]
	inc edi					;increment the string pointer for the next index
	inc eax					;increment the count
	cmp ebx,0
	jne strLengthLoop
	pop ebx
	ret
strLength1 ENDP

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
;needs 3 parameters <name> <priority> <run_time>
;
cmdLoad PROC
	println "Load command entered"
	;get the first parameter
	mov edi,offset inBuffer
	mov esi,offset firstParam
	mov edx,1
	call getParams
	cmp ecx,0
	je firstParamError
	;get the second parameter
	mov edi,offset inBuffer
	mov esi,offset secParam
	mov edx,2
	call getParams
	cmp ecx,0
	je secParamError
	;get the third parameter
	mov edi,offset inBuffer
	mov esi,offset thirdParam
	mov edx,3
	call getParams
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
	call dispParams			;display the parameters to check their values
	;check to see if the second parameter entered is a digit
Loop1:
	mov edi,offset secParam
	call isDigit1
	cmp eax,1				;will contain a one if the string contains only digits
	je Loop2
	print "Second parameter entered does not have a digit value, please enter a digit value: "
	mov edx,offset secParam
	mov ecx,sizeof secParam
	call ReadString
	jmp Loop1					;loop until a correct input is entered
	;check to see if the third parameter is a digit value
Loop2:
	mov edi,offset thirdParam
	call isDigit1
	cmp eax,1				;will contain a one if the string contains only digits
	je parametersCorrect
	print "Third parameter entered does not have a digit value, please enter a digit value: "
	mov edx,offset thirdParam
	mov ecx,sizeof thirdParam
	call ReadString
	jmp Loop2					;loop until a correct input is entered
parametersCorrect:
	;;;start processing load command
	println "Parameters are correct"
	mov index,0								;start at index 0 initially
	movzx edi,index							;mov the index value into edi
	sub edi,indexsize
	;cycle through the program structure to find an empty location
Loop3:
	add edi,indexsize
	cmp program[edi],0			;check to see if the pointer is equal to 0
	je Loop3Done
	jmp Loop3
Loop3Done:
	;copy the name
	mov tempAddress,edi				;move the empty address into the temporary address
	mov esi,offset program			;mov into esi the address of the source
	add edi,offset firstParam		;move into edi the address of the target
	call cpyString					;copy the string
	mov edi,offset firstParam
	call strLength1					;recorrect for the cpyString function, subtract the length of the string
	sub edi,eax
	;process the priority
	mov edi,offset secParam			;move into edi the offset of the second parameter
	call cvtdec						;convert the number to a decimal
	;mov ax,eax
	mov priority[esi],eax			;will be the length of the string away from the beginning of program, so will write to a weird place
	;need to get the legnth of the added string and subtract the bitch, working on strLength procedure
	;process the run time
	mov edi, offset thirdParam
	call cvtdec
	mov runtime[esi],eax
	ret
cmdLoad ENDP

;
;cmdHold
;needs 1 parameter <name>
;
cmdHold PROC
	println "Hold command entered"
	mov eax,30
	nullFill firstParam,eax
	;get the first parameter
	mov edi,offset inBuffer
	mov esi,offset firstParam
	mov edx,1
	call getParams
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
	mov eax,30
	nullFill firstParam,eax
	;get the first parameter
	mov edi,offset inBuffer
	mov esi,offset firstParam
	mov edx,1
	call getParams
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
	mov edi, offset inBuffer
	mov esi, offset firstParam
	mov edx,1
	call getParams
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
	mov index,0						;set the index to the start
	mov edi,offset program			;set the initial start of the program
	sub edi,indexsize
Loop1:
	add edi,indexsize
	mov eax,[edi]						;copy a temporary variable from edx
	;process and display name
	print "Name: "
	mov edx,edi							;mov edx,offset program
	call WriteString
	;process and display priority
	print "	Priority: "
	mov edx,priority[edi]
	call WriteDec
	;process and display hold
	mov edx,priority[edi]
	call WriteDec
	print "	Hold status: "
	mov edx,hold[edi]
	call WriteDec
	;process and display run_time
	call Crlf						;next line
	mov edx,eax						;copy the temp variable
	print "		Run_time: "
	mov edx,runtime[edi]
	call Crlf				;next line
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
	;gete the first parameter
	mov edi, offset inBuffer
	mov esi, offset firstParam
	mov edx,1
	call getParams
	;display the parameter
	mov edx,offset firstParam
	call WriteString
	call Crlf
	;check to see if the first parameter is a digit
cmdStepLoop1:
	mov edi,offset firstParam
	call isDigit1
	cmp eax,1
	je cmdStepParamsGood
	print "Parameter entered is not a digit, please enter a digit: "
	mov edx,offset firstParam
	mov ecx,sizeof firstParam
	call ReadString
	jmp cmdStepLoop1
cmdStepParamsGood:
	println "Parameter is good"
	ret
cmdStep ENDP

;
;cmdChange
;needs 2 parameters <name> <priority>
;
cmdChange PROC
	println "Change command entered"
	mov eax,30
	nullFill firstParam,eax
	mov eax,30
	nullFill secParam,eax
	mov eax,30
	nullFill thirdParam,eax
	;get the first parameter
	mov edi, offset inBuffer
	mov esi, offset firstParam
	mov edx, 1
	call getParams
	cmp ecx,0
	je firstParamError
	;get the second parameter
	mov edi, offset inBuffer
	mov esi, offset secParam
	mov edx, 2
	call getParams
	jmp cmdChangePrint
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
	;check to see if the second parameter is a digit
cmdChangeLoop1:
	mov edi,offset secParam
	call isDigit1
	cmp eax,1
	je cmdChangeParamsGood
	print "Second parameter entered is not a digit, please enter a digit: "
	mov edx,offset secParam
	mov ecx,sizeof secParam
	call ReadString
	jmp cmdChangeLoop1
cmdChangeParamsGood:
	println "Parameters are good"
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
	toLowerCase inBuffer			;normalize the inBuffer to all lowercase letters
	call switchCmd					;check for the input of a command
	jmp MainStart					;infinite loop until user types 'quit'
main ENDP

END main
