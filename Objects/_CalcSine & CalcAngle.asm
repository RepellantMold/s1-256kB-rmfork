; ---------------------------------------------------------------------------
; Subroutine to convert an angle (0 to $FF) to sine and cosine (-$100 to $100)

; input:
;	d0 = angle

; output:
;	d0 = sine
;	d1 = cosine
; ---------------------------------------------------------------------------

CalcSine:
		andi.w	#$FF,d0				; read low byte of angle only
		add.w	d0,d0
		addi.w	#$80,d0				; start 90 degrees later for cosine
		move.w	Sine_Data(pc,d0.w),d1		; get cosine
		subi.w	#$80,d0				; start at 0 for sine
		move.w	Sine_Data(pc,d0.w),d0		; get sine
		rts

; ---------------------------------------------------------------------------
; Subroutine to convert x/y distance to an angle

; input:
;	d1 = x-axis distance
;	d2 = y-axis distance

; output:
;	d0 = angle
; ---------------------------------------------------------------------------

include_CalcAngle:	macro

CalcAngle:
		movem.l	d3-d4,-(sp)
		moveq	#0,d3
		moveq	#0,d4
		move.w	d1,d3				; d3 = x distance
		move.w	d2,d4				; d4 = y distance
		or.w	d3,d4
		beq.s	CalcAngle_Both0			; branch if both are 0
		move.w	d2,d4
		tst.w	d3
		bpl.w	@x_positive			; branch if x is positive
		neg.w	d3				; force x positive

	@x_positive:
		tst.w	d4
		bpl.w	@y_positive			; branch if y is positive
		neg.w	d4				; force y positive

	@y_positive:
		cmp.w	d3,d4
		bcc.w	@y_larger			; branch if y is larger or same
		lsl.l	#8,d4
		divu.w	d3,d4				; d4 = (y*$100)/x
		moveq	#0,d0
		move.b	Angle_Data(pc,d4.w),d0
		bra.s	CalcAngle_ChkRotation
; ===========================================================================

@y_larger:
		lsl.l	#8,d3
		divu.w	d4,d3				; d3 = (x*$100)/y
		moveq	#$40,d0
		sub.b	Angle_Data(pc,d3.w),d0

CalcAngle_ChkRotation:
		tst.w	d1
		bpl.w	@x_positive			; branch if x is positive
		neg.w	d0
		addi.w	#$80,d0

	@x_positive:
		tst.w	d2
		bpl.w	@y_positive			; branch if y is positive
		neg.w	d0
		addi.w	#$100,d0

	@y_positive:
		movem.l	(sp)+,d3-d4
		rts	
; ===========================================================================

CalcAngle_Both0:
		move.w	#$40,d0
		movem.l	(sp)+,d3-d4
		rts

		endm
