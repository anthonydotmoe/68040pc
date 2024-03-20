AS		= vasmm68k_mot
DAS		= vda68k

CC		= m68k-elf-gcc

TARGET		= rom.bin

ASM_SRC		= $(wildcard src/*.s)
ASM_OBJ		= $(patsubst src/%.s,obj/%.o,$(ASM_SRC))

C_SRC		= $(wildcard src/*.c)
C_OBJ		= $(patsubst src/%.c,obj/%.o,$(C_SRC))

LIB_OBJ		= $(wildcard lib/*.o)
ROM_OBJ		= $(ASM_OBJ) $(C_OBJ)

ASFLAGS		= -esc -m68040
ASFLAGS_ELF	= -Felf

CFLAGS		= -m68040 -O2 -Iinc

#-------------------------------------------------------------------------------

$(TARGET): $(ROM_OBJ) $(LIB_OBJ)
	m68k-elf-ld -o $@ $(ROM_OBJ) $(LIB_OBJ) -T link.ld

$(ASM_OBJ): obj/%.o : src/%.s
	$(AS) $(ASFLAGS) -Iinc -o $@ $(ASFLAGS_ELF) $<

$(C_OBJ): obj/%.o : src/%.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm obj/*
	rm rom.bin
