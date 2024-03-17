AS		= vasmm68k_mot
DAS		= vda68k

ROM_SRC		= $(wildcard src/*.s)
ROM_OBJ		= $(patsubst src/%.s,obj/%.o,$(ROM_SRC))
ROM_BIN		= rom.bin

LIB_OBJ		= $(wildcard lib/*.o)

ASFLAGS		= -esc -m68040
ASFLAGS_ELF	= -Felf

#-------------------------------------------------------------------------------

.PHONY: rom

rom: $(ROM_BIN)

$(ROM_BIN): $(ROM_OBJ) $(LIB_OBJ)
	m68k-elf-ld -o $(ROM_BIN) $(ROM_OBJ) $(LIB_OBJ) -T link.ld

$(ROM_OBJ): obj/%.o : src/%.s
	$(AS) $(ASFLAGS) -Iinc -o $@ $(ASFLAGS_ELF) $<

clean:
	rm obj/*
	rm rom.bin
