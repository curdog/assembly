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
SIZE_C 		equ 0						;size of node (max total bytes is 16kb)
NAME_C 		equ 2						;name of node
DQUEUE_C	equ 3						;end index of queue
EQUEUE_C 	equ 4						;start index of queue
QUEUE_C 	equ 5 						;set size to 10 to start
QUEUE_S 	equ 10 * QUEUE_SS			;queue size
RXARRPTR_C 	equ QUEUE_C + QUEUE_S		;array pointer for rx queue
RXARRPTC_S 	equ RXARRPTR_C + 4			;size of rx array
TXARRPTR_C 	equ RXARRPTR_S + 1			;array pointer of pointers for tx queue
TXARRPTR_S 	equ TXARRPTR_C + 4			;size of tx array
CONNS_C 	equ TXARRPTR_S + 1			;string array of connection names
DATA_C 		equ CONNS_C + 4				;start of the data portion
;data is a bunch of bytes allocated after this data
;formula for node size
;size = 25 + QUEUE_S * QUEUE_SS + (n * 12) : where n is number of nodes (for perfect networks)
;node pointers

;4 nodes to start, all connected
;              |---------------formula-------------| * #nodes
nodesptr byte ( 25 +    QUEUE_S * QUEUE_SS + 3 * 12) * 4     dup(0)
nodesptr_s equ ( 25 +    QUEUE_S * QUEUE_SS + 3 * 12) * 4
;node

.code
;init of nodes
nodeinit proc
	pushad
	;node size
	mov ebx, nodesptr_s
	push ebx
	mov edi, nodesptr
	;node a
	;use edx for offsets for now
	mov [edi + SIZE_C], notesptr_s
	mov [edi + NAME_C], 'A'
	mov [edi + DQUEUE_C], 0
	mov [edi + EQUEUE_C], 0
	  
	mov [edi + RXARRPTC_S], 3
	

	;move other rx buffer offsets here
	;math for A
	
	mov [edi + TXARRPTC_C],
	;math for B
	mov [edi + TXARRPTC_C],	
	;math for C
	mov [edi + TXARRPTC_C],	
	;math for D
	
	mov eax, edi
	add eax, 4
	
	mov [edi + TXARRPTC_S], 3
	
	mov [edi + CONNS_C],
	mov eax, edi
	add eax, CONNS_C
	
	mov [eax], 'B'
	mov [eax + 1], 'C'
	mov [eax + 2], 'D'
	
	;change node
	add edi + nodesptr_s
	;node b

	;change node
	add edi + nodesptr_s	
	;node c

	;change node
	add edi + nodesptr_s
	;node d
	popad
endp nodeinit


;helper functions

;adds element to queue
;msg ptr in eax
;nodeptr from in edi
;cflag if full
encqueue proc
	pushad
	mov ebx, [edi + EQUEUE_C]
	inc ebx						;temporary increment
	cmp [edi+DQUEUE_C], ebx
	jz Equal					;full
 	;copy
	mov [edi+EQUEUE_C], ebx 	;save new index
	
	
	
	mov edx, QUEUE_SS
Equal:
	setc
Done:
	popad
endp encqueue

;msg ptr in eax
;nodeptr in edi
;zflag if full
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

open

logMesg proc

endp logMesg



;entry point
main proc
	call nodeinit
endp main