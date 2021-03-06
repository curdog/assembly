TITLE Assembly Program 3  by Group 5

; Description:    Assembly Program 3
; Class:          CSC 323
; Members:        Sean Curtis, Max Conroy, John Kirshner
; Revision date:  3/24/15
; Purpose: To simulate a multi threaded operating system. This is accomplished
;	by having a data structure that contains jobs, their priorities, how many 
;	execution steps for the process to finish, and a flag byte containing data
;	on the state of the program. The program takes a step command that will 
;	simulate a step in the processor that decrements the job structure's time
;	to live variable

Include Irvine32.inc
.386
.model flat, stdcall
ExitProcess PROTO, dwExistCode:DWORD
.data
	CR equ 0Dh
	LF equ 0Ah
	stateKill equ 1
	stateHold equ 2
	stateRun equ 3
	BUFFERSIZE equ 80
	flag byte 1 dup(0)
	inBuffer byte 80 dup(0)
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
;PROCEDURES
;

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
;@setup
;mov esi, offset str1
;mov edi, offset str2
cmpString PROC
	push esi
	push edi
Start:	nop
	mov al, byte ptr [esi]
	mov ah, byte ptr [edi]
	cmp ah, NULL		;end of string and equal
	je Equal
	cmp al,NULL
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
;cmpStringAbs
;checks the absolute string
;@setup
;mov edi,offset str1
;mov esi,offset str2
;@return 
;eax=1 if strings equal, eax=0 if not equal
;
cmpStringAbs PROC
	push esi
	push edi
StartCmpStringAbs:	nop
	mov al, byte ptr [esi]
	mov ah, byte ptr [edi]
	cmp ah, al			;compare chars
	jne cmpNotEqu			;quit early NOTE: will quit if one is NULL and other not
	cmp ah, NULL		;end of string and equal
	je cmpEqual
	cmp al,NULL
	je cmpEqual		
	inc esi
	inc edi
	jmp StartCmpStringAbs
cmpNotEqu: nop 			;not equal case 
	mov eax,0
	jmp cmpStringAbsFin
cmpEqual:	nop		  ;equal case
	mov eax,1
cmpStringAbsFin:
	pop edi
	pop esi	
	ret
cmpStringAbs ENDP

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
;findJob
;finds a job name and returns in edi the address of the start of the job
;@setup
;mov edi,offset jobname
;@return
;esi = address of job
;edi = 0 if job is not found
;
findJob PROC
	push eax
	mov esi,offset program		;move the offset of the program
	sub esi,indexsize
findJobLoop:
	add esi,indexsize
	cmp byte ptr[esi],0
	je findJob404				;if pointer reaches an uninitalized data then the job doesn't exist
	call cmpStringAbs
	cmp eax,1
	je findJobDone
	mov al,byte ptr[esi]
	cmp al,0					;compare to null
	jmp findJobLoop
findJob404:
	mov edi,0					;0 if the job doesn't exist
findJobDone:
	pop eax
	ret
findJob ENDP

;
;fillArray
;@setup
;mov edi,offset array
;mov ecx,sizeof array
;mov al,(desired content to fill)
;
fillArray PROC
	dec edi
fillArrayLoop:
	inc edi
	mov byte ptr[edi],al
	dec ecx
	cmp ecx,0
	jg fillArrayLoop
	ret
fillArray ENDP

;
;nullParams
;fills all the parameter variables with null values
;
nullParams PROC
	push edi
	push edx
	mov edi,offset firstParam
	mov edx,BUFFERSIZE
	mov al,0
	call fillArray
	mov edi,offset secParam
	mov edx,BUFFERSIZE
	mov al,0
	call fillArray
	mov edi,offset thirdParam
	mov edx,BUFFERSIZE
	mov al,0
	call fillArray
	pop edx
	pop edi
	ret
nullParams ENDP

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
	call nullParams
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
	;Look for a duplicate job in the list
	mov edx,offset program
	sub edx,indexsize
