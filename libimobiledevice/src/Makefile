TARGET=libimobiledevice.2.dylib
COMPVER=3.0.0
CURRVER=3.1.0
CC=gcc
CFLAGS=-g -I. -I/usr/local/Cellar/glib/2.28.6/include/glib-2.0 -I/usr/local/Cellar/glib/2.28.6/lib/glib-2.0/include
LDFLAGS= -static -L/usr/lib -L/usr/local/lib -lplist -lSystem -lgnutls -lglib-2.0 -lgthread-2.0 -lusbmuxd -ltasn1 -lgcrypt -compatibility_version ${COMPVER} -current_version ${CURRVER}

ODIR=./obj
SOURCE=$(wildcard *.c )
OBJS=$(patsubst %.c,$(ODIR)/%.o,$(SOURCE))

all: display $(TARGET)
	
$(ODIR)/%.o: %.c 
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET): $(OBJS)
	$(CC) -shared -static -o $@ $^ $(LDFLAGS)
		

clean:
	-rm -rf $(ODIR) *.dylib
	
display:
	-mkdir -p $(ODIR)
	@echo $(OBJS)
