# Ideas

* Use ATF1508 for the DRAM controller. This leaves more pins for a non-BGA FPGA
  to be useful.

# Problems

## XR68C681 DUART

I attempted to write a simple monitor ROM program for the 68040pc pretty early
on. I ran into problems when I reached the point of wanting user input.

### Original symptom

After not being able to debug my monitor CLI logic, I made a test program
intended to behave like a simple polling echo loop:

1. Poll SRA until `RxRDY` is set.
2. Read one byte from RBA
3. Poll SRA until `TxRDY` is set.
4. Write that byte to TBA.
5. Repeat.

The observed failure was that sending one character to the computer would
eventually result in an extra character being handled. At first this looked
like:

1. Host sends one character.
2. 68040 reads one character.
3. 68040 writes it to TBA.
4. Then the DUART appears to have another received character pending.

My early suspicion was that the DUART transmit write might somehow be making
`RxRDY` true, either through accidental loopback, or through my novice-level
Verilog controlling the bus behavior.

### Troubleshooting

* Terminal behavior

  I considered that maybe my tried and true `picocom` terminal emulator was the
  problem. I had ChatGPT generate a test program in Python that wrote out single
  bytes to the serial port, but no change was observed.

* Rewired DUART address lines:

  I moved the DUART `RS[4:1]` lines from `{ A[3:2], PA[1:0] }` to `A[5:2]`. The
  goal was to force accesses to always land on the same byte lane and remove
  byte-lane steering from the MC68150 as a varible. No change.

* Checked whether the 68150 was generating multiple accesses

  If the CPU was issuing a word or long word access to the DUART address space,
  the 68150 would generate multiple accesses to fill in the request. Probing the
  bus while testing did not give any evidence of duplicate DUART select cycles.

* Checked address setup relative to `/CS`

  With a logic analyzer, I determined that address setup time going into `/CS`
  was well within spec.

* Verified that the DUART was in the correct mode

  I changed the initialization routine to purposefully set up remote loopback
  mode, as the bits that do that were previously not being set. Remote loopback
  mode behaves completely differently, and behaves as expected. Characters are
  sent right through from the RX shift register to the TX shift register.

  I also tried automatic echo mode, and it behaved as expected.

* Considered accidental multidrop mode

  I remember seeing something about a different mode in the datasheet, so maybe
  I had the DUART in that mode. After looking into it further, the symptoms
  aren't consistent with having the DUART in the multidrop mode.

* Crystal wiring

  I had wired in the crystal to the DUART without much thought, and it turns out
  it is not what the datasheet has specified. I have capacitors inline with the
  crystal, but the reference design uses capacitors to ground on X1/CLK and X2.
  The DUART behaved well enough that I didn't think it would be possible for it
  to be an issue, but I was running out of things to try.

  I used a PLL in the FPGA to synthesize a 3.6805 MHz 3.3V clock signal. This is
  about 0.16% low relative to 3.6864 MHz, but it was within the error margin.
  No change.

* RxA/external serial line checks

  I scoped RxA and did not see any evidence of more than one character on the
  line for a given keypress in the terminal.

### Yet to confirm

* I haven't thoroughly checked the reset line on the DUART. I assume it's
  working because the first character the test program receives works without
  issue, but any subsequent characters end up repeating nonsense. However, I
  haven't completely tested it.

* The bus interface is not entirely without suspicion. I feel like I know enough
  about the 68040 bus to have wired everything and got the HDL correct, but I'm
  far from an expert on this and still have doubts.

### Remaining failure modes to consider

1. Reset/init does not fully clear the DUART receiver/FIFO/status state.
2. RBA read-clear behavior is not reliably recognized.
3. TBA write or nearby DUART bus access subtly corrupts internal state.
4. Register-select/read/write timing is marginal despite the cycle looking
   generally normal.
5. Data bus behavior causes stale/wrong RBA values to be read.
6. XR68C681 clone-specific quirk, board-level sensitivity, or undocumented
   behavior.