checkExistingName:
	add edx,indexsize
	mov eax,edx
	cmp byte ptr[eax],0
	je checkExistingNameDone
	mov edi,eax
	mov esi,offset firstParam
	call cmpStringAbs
	cmp eax,1			;1 if a duplicate job is encountered
	je jobFound
	jmp checkExistingName
jobFound:
	println "Already existing job found"
	jmp cmdLoadDone
checkExistingNameDone:

	;display all the parameters and what they have done. 
	println "New job entered"
	print "Name: "
	mov edx,offset firstParam
	call WriteString
	print "		Priority: "
	mov edx,offset secParam
	call WriteString
	print "		Run Time: "
	mov edx,offset thirdParam
	call WriteString
	call Crlf
	mov edi,offset program			;move program address into edi
	sub edi,indexsize				;initialize the pointer
	;cycle through the program structure to find an empty location
Loop3:
	add edi,indexsize
	cmp byte ptr[edi],0			;check to see if the pointer is equal to 0
	je Loop3Done
	jmp Loop3
Loop3Done:
	;copy the name
	mov tempAddress,edi				;move the empty address into the temporary address
	mov esi,edi						;mov into esi the address of the source
	mov edi,offset firstParam		;move into edi the address of the target
	call cpyString					;copy the string
	;process the priority
	mov edi,offset secParam			;move into edi the offset of the second parameter
	call strLength					;length of the string in eax
	mov ecx,eax
	mov edx,offset secParam
	call ParseInteger32				;32 bit integer in eax
	;check to see if the data entered is valid
cmdLoadPriorityCheck:
	cmp eax,10
	jle priorityCont
	print "Priority entered is not 10 or below: "
	call ReadDec		;read a decimal, it's contents is stored back in eax
	jmp cmdLoadPriorityCheck
priorityCont:
	mov edi,tempAddress
	add edi,priority
	mov [edi],eax		;move the result into priority
	;change the hold parameter
	mov edi,tempAddress
	add edi,hold
	mov ax,stateHold
	mov [edi],ax
	;process the run time
	mov edi,offset thirdParam
	call strLength
	mov ecx,eax
	mov edx,offset thirdParam
	call ParseInteger32			;32 bit integer in eax
runTimeCheck:
	cmp eax,512				;Any value over 10k is not accepted
	jle runTimeCheckDone
	print "You entered too large of a number, please enter a number less then 512: "
	call ReadDec
	jmp runTimeCheck
runTimeCheckDone:
	mov edi,tempAddress
	add edi,runtime
	mov [edi],eax
cmdLoadDone:
	ret
cmdLoad ENDP

;
;cmdHold
;needs 1 parameter <name>
;
cmdHold PROC
	println "Hold command entered"
	call nullParams
	;get the first parameter
	mov edi,offset inBuffer
	mov esi,offset firstParam
	mov edx,1
	call getParams
	;start processing hold command
	;Look for the job
	mov edi,offset firstParam
	call findJob
	cmp edi,0
	je cmdHoldNoJob
	print "Found job: "			;job was found so print that bitch out
	mov eax,offset program
	mov edx,esi					;edi contains the address of the job now
	call WriteString
	call Crlf
	println "Chaning job state to hold"
	jmp cmdHoldCont
cmdHoldNoJob:
	println "Job does not exist"
	jmp cmdHoldDone
cmdHoldCont:
	add esi,hold						;edi contains the offset of the found job
	mov byte ptr[esi],stateHold			;rewrite the hold state over to the edi
cmdHoldDone:
	ret
cmdHold ENDP

;
;cmdRun
;needs 1 parameter <name>
;changes the state of the job to run
;
cmdRun PROC
	println "Run command entered"
	call nullParams
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
	;start processing data for run command
	;Look for the job
	mov edi,offset firstParam
	mov esi,offset program
	call findJob
	cmp edi,0
	je cmdRunNoJob
	print "Found job: "			;job was found so print that bitch out
	mov edx,esi					;esi contains the address of the job now
	call WriteString
	call Crlf
	jmp cmdRunCont
