AS		= vasmm68k_mot
DAS		= vda68k

ROM_SRC		= rom.asm
ROM_SREC	= rom.srec
ROM_LST		= rom.lst
ROM_DASM	= rom-dasm.lst
ROM_BIN		= rom.bin

ASFLAGS		= -esc -m68020up
ASFLAGS_SREC	= -Fsrec
ASFLAGS_BIN	= -Fbin

#-------------------------------------------------------------------------------

.PHONY: rom

rom: $(ROM_BIN)

$(ROM_BIN): $(ROM_SREC)
	srec_cat $< -o $@ -binary

$(ROM_DASM): $(ROM_SREC)
	srec_cat $< -o $<.bin -binary
	$(DAS) $<.bin > $(ROM_DASM)

$(ROM_SREC): $(ROM_SRC)
	$(AS) $(ASFLAGS) -o $@ $(ASFLAGS_SREC) -L $(ROM_LST) $<
