# Overflowme Level 1 - The Basics

Your challenge should you accept it is to get the overflowme binary to print out the hidden message "Hey you're not supposed to be here!" without modifying the source code. If you want to follow along with the walkthrough the rest of the readme will guide you through step by step instructions. 

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

## Step 2 - Source Code Review

The binary is tempting us to overflow it, let's review the source code and see how we can. 

Starting from the `main:` label which denotes the main function and where the program will start a few lines in the `echo_print` function is called which is where the user input is taken and printed back out. Let's investigate this function further. 

The first two lines perform what is called the function prologue, this is done to preserve the callers base pointer and set the callees (inside the function) basepointer to the current stack pointer. This places the call stack ontop of the current stack so that it can be preserved for when the function returns. Next the stack pointer is moved down 512 by substracting 512 from it, recall that the stack grows downwards. This is done to allocate space on the stack to hold temporary variables. This would be the equivalent in C of allocating a local array using `char buffer[512];`.

The next 4 lines setup to perform a read syscall, note that each of the lines of assembly is carefully commented so you can review and see what they do. If you want to see more details about syscalls, this [document](https://www.chromium.org/chromium-os/developer-library/reference/linux-constants/syscalls/) provides excellent details. Of importance in our investigation is the line which sets RDX to 1023. This is what sets the maximum amount of characters that can be read in by syscall to prevent overflowing the buffer set to hold it. Above this line we also see that a pointer is moved into RSI to point to the start of the buffer allocated on the stack (512 down from the basepointer). This is where the input from read syscall will be stored. You've probably already noticed the mistake, we allocated a buffer of 512 bytes but will allow 1023 to be read in. 

## Step 3 - Overflowing Overflowme

We're now ready to overflow the buffer and see what happens, to do so we'll need an input of greater than 512 chars. Instead of manually doing this we'll use a python script. I've included one to work off that in its current state will print out 528 "A"s. We can pipe the output of it into the overflowme binary. 

```bash
python3 exploit.py | ./overflowme
```

You should see that the program echoed back the A's however afterwards it crashed with a segmentation fault. Segmentation faults usually occur when the program attempts to access an invalid memory address or memory that it doesn't have permission to access.

## Step 4 - Investigating with GDB

To understand why this is happenning we'll investigate further with GDB, before we do so it will make things a bit easier in GDB to store the output of the python script into a file we can pass in. 

```bash
python3 exploit.py > AAAA
```

Now we can launch up GDB to step through the binary

```bash
gdb ./overflowme
```

First let's set up some breakpoints to catch the code at specific key points so we can investigate. To do so in gdb you can use "b" followed by either a line number or lable. Set the following:

`b before_function_call`

`b before_read_syscall`

`b before_function_return`

Now let's run the program but direct the file we created into stdin. 

`r < AAA`

GDB will automatically halt execution at the first breakpoint before we call the `echo_print` function. At this point let's investigate a few key pieces of information. First let's check what the current base pointer is, this can be displayed with:

`i r rbp`

For me the base pointer is currently 0x7fffffffdd60 however it may be different for you.

Next, let's check the return address from the function using the label `return_from_function`:

`info address return_from_function`

On my system the return address is at 0x5555555551bf (again it might be different for you).

For now let's keep note of both of these addresses and continue execution of the program by pressing `c`.

GDB has again halted execution, this time right before the read syscall which will fill our buffer up with A's. In the function prologue we saved the callers basepointer to the stack directly above the current basepointer. We can verify this by reading the 8 bytes above the current basepointer with:

`x/xg $rbp`

The second value displayed in white is the contents and the value in blue is the address being read from. Notice how the contents match the basepointer we saw before the function call. 

After the function is done executing it needs to know where to return in the program, this is done by retrieving the return address from the stack. When a function is called the the return address is pushed onto the stack directly before program control is switched to the function code. We can see this return address by looking at the memory starting 8 bytes above the current basepoint with:

`x/xg $rbp+8`

Note how at this point this matches the address we saw for the return label. This implementation of the call stack is what makes stack overflows potentially so dangerous because if we can overwrite the stack into where the return address is then we can control the flow of the program. A visual representation of the stack at this point is provided below. 

Let's continue on with the program executiong with `c` again.

The function works as expected printing out the A's we input and at this point has not crashed. GDB has again halted execution after the syscall before the function performs the epilogue and returns. We can investigate the callers basepointer and the return address again resuing the above commands. As you can see they are both filled with 41 (which is the hex ascii representation of A). The same stack diagram is shown below with the current state of the stack. 

Continuing one last time with `c` and you'll notice that now we get a segmentation fault. When the function attempts to return the return address has been corrupted and the program is not able to access it to get what would be the next instruction resulting in a segmentation fault. 

Before we exit GDB, let's get one other piece of key information we will need, the address for the `hidden_print` function so we can craft an exploit to jump there. 

To do so rerun the program with `r` and then display the address with:

`info address hidden_print`

Mine is located at 0x555555555129, again yours may be different so make sure to take note of this. 

## Step 5 - Craft the Exploit

Now that we understand how the call stack works and what happens when we overflow the stack past the callers basepointer and into the return address we can craft an exploit to take control of program flow and jump to the hidden print. 

Let's start by updating the exploit script with the return address instead of just 41s. One important thing to keep in mind is that the bytes will be pushed onto the stack in reverse order from how they are read so we need to fill them in our exploit backwards. For example my address of 0x555555555129 would translate into "\x29\x51\x55\x55\x55\x55". 

Let's create another file with our updated exploit. 

```bash
python3 exploit.py > jmp2hidden
```

## Step 6 - Launch the Exploit

Now let's re-run the binary with GDB using the exact same steps to set the same breakpoints except this time point the jmp2hidden file to stdin `r < jmp2hidden`. 

If you'd like you can investigate the return address and base pointer at each progression, however, the one we are most concerned with is the one right before the return from the function call. Use `c` to continue until that breakpoint and then review the return address with:

`x/xg $rbp+8`

If everything worked with the exploit you should see the address for `hidden_print` listed. Continue execution again with `c` and you should now see the hidden message printed out followed by another segmentation fault. 

Congrats your exploit worked! If you're curious about why the program ends with a segmentation fault still, this is because we didn't properly call the `hidden_print` function, instead we hijacked the instruction pointer and moved directly there. Because of this we didn't push a return address to the stack so when the function attempts to return it gets a garbage return address which causes a segmentation fault. In future levels down the road we'll look at how we can prevent this if we want to keep the exploit from crashing our program. 

## Step 7 - Remediation and Protections

In this step we'll take a look at some remediation and protections that we can put in place to prevent stack overflows and other memory corruption attacks. These will be important because in later levels where we'll also look at how we can potentially bypass these. 

Of course the easiest remediation step is to make sure the amount of characters we'll receive from the read syscall matches the buffer. In a higher level language like C this could also mean using memory safe versions of functions. For example snprintf() instead of sprintf(). 

Outside of ensuring the code doesn't contain overflow vulnerabilities, modern operating systems have muliple protections built in to prevent memory corruption attacks like a stack overflow. We'll explore two of them in this level. The first one is ASLR which stands for Address Space Layout Randomization. This protection randomizes the address space of binaries/executables when they are run. This makes exploitation much more difficult because we won't know the addresses of things like the stack and other functions. To see this in progress try to run the updated exploit with the retrun address against the overflowme binary outside of GDB. 

```bash
python3 exploit.py | ./overflowme
```

If you're running on a modern Linux distro then you will get the same result as you did with the exploit that has just A's, a seg fault after the echo without printing out the hidden message. This is because when the binary is run in GDB it disables ASLR as it makes debugging easier with it off, however, when the binary is run outside of GDB ASLR is enabled and now the address of the `hidden_print` function is different preventing us from knowing what address is needed to jump to it. You can temporarily turn off ASLR with the following command: 

```bash
sudo sysctl -w kernel.randomize_va_space=0
```

Now if you re-run the exploit it should work and jump you to the hidden print. If you want to turn ASLR back on you can set it back with the following: 

```bash
sudo sysctl -w kernel.randomize_va_space=2
```

We'll learn more about some methods to chain vulnerabilities together to bypass ASLR in future levels. 

The next protection we'll look at are stack canaries. These are a randomized value retrieved from the operating system that is placed onto the stack directly below the callers base pointer after the function prologue. Prior to returning from a function the stack canary that was placed onto the stack is checked against the one that the operating system provided, if they don't match this means that something has corrupted the memory and potentially overwritten the return address. Instead of returning from the funciton the process will display an error message and exit. 

To see an implementation of stack canaries in practice let's build a modified version of overflowme. 

```bash
make overflowme_canary
```

If you run the binary normally without overflowing the buffer you'll notice it functions as you would expect. If you run it again and pass in the exploit as input you'll notice a different message displayed "Hey you overflowed me". Let's take a look at the source code for overflowme_canary and see how this works. 

Inside of the `echo_print` on the third line in the function the stack canary is received from a special address that the OS places the stack canary. It is then pushed onto the stack. 

The function then continues as normal until directly before the return where the stack canary is retrieved from the stack again and checked against the one on the stack. If they are equal the function proceeds and returns as normal. If they don't match instead the stack overflow message is printed and the process exits. 

When working in higher level languages like C stack canaries are added by default by the compiler. In this example I've hand written one in assembly so that it's easier to see how they work, however, the implementation from GCC or other compilers is very similar. 

Similar to ASLR there are ways that stack canaries can be bypassed by chaining together vulnerabilities. We'll learn more about this in future levels as well. 

## Nice Job!

That wraps up the first level of overflowme, in the next level we'll take a look at upgrading our exploit from just jumping to another place in the program to jumping to our own shellcode we load into the stack. 


