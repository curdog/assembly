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
  
  accum word 0
  
  promptbeg byte "Enter numbers separated by spaces Q to exit",0
  prompterrc byte "Bad char",0
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
;  mov ecx,ah
  cmp buffer[edi],'Q'
  lahf
  mov al,ah
  mov ah,0
  
  
;more data

;process number loop


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
exit
main ENDP
END main
