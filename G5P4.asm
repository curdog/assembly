;The last program
; Description:    Assembly Program 4
; Class:          CSC 323
; Members:        Sean Curtis, Max Conroy, John Kirshner

.486
;.model flat, stdcall

Include Irvine32.inc
.data
;general data
buffer		byte	25	 dup(0)		;used for input
dest		byte	1	 dup(0)		;destination node
source		byte	1	 dup(0)		;source node
char		byte	2	 dup(0)		;used for temporarily printing out character values

;
;message structure
QUEUE_DEST 		equ 0	;message destination				
QUEUE_SRC		equ 1	;message source
QUEUE_ORG		equ 2	;message origin (last touched)
QUEUE_TTL		equ 4	;Time to Live (and let die)
QUEUE_MSG_SIZE	equ 5	;Size of message (constant for now, place holder for awesome)
QUEUE_MSG		equ 6	;Message value
QUEUE_SS 		equ 12	;total message size (for now)
msg				byte	QUEUE_SS	 dup(0)		;holds the transmission message structure

;=======Strings=======
welcome_msg byte "Welcome to the Nodetrix!!!",0
bye_msg     byte "Congrats on taking the blue pill",0
file_msg	byte "Enter File Name",0

;test node structure
;constants in the structure
;byte name				- character value A through F
;byte connections		- number of connections to the node
;dword txqueue			- address of the transmit queue
;dword inPtr			- pointer to the receiving queue?
;dword outPtr			- pointer to the transmit queue?
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
inPtr			equ		6		;offset of the inPtr				size: 4 bytes
outPtr			equ		10		;offset of the outPtr				size: 4 bytes
constNodesize	equ		14		;size of the constant space in each node
;variable sized structure data fields
;total size: 16 bytes
nextNode		equ		14		;offset of the next node pointer	size: 4 bytes
nodetx			equ		18		;offset of the next node tx pointer	size: 4 bytes
noderx			equ		22		;offset of the next node rx pointer	size: 4 bytes
nodeConnection	equ		26		;offset of the next node connection	size: 4 bytes
varNodeSize		equ		16		;size of each variable space in the node

