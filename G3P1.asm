TITLE Assembly Program 1  by Group 3

; Description:    Assembly Program 1
; Class:          CSC
; Members:        Sean Curtis, Max Conroy, John Kirshner
; Revision date:  2/2
Include Irvine32.inc
.386
.model flat
.data
;data declarations

avg dword 0
sum dword 0
count dword 0
grade dword 0
buffersize equ 41
buffer byte buffersize dup(0)
prompt byte "Enter a number: ",0
promptdesc byte "Grade Averager. Enter a number greater than 100 or less then 0 to exit. ",0
promptavg byte "Average: ",0
promptrem byte "Division Rem: ",0
promptcount byte "Count: ",0
prompterr byte "Terminating program, here are the results",0
promptdiverr byte "Division by zero, results may be inaccurate",0
.code
main PROC
;we are more important than everything else
call Clrscr
mov edx,OFFSET promptdesc
call WriteString
call Crlf
;input loop
InLoop:
mov edx, OFFSET prompt
call WriteString
;input handle
mov edx, OFFSET buffer
mov ecx, sizeof buffer
call ReadString
;check chars read
cmp eax, 0
jz Done
;convert to dword
mov edx, offset buffer
mov ecx, eax
call ParseInteger32
;check range
jo DoneE
cmp eax, 0
jl Done
cmp eax, 100
jg Done
;add to sum and count
add sum, eax
inc count
;if we made it this far everything is good
;for another go
jmp InLoop
;quit error
DivEr:
mov edx, offset promptdiverr
call WriteString
jmp Fin

DoneE:
mov edx, offset prompterr
call WriteString
call Crlf
jmp Fin
;quit normal
Done:
;check for 0 count
cmp sum, 0
je DivEr
;print stuff
;average printing
mov edx, offset promptavg
call WriteString
mov eax,sum
mov edx,0
idiv count ;answer in eax
push edx
call WriteDec
call Crlf
;remainder printing
mov edx, offset promptrem
call WriteString
pop edx
mov eax, edx
call WriteDec
call Crlf
;count printing
mov edx, offset promptcount
call WriteString
mov eax, count
call WriteDec
call Crlf
;keep program open after execution is finished so user can read output
Fin:
call Crlf
call WaitMsg
mov edx, offset buffer
mov ecx, sizeof buffer
call ReadString
exit
main ENDP
END main
