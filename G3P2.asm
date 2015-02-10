TITLE Assembly Program 1  by Group 3

; Description:    Assembly Program 1
; Class:          CSC
; Members:        Sean Curtis, Max Conroy, John Kirshner
; Revision date:  2/2

Include Irvine32.inc
.386
.model flat
.data
STACKDATASIZE eq 4
dstack dsword 8 DUP(0)
shead word

.code
;pop MACRO
;result in eax
pops PROC 
cmp shead, 0;
push edi
mov eax,shead
inc eax
;check size
cmp eax, 8
jge ERROR
mov shead,eax
mul eax, STACKDATASIZE
mov edi,eax
pop eax
mov dstack[edi], eax
pop edi
clc
ret
ERROR: nop
pop edi
setc
ret
ENDP

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
mul eax, STACKDATASIZE
mov edi,eax
pop eax
mov dstack[edi], eax
pop edi
clc
ret
ERROR: nop
pop eax
pop edi
setc
ret
ENDP
;add macro
add MACRO
;sub macro
adds MACRO

ENDM
;div macro
divs MACRO

ENDM
;mul macro
muls MACRO

ENDM
;exch macro
exchs MACRO

ENDM
;neg macro
negs MACRO

ENDM
;roll up macro
rollu MACRO

ENDM
;roll down
rolld MACRO

ENDM
;view stack macro
views MACRO


ENDM
;clear stack macro
clears MACRO

ENDM


main PROC
;title/desc

;start loop


;endloop


main ENDP
END main