TITLE Group 5 Exam 1 Program
;Exam 1 group 5 program
;
;
Include Irvine32.inc

.386
.model flat
.stack 4096

.data
  buffsize byte 80
  buffer byte 80 dup (0) 
  
  accum dword 0
  
  promptbeg byte "Enter numbers separated by spaces Q to exit: ",0
  prompterrc byte "Bad char",0
  promptend byte "End of Program.  Sum: ",0
.code
main PROC
;loop start
LOOPT: 
;friendly message
  mov edx, offset promptbeg
  call WriteString

;read input
  mov edx, OFFSET buffer
  mov ecx, sizeof buffer
  call ReadString
;jump quit
  mov ebx, eax
  mov eax,0
  sahf
  cmp ebx,1
  lahf
  movzx ecx,ah
  cmp buffer[edi],'Q'
  lahf
  mov al,ah
  and ebx,eax
  and ebx, 64
  cmp ebx, 64
  je ENDL
  
;more data
.data
  buf byte 80
  buf2 byte sizeof buf dup(0)

;process number loop
.code
mov esi,0
mov ecx, sizeof buf
NUMLOOP: nop
  mov al,buf[esi]
  mov buf2[esi],al
  inc esi
  loop NUMLOOP


;add into acc


;print nmber

;clear array
  mov edi, 0
CLRA: nop
  mov buffer[edi],0
  add edi,1
  cmp edi, 80
  jne CLRA
;quit
ENDL: nop

mov edx, offset promptend
call WriteString

mov eax,accum
call WriteInt

call Crlf
call WaitMsg

exit
main ENDP
END main

