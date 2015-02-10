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


;ckEqual
;checks to see if a value, in eax, is equal to the value inputted
ckEqual MACRO char
  cmp eax,char
  mov ebx,0x40
  and ebx,eflags
  add ecx,ebx
ENDM

;check if an ascii value is a valid operation
;valid operations: +,-,*,/,X,N,U,D,V,C,Q
;input is in eax
;@return 1 in ebx if value is digit, otherwise 0
checkOp PROC
  mov ecx,0
;check for '+'
  ckEqual '+'
;check for '-'
  ckEqual '-'
;check for *
  ckEqual '*'
;check for /
  ckEqual '/'
;check for 'X' or 'x'
  ckEqual 'X'
  ckEqual 'x'
;check for 'N' or 'n'
  ckEqual 'N'
  ckEqual 'n'
;check for 'U' or 'u'
  ckEqual 'U'
  ckEqual 'u'
;check for 'D' or 'd'
  ckEqual 'D'
  ckEqual 'd'
;check for 'V' or 'v'
  ckEqual 'V'
  ckEqual 'v'
;check for 'C' or 'c'
  ckEqual 'C'
  ckEqual 'c'
;check for 'Q' or 'q'
  ckEqual 'Q'
  ckEqual 'q'
;check to see if the zero bit was set at any point
  cmp ecx,0x64
  jz  valid
invalid:
  mov ebx,0
  jmp fin
valid:
  mov ebx,1
fin:
  ret
checkOp ENDP
