;The last program
; Description:    Assembly Program 4
;	This program is a node network topology simulator. It creates a set of nodes
;	and connects them together through pointers. User can create a message. They
;	have the choice to specify the starting and ending nodes. They then type
;	the message in to send. The TTL counter is automatically set to 5 each time
;	because that's the max amount of jumps that a packet can have and not reach
;	the target node. 
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
nodesRecv	byte	6	 dup(0)		;used for keeping track which nodes have been processed each tx cycle
didTx		byte	1	 dup(0)		;used for keeping track of whether or not a message transmitted
echoOn		byte	1	 dup(0)		;used to keep track if the user wants to turn echo on or off
totalTime	byte	1	 dup(0)		;keeps track of total time being processed
msgRecv		byte	1	 dup(0)		;keeps track of messages received
totalMsgs	byte	1	 dup(0)		;keeps track of total amount of messages
temp1		dword	1	 dup(0)
temp2		dword	1	 dup(0)
temp3		dword	1	 dup(0)
temp4		dword	1	 dup(0)

;
;message structure
QUEUE_DEST 		equ 0	;message destination				-1 byte
QUEUE_SRC		equ 1	;message source						-1 byte
QUEUE_ORG		equ 2	;message origin (last touched)		-1 byte
QUEUE_TTL		equ 3	;Time to Live (and let die)			-1 byte
QUEUE_MSG		equ 4	;Message value						-10 bytes
QUEUE_MSG_SIZE	equ 10	;Size of message, limits size of the message
QUEUE_SS 		equ 15	;total message size (for now)
msg				byte	QUEUE_SS	 dup(0)		;holds the transmission message structure

;=======Strings=======
welcome_msg byte "Welcome to the Nodetrix!!!",0
bye_msg     byte "Congrats on taking the blue pill",0
file_msg	byte "Enter File Name",0

;node structure
;constants in the structure
;byte name				- character value A through F
;byte connections		- number of connections to the node
;dword txqueue			- address of the transmit queue
;dword inPtr			- pointer to the receiving queue
;dword outPtr			- pointer to the transmit queue
;variable space in the structure
;note: multiplied for how many connections there are
;dword node				- pointer to a connected node
;dword tx				- pointer to that node's tx queue
;dword rx				- pointer to that node's rx queue
;dword connection		- pointer from tx to rx?
nodes byte 2000 dup(0)

;constants for pulling data from the structure
;constant structure data fields
;total size: 18 bytes
name			equ		0		;offset of the name					size: 1 byte
connections		equ		1		;offset of the connections			size: 1 byte
txqueue			equ		2		;offset of the txqueue				size: 4 bytes
rxqueue			equ		6		;offset of the outPtr				size: 4 bytes *3
constNodesize	equ		18		;size of the constant space in each node
;variable sized structure data fields
nextNode		equ		18		;offset of the next node pointer	size: 4 bytes
nodeConnection	equ		22		;offset of the next node connection	size: 4 bytes
varNodeSize		equ		8		;size of each variable space in the node

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
;PROCEDURES
;

;
;fillArray
;@setup
;mov edi,offset array
;mov ecx,sizeof array
;mov al,(desired content to fill)
;
fillArray PROC
	dec edi
fillArrayLoop:
	inc edi
	mov byte ptr[edi],al
	dec ecx
	cmp ecx,0
	jg fillArrayLoop
	ret
fillArray ENDP

;
;toUpperCase
;steps through a null terminated string and converts all 
;characters to uppercase
;@set up
;mov edx,offset str
toUpperCase PROC
	push edx
	push eax
	dec edx					;initialize edx so that it corrects to the first value when looping
toUpperLoop:				;loop for stepping through the entire string
	inc edx					;go to the next character value
	mov eax,0				;clear eax
	mov al,byte ptr[edx]	;move the character in the string to al so you can play around with it
	cmp al,0
	je toUpperDone			;loop back up to the toUpperLoop label if the character in the string is not a null terminator
	cmp al,'a'
	jl toUpperLoop			;nothing needs to be done because the character is less then 'a', so go back to toUpperLoop
	cmp al,'z'
	jg toUpperLoop
	sub al,20h				;change character to upper case
	mov byte ptr[edx],al	;move the character back into the string
	jmp toUpperLoop
