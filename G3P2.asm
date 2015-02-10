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