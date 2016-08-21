AS := ca65
LD := ld65

APPNAME = pacman

ASFLAGS := -g 
LABELSNAME = labels.txt
LDFLAGS := -Ln $(LABELSNAME)
SRCDIR := src
CONFIGNAME := $(APPNAME).cfg
OBJNAME := main.o
MAPNAME := map.txt
LISTNAME := listing.txt

TOPLEVEL := main.asm

EXECUTABLE := $(APPNAME).nes

.PHONY: all build $(EXECUTABLE)

build: $(EXECUTABLE)

all: $(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE) $(LISTNAME) $(OBJNAME) $(MAPNAME) $(EXECUTABLE) $(LABELSNAME.TXT)

$(EXECUTABLE):
	$(AS) $(SRCDIR)/$(TOPLEVEL) $(ASFLAGS) -I $(SRCDIR) -l $(LISTNAME) -o $(OBJNAME) -g
	$(LD) $(LDFLAGS) -C $(CONFIGNAME) -o $(EXECUTABLE) -m $(MAPNAME) -vm $(OBJNAME) --dbgfile $(EXECUTABLE).dbg

run: $(EXECUTABLE)
	nestopia ./$(EXECUTABLE)