cmdRunNoJob:
	println "Job does not exist"
	jmp cmdRunDone
cmdRunCont:
	println "Changing job state to run"
	add esi,hold						;edi contains the offset of the found job
	mov byte ptr[esi],stateRun					;rewrite the hold state over to the edi
cmdRunDone:
	ret
cmdRun ENDP

;
;cmdKill
;needs 1 parameter <name>
;
cmdKill PROC
	call nullParams
	println "Kill command entered"
	mov edi, offset inBuffer
	mov esi, offset firstParam
	mov edx,1
	call getParams
	;Look for the job
	mov edi,offset firstParam
	call findJob
	cmp edi,0
	je cmdKillNoJob
	print "Found job: "			;job was found so print that bitch out
	mov eax,offset program
	mov edx,esi					;edi contains the address of the job now
	call WriteString
	call Crlf
	println "Changing job state to killed"
	jmp cmdKillCont
cmdKillNoJob:
	println "Job does not exist"
	jmp cmdKillDone
cmdKillCont:
	add esi,hold						;edi contains the offset of the found job
	cmp byte ptr[esi],stateHold
	jne cmdKillChangeError
	mov byte ptr[esi],stateKill			;rewrite the hold state over to the edi
	println "Successfully killed job"
	jmp cmdKillDone
cmdKillChangeError:
	Println "Set hold flag to hold before killing a job"
cmdKillDone:
	ret
cmdKill ENDP

;
;cmdShow
;0 parameters
;
cmdShow PROC
	println "Show command entered"
	mov edi,offset program			;set the initial start of the program
	cmp byte ptr[edi],0
	je noEntries
	sub edi,indexsize
Loop1:
	add edi,indexsize
	cmp byte ptr[edi],0					;check if there were no job entries
	je cmdShowDone
	;process and display name
	print "Name: "
	mov edx,edi							;mov edx,offset program
	call WriteString
	;process and display priority
	print "	Priority: "
	mov edx,edi
	add edx,priority					;add offset for priority
	movzx eax,byte ptr[edx]
	call WriteDec						;print priority
	;process and display hold
	print "	Hold status: "
	mov edx,edi
	add edx,hold						;add offset for hold
	movzx eax,byte ptr[edx]
statKill:
	cmp eax,stateKill
	jne statHold
	print "Killed"
	jmp statFin
statHold:
	cmp eax,stateHold
	jne statRun
	print "Hold"
	jmp statFin
statRun:
	print "Run"
statFin:
	;process and display run_time
	call Crlf						;next line
	print "		Run_time: "
	mov edx,edi
	add edx,runtime			;add offset for the run time
	movzx eax,word ptr[edx]
	call WriteDec		
	call Crlf				;next line
	;jump back up to next program entry if not done
	jmp Loop1
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
	.data
	highestPriority byte 1 dup(11)
	runTimeStep word 1 dup(0)
	.code
	mov highestPriority,11			;reset the highestPriority variable
	mov runTimeStep,0				;reset runTimeStep
	call nullParams					;reset the parameter variables
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
	call strLength1
	mov edx,offset firstParam
	mov ecx,eax
	call parseDecimal32			;result is in eax
	mov runTimeStep,ax			;send the result to runTimeStep
	mov edi,offset program
	cmp byte ptr[edi],0
	je cmdStepNoJobs
	println "Jobs found, beginning execution"
	sub edi,indexsize
	;Find the highest priority job
