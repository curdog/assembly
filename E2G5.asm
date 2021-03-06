TITLE Assembly Program 3  by Group 5

; Description:    Assembly Exam Program 2
; Class:          CSC 323
; Members:        Sean Curtis, Max Conroy, John Kirshner
; Revision date:  3/25/15
; Purpose: To display an understand of how data structures work
;	in assembly. This program takes a user's input for a name and 
;	a value for an age. It then stores that information in a data 
;	structure that is accessed using pointers. 

Include Irvine32.inc
.386
.model flat, stdcall
ExitProcess PROTO, dwExistCode:DWORD
.data
	BUFFERSIZE equ 21
	inBuffer byte 21 dup(0)
	tempAddress dword 1 dup(0)	;temprory variable for holding the address of something
	namesize equ 20
	age equ 21					;offset of age in the person data structure
	indexsize equ 22			;size of each data structure index
	person byte indexsize*5+1 dup(0)
	count byte 1 dup(0)
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
;PROCEDURES
;

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
;cpyString
;copies a string starting in edi to another variable in esi
;@set up:
;mov edi,offset source
;mov esi,offset target
;
cpyString PROC
	push eax
	push edi
	push esi
cpyStringLoop:
	movzx eax,byte ptr[edi]			;move the contents of the source into eax
	mov [esi],eax					;copy the contents into the target
	inc edi
	inc esi
	cmp eax,0						;check for the null character
	jne cpyStringLoop				;jump back if the null character isn't encountered
cpyStringDone:
	pop esi
	pop edi
	pop eax
	ret
cpyString ENDP

;
;strToInt
;converts a string to an integer value
;@setup
;mov edx,offset str
;mov ecx,sizeof str
;@return
;eax=the value converted
strToInt PROC
	call parseDecimal32
	ret
strToInt ENDP


;
;printStructure
;prints out all the data in the data structure
;
printStructure PROC
	mov edi,offset person
	sub edi,indexsize
printLoop:
	add edi,indexsize
	cmp byte ptr[edi],0
	je printDone			;check for the end of the data structure
	print "Name: "
	mov edx,edi
	call WriteString		;print the name
	;print the age
	print "		Age: "
	mov edx,edi
	add edx,age				;go to the offset of the age
	movzx eax,byte ptr[edx]
	call WriteDec			;print the decimal
	call Crlf
	jmp printLoop			;go to the next part
printDone:
	ret
printStructure ENDP

;
;enterName
;makes the user enter a name and stores it in the next available location
enterName PROC
	print "Enter a full name for a person: "
	mov edx,offset inBuffer
	mov ecx,sizeof inBuffer
	call ReadString
	;check if the user wants to quit
	cmp inBuffer,0
	je enterNameAlmostDone
	;find the next available entry space for the byte
	mov edi,offset person
	sub edi,indexsize
findAvailableSpaceLoop:
	add edi,indexsize
	mov al,byte ptr[edi]
	cmp byte ptr[edi],0
	jne findAvailableSpaceLoop
	;shift edi and esi around to copy the string
	push edi
	mov edi,offset inBuffer
	pop esi
	call cpyString
	;shift edi and esi back around to maintain what was being done
	mov edx,esi
	jmp enterNameDone
enterNameAlmostDone:
	mov count,5
enterNameDone:
	ret
enterName ENDP

;
;enterAge
;prompts a user to enter an age value and retrieves their age
;
enterAge PROC;prompt for and get the user's input for age
getAge:
	print "Enter an age value under 120: "
	mov edx,offset inBuffer
	mov ecx,sizeof inBuffer
	call ReadString
	mov edx,offset inBuffer
	mov ecx,sizeof inBuffer
	call strToInt
	cmp eax,120
	jg getAge
	cmp eax,0
	jl getAge
	;after clearing the checks you can store the age
	mov edx,edi
	add edx,age
	mov byte ptr[edx],al
	ret
enterAge ENDP

main PROC
	println "Welcome to the big brother census program"
	println "When entering names enter an empty string to exit"
mainLoop:
	call enterName
	mov edi,edx
	cmp count,5
	je mainLoopDone
	call enterAge
	println "--------------------------------------------------"
	println "Current contents of the data structure: "
	call printStructure
	println "--------------------------------------------------"
	inc count
	cmp count,5
	jl mainLoop
mainLoopDone:
	println "--------------------------------------------------"
	println "Final contents of the data structure: "
	call printStructure
	println "--------------------------------------------------"
	call Waitmsg
	INVOKE ExitProcess,0
main ENDP
END main
