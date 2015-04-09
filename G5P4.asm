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
QUEUE_S 	equ QUEUE_N * QUEUE_SS	;queue 
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
nodesptr byte  1000     dup(0)
nodesptr_s equ 1000
;node

;=======Strings=======
char		byte 2 dup(0)		;used for temporarily printing out character values
welcome_msg byte "Welcome to the Nodetrix!!!",0
bye_msg     byte "Congrats on taking the blue pill",0
file_msg	byte "Enter File Name",0

;test node structure
;constants in the structure
;byte name				- character value A through F
;byte connections		- number of connections to the node
;dword txqueue			- address of the transmit queue
;dword inPtrtxqueue		- pointer to the receiving queue?
;dword outPtrtxqueue	- pointer to the transmit queue?
;variable space in the structure
;note: multiplied for how many connections there are
;dword node				- pointer to a connected node
;dword tx				- pointer to that node's tx queue
;dword rx				- pointer to that node's rx queue
;dword connection		- pointer from tx to rx?
nodes byte 2000 dup(0)

;constants for pulling data from the structure
;constant structure data fields
;total size: 14 bytes
name			equ		0		;offset of the name					size: 1 byte
connections		equ		1		;offset of the connections			size: 1 byte
txqueue			equ		2		;offset of the txqueue				size: 4 bytes
inPtrtxqueue	equ		6		;offset of the inPtrtxqueue			size: 4 bytes
outPtrtxqueue	equ		10		;offset of the outPtrtxqueue		size: 4 bytes
constNodesize	equ		14		;size of the constant space in each node
;variable sized structure data fields
;total size: 16 bytes
nextNode		equ		14		;offset of the next node pointer	size: 4 bytes
nodetx			equ		18		;offset of the next node tx pointer	size: 4 bytes
noderx			equ		22		;offset of the next node rx pointer	size: 4 bytes
nodeConnection	equ		26		;offset of the next node connection	size: 4 bytes
varNodeSize		equ		16		;size of each variable space in the node

.code
;
;Macros
;
;print
;takes in a string literal and prints it out
;@text a string literal to pass
;
print MACRO text
	LOCAL str
	.data
	str byte text,0
	.code
	push edx
	mov edx, offset str
	call WriteString
	pop edx
ENDM
;
;println
;takes in a string literal and prints it out along with a CR and LF
;@text a string literal to pass
;
println MACRO text
	LOCAL str
	.data
	str byte text,0Dh,0Ah,0
	.code
	push edx
	mov edx, offset str
	call WriteString
	pop edx
ENDM