toUpperDone:
	pop eax
	pop edx
	ret
toUpperCase ENDP

;
;cpyString
;copies a string starting in edi to another variable in esi
;@set up:
;mov edi,offset source
;mov esi,offset target
;
cpyString PROC
	push eax
cpyStringLoop:
	mov al,byte ptr[edi]			;move the contents of the source into eax
	mov byte ptr[esi],al					;copy the contents into the target
	inc edi
	inc esi
	cmp al,0						;check for the null character
	jne cpyStringLoop				;jump back if the null character isn't encountered
cpyStringDone:
	pop eax
	ret
cpyString ENDP

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
	;jmp cont
	;
	push edx
	push eax
	println " "
	print "txQueue: "
	mov edx,edi
	add edx,txqueue			;point to the txqueue field
	mov eax,dword ptr[edx]	;move the pointer over to the eax register
	call WriteDec			;print the pointer
	print "	rxQueue: "
	mov edx,edi
	add edx,rxqueue			;point to the rxqueue field
	mov eax,dword ptr[edx]	;move the pointer over to the eax register
	call WriteDec
	print ", "
	add edx,4				;point to the next rxqueue field
	mov eax,dword ptr[edx]
	call WriteDec
	print ", "
	add edx,4				;point to the next rxqueue field
	mov eax,dword ptr[edx]
	call WriteDec
	pop eax
	pop edx
cont:
	
	;go to the next node
	println " "
	println "	Connections content: "
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
	call makeMsg			;create the message that will be transmitted
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
	println "3. Create a message to transmit"
	println "4. Step in time so messages transmit"
	println "5. Quit"
	ret
dispMenu ENDP

;
;dispMsgStruct
;displays the contents of the msg structure
;will mainly be used for debugging and checking contents of the msg structure
dispMsgStruct PROC
	mov edx,offset char
	inc edx
	mov byte ptr[edx],0			;null terminate the character holder
	;start working with the msg structure
	mov edi,offset msg			;move the msg structure's address into edi
	mov edx,edi
	add edx,QUEUE_DEST
	mov eax,0
	mov al,byte ptr[edx]
	mov char,al
	print "Destination: "
	mov edx,offset char
	call WriteString			;print the destination
	mov edx,offset msg
	add edx,QUEUE_SRC
	mov al,byte ptr[edx]
	mov char,al
	print "	Source: "
	mov edx,offset char
	call WriteString			;print the source
	;print out the origin of the message
	print "	Org: "
	mov edx,offset msg
	add edx,QUEUE_ORG			;offset to the org field
	mov al,byte ptr[edx]
	mov char,al					;move the character into the character holder thinga ma bob
	mov edx,offset char
	mov ecx,sizeof char
	call WriteString			;print out the org field
	;print out the TTL of the message
	print "	TTL: "
	mov edx,offset msg
	add edx,QUEUE_TTL
	mov al,byte ptr[edx]		;move the TTL into al
	add al,30h					;cast TTL to a character value
	mov char,al					;store TTL character value into the char holder
	mov edx,offset char
	mov ecx,sizeof char
	call WriteString			;print the TTL field out
	;print out the msg field
	println " "
	print "Message: "
	mov edx,offset msg
	add edx,QUEUE_MSG
	call WriteString
	
	ret
dispMsgStruct ENDP

;
;exitProgram
;exits the program
;in a function for ease of use
exitProgram PROC
	INVOKE ExitProcess,0
exitProgram ENDP

;source node in eax
;source buff in esi
;cflag if full
encqueue proc
	pushad
	;check for full
	mov ebx, eax;
	mov ecx, eax;
	add ebx, rxqueue
	add ecx, txqueue
	
	cmp ebx, ecx
;	je MaybeFull
JustKidding:
	add ebx, QUEUE_SS
	;check overflow
	push eax
	xor ecx, ecx
	mov ecx, ebx
	;check exceeds the follow
	;queueptr + QUEUE_SS * size of queue
	mov eax, QUEUE_SS
	mov edx, 10 ; TODO: change to queuesize
	imul edx
	add ecx, eax
	cmp  ecx, dword ptr [eax + rxqueue]
	je Adjust
	
Adjust:	
	pop eax
	;start move
	mov ecx, QUEUE_SS
	cld
	mov edi, ebx
