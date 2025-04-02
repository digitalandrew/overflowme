overflowme.o: overflowme.s
	as -g -o overflowme.o overflowme.s

overflowme: overflowme.o
	gcc -o overflowme overflowme.o
	rm -f overflowme.o

print_shellcode.o: print_shellcode.s
	as -g -o print_shellcode.o print_shellcode.s

print_shellcode: print_shellcode.o
	ld -e start -o print_shellcode print_shellcode.o
	rm -f print_shellcode.o

print_shellcode_rm_bad_chars.o: print_shellcode_rm_bad_chars.s
	as -g -o print_shellcode_rm_bad_chars.o print_shellcode_rm_bad_chars.s

print_shellcode_rm_bad_chars: print_shellcode_rm_bad_chars.o
	ld -e start -o print_shellcode_rm_bad_chars print_shellcode_rm_bad_chars.o
	rm -f print_shellcode_rm_bad_chars.o

all: overflowme.o overflowme print_shellcode.o print_shellcode print_shellcode_rm_bad_chars.o print_shellcode_rm_bad_chars

clean:
	rm -f overflowme.o
	rm -f overflowme
	rm -f print_shellcode
	rm -f print_shellcode_rm_bad_chars