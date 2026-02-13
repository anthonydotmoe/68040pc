AS		= vasmm68k_mot
DAS		= vda68k

CC		= m68k-elf-gcc

TARGET		= rom.bin
TARGET_ELF  = rom.elf

ASM_SRC		= $(filter-out $(CRT0_SRC), $(wildcard src/asm/*.s))
ASM_OBJ		= $(patsubst src/asm/%.s,obj/%.o,$(ASM_SRC))

C_SRC		= $(wildcard src/c/*.c)
C_OBJ		= $(patsubst src/c/%.c,obj/%.o,$(C_SRC))

LIB_OBJ		= $(wildcard lib/*.o)
ROM_OBJ		= $(ASM_OBJ) $(C_OBJ)

ASFLAGS		= -esc -m68040 -Iinc
ASFLAGS_ELF	= -Felf

LDFLAGS     = -T link.ld -Map=output.map --print-memory-usage --no-warn-rwx-segments

KERNEL_ELF	= $(abspath ./../../os/out/kernel/kernel.elf)
USERIMAGE_ELF = $(abspath ./../../os/out/servers/root.elf)

CWARNERR	= -Wall -Wextra -Wpedantic -Werror
CFLAGS		= -m68040 -DKERNEL_FILEPATH=\"$(KERNEL_ELF)\" -DUSERIMAGE_FILEPATH=\"$(USERIMAGE_ELF)\" -g -std=gnu23 -msoft-float -ffreestanding -fno-builtin -Os -Iinc $(CWARNERR)

#-------------------------------------------------------------------------------

$(TARGET): $(TARGET_ELF)
	m68k-elf-objcopy -O binary $< $@

$(TARGET_ELF): $(ROM_OBJ) $(LIB_OBJ) $(CRT0_OBJ)
	m68k-elf-ld -o $@ $(ROM_OBJ) $(LIB_OBJ) $(LDFLAGS)

$(ASM_OBJ): obj/%.o : src/asm/%.s
	$(AS) $(ASFLAGS) -o $@ $(ASFLAGS_ELF) $<

$(C_OBJ): obj/%.o : src/c/%.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm obj/*
	rm rom.bin
