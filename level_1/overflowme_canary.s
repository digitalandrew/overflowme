	.file	"overflowme_canary.s"
    .intel_syntax noprefix
	.text
	.section	.rodata
intro_message:
	.string	"My buffer is open for input, please don't overflow me!\n"
	.equ intro_length, .-intro_message -1

outro_message:
	.string	"Thanks for not overflowing me!\n"
	.equ outro_length, .-outro_message -1
	

overflow_message:
	.string	"\nHey you overflowed me!\n"
	.equ overflow_length, .-overflow_message -1

	.text
	.globl	echo_print
	.type	echo_print, @function
echo_print:
	# start of function prologue
	push rbp
	mov	rbp, rsp
	# code to store stack canary onto the stack
	mov rcx, fs:40                              # stack canary from OS can be read from fs:40
	push rcx                                    # push the stack canary onto the stack right before the callers BP and return address
	
	sub rsp, 512								# allocate space on stack for buffer to hold input string (this is the equivalent in C of a local variable declared as char buffer[512])
	# code to read user input and store onto stack
	mov rax, 0					                # setting rax for read syscall
	mov rdi, 0					                # fd for STDIN (0)
	lea rsi, QWORD PTR -512[rbp]                # pointer to allocated space on the stack
	mov rdx, 1023          	                    # this should match buffer size to prevent overflow
    syscall
	# code to echo out message
	mov rdx, rax								# length of string input is returned from read syscall into rax, moving it into rdx
    mov rax, 0x01			                    # 0x01 is write syscall
	mov rdi, 1				                    # setting fd to STDOUT (1)
	lea rsi, QWORD PTR -512[rbp]	            # pointer to start of message to print
	syscall
	# code to verify stack canary has not been tampered with
	mov rcx, fs:40					            # re-read the stack canary from the OS
	xor rcx, QWORD PTR -8[rbp]                  # check stack canary from the OS with the stack canary that was placed onto the stack, if they are equal then XOR will return 0
	test rcx, rcx                               # check if zero which means stack canary has not been modified
	jnz overflow_detected                       # if not zero, this means the stack is corrupted and we should not return from the call
	mov rsp, rbp
	pop rbp
	ret
	overflow_detected:
	# Start of function code to print overflow detected message, this is similar to the "*** Stack Smashing Detected *** : terminated" message and functionality in the default stack canaries implemented by GCC
    mov rax, 0x01			                    # 0x01 is write syscall
	mov rdi, 1				                    # setting fd to STDOUT (1)
	lea rsi, overflow_message[rip]	    		# pointer to start of message to print
	mov rdx, overflow_length  					# length fo string to print
	syscall
	# Syscall to exit
    mov rax, 60                                 # syscall sub function to exit
    mov rdi, 1                                  # return 1 for standard error
    syscall

	.text
	.globl	main
	.type	main, @function
main:
	push rbp
	mov	rbp, rsp
	# Start of code to print intro message
    mov rax, 0x01			                    # 0x01 is write syscall
	mov rdi, 1				                    # setting fd to STDOUT (1)
	lea rsi, intro_message[rip]	                # pointer to start of message to print
	mov rdx, intro_length			            # length fo string to print
	syscall
	call echo_print
	# Start of code to print outro message
    mov rax, 0x01			                    # 0x01 is write syscall
	mov rdi, 1				                    # setting fd to STDOUT (1)
	lea rsi, outro_message[rip]	                # pointer to start of message to print
	mov rdx, outro_length			            # length fo string to print
	syscall
	mov	eax, 0
	mov rsp, rbp
	pop	rbp
	ret
	.size	main, .-main
	.section	.note.GNU-stack,"",@progbits