findHighestPriority:
	add edi,indexsize
	cmp byte ptr[edi],0			;check for the end of the job list
	je cmdStepNext				;jump if end of list is found to cmdStepNext
	;check to see if the program is in run mode
	mov edx,edi
	add edx,hold
	mov ah,byte ptr[edx]
	cmp ah,stateRun
	jne findHighestPriority2		;jump if the program data isn't in the run state to the next program data
	;check the priority of the data
	mov edx,edi
	add edx,priority			;offset to read the priority
	mov ah,highestPriority
	cmp byte ptr[edx],ah		;if the priority is higher then highestPriority then set highestPriority to that number
	jg findHighestPriority2		;else just go back to the beginning of the loop and check the next index
	mov ah,byte ptr[edx]
	mov highestPriority,ah
findHighestPriority2:
	jmp findHighestPriority
cmdStepNext:
	;print out the highest priority now
	print "Highest priority: "
	movzx eax,highestPriority
	call WriteDec
	call Crlf
	;start processing the run time variables
	mov edi,offset program
	sub edi,indexsize
DecRunTime:
	add edi,indexsize		;go to the next index
	;check for the end of program data
	cmp byte ptr[edi],0
	je DecRunTimeDone		;go and decrement the runTimeStep value after stepping through the loop
	;check the state
	mov edx,edi
	add edx,hold
	cmp byte ptr[edx],stateRun
	jne DecRunTime
	;check the priority
	mov edx,edi
	add edx,priority
	mov ah,byte ptr[edx]	;move the priority value into ah
	mov al,highestPriority
	cmp ah,al				;compare the data's priority value to the highestPriority's value
	jne DecRunTime
	mov edx,edi
	add edx,runtime			;point edx to the runtime value of the program data
	dec byte ptr[edx]		;decrement the value stord in the run time data
	;check to see if that value has reached 0, if so go back and recalculate the lowest priority
	cmp byte ptr[edx],0
	jne DecRunTimeDone
	;jne DecRunTime			;don't care if it isn't 0, go back up to the decRunTime so you can continue cycling through the program data
	mov edx,edi
	add edx,hold			;want to kill the process
	mov al,stateKill
	mov byte ptr[edx],al	;kill that son of a bitch
	mov highestPriority,11	;reset the highestPriority
	jmp findHighestPriority	;go back up to find the highest priority
DecRunTimeDone:
	dec runTimeStep			;decrement runTimeStep
	mov edi,offset program	;want to reset the data pointed to in edi to the program so you can cycle back through the data
	sub edi,indexsize
	mov ax,runTimeStep		;check to see if runTimeStep has reached 0
	cmp ax,0
	jg DecRunTime
	jmp cmdStepDone
cmdStepNoJobs:
	println "There are no job entries"
cmdStepDone:
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
	call getParams
	cmp ecx,0
	je firstParamError
	;get the second parameter
	mov edi, offset inBuffer
	mov esi, offset secParam
	mov edx, 2
	call getParams
	jmp cmdChangeLoop1
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
	mov edi, offset secParam
	call strLength1
	mov edx, offset secParam
	mov ecx, eax
	call parseDecimal32
	cmp eax,10						;check for a valid priority entry
	jle cmdChangeCont
	print "Priority value entered is not 10 or below: "
	call ReadInt
	jmp cmdChangeParamsGood
cmdChangeCont:
	mov edi, offset firstParam
	call findJob
	cmp edi,0
	je noJobFound
	add esi,priority
	mov byte ptr [esi], al
	ret
noJobFound:
	println "Job not found"
	ret
cmdChange ENDP

;
;main procedure
;
main PROC
	println "Welcome to Goat OS"
	println "Type help to display a list of commands and what they do"
MainStart:
	print ":"						;prompt the user for entry
	mov edx, OFFSET inBuffer		;set everything up for ReadString
	mov ecx, sizeof inBuffer
	call ReadString
	toLowerCase inBuffer			;normalize the inBuffer to all lowercase letters
	call switchCmd					;check for the input of a command
	mov edi,offset inBuffer
	mov edx,BUFFERSIZE
	mov al,0
	call fillArray					;reset the input buffer to all null values
	jmp MainStart					;infinite loop until user types 'quit'
main ENDP

END main