;
;initNodes
;initializes all the nodes in the network
;
initNodes PROC
	mov edi,offset nodes		;move into edi the offset of the nodes structure

	;initialize the A node
	println "Initializing the A node..."
	;A has 2 connections	(B F)
	mov edx, edi				;copy address over to temporary space
	mov byte ptr[edx],'A'		;move the A connection name into the structure
	;calculate the offset of the 'B' node to input into the pointer of A
	mov ebx,edi					;copy a temporary offset into ebx
	add ebx,constNodeSize		;add the constantNodeSize
	add	ebx,varNodeSize				;add the variable node size
	add ebx,varNodeSize				;There's 2 nodes, add twice
	mov edx,edi
	add edx,connections
	mov byte ptr[edx],2			;2 connections added

	;initialize the B node
	println "Initializing the B node..."
	;B has 3 connections	(A C F)
	add edi,constNodeSize
	add edi,varNodeSize
	add edi,varNodeSize			;coming from A so add 2 variable node connections to the offset
	mov edx,edi
	mov byte ptr[edx],'B'		;put the 'B' in
	mov edx,edi
	add edx,connections			;move to the offset of the connections field
	mov byte ptr[edx],3			;3 connections to the node (A C F)

	;initialize the C node
	;C has 3 connections (B D F)
	println "Initializing the C node..."
	add edi,constNodeSize
	add edi,varNodeSize
	add edi,varNodeSize
	add edi,varNodeSize			;coming from B so add 3 variable node connections to the offset
	mov edx,edi
	mov byte ptr[edx],'C'		;move the C value into the C node
	mov edx,edi
	add edx,connections
	mov byte ptr[edx],3			;3 connections to the C node (B D E)

	;initialize the D node
	;D has 2 connections (C E)
	println "Initializing the D node..."
	add edi,constNodeSize
	add edi,varNodeSize
	add edi,varNodeSize
	add edi,varNodeSize			;coming from C so add 3 variable node connections to the offset
	mov edx,edi
	mov byte ptr[edx],'D'		;move the 'D' value into the structure
	add edx,connections
	mov byte ptr[edx],2			;2 connections to the D node (C E)

	;initialize the E node
	;E has 3 connections (C D F)
	println "Initializing the E node..."
	add edi,constNodeSize
	add edi,varNodeSize
	add edi,varNodeSize			;coming from D which has 2 variable connections
	mov edx,edi
	mov byte ptr[edx],'E'		;move the 'E' value into the E node
	add edx,connections
	mov byte ptr[edx],3			;3 connections to the node (C D F)

	;initialize the F node
	;F has 3 connections (A C E)
	println "Initializing the F node..."
	add edi,constNodeSize
	add edi,varNodeSize
	add edi,varNodeSize
	add edi,varNodeSize			;coming from E which has 3 variable connections
	mov edx,edi
	mov byte ptr[edx],'F'		;put the 'F' value into the F node
	add edx,connections
	mov byte ptr[edx],3			;3 connections to the F node (A C E)

	println "Initialization complete."
	ret
initNodes ENDP

;
;dispNodes
;displays all of the nodes and their contents
;displays memory addresses where necessary
;
dispNodes PROC
	mov edi,offset nodes
	mov ecx,6				;6 nodes, will want to loop 6 times
dispLoop:
	;display the character of the node
	print "Node: "
	mov ebx,offset char		;move offset of the character "string"
	mov al,byte ptr[edi]	;node character moved into eax
	mov byte ptr[ebx],al	;copy the contents of the character of the node over to the character "string"
	mov edx,offset char
	call WriteString		;print the character
	;display the number of connections
	print "	Connections: "
	mov edx,edi
	add edx,connections		;move to the offset of the connections
	movzx eax,byte ptr[edx]	;move the contents number of connections over to the eax register
	call WriteDec			;and print it out
	
	;go to the next node
	add edi,constNodeSize	;add the constant node size to skip over the constant space
varNodeSizeLoop:
	add edi,varNodeSize		;add the variable node size for each connection
	dec eax
	cmp eax,0
	jg varNodeSizeLoop		;cycle through the variable structure space

	println " "				;throw out the carriage return for orderly data
	dec ecx
	cmp ecx,0				;have we reached the end of the structure yet?
	jg dispLoop				;if not, jump back up the beginning of dispNodes
	ret
dispNodes ENDP


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
;performs inner node operations
;node in edi
handletx proc
	pushad
;have msg?

;for each conn
;set des rxptr to txptr -> queue


	popad
	ret
handletx endp 
	
handlerx proc
	pushad
	
	popad
	ret
handlerx endp 

;process functions (world level)
;===============================
;performs outer node operations
txstep proc
	pushad
	;for each node
		;do handletx
	popad
	ret
txstep endp 

rxstep proc
	pushad
	popad
	ret
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
	ret
logClose endp 

;entry point
main proc
	call initNodes
	call dispNodes
	call logOpen
	mov edx, offset welcome_msg
	call WriteString
	
	call txstep
	call rxstep
	
	mov edx, offset bye_msg
	call logClose
	call WriteString
	call Waitmsg			;just wait up at the end for now
	INVOKE ExitProcess,0
main endp 
END main