;offfsets for the different nodes
aOffset			equ		0
bOffset			equ		aOffset+constNodesize+varNodeSize*2		;2 variable connections from A
cOffset			equ		bOffset+constNodesize+varNodeSize*3		;3 variable connections from B
dOffset			equ		cOffset+constNodesize+varNodeSize*3		;3 variable connections from C
eOffset			equ		dOffset+constNodesize+varNodeSize*2		;2 variable connections from D
fOffset			equ		eOffset+constNodesize+varNodeSize*3		;3 variable connections from E

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
;ckEqual
;checks to see if a value, in eax, is equal to the value inputted
ckEqual MACRO char, func
  LOCAL nit
  cmp eax,char
  jnz nit
  call func
  nit:
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
	;initialize the node connection pointers
	;initialize the B node connection pointer
	add edi,constNodeSize		;point edi to the beginning of the variable node structure part
	mov byte ptr[edi],'B'		;Puts 'B' into the location manually, it isn't initialized yet
	mov eax,offset nodes
	add eax,bOffset				;point eax to the B node's address
	mov edx,edi
	sub edx,constNodeSize		;reset to the initial node A connection so that you can offset to the connection
	add edx,nodeConnection		;offset to the node connection so you can link the two nodes up
	mov dword ptr[edx],eax		;should be the location of B
	;;initialize the F node connection pointer
	add edi,varNodeSize
	mov byte ptr[edi],'F'		;F isn't initialized yet so just throw the letter straight into it
	mov eax,offset nodes
	add eax,fOffset				;point eax to node F's location
	mov edx,edi
	sub edx,constNodeSize		;reset edx to the beginning of node A with an offset of 1 varNodeSize
	add edx,nodeConnection		;point edx to the node connection field
	mov dword ptr[edx],eax		;location of F is now in the data structure

	;initialize the B node
	println "Initializing the B node..."
	;B has 3 connections	(A C E)
	add edi,varNodeSize			;coming from A so add 2 variable node connections to the offset
	mov edx,edi
	mov byte ptr[edx],'B'		;put the 'B' in
	mov edx,edi
	add edx,connections			;move to the offset of the connections field
	mov byte ptr[edx],3			;3 connections to the node (A C F)
	;;time to link up the nodes to B
	;link A node to B node
	mov edx,edi					;move the pointer over to the temporary space
	add edx,nodeConnection		;move to the pointer location of the first node
	mov eax,offset nodes
	mov dword ptr[edx],eax		;move the pointer address over to the structure
	mov al,byte ptr[eax]
	mov edx,edi					;copy the address of B over to edx again
	add edx,nextNode			;offset to the next node
	mov byte ptr[edx],al		;move the character A over into the data Structure
	;link C node to B node
	add edi,varNodeSize			;go to the next variable node size
	mov edx,edi
	add edx,nextNode			;set to the next node
	mov byte ptr[edx],'C'		;C isn't initialized yet so just throw it in there
	sub edx,nextNode			;set back to point to pointer location
	add edx,nodeConnection		;offset to the pointer location
	mov eax,offset nodes
	add eax,cOffset				;add to the offset of nodes the offset of C node
	mov dword ptr[edx],eax
	;link E node to B node
	add edi,varNodeSize
	mov edx,edi
	add edx,nextNode
	mov byte ptr[edx],'E'		;move the character in since that node isn't initialized yet
	sub edx,nextNode
	add edx,nodeConnection		;set edx to the offset of the nodeConnection so you can link the two together
	mov eax,offset nodes
	add eax,eOffset				;add the offset of the E node to the nodes address
	mov dword ptr[edx],eax

	;initialize the C node
	;C has 3 connections (B D F)
	println "Initializing the C node..."
	add edi,constNodeSize
	add edi,varNodeSize			;coming from B so add 3 variable node connections to the offset
	mov edx,edi
	mov byte ptr[edx],'C'		;move the C value into the C node
	mov edx,edi
	add edx,connections
	mov byte ptr[edx],3			;3 connections to the C node (B D E)
	;;time to initialize all the node connections
	;link C node to B node
	mov edx,edi
	add edx,nextNode
	mov eax,offset nodes
	add eax,bOffset				;move the B node offset to eax so you can pull the character value
	mov al,byte ptr[eax]		;move the character over
	mov byte ptr[edx],al		;throw that character into the structure
	sub edx,nextNode
	add edx,nodeConnection		;set to the node connection field
	mov eax,offset nodes
	add eax,bOffset				;pull B node's address
	mov dword ptr[edx],eax		;copy the address over
	;link C node to D node
	add edi,varNodeSize
	mov edx,edi					;copy into a temporary pointer holder
	add edx,nextNode			;offset to the nextNode field
	mov byte ptr[edx],'D'		;D isn't initialized so just put the character in manually
	sub edx,nextNode
	add edx,nodeConnection		;offset to the nodeConnection field
	mov eax,offset nodes
	add eax,dOffset				;offset eax to the D node
	mov dword ptr[edx],eax		;move the pointer over to the nodeConection field
	;link C node to F node
	add edi,varNodeSize
	mov edx,edi
	add edx,nextNode			;offset to the nextNode field
	mov byte ptr[edx],'F'		;manually put F in because the F node isn't initialized yet
	sub edx,nextNode
	add edx,nodeConnection		;offset to the nodeConnection field
	mov eax,offset nodes
	add eax,fOffset				;offset eax to the F node's address
	mov dword ptr[edx],eax		;move the F node's address into the nodeConnection field

	;initialize the D node
	;D has 2 connections (C E)
	println "Initializing the D node..."
	add edi,constNodeSize
	add edi,varNodeSize			;coming from C so add 3 variable node connections to the offset
	mov edx,edi
	mov byte ptr[edx],'D'		;move the 'D' value into the structure
	add edx,connections
	mov byte ptr[edx],2			;2 connections to the D node (C E)
	;;link up the nodes connected to D
	;link C node to D node
	mov edx,edi
	add edx,nextNode			;offset edx to the nextNode field
	mov eax,offset nodes
	add eax,cOffset				;offset eax to the C node
	mov al,byte ptr[eax]		;move the C character over to al
	mov byte ptr[edx],al		;move the C character over to the nextNode field
	sub edx,nextNode
	add edx,nodeConnection		;reoffset to the nodeConnection field
	mov eax,offset nodes
	add eax,cOffset				;offset eax to the C node
	mov dword ptr[edx],eax		;move the address into the nodeConnection field
	;link E node to D node
	add edi,varNodeSize
	mov edx,edi
	add edx,nextNode			;offset edx to the nextNode field
	mov byte ptr[edx],'E'		;E isn't initialized so move the character manually
	sub edx,nextNode
	add edx,nodeConnection		;offset edx to the nodeConnection field
	mov eax,offset nodes
	add eax,eOffset				;move the offset of E node into eax
	mov dword ptr[edx],eax		;move the address of E node into the nodeConnection field

	;initialize the E node
	;E has 3 connections (B D F)
	println "Initializing the E node..."
	add edi,constNodeSize
	add edi,varNodeSize			;coming from D which has 2 variable connections
	mov edx,edi
	mov byte ptr[edx],'E'		;move the 'E' value into the E node
	add edx,connections
	mov byte ptr[edx],3			;3 connections to the node (B D F)
	;;link the nodes to the E node
	;link the B node to the E node
	mov edx,edi
	add edx,nextNode			;offset to the nextNode field
	mov eax,offset nodes
	add eax,bOffset				;offset eax to the B node
	mov al,byte ptr[eax]		;move the character over to al
	mov byte ptr[edx],al		;move the B node character over to the nextNode field
	sub edx,nextNode
	add edx,nodeConnection		;offset to the nodeConnection field
	mov eax,offset nodes
	add eax,bOffset				;offset eax to the B node
	mov dword ptr[edx],eax		;move the B node address into the nodeConnection field
	;link the D node to the E node
	add edi,varNodeSize			;offset to the next variable node structure
	mov edx,edi
	add edx,nextNode			;point edx to the nextNode field
	mov eax,offset nodes
	add eax,dOffset				;move the D address into eax
	mov bl,byte ptr[eax]
	mov byte ptr[edx],bl		;move the D character over to the nextNode field
	sub edx,nextNode
	add edx,nodeConnection		;offset edx to the nodeConnection field
	mov dword ptr[edx],eax		;move the address of the D node to the nodeConnection field
	;link the F node to the E node
	add edi,varNodeSize
	mov edx,edi
	add edx,nextNode
	mov byte ptr[edx],'F'		;manually move the F character over since F isn't initialized
	sub edx,nextNode
	add edx,nodeConnection		;offset to the nodeConnection field
	mov eax,offset nodes
	add eax,fOffset				;move the F offset into eax
	mov dword ptr[edx],eax		;move the pointer over

	;initialize the F node
	;F has 3 connections (A C E)
	println "Initializing the F node..."
	add edi,constNodeSize
	add edi,varNodeSize			;coming from E which has 3 variable connections
	mov edx,edi
	mov byte ptr[edx],'F'		;put the 'F' value into the F node
	add edx,connections
	mov byte ptr[edx],3			;3 connections to the F node (A C E)
	;;link the F node with other nodes
	;link the A node with the F node
	mov edx,edi
	add edx,nextNode			;point edx to the nextNode field
	mov eax,offset nodes
	add eax,aOffset				;point eax to the A node
	mov bl,byte ptr[eax]		;move the character over to bl
	mov byte ptr[edx],bl		;move the character value over to the nextNode field
	sub edx,nextNode
	add edx,nodeConnection		;offset edx to the nodeConnection field
	mov dword ptr[edx],eax		;move node A's address into the nodeConnection field
	;link the C node with the F node
	add edi,varNodeSize
	mov edx,edi
	add edx,nextNode			;offset to the nextNode field
	mov eax,offset nodes
	add eax,cOffset				;offset eax to to the C node
	mov bl,byte ptr[eax]		;move the character to bl
	mov byte ptr[edx],bl		;move the character over to the nextNode field
	sub edx,nextNode
	add edx,nodeConnection		;offset edx to the nodeConnection field
	mov dword ptr[edx],eax		;move the address of the C node into the nodeConnection field
	;link the E node with the F node
	add edi,varNodeSize
	mov edx,edi
	add edx,nextNode			;move edx to the nextNode field
	mov eax,offset nodes
	add eax,eOffset				;position eax to the E node address
	mov bl,byte ptr[eax]		;move the character over to the bl register
	mov byte ptr[edx],bl
	sub edx,nextNode
	add edx,nodeConnection		;offset to the nodeConnection field
	mov dword ptr[edx],eax		;move E's address into the nodeConnection field

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
	println "	Connections: "
	add edi,constNodeSize	;add the constant node size to skip over the constant space
