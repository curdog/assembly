;The last program
; Description:    Assembly Program 4
; Class:          CSC 323
; Members:        Sean Curtis, Max Conroy, John Kirshner

.486
.model flat, stdcall

Include Irvine32.inc
.data
;node structure
;note: fixed length members should go first
SIZE_C equ 0						;size of node (total bytes: max is 16k)
NAME_C equ 2						;name of node
DQUEUE_C equ 3						;end index of queue
EQUEUE_C equ 4						;start index of queue
QUEUE_C equ 5 						;set size to 10 to start
QUEUE_S equ 10						;queue size
RXARRPTR_C equ QUEUE_C + QUEUE_S	;array pointer for rx queue
RXARRPTC_S equ RXARRPTR_C + 4		;size of rx array
TXARRPTR_C equ RXARRPTR_S + 1		;array pointer of pointers for tx queue
TXARRPTR_S equ TXARRPTR_C + 4		;size of tx array
CONNS_C equ TXARRPTR_S + 1			;string array of connection names
DATA_C equ CONNS_C + 4				;start of the data portion
;data is a bunch of bytes allocated after this data


;node pointers


;node

.code

;helper functions
encqueue proc

endp encqueue


dequeue proc

endp dequeue

;process functions
txstep proc

endp txstep

rxstep proc

endp rxstep

;entry point
main proc

endp main