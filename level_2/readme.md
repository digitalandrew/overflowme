# Overflowme Level 2 - Shellcodin' and Exploitin'

Your challenge should you accept it is to get the overflowme binary to print out message "TCMRULEZ" without modifying the source code. If you want to follow along with the walkthrough the rest of the readme will guide you through step by step instructions. 

## Step 1 - Assemble and Link the Binary

This level makes use of assembly source code to help teach about the basics of binary exploitation and the call stack. The assembly code has been tweaked from compiled C code to make it a bit more readable but closely mimics a stack overflow that could be present in poorly written C code. 

To assemble and link a Makefile has been provided. 

```bash
make overflowme
```

You can give the binary a spin now.

```bash
./overflowme
```

The binary performs an echo print that will echo back whatever you input to it (so long as you don't overflow it...).

## Step 2 - Stack Smashing Fundamentals

From the previous level we found that the binary was vulnerable to a stack overflow. By crafting a specifically crafted input (which we turned into an exploit) we were able to get the binary to jump to a section of code we shouldn't have access to and execute it to print the hidden message. In this challenge we need to print out a new message that's not included anywhere in the binary, to do this we'll need to exploit the stack overflow to run code that we generate instead of jumping to pre-existing code in the binary. To do this we'll perform a stack smashing attack, one of the oldest forms of stack overflow exploits. In this exploit, instead of filling up the stack with A's or random characters, we'll craft an input that fills the stack with code that we've written and then overwrite the return address so it points to the start of the code in the stack.  

## Step 3 - Writing Shellcode

When the overflowme binary is run, its content is loaded into memory as actual binary (hence why it's called a binary). The executable sections of the binary which are the "code" are in machine code format which is the 1s and 0s (or hexadecimal) representation of assembly. In order to inject code into the memory through the stack overflow vulnerability we found, we'll need it to be in raw machine code, which when working on exploits is commonly refferred to as the shellcode. In our case we won't be using it to spawn a shell, however that's the most common use of shellcode, which is how it got the name. 

There are multiple processes or steps to generate shellcode, one of the most common is to use a tool like msfvenom to generate it for you, however, it's best to learn how to write it yourself because you'll frequently be up against constraints that require custom shellcode and auto generated shellcode will most likely get picked up by AV and other detections. 

In this walkthrough I'm going to outline the method that I use. 

The first step is to start with assembly code and write a bare minimum program that will accomplish the task we want. Usually shellcode will simply set up for a system call and then make that system call to perform the task we want. In our case it's to print out a message. I like to refer to this [https://www.chromium.org/chromium-os/developer-library/reference/linux-constants/syscalls/](Table) hosted by the chromium project. Consulting the table we see that syscall number 1 is the write syscall and also a handy reference of what registers need to be set. Arg0(rdi) is set to the file descriptor, which in our case will be stdout, Arg1(rsi) is a pointer to the first char in the string to print, Arg2(rdx) is the number of chars we want to print. 

Here are the steps we'll need to take to write this basic program:

1. Push the string we want to print onto the stack in reverse order (we need everything to be self contained so we can't use a data section in our assembly)
2. Set RAX to the syscall number, which for read is 1
3. Set RDI to the file descriptor number for stdout which is also 1
4. Set RSI to point to the start of the string, which for us conveniently starting at the stack pointer
5. Set RDX to the length of the string to print (which is 8)

If you want to see my code for this, check out print_shellcode.s

After writing the assembly, the next step is to assemble, link it and then run the resulting binary to make sure it works.

I've included a makefile to make the process easier. 

```bash
make print_shellcode
```
We can now run it and make sure that it does what we want it to do (print out our string).

```bash
./print_shellcode
```

If yours worked properly you should see it print out TCMRULEZ and then crash with a seg fault. This is because we don't have a proper epilogue or exit to the program, but don't worry that's okay because we just want to stript the raw shellcode out of this. 

## Step 4 - Extracting the Shellcode 

Inside of our binary is the shellcode that we want to extract, there are a few ways to do this. First let's take a look at the contents of our binary with objdump, we can do this with: 

```bash
objdump -M intel -d print_shellcode
```
In the middle column we see the raw machine code for the binary, and the right column shows the assembly. Each line represents one instruction, and the actual raw machine code for each line is the opcode. So at this point we could manually pull out the machine code, however there is a better way to automate this. 

To start we'll used xxd to print out the raw hex with:

```bash
xxd -p print_shellcode
```

Now we have the raw hexcode for he entire binary, however we only need the hex for the machine code. If you take note of the objdump output I find it easiest to take note of the first few hex characters and the last few and then locate the machine code that way from the xxd output. I suggest using grep for this. 

```bash
xxd -p print_shellcode | grep -A2 48b954
```
Now you can easily copy all of the machine code starting from the first character all the way to the last. If you're ending on a syscall in x64 llinux then the opcode for that is 0f05 so that will always be the last two hex characters. 

Your raw hexcode should be: "48b954434d52554c455a5148c7c0
0100000048c7c7010000004889e64831d248c7c2080000000f05"


## Step 5 - Testing the Shellcode

The next step I like to do is test the shellcode and make sure that it will work before going to the trouble of crafting an exploit. I've included a simple C program that mimic closely what happens in a stack overflow so that we can attempt to execute raw shellcode and make sure it works properly. 

In order to use the shellcode we'll need it in what's called hexadecimal escape sequence which is where each hex character is escaped with \x. 

You can manually do this, however I don't have time for that so I've inlcuded a basic python script that can do it as well. 

```bash
python3 shellcode_formatter.py 48b954434d52554c455a5148c7c00100000048c7c7010000004889e64831d248c7c2080000000f05
```
This will spit you out the format we need, now we can copy this over to the test_shell.c code and paste it in. 

Now we can compile this test and run it, the compilation command is included as a comment in the file. 

```bash
gcc -o test_shell test_shell.c
```
Now run it with:

```bash
./test_shell.c
```
We see the output is the same as when we ran the binary, which means our shellcode is working, however I've added in an extra check that shows the length of the shellcode. The c code has detected that the shellcode is 15 bytes long, however our shellcode is much longer. 

## Step 6 - Removing Bad Characters

If you count through the raw shellcode 15 bytes, you'll notice that the 16th byte is \x00. In c 00 is used as a null terminator to represent the end of a string. Since most stack overflows in C are going to result from working with strings if we include a null terminator in our shellcode, then it's going to prevent the entire shellcode from being copied into the stack. This is what's refferred to as a bad character. Depending on the program there can be multiple bad characters as recall the program is initially processing our shellcode as data, mostly likely as ascii characters and it may filter out certain characters. 

In order to avoid this we need to re-write our shellcode to avoid these bad characters. In our example this is going to be to just avoid any null terminators. 

If you run objdump again and notice each of the opcodes we can see the offending instructions. 

mov rax, 0x1
mov rdi, 0x1
mov rdx, 0x8

All of these instructions have 0s in their corresponding opcodes, this is because when we move a single integer into the full registers it's actually moved as 0x00000001. We can easily get around this though. 

Insted of moving into the full register, we can instead mov into the low byte only. For example:

mov al, 1

When we move into al directly, there is no guarantee of the state of the rest of the bytes of the register, however we need them all as 0. We know we can't use 0 in our assembly as this will result in a bad character, luckily we can use xor as xoring anything with itself results in 0. 

xor rax, rax
mov al, 1

Is the equivalent of mov rax, 0x1 however without any bad characters. Now we can modify our shellcode using that same stragey for all offending instructions. 

I've included my solution in print_shellcode_rm_bad_chars.s

Now we can repeat the exact same steps we did before to extract the raw shellcode. 

Firstly, if you run objdump on it you'll notice we have no 00 in the opcodes. 

Extracting the shellcode and placing it into the tester c code, compiling and running you'll notice we now have a length of 29 bytes, which if you count it out is the correct amount. We're now ready to put this into an exploit and run it. 
