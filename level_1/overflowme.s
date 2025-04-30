	.file	"overflowme.s"
    .intel_syntax noprefix
	.text
	.section	.rodata
intro_message:
	.string	"My buffer is open for input, please don't overflow me!\n"
	.equ intro_length, .-intro_message -1

outro_message:
	.string	"Thanks for not overflowing me!\n"
	.equ outro_length, .-outro_message -1

hidden_message:
	.string	"Hey you're not supposed to be here!\n"
	.equ hidden_length, .-hidden_message -1


	.text
	.globl	hidden_print
	.type	hidden_print, @function
hidden_print:
	# function prologue
	push rbp
	mov	rbp, rsp
	# code to echo out message
    mov rax, 0x01			                    # 0x01 is write syscall
	mov rdi, 1				                    # setting fd to STDOUT (1)
	mov rdx, hidden_length						# length of string to print
	lea rsi, hidden_message[rip]	            # pointer to start of message to print
	syscall
	# function epilogue
	mov rsp, rbp
	pop rbp
	ret

	.text
	.globl	main
	.type	main, @function


	.text
	.globl	echo_print
	.type	echo_print, @function
echo_print:
	# function prologue
	push rbp
	mov	rbp, rsp
	sub rsp, 512								# allocate space on stack for buffer to hold input string (this is the equivalent in C of a local variable declared as char buffer[512])
	# code to read user input and store onto stack
	mov rax, 0					                # setting rax for read syscall
	mov rdi, 0					                # fd for STDIN (0)
	lea rsi, QWORD PTR -512[rbp]                # pointer to allocated space on the stack
	mov rdx, 1023          	                    # this should match buffer size -1 to prevent overflow
	before_read_syscall:						# label to set breakpoint before filling buffer with read syscall
    syscall
	# code to echo out message
	mov rdx, rax								# length of string input is returned from read syscall into rax, moving it into rdx
    mov rax, 0x01			                    # 0x01 is write syscall
	mov rdi, 1				                    # setting fd to STDOUT (1)
	lea rsi, QWORD PTR -512[rbp]	            # pointer to start of message to print
	syscall
	# function epilogue
	before_function_return:						# label to set breakpoint before the function return
	mov rsp, rbp
	pop rbp
	ret

	.text
	.globl	main
	.type	main, @function
main:
	push rbp
	mov	rbp, rsp
	# code to print intro message
    mov rax, 0x01			                    # 0x01 is write syscall
	mov rdi, 1				                    # setting fd to STDOUT (1)
	lea rsi, intro_message[rip]	                # pointer to start of message to print
	mov rdx, intro_length			            # length of string to print
	syscall
	before_function_call:						# label to set breakpoint before the function call
	call echo_print
	return_from_function:						# label added to easily find return address from function call
	# code to print outro message
    mov rax, 0x01			                    # 0x01 is write syscall
	mov rdi, 1				                    # setting fd to STDOUT (1)
	lea rsi, outro_message[rip]	                # pointer to start of message to print
	mov rdx, outro_length			            # length of string to print
	syscall
	mov	eax, 0									# return 0 for no error
	# function epilogue
	mov rsp, rbp
	pop	rbp
	ret
	.size	main, .-main
	.section	.note.GNU-stack,"",@progbits
