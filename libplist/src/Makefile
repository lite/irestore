TARGET=libplist.1.1.3.dylib
COMPVER=1.0.0
CURRVER=1.1.3
CC=gcc
CFLAGS=-g -I. -I/usr/local/Cellar/glib/2.28.6/include/glib-2.0 -I/usr/local/Cellar/glib/2.28.6/lib/glib-2.0/include -I/usr/local/Cellar/libxml2/2.7.8/include/libxml2
LDFLAGS= -static -L/usr/lib -L/usr/local/lib -lxml2 -lglib-2.0 -lSystem -compatibility_version ${COMPVER} -current_version ${CURRVER}

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
