overflowme.o: overflowme.s
	as -g -o overflowme.o overflowme.s

overflowme: overflowme.o
	gcc -o overflowme overflowme.o
	rm -f overflowme.o

overflowme_canary.o: overflowme_canary.s
	as -g -o overflowme_canary.o overflowme_canary.s

overflowme_canary: overflowme_canary.o
	gcc -o overflowme_canary overflowme_canary.o
	rm -f overflowme_canary.o

all: overflowme.o overflowme overflowme_canary.o overflowme_canary

clean:
	rm -f overflowme.o
	rm -f overflowme
	rm -f overflowme_canary.o
	rm -f overflowme_canary