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
	BUFFERSIZE equ 21
	inBuffer byte 21 dup(0)
	tempAddress dword 1 dup(0)	;temprory variable for holding the address of something
	namesize equ 20
	age equ 21					;offset of age in the person data structure
	indexsize equ 22			;size of each data structure index
	person byte indexsize*5 dup(0)
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
;printStructure
;prints out all the data in the data structure
;
printStructure PROC
	mov edi,offset person
	sub edi,indexsize
printLoop:
	add edi,indexsize
	mov al,byte ptr[edi]		;test
	cmp byte ptr[edi],0
	je printDone
	mov edx,edi
	call WriteString		;print the name
	mov edx,edi
	add edx,age				;go to the offset of the age
	jmp printLoop			;go to the next part
	call Crlf
printDone:
	ret
printStructure ENDP

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
	inc esi
	mov byte ptr[esi],0
	inc edi
	mov byte ptr[edi],0
	pop edi
	pop esi
	pop eax
	ret
cpyString ENDP

;
;enterName
;makes the user enter a name and stores it in the next available location
enterName PROC
	print "Enter a full name for a person: "
	mov edx,offset inBuffer
	mov ecx,sizeof inBuffer
	call ReadString
	;find the next available entry space for the byte
	mov edi,offset person
	sub edi,indexsize
findAvailableSpaceLoop:
	add edi,indexsize
	mov al,byte ptr[edi]
	cmp byte ptr[edi],0
	jne findAvailableSpaceLoop

	push edi
	mov edi,offset inBuffer
	pop esi
	call cpyString
	ret
enterName ENDP

main PROC
	.data
	count byte 1 dup(0)
	.code
	println "Welcome to the big brother census program"
mainLoop:
	call enterName
	inc count
	cmp count,5
	jl mainLoop
	println "Finished processing information"
	println "The entries are as follows: "
	call printStructure
	call Waitmsg
	INVOKE ExitProcess,0
main ENDP
END main
