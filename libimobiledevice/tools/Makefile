CC=gcc
CFLAGS=-g -DHAVE_LIBIMOBILEDEVICE_1_0 -DHAVE_LIBIMOBILEDEVICE_1_1 -I../src -I/usr/local/Cellar/glib/2.28.6/include/glib-2.0 -I/usr/local/Cellar/glib/2.28.6/lib/glib-2.0/include 
LDFLAGS= -L/usr/lib -L/usr/local/lib -limobiledevice -lplist -lglib-2.0 -lgcrypt -lzip

SOURCE=$(wildcard *.c )
TARGETS = $(patsubst %.c,%,$(SOURCE))

all: $(TARGETS)
	-rm -rf *.dSYM
	
.c: 
	$(CC) -o $@ $< $(CFLAGS) $(LDFLAGS)

clean:
	-rm -rf $(TARGETS) *.dSYM

display:      
	@echo $(TARGETS)	
