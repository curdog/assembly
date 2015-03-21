INCLUDE Irvine32.inc

.data

null              equ      0
TAB               equ      9
space             equ      32
      
RecordSize 	      equ      15
NumOfJobs         equ      10
JobAvailable      equ      0
JobRun            equ      1
JobHold           equ      -1
      
      
JobStatus         equ      0
JobPriority       equ      1
JobRuntime        equ      2
JobLoadTime       equ      3
JobRemainingTime  equ      5
JobName           equ      6

jobs              byte     NumOfJobs*RecordSize dup(JobAvailable)
EndOfJobs         dword    EndOfJobs

; Input Buffer declaration
buffsize          equ      81
buffer            byte     buffsize dup(null)
; Index for parsing the buffer.
bufferIndex       sdword   0

tokensize         equ      10
token             byte     tokensize dup(null)

MSIndex           sdword   0

initPrompt        byte     "Please Enter a Command",0Ah,0Dh,0

number            sdword   0


; ---- Help Menu Vars ----
MSHelp            byte     "HELP",0

; ---- Load Menu Vars ----
MSLoad            byte     "LOAD",0

; ---- Run Menu Vars ----
MSRun             byte     "RUN",0

; ---- Hold Menu Vars ----
MSHold            byte     "HOLD",0

; ---- Kill Menu Vars ----
MSKill            byte     "KILL",0

; ---- Show Menu Vars ----
MSShow            byte     "SHOW",0

; ---- Step Menu Vars ----
MSStep            byte     "STEP",0

; ---- Change Menu Vars ----
MSChange          byte     "CHANGE",0

; ---- Quit Menu Vars ----
MSQuit            byte     "QUIT",0


; FLAGS
quit              byte     0
found             byte     0


.code
main PROC

   ; DEBUG: Get Memory location
	call memHexOutput

L1:
   call ProcessCommand
   
   cmp quit,0
   jne L1end
   jmp L1
L1end:

	exit		; exit to operating system
main ENDP

; -----------------------------------------------
;
ProcessCommand PROC
   pushad
   call GetInput
   jc EndOfCase ;TODO: Jump to incrementing the system time
   call GetNextWord
   call MakeUpperCase
   
   mov esi, offset token
   mov edi, offset MSQuit
   mov ecx, sizeof MSQuit
   cld
   repe cmpsb
   JNE Case1
   mov quit, 1
   jmp EndOfCase
Case1:
   mov esi, offset token
   mov edi, offset MSHelp
   mov ecx, sizeof MSHelp
   cld
   repe cmpsb
   JNE Case2
   ;Call HelpFcn
   jmp EndOfCase
Case2:
   mov esi, offset token
   mov edi, offset MSLoad
   mov ecx, sizeof MSLoad
   cld
   repe cmpsb
   JNE Case3
   Call LoadFcn
   jmp EndOfCase
Case3:
   mov esi, offset token
   mov edi, offset MSRun
   mov ecx, sizeof MSRun
   cld
   repe cmpsb
   JNE Case4
   ;Call RunFcn
   jmp EndOfCase
Case4:
   mov esi, offset token
   mov edi, offset MSHold
   mov ecx, sizeof MSHold
   cld
   repe cmpsb
   JNE Case5
   ;Call HoldFcn
   jmp EndOfCase
Case5:
   mov esi, offset token
   mov edi, offset MSKill
   mov ecx, sizeof MSKill
   cld
   repe cmpsb
   JNE Case6
   ;Call KillFcn
   jmp EndOfCase
Case6:
   mov esi, offset token
   mov edi, offset MSShow
   mov ecx, sizeof MSShow
   cld
   repe cmpsb
   JNE Case7
   ;Call ShowFcn
   jmp EndOfCase
Case7:
   mov esi, offset token
   mov edi, offset MSStep
   mov ecx, sizeof MSStep
   cld
   repe cmpsb
   JNE Case8
   ;Call StepFcn
   jmp EndOfCase
Case8:
   mov esi, offset token
   mov edi, offset MSChange
   mov ecx, sizeof MSChange
   cld
   repe cmpsb
   JNE EndOfCase
   ;Call ChangeFcn
   jmp EndOfCase
EndOfCase:
   popad
   ret
ProcessCommand ENDP

; -----------------------------------------------
; 
LoadFcn PROC
   pushad
   call GetFreeJobSlot
   
   popad
   ret
LoadFcn ENDP




















