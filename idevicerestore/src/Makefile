TARGET=idevicerestore
CC=gcc
CFLAGS=-g -I. 
LDFLAGS= -L/usr/lib -L/usr/local/lib -L../libirecovery -lplist -lSystem -limobiledevice -lzip -lcurl -lirecovery -lusb-1.0

ODIR=./obj
SOURCE=$(wildcard *.c )
OBJS=$(patsubst %.c,$(ODIR)/%.o,$(SOURCE))

all: display $(TARGET)
	-rm -rf *.dSYM 
	
$(ODIR)/%.o: %.c 
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)
		

clean:
	-rm -rf $(ODIR)
	
display:
	-mkdir -p $(ODIR)
	@echo $(OBJS)