varNodeSizeLoop:
	;display what the structure is pointing to
	print "	Node: "
	mov ebx,offset char
	push eax				;save eax
	mov al,byte ptr[edi]
	mov byte ptr[ebx],al
	mov edx,offset char
	call WriteString		;print out the node name

	;print out the memory location of the connected node
	print "		Address: "
	mov edx,edi
	sub edx,constNodeSize	;reset to the beginning so you can print the node connection address
	add edx,nodeConnection
	mov eax,dword ptr[edx]
	call WriteDec			;print the address
	pop eax					;pop eax

	add edi,varNodeSize		;add the variable node size for each connection
	println " "				;print a carriage return
	dec eax
	cmp eax,0
	jg varNodeSizeLoop		;cycle through the variable structure space

	dec ecx
	cmp ecx,0				;have we reached the end of the structure yet?
	jg dispLoop				;if not, jump back up the beginning of dispNodes
	ret
dispNodes ENDP

;
;transmitMessage
;transmits a message through the node system
;
transmitMessage PROC
	println "Placeholder"
	ret
transmitMessage ENDP

;
;dispConnections
;displays all the nodes and how they're connected to one another
;uses a kind of graphic display with ascii characters
;
dispConnections PROC
	println "   B-----------C"
	println "  / \____ ____/ \"
	println " A       X       D"
	println "  \ /---/ \---\ /"
	println "   F-----------E"
	ret
