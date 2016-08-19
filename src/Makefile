CC ?= gcc
CFLAGS ?= -Wall -O2

CFILES=mkzeros.c

objects = $(CFILES:.c=.o)

progs = mkzeros

override CFLAGS += -D_FILE_OFFSET_BITS=64 -D_ISOC11_SOURCE
#LIBRARY_FLAGS += $(hash_LIBS) $(glib_LIBS) $(sqlite_LIBS) -lm

DESTDIR ?= /
PREFIX ?= /usr/local
SHAREDIR = $(PREFIX)/share
SBINDIR = $(PREFIX)/sbin
MANDIR = $(SHAREDIR)/man

.c.o:
	$(check) $(CFLAGS) -c $< -o $@ $(LIBRARY_FLAGS)
	$(CC) $(CFLAGS) -c $< -o $@ $(LIBRARY_FLAGS)

all: $(progs)

#$(objects): $(HEADERS)
mkzeros: mkzeros.c
	$(CC) $(CFLAGS) mkzeros.c -o mkzeros

clean:
	rm -fr $(objects) $(progs) *~
