.intel_syntax noprefix
.text
.globl start

# Program to print out hello
start:
    mov rcx, 0x5A454C55524D4354     # setting up to push string onto the stack in reverse order
    push rcx
    xor rax, rax                # zeroing out rax
    mov al, 1                   # setting rax to 1 for write syscall
    mov rdi, rax                # setting rdi to fd of stdout
    mov rsi, rsp                # stack pointer pointing to string to print
    xor rdx, rdx                # zeroing out rdx
    mov dl, 8                   # length of string to print
    syscall
