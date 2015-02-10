TITLE Assembly Program 1  by Group 3

; Description:    Assembly Program 1
; Class:          CSC
; Members:        Sean Curtis, Max Conroy, John Kirshner
; Revision date:  2/2

Include Irvine32.inc
.386
.model flat
.data
dstack dsword 8 DUP(0)
shead word

.code
;pop MACRO
;result in eax
pops MACRO 
mov eax, dsword + shead
dec shead
ENDM
;push MACRO
;push in eax
pushs MACRO
mov eax, dsword + shead, eax
inc shead
ENDM
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


;check if an ascii value is a valid operation
;valid operations: +,-,*,/,X,N,U,D,V,C,Q
;input is in eax
;@return 1 in ebx if value is digit, otherwise 0
checkOp PROC
;check for '+'
  cmp eax,'+'
  jz valid
;check for '-'
  cmp eax,'-'
  jz valid
;check for *
  cmp eax,'*'
  jz valid
;check for /
  cmp eax,'/'
  jz valid
;check for 'X' or 'x'
  cmp eax,'X'
  jz valid
  cmp eax,'x'
  jz valid
;check for 'N' or 'n'
  cmp eax,'N'
  jz valid
  cmp eax,'n'
  jz valid
;check for 'U' or 'u'
  cmp eax,'U'
  jz valid
  cmp eax,'u'
  jz valid
;check for 'D' or 'd'
  cmp eax,'D'
  jz valid
  cmp eax,'d'
  jz valid
;check for 'V' or 'v'
  cmp eax,'V'
  jz valid
  cmp eax,'v'
  jz valid
;check for 'C' or 'c'
  cmp eax,'C'
  jz valid
  cmp eax,'c'
  jz valid
;check for 'Q' or 'q'
  cmp eax,'Q'
  jz valid
  cmp eax,'q'
  jz valid
invalid:
  mov ebx,0
  jmp fin
valid:
  mov ebx,1
fin:
  ret
checkOp ENDP
