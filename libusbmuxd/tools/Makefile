CC=gcc
CFLAGS=-g -D__CYGWIN__ -I../src 
LDFLAGS= -L/usr/lib -L/usr/local/lib -L../src -lusbmuxd 

all: iproxy
	
iproxy: iproxy.o
	$(CC) -o $@ $^ $(LDFLAGS)
	
%.o: %.c 
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	-rm -rf *.o iproxy
	
