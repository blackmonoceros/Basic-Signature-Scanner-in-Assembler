section .data
    filename    db "test_file.bin", 0      ; File to be scanned
    virus_sig   db 0xDE, 0xAD, 0xBE, 0xEF  ; Our "virus signature"
    sig_len     equ $ - virus_sig
    
    msg_clean   db "File is clean.", 10
    len_clean   equ $ - msg_clean
    msg_virus   db "ALARM! Virus signature detected!", 10
    len_virus   equ $ - msg_virus
    msg_error   db "Error: Could not open file.", 10
    len_error   equ $ - msg_error

section .bss
    buffer      resb 4096                  ; Buffer for file data
    bytes_read  resq 1

section .text
    global _start

_start:
    ; 1. Open the file (sys_open)
    mov rax, 2          ; syscall: open
    mov rdi, filename   ; file path
    mov rsi, 0          ; flags: O_RDONLY
    syscall
    
    cmp rax, 0
    jl error            ; If rax < 0, handle error
    mov r8, rax         ; Save file descriptor in r8

    ; 2. Read the file (sys_read)
    mov rax, 0          ; syscall: read
    mov rdi, r8         ; file descriptor
    mov rsi, buffer     ; buffer address
    mov rdx, 4096       ; bytes to read
    syscall
    mov [bytes_read], rax

    ; 3. Scanning Logic (Searching for the signature)
    mov rcx, [bytes_read]
    sub rcx, sig_len    ; Don't scan past the end of the data
    jl clean            ; If file is smaller than signature -> clean

    mov rsi, buffer     ; Pointer to file data

scan_loop:
    ; Compare current buffer fragment with the signature
    mov rax, 0
check_sig:
    movzx rbx, byte [rsi + rax]     ; Byte from buffer
    movzx rdx, byte [virus_sig + rax] ; Byte from signature
    cmp bl, dl
    jne next_byte                   ; If no match, move to next byte in buffer
    
    inc rax
    cmp rax, sig_len
    je virus_found                  ; If all bytes match -> virus detected
    jmp check_sig

next_byte:
    inc rsi
    loop scan_loop

clean:
    mov rax, 1          ; syscall: write
    mov rdi, 1          ; stdout
    mov rsi, msg_clean
    mov rdx, len_clean
    syscall
    jmp exit

virus_found:
    mov rax, 1          ; syscall: write
    mov rdi, 1          ; stdout
    mov rsi, msg_virus
    mov rdx, len_virus
    syscall
    jmp exit

error:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_error
    mov rdx, len_error
    syscall

exit:
    ; Close file and exit
    mov rax, 3          ; syscall: close
    mov rdi, r8
    syscall

    mov rax, 60         ; syscall: exit
    xor rdi, rdi
    syscall