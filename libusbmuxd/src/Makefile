COMPVER=1.0.0
CURRVER=1.0.7
CC=gcc
AR =ar
CFLAGS=-g -D__CYGWIN__ -DHAVE_PLIST -I. 
LDFLAGS= -static -L/usr/lib -L/usr/local/lib -lplist -lSystem -compatibility_version ${COMPVER} -current_version ${CURRVER}
OBJS = sock_stuff.o libusbmuxd.o utils.o

all: libusbmuxd.a libusbmuxd.1.0.7.dylib

libusbmuxd.1.0.7.dylib: $(OBJS)
	$(CC) -shared -static -o $@ $^ $(LDFLAGS)
	
libusbmuxd.a: libusbmuxd.o
	$(AR) -r -cv $@ $^
	
%.o: %.c 
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	-rm -rf *.o *.a *.dylib
	