; -----------------------------------------------
; 
GetFreeJobSlot PROC
   mov edi, offset jobs
   mov found, 0
GGJSL1:
   cmp edi, EndOfJobs
   jge endfind
   cmp byte ptr JobStatus[edi],0
   je foundone
   add edi, RecordSize
   jmp GGJSL1
foundone:
   mov found,1
endfind:
   ret
GetFreeJobSlot ENDP

; -----------------------------------------------
; 
GetInput PROC
   pushad
   call ClearBuffer
   call Crlf
   mov edx, offset initPrompt
   call WriteString
   
   mov edx,OFFSET buffer
	mov ecx,sizeof buffer
	call ReadString
   ; MAYBE keep count in bytecount
   call clearWhiteSpace
   popad
   ret
GetInput ENDP

; -----------------------------------------------
;
GetNextWord PROC
   pushad
   mov esi, 0
C1:
   cmp esi, tokensize
   jge GNWC1
   mov token[esi],null
   inc esi
   jmp C1
   
GNWC1:
   mov edi, bufferIndex
   mov esi, 0
   mov edx, 0
GNWL1:
   cmp esi,tokensize
   jge tokenFull
   cmp edi,buffsize
   jge GNWL1end
   mov dl, buffer[edi]
   cmp edx, 0
   je GNWL1end
   mov token[esi],dl
   inc edi
   inc esi
   jmp GNWL1

tokenFull:
   cmp edi,buffsize
   jge GNWL1end
   mov dl, buffer[edi]
   cmp edx, 0
   je GNWL1end
   inc edi
   jmp tokenFull
   
   
GNWL1end:
   mov bufferIndex, edi
   popad
   ret
GetNextWord ENDP


; -----------------------------------------------
; Convert next word in the buffer to uppercase
MakeUpperCase PROC
   pushad

   mov esi, 0
   mov edx, 0
   
MUCL1:
   cmp esi,tokensize
   jge MUCL1end
   mov dl, token[esi]
   cmp edx, 0
   je MUCL1end
   cmp edx, 'a'
   jl notlower
   cmp edx, 'z'
   jg notlower
   and edx,0DFh
notlower:
   mov token[esi],dl
   inc esi
   jmp MUCL1

MUCL1end:
   popad
   ret
MakeUpperCase ENDP


; -----------------------------------------------
; Shift index past the white-space in the buffer
clearWhiteSpace PROC
	pushad
	mov eax,buffsize
	mov edi,bufferIndex
	mov edx,0

cwsL1:
	mov dl,buffer[edi]
	cmp edx,null
	je cswEndReached
	cmp eax,ebx
	je cswEndReached 
	cmp edx,space
	je cswIncBuf
	; 09H is horizontal TAB
	cmp edx,TAB
	je cswIncBuf
	mov bufferIndex, edi
    clc
	jmp cwsext
	
cswIncBuf:
	inc edi
	jmp cwsL1
	
cswEndReached:
	stc
	
cwsext:
	popad
	ret
clearWhiteSpace ENDP

; -----------------------------------------------
; Convert to Decimal
cvtdec PROC
	pushad
	mov number,0
	mov eax,0
	mov ecx,0
	mov edx,0
	mov edi, bufferIndex
	mov ebx,10
	
cvdL1:
	mov dl,buffer[edi]
	cmp edx,0
	je cdvext
	cmp edx,'0'
	jl cdvext
	cmp edx,'9'
	jg cdvext
	; remove the 30h from the register to get the real number
	and edx,0FH
	mov ecx,edx
	imul ebx
	add eax,ecx
	inc edi
	jmp cvdL1

cdvext:
	mov number,eax
	mov bufferIndex, edi
	popad
	ret
cvtdec ENDP


; -----------------------------------------------
;
clearBuffer PROC
	pushad
	mov edi,0
cblp1:
	cmp edi,buffsize
	jge cblp1end
	mov buffer[edi],0
	inc edi
	jmp cblp1
cblp1end:
	mov bufferIndex, 0
	popad
	ret
clearBuffer ENDP


; -----------------------------------------------
; DEBUG Function - writes the hex address of the first variable to the 

screen for viewing the memory while debugging
memHexOutput PROC
	pushad
	; -------------------------------------
	; Used to get memory location of data
	; Offset variable has to be changed for each program to the first 

var declared
	mov eax,OFFSET jobs
	mov ebx,TYPE DWORD
	call WriteHexB
	call Crlf
	; -------------------------------------
	popad
	ret
memHexOutput ENDP



END main
