;The last program
; Description:    Assembly Program 4
; Class:          CSC 323
; Members:        Sean Curtis, Max Conroy, John Kirshner

.486
;.model flat, stdcall

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
QUEUE_N		equ 10
QUEUE_S 	equ QUEUE_N * QUEUE_SS			;queue 
RXARRPTR_C 	equ QUEUE_C + QUEUE_S		;array pointer for rx queue
RXARRPTR_S 	equ RXARRPTR_C + 4			;size of rx array
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
	mov edi, offset nodesptr
	;node a
	;use edx for offsets for now
	mov word ptr[edi + SIZE_C], nodesptr_s
	mov byte ptr[edi + NAME_C], 'A'
	mov byte ptr[edi + DQUEUE_C], 0
	mov byte ptr[edi + EQUEUE_C], 0
	  
	mov byte ptr[edi + RXARRPTR_S], 3
	

	;move other rx buffer offsets here
	;math for A
	
;	mov [edi + TXARRPTC_C],
	;math for B
;	mov [edi + TXARRPTC_C],	
	;math for C
;	mov [edi + TXARRPTC_C],	
	;math for D
	
	mov eax, edi
	add eax, 4
	
	mov byte ptr[edi + TXARRPTR_S], 3
	
;	mov [edi + CONNS_C],
	mov eax, edi
	add eax, CONNS_C
	
	mov byte ptr [eax], 'B'
	mov byte ptr[eax + 1], 'C'
	mov byte ptr[eax + 2], 'D'
	
	;change node
	add edi, nodesptr_s
	;node b

	;change node
	add edi, nodesptr_s	
	;node c

	;change node
	add edi, nodesptr_s
	;node d
	popad
	ret
nodeinit endp 


;helper functions
;======================================
;adds element to queue
;msg ptr in eax
;nodeptr from in edi
;cflag if full
encqueue proc
	pushad
	mov ebx, [edi + EQUEUE_C]
	inc ebx						;temporary increment
	
	push eax					;mod for circular
	mov eax, ebx
	mov eax, QUEUE_S
	call moduOp
	mov ebx,eax
	pop eax
	
	cmp [edi+DQUEUE_C], ebx
	jz Full						;full
 	;copy
	mov [edi+EQUEUE_C], ebx 	;save new index
	;calculate index
	push eax
	xor eax,eax
	mov al, byte ptr [edi+EQUEUE_C]
	mov ecx, QUEUE_SS
	mul ecx			;calculate offset of mesg
	add eax,edi					;add to addr of node
	mov ebx,eax
	pop eax
	
	xor ecx,ecx					;zero
Copy:
	movzx edx,byte ptr[eax+ecx]				;move
	xor eax,eax
	mov al,byte ptr[ebx+ecx+QUEUE_S]
	mov edx, eax
	inc ecx
	cmp ecx, QUEUE_SS						;check size
	jl Copy
	clc
	jmp Done
Full:
;	setc
Done:
	popad
encqueue endp 

;nodeptr in edi
;cflag if full
dequeue proc
	mov ebx, [edi + DQUEUE_C]
	cmp ebx, [edi + EQUEUE_C]
	jz Empty
	
	dec ebx
	clc
	jmp Done
Empty:
;	setc
Done:
	popad
dequeue endp 

;performs modulus
;eax --- number
;ebx --- radius
;return
;eax --- result
moduOp proc 
	push edx
	push ecx
	
	xor edx, edx
	mov ecx, ebx
	div ecx
	mov eax, edx
	
	pop ecx
	pop edx
	ret
moduOp endp 

;node functions (local level)
;=============================
handletx proc

handletx endp 

handlerx proc

handlerx endp 

;process functions (world level)
;===============================
txstep proc

txstep endp 

rxstep proc

rxstep endp 


;log processing
;===============================
.data
;used in functions
logFileHandle dword 0
;used everywhere else
logFileName byte 80 dup(0)
logFileLogStr byte 120 dup(0)
.code

;writes line to log
;automagically appends \n
;edx - offset of string
;ecx - charaters to write
;cf set if not successful
logMesg proc
	pushad
	mov eax, logFileHandle
	call WriteToFile
	cmp eax, ecx
	jz Good
;	setc
	popad
	ret
Good:
	clc
	popad
	ret
logMesg endp 

;opens a log file
;edx - filename offset
;carry flag if not good
logOpen proc
	pushad
	call CreateOutputFile
	mov logFileHandle, eax
	cmp eax, INVALID_HANDLE_VALUE
	jz Good
;	setc
	popad
	ret
Good:
	clc
	popad
	ret
logOpen endp 

;
;close logfile
;zf if not good
logClose proc
	pushad
	mov eax, logFileHandle
	call CloseFile
	cmp eax, 0	;set zf if not good
	popad
logClose endp 

;entry point
main proc
	call nodeinit
main endp 
END main