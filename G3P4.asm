;The last program
; Description:    Assembly Program 4
; Class:          CSC 323
; Members:        Sean Curtis, Max Conroy, John Kirshner

.486
.model flat, stdcall

Include Irvine32.inc
.data

;message structure
QUEUE_DEST 	equ 0	;message destination				
QUEUE_SRC	equ 1	;message source
QUEUE_ORG	equ 2	;message origin (last touched)
QUEUE_REC	equ 3	;message received flag 0-no  AOV-yes 
QUEUE_TTL	equ 4	;Time to Live (and let die)
QUEUE_MSG_S	equ 5	;Size of message (constant for now, place holder for awesome)
QUEUE_MSG_V equ 6	;Message value

QUEUE_SS 	equ 10	;total message size (for now)
		
;node structure
;note: fixed length members should go first, calculate rest
SIZE_C equ 0						;size of node (max total bytes is 16kb)
NAME_C equ 2						;name of node
DQUEUE_C equ 3						;end index of queue
EQUEUE_C equ 4						;start index of queue
QUEUE_C equ 5 						;set size to 10 to start
QUEUE_S equ 10 * QUEUE_SS			;queue size
RXARRPTR_C equ QUEUE_C + QUEUE_S	;array pointer for rx queue
RXARRPTC_S equ RXARRPTR_C + 4		;size of rx array
TXARRPTR_C equ RXARRPTR_S + 1		;array pointer of pointers for tx queue
TXARRPTR_S equ TXARRPTR_C + 4		;size of tx array
CONNS_C equ TXARRPTR_S + 1			;string array of connection names
DATA_C equ CONNS_C + 4				;start of the data portion
;data is a bunch of bytes allocated after this data
;formula for node size
;size = 25 + QUEUE_S * QUEUE_SS + (n * 12) : where n is number of nodes (for perfect networks)
;node pointers

;4 nodes to start, all connected
;              |---------------formula-------------| * #nodes
nodesptr byte ( 25 +    QUEUE_S * QUEUE_SS + 3 * 12) * 4     dup(0)
;node

.code
;init of nodes
nodeinit proc
	;node a
	
	;node b
	
	;node c
	
	;node d

endp nodeinit


;helper functions

;adds element to queue
;data in eax
;nodeptr in edi
encqueue proc

endp encqueue


dequeue proc

endp dequeue

;node functions (local level)
handletx proc

endp handletx

handlerx proc

endp handlerx

;process functions (world level)
txstep proc

endp txstep

rxstep proc

endp rxstep

;entry point
main proc
	call nodeinit
endp main