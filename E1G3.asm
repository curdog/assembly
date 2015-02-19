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
  
  
  
  promptbeg byte "Enter numbers separated by spaces Q to exit: ",0
  prompterrc byte "Bad char ", 0
  promptend byte "End of Program.  Sum: ",0
  accum dword 0
.code
main PROC
;loop start
LOOPT: 
;friendly message
  mov edx, offset promptbeg
  call WriteString
  mov edi, 0
;read input
  mov edx, OFFSET buffer
  mov ecx, sizeof buffer
  call ReadString
;jump quit
  mov ebx, eax
  mov eax,0
  sahf
  cmp ebx,1
  je QCHE
  jmp SLOOP
  QCHE:
  cmp buffer[edi],'Q'
  je ENDL
  
SLOOP:
mov eax,0
;more data
MDLOOP:
mov ebx,0
PNLOOP: nop
  mov edi,eax
  
  cmp buffer[edi], ' '
  je ADDAC
  push eax
  mov eax,0
  mov al, buffer[edi]
  mov ecx, eax
  
  ;check for number col
  and ecx, 30h
  cmp ecx, 30h
  jne Error
  
  ;check for number row
  and eax, 0Fh
  cmp eax, 9
  jg Error

  ;shift and add
  imul ebx, 10
  add ebx,eax
  ;restore index
  pop eax
  inc eax
  cmp eax, 80
  jl PNLOOP

Error:
pop eax
mov edx, offset prompterrc
call WriteString
ADDAC:
;add into acc
add accum,ebx
inc eax ;skip space or bad data
cmp eax, 80
jl MDLOOP

;clear array
  mov edi, 0
CLRA: nop
  mov buffer[edi],0
  add edi,1
  cmp edi, 80
  jne CLRA
;quit
jmp LOOPT
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
