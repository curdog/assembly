TITLE Assembly Program 1  by Group 3

; Description:    Assembly Program 1
; Class:          CSC
; Members:        Sean Curtis, Max Conroy, John Kirshner
; Revision date:  2/2

INCLUDE Irvine32.inc
.data
;myMessage BYTE "MASM program example",0dh,0ah,0
avg dword 0
sum dword 0
count dword 0
grade dword 0
buffersize eq 41
buffer byte buffersize dup(0)
prompt byte "Enter a number.",0
promptdesc byte "Grade Averager.\n",0
promptavg byte "Average: ",0
promptrem byte "Division Rem: ",0
promptcount byte "Count: ",0
prompterr byte "You did something bad, so I quit",0

.code
main PROC
	;we are more important than everything else
	call Clrscr
	;main prog desc
	mov	 edx,OFFSET promptdesc
	call WriteString
	;input loop
	InLoop: nop
	mov edx, OFFSET prompt
	call WriteString
	;input handle
	mov edx offset buffer
	mov ecx sizeof buffer
	call ReadString
	;check chars read
	cmp eax, 0
	jz Done
	;convert to dword
	mov edx, offset buffer
	mov ecx, eax
	call ParseInteger32
	;check range
	cmp eax, 0
	jb DoneE
	cmp eax, 100
	jg DoneE
	
	;add to sum and count
	add sum, eax
	add count, 1
	
	;if we made it this far everything is good
	;for another go
	jmp InLoop
	;quit error
	DoneE: nop
	mov edx, offset promterr
	call WriteString
	;quit normal
	Done: nop
	;print stuff
	exit
main ENDP

END main