Moving:
	rep movsb	
Done:
	clc
	jmp Done
Full:
;	setc
;Done:
	popad
encqueue endp 

;nodeptr in edi
;cflag if full
dequeue proc
;	mov ebx, [edi + DQUEUE_C]
;	cmp ebx, [edi + EQUEUE_C]
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
	push eax
	mov edx,offset msg
	mov al,byte ptr[edx]
	cmp al,0
	je getSource
	println "Message field is already filled, cannot create another message"
	jmp makeMsgDone
getSource:
	print "Enter source node: "
	mov edx,offset buffer
	mov ecx,sizeof buffer
	call ReadString			;store character into buffer
	mov edx,offset buffer
	call toUpperCase
	mov al,byte ptr[edx]	;move the character into entered into al
	cmp al,'A'
	jl getSource			;reprompt if character entered is less then 'A'
	cmp al,'F'
	jg getSource			;reprompt if character entered is greater then 'F'
	mov edx,offset msg
	add edx,QUEUE_SRC
	mov byte ptr[edx],al		;move the character into the msg structure source field
getDest:
	print "Enter destination node: "
	mov edx,offset buffer
	mov ecx,sizeof buffer
	call ReadString			;store the destination in buffer
	mov edx,offset buffer
	call toUpperCase
	mov al,byte ptr[edx]	;move the character entered in al
	cmp al,'A'
	jl getDest				;if letter entered is less then 'A' then reprompt
	cmp al,'F'
	jg getDest				;if letter entered is greater then 'F' then reprompt
	mov edx,offset msg
	add edx,QUEUE_DEST
	mov byte ptr[edx],al	;move the destination into the msg structure
getOrg:
	;the origin of the preceeding node will be itself when initially sent
	mov edx,offset msg
	add edx,QUEUE_SRC		;set the pointer equal to the src field in the msg struct
	mov al,byte ptr[edx]	;pull the src out of the msg
	mov edx,offset msg
	add edx,QUEUE_ORG		;offset to the org field in the msg
	mov byte ptr[edx],al	;move the src data into the org data
getTTL:
	;time to live will always be set to 5 initially
	mov edx,offset msg
	add edx,QUEUE_TTL		;offset to the TTL field
	mov byte ptr[edx],5		;move 5 over to the TTL field
getMessage:
	;retrieve the message to send
	print "message: "
	mov edx,offset buffer
	mov ecx,10				;limit to 10 because of limit of msg structure
	call ReadString
	mov edi,offset buffer	;set esi up for the cpyString procedure
	mov esi,offset msg
	add esi,QUEUE_MSG		;point to the msg field
	call cpyString			;copy the buffer over to the msg QUEUE_MSG field
getEcho:
	print "Echo?(y/n): "
	mov edx,offset char
	mov ecx,1
	call ReadString			;get user input
	mov edx,offset char
	call toUpperCase		;convert character to upper case
	cmp char,'Y'
	jne getEchoDone
	cmp char,'N'
	jne getEchoDone
	jmp getEcho
getEchoDone:
	mov edi,offset echoOn
	mov eax,offset char
	mov al,byte ptr[eax]
	mov echoOn,al			;move the character value into echo

	println "Message contents: "
	call dispMsgStruct
	;TODO put msg structure into the queues
	mov edi,offset nodes
	mov edx,offset msg
	add edx,QUEUE_SRC		;point to the src field in the message
	mov al,byte ptr[edx]	;move the src character into al
	println " "
	cmp al,'A'
	jne makeMsg1
	add edi,aOffset
	println "Placing message in node A"
	jmp makeMsg6
makeMsg1:
	cmp al,'B'
	jne makeMsg2
	add edi,bOffset
	println "Placing message in node B"
	jmp makeMsg6
makeMsg2:
	cmp al,'C'
	jne makeMsg3
	add edi,cOffset
	println "Placing message in node C"
	jmp makeMsg6
makeMsg3:
	cmp al,'D'
	jne makeMsg4
	add edi,dOffset
	println "Placing message in node D"
	jmp makeMsg6
makeMsg4:
	cmp al,'E'
	jne makeMsg5
	add edi,eOffset
	println "Placing message in node E"
	jmp makeMsg6
makeMsg5:
	cmp al,'F'
	jne makeMsg6
	add edi,fOffset
	println "Placing message in node F"
makeMsg6:
	;done figuring out what the source node was
	add edi,rxqueue			;point to the tx queue 
	mov eax,offset msg		;move msg's pointer into eax
	mov dword ptr[edi],eax	;mov msg's pointer into the correct position
makeMsgDone:
	pop eax
	ret
makeMsg ENDP

;
;addNodesRecv
;adds a character value to nodesRecv
;used for the tx function in stepTime
;@setup
;mov al,character
;
addNodesRecv PROC
	push ebx
	push edx
	push ecx
	push edi
	mov edx,offset nodesRecv	;move the offset of nodesRecv into edx
	mov ebx,6					;6 node slots in this baby
cycleNodesRecv:
	mov cl,byte ptr[edx]		;move the character value from nodesRecv over for comparison
	cmp cl,0
	je cycleNodesRecvDone		;did we hit a null?
	dec ebx
	cmp ebx,0
	jle addNodesRecvFin			;if we've gone through 6 characters we've gone too far
	cmp cl,al
	jne cycleNodesRecv			;if characters != then go to the next character
	jmp addNodesRecvFin			;character dup detected, don't add al to nodesRecv
cycleNodesRecvDone:
	mov edx,offset nodesRecv
	dec edx
cycleNodesRecvLoop2:
	inc edx
	mov cl,byte ptr[edx]
	cmp cl,0
	jne cycleNodesRecvLoop2
	mov byte ptr[edx],al		;move the character to the nodesRecvArray
addNodesRecvFin:
	pop edi
	pop ecx
	pop edx
	pop ebx
	ret
addNodesRecv ENDP

;
;clearRxAndTx
;clears all the nodes rx and tx fields
;
clearRxAndTx PROC
	push edx
	push eax
	mov edx,offset nodes

	;clear the node A rx and tx
outerLoop:
	mov al,byte ptr[edx]
	mov char,al
	push edx
	mov edx,offset char
	print "Wiping rx and tx of node "
	call WriteString
	println " "
	pop edx
	add edx,txqueue
	mov dword ptr[edx],0		;clear the field
	sub edx,txqueue
	add edx,rxqueue
	mov dword ptr[edx],0
	add edx,4
	mov dword ptr[edx],0
	add edx,4
	mov dword ptr[edx],0
	sub edx,4
	sub edx,4
	sub edx,rxqueue				;reset to the beginning of the node now
	add edx,connections
	mov al, byte ptr[edx]		;move the number of connections over to al
	sub edx,connections
	add edx,constNodesize		;add the constant node size to this sum bitch
innerLoop:
	add edx,varNodeSize
	dec al
	cmp al,0
	jg innerLoop
	;see if we're at the end of the nodes
	mov eax,offset nodes
	add eax,fOffset
	inc eax
	cmp edx,eax					;have we gotten through f yet?
	jl outerLoop

	pop eax
	pop edx
	ret
clearRxAndTx ENDP

;
;stepTime
;steps one step in time so that each queue can transmit a message
stepTime PROC
	push eax
	;check to see if the TTL is 0
	;if it is 0 then nullify the message and wipe all the tx queues

	mov edx,offset msg
	add edx,QUEUE_TTL		;point to the TTL field in the msg structure
	mov al,byte ptr[edx]	;move the TTL counter
	cmp al,0
	jg stepTimeStart			;if TTL is greater then 0 then transmit the message
	;or else you will have to wipe the msg structure
	println "TTL counter depreciated, destroying message"
	mov edi,offset msg
	mov ecx,QUEUE_SS
	mov al,0
	call fillArray			;fill the msg structure with null characters
	;TODO wipe the tx and rx fields in each node
	call clearRxAndTx
	jmp finalCont

stepTimeStart:					;transmit the message
	mov edi,offset nodesRecv	;going to clear nodesRecv
	mov ecx,6				;size of 6 slots in the nodesRecv array
	mov al,0
	call fillArray			;fill up the nodesRecv array
	mov edi,offset nodes	;nodes pointer is now in edi
	mov eax,9999			;use eax to deliminate the first node 
stepTimeNextNode:
	;cycle through each node
	;print out which node is being processed
	print "Processing node "
	mov bl,byte ptr[edi]
	mov char,bl
	mov edx,offset char
	call WriteString		;print out the node currently being processed
	println " "
	cmp eax,9999
	je checkRxAndTxFields	;skip the adding offset if this is the first node
	;add the offset of the next node
	mov edx,edi
	add edx,connections		;point to the connections field in the nodes structure
	mov al,byte ptr[edx]	;move the number of connections to the al register
	add edi,constNodesize	;add the constant node size to edi
addVarNodeSize:
	add edi,varNodeSize		;add the variable node size to edi
	dec al
	cmp al,0
	jg addVarNodeSize		;if the connections field hasn't decremented to 0 then add another varNodeSize
	
checkRxAndTxFields:
	;check to see if both tx and rx fields are empty
	mov edx,edi
	add edx,txqueue
	cmp dword ptr[edx],0
	jne transmit		;there's something in the tx field, transmit that sucker
	mov edx,edi
	add edx,rxqueue
	mov eax,dword ptr[edx]
	cmp dword ptr[edx],0
	jne moveRxToTx			;there's something in the rx field, move that sucker up
	println "	Nothing in tx or rx queue"
	jmp checkEndOfNodes


transmit:
	println "	Transmitting to  connected nodes"
	mov edx,edi				;use as a temporary pointer for grabbing the tx queue contents
	add edx,txqueue
	mov ebx,dword ptr[edx]	;move the pointer from the tx queue into ebx, done with ebx until cycleThroughConnections
	mov dword ptr[edx],0	;clear the txqueue field because you have the data saved in ebx
	mov edx,edi
	add edx,connections		;point edx to the number of connections
	mov al,byte ptr[edx]	;move the number of connetions over to al so you can loop through each connection
	;time to start cycling through the connections
	mov esi,edi				;esi will contain the original address that can be switched up and cycled through
cycleThroughConnections:
	mov temp1,eax
	mov edx,esi				;mov node pointer to edx to access connections
	add esi,varNodeSize		;go to the next node connection
	add edx,nodeConnection	;point edx to the pointer to the connection
	mov edx,dword ptr[edx]	;move the pointer to the next node into edx

	;check to see if we should send the message to the previously connected node
	;cmp echo,'N'
	;je txContEcho			;if user doesn't want to echo back then we execute the follow code
	;yup, that requires a complete rehaul of the messaging system
	;nope, that's not happening at 2am

txContEcho:
	print "	Transmitting to node "
	mov al,byte ptr[edx]
	mov char,al
	call addNodesRecv		;add the node name to the nodesRecv array
	push edx
	mov edx,offset char
	call WriteString		;print out what node is being processed
	println " "
	inc totalMsgs
	mov didTx,1				;set the flag for whether or not the message transmitted
	pop edx
	add edx,rxqueue			;offset edx to the rxqueue field
	mov temp2,ebx				;save bl
	mov bl,0
	;point to the next available space in the receiving node's rxqueue field
cycleRxQueueData:
	mov eax,dword ptr[edx]	;move the rxqueue data into eax
	cmp eax,0
	je cycleRxQueueDataDone
	add edx,4				;go to the next queue
	inc bl
	cmp bl,3
	jl cycleRxQueueData		;check to see if there has been 3 slots viewed
cycleRxQueueDataDone:
	cmp bl,3
	jne cycleRxQueueDataCont
	println "	Receiving node's rx queue is full"
	jmp checkEndOfNodes		;go to the next node since the rx field is full   ???
cycleRxQueueDataCont:
	mov ebx,temp2
	mov dword ptr[edx],ebx	;move the node's tx queue into the connected node's rx queue

	mov eax,temp1
	dec al
	cmp al,0				;check to see if we're at the end of the connections
	jg cycleThroughConnections
	jmp checkEndOfNodes		;go to the end of the function and check to see if we're at the end of the nodes

	;move the rxqueue up to the txqueue
