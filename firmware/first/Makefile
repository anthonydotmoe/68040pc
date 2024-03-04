AS		= vasmm68k_mot
DAS		= vda68k

ROM_SRC		= rom.s
ROM_OBJ		= obj/$(ROM_SRC:.s=.o)
ROM_SREC	= rom.srec
ROM_LST		= rom.lst
ROM_DASM	= rom-dasm.lst
ROM_BIN		= rom.bin

C_SRC_OBJ	= obj/printf.o

ASFLAGS		= -esc -m68040
ASFLAGS_SREC	= -Fsrec
ASFLAGS_ELF	= -Felf
ASFLAGS_BIN	= -Fbin

#-------------------------------------------------------------------------------

.PHONY: rom objfolder

rom: $(ROM_BIN)

#dasm: $(ROM_DASM)

# $(ROM_BIN): $(ROM_SREC)
#	srec_cat $< -o $@ -binary

#$(ROM_DASM): $(ROM_SREC)
	srec_cat $< -o $<.bin -binary
	$(DAS) $<.bin > $(ROM_DASM)

#$(ROM_SREC): $(ROM_OBJ)

$(ROM_BIN): $(ROM_OBJ) $(C_SRC_OBJ)
	m68k-elf-ld -o $(ROM_BIN) $(ROM_OBJ) $(C_SRC_OBJ) -T link.ld

$(ROM_OBJ): $(ROM_SRC)
	$(AS) $(ASFLAGS) -o $@ $(ASFLAGS_ELF) $<