dispConnections ENDP

;
;dispMenu
;displays the menu so that the user can choose a command to execute
;
dispMenu PROC
	println "1. Display node connections"
	println "2. Display node information"
	println "3. Transmit a string from one node to another"
	println "4. Quit"
	ret
dispMenu ENDP

;
;exitProgram
;exits the program
;in a function for ease of use
exitProgram PROC
	INVOKE ExitProcess,0
exitProgram ENDP


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

;
;makeMsg
;creates the message that will be sent between nodes
;will have a header that consists of the following fields
;Destination - 1 byte, will hold the destination node of the message
;Source		 - 1 byte, will hold the source node of the message
;Origin		 - 1 byte, will hold the node that sent the message
;TTL		 - 1 byte, time to live, how many hops the message will perform
;MessageSize - 1 byte, size of the message to transmit
;Message	 - equivalent to the MessageSize field
makeMsg PROC
	ret
makeMsg ENDP

;
;switchMenu
;a switch case menu kind of system
;will be used in conjunction with the dispMenu to let
;the user choose what action to perform
;will be an ascii value of '1' to '4'
switchMenu PROC
	movzx eax,buffer
	ckEqual '1',dispNodes			;display the node information for the user
	ckEqual '2',dispConnections		;display the node connections for the user
	ckEqual '3',transmitMessage		;transmit a message for the user
	ckEqual '4',exitProgram			;exit the program for the user
	ret
switchMenu ENDP

;
;main procedure
;executes the main loop of the program, is the spine of the program
;
main proc
	call initNodes			;initialize all the nodes
	println " "				;throw an extra carriage return in there

loopMain:
	call dispMenu			;display the menu
	print ": "				;prompt the user
	mov edx,offset buffer
	mov ecx,sizeof buffer
	call ReadString			;read user input
	mov eax,0
	mov al,buffer			;move the character that buffer is pointing to into al to prep for switchMenu
	call switchMenu			;call the procedure that is basically a switch menu
	println " "				;print out a carriage return
	jmp loopMain			;branch back up the mainLoop infinitely until user decides to exit

main endp 
END main