moveRxToTx:
	;check to see if there's anything in the rx queue, if not, just cycle to the next node
	println "	Moving node's rx data to the tx field"
	jmp moveRxUp		;;;Testing
	mov edx,edi
	add edx,rxqueue			;point to the rxqueue field
	;move rx queue to the tx queue, if there's a node character in nodesRecv[] && rxqueuesize > 1
	;	don't move the rx queue to the tx queue
	mov bl,0				;if bl==1 by the end then a letter was in the nodesRecv array
	mov esi,edi				;copy the nodes pointer to esi
	mov al,byte ptr[esi]	;pull the name of the node that is being operated on out of the structure
	mov esi,offset nodesRecv	;move the pointer of nodesRecv into esi
	dec esi					;offset esi so it corrects at the beginning of the loop
	;time to step through the nodesRecv array to check to see if any nodes had transmitted to that node
stepTimeNodesRecv:
	inc esi					;go to the next array slot
	mov cl,byte ptr[esi]	;move the character out, can also be a null byte to deliminate the end of the array
	cmp cl,0				
	je stepTimeNodesRecvDone	;go to the end of the loop if the byte pulled is a null byte
	cmp cl,al				;compare the byte pulled from nodesRecv to the node name currently being processed
	jne stepTimeNodesRecv	;go to the loop again if the characters compared were not equal to one another
	mov bl,1				;move a 1 into bl to signify that there was the same character in the nodesRecv array
	;can just break out of loop because we found the character
stepTimeNodesRecvDone:
	;check to see if bl==1 and that rxqueue has more then 1 item in queue
	mov edx,edi				;copy the nodes address over to the 
	add edx,rxqueue			;point to the rxqueue field
	add edx,4				;point to the second rxqueue field
	cmp byte ptr[edx],0		;check to see if it's null
	jne moveRxUp
	cmp bl,1
	je stepTimeNextNode		;if both bl==1 and rxqueue+4==0 then you don't want to transmit
moveRxUp:
	;check to see if msg's destination is equal to the current node's
	;	this will prevent the moving of the packet to the tx field
	mov esi,offset msg
	add esi,QUEUE_DEST
	mov al,byte ptr[esi]	;move the message destination into al
	mov bl,byte ptr[edi]	;move the current character into bl
	cmp al,bl
	jne moveRxUpCont
	println "****Message arrived at destination node****"
	inc msgRecv
	dec totalMsgs
moveRxUpCont:
	mov edx,edi
	add edx,rxqueue			;point to the rxqueue
	mov eax,dword ptr[edx]	;move the rx pointer to the eax register
	mov edx,edi
	add edx,txqueue			;point to the txqueue
	mov dword ptr[edx],eax	;move the pointer to the txqueue field
	;will have to move the rest of the queue up a slot in the 3 slot array
	;nullify the first slot of the rxqueue
	mov edx,edi
	add edx,rxqueue
	mov dword ptr[edx],0	;move the 0 over to the rxqueue field
	;now it's time to move the next queue slots up 
	add edx,4				;move to the next rx queue slot
	mov eax,dword ptr[edx]
	sub edx,4				;move edx back to the first rxqueue slot
	mov dword ptr[edx],eax	;move the data back into the first slot
	add edx,8				;point to the last slot in the queue
	mov eax,dword ptr[edx]	;move the last queue's contents into eax
	sub edx,4				;move edx back to the second rxqueue slot
	mov dword ptr[edx],eax	;move the 3rd queue slot to the 2nd queue slot
	
checkEndOfNodes:
	mov eax,offset nodes
	add eax,fOffset
	add eax,constNodeSize
	add eax,varNodeSize
	add eax,varNodeSize
	add eax,varNodeSize
	cmp eax,edi
	jne stepTimeNextNode	;if the address is less then the end of the nodes then go back to the next node

stepTimeDone:
	cmp didTx,1
	jne finalcont
	mov edx,offset msg
	add edx,QUEUE_TTL		;go to the TTL field in the msg structure
	dec byte ptr[edx]		;decrement the TTL field
	mov didTx,0				;reset the didTx flag
finalcont:
	inc totalTime
	println " "
	print "Total time: "
	movzx eax,totalTime
	call WriteDec			;print the total time
	println " "
	print "Messages received: "
	movzx eax,msgRecv
	call WriteDec
	println " "
	print "Total messages: "
	movzx eax,totalMsgs
	call WriteDec
	pop eax
	ret
stepTime ENDP

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
	ckEqual '3',makeMsg				;Create a message for the user to transmit
	ckEqual '4',stepTime			;step in time to transmit message and the such
	ckEqual '5',exitProgram			;exit the program for the user
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
