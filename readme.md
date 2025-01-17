# Overflowme

Overflowme is a walkthrough to learn the basics of binary exploitation. Detailed instructions, stack diagrams and fully commented assembly source code are provided for each of the challenges.
There are multiple levels with each level building on the next to introduce new techniques or how to bypass various protections. 

## Getting Started

### Installing required tools

Before starting you'll need to install a few pre-requisites. Firstly this walkthrough covers Linux x86 binary exploitation, my suggestion is to run a VM. Most Linux distros should work, however, if you want to ensure everything works Ubuntu 22.04 LTS Desktop was used to design and test all of the challenges.

Next you'll need to install some tools.

GCC
`sudo apt install gcc`

GDB (GNU Debugger)
`sudo apt install gdb`

xxd
`sudo apt install xxd`

make
`sudo apt install make`

git
`sudo apt install git`

### Cloning Repo
Clone the entire repo
`git clone repo name`

You're now ready to get started, each directory contains all the details for each level and it's own readme with instructions.

## Levels

### Level 1 - Stack Overflow Basics
Learn the basics of stack overflows such as the layout of the call stack, how the callers basepointer and return address are preserved onto the stack and finally how to perform a basic stack overflow exploit to take control of the instruction pointer and control program flow. 

### Level 2 - Smashing the Stack
Learn about the tried and trusted stack smashing attack where shellcode is written into the buffer on the stack and then executed.

### Level 3 - Return Oriented Programming
Learn about how to bypass data execution protection (DEP) using return oriented programming (ROP).

### Level 4 - Information Leaks
Learn how to use information leaks to bypass stack canaries and ASLR protections. 

### Level 5 - Working from the outside
Learn how to use tools and techniques such as fuzzing and spiking to identify and exploit stack overflows without access to the source code or debugging versions. 





