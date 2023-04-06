; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	load the DAC driver
; ---------------------------------------------------------------------------

DacDriverLoad:
		bsr.s	StoptheZ80			; stop the z80 and make sure z80 reset was not asserted
		resetZ80_release

		lea	(Kos_DacDriver).l,a0		; compressed DAC driver address
		lea	(z80_ram).l,a1			; load into start of z80 RAM
		bsr.w	KosDec				; decompress the DAC driver

		bsr.s	ResettheZ80			; z80 reset 
		bra.s	StarttheZ80			; start z80 again

StoptheZ80:
		stopZ80
		rts

WaitforZ80:
		btst	#0,(z80_bus_request).l
		bne.s	WaitforZ80
		rts

ResettheZ80:
		resetZ80_assert				; assert z80 reset
	rept 4
		nop					; wait a little time to finish resetting
	endr
		resetZ80_release			; release z80 reset (enables z80)
		rts

StarttheZ80:
		startZ80				; start z80
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutines to play sounds in various queue slots
;
; input:
;	d0 = sound to play
; ---------------------------------------------------------------------------

PlaySound0:
		move.b	d0,(v_snddriver_ram+v_soundqueue+0).w	; play in slot 0
		rts

PlaySound1:
		move.b	d0,(v_snddriver_ram+v_soundqueue+1).w	; play in slot 1
		rts

PlaySound2:
		move.b	d0,(v_snddriver_ram+v_soundqueue+2).w	; play in slot 2 (broken!)
		rts
