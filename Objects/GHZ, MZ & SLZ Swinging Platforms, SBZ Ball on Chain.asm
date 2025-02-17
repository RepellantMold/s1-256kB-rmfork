; ---------------------------------------------------------------------------
; Object 15 - swinging platforms (GHZ, MZ, SLZ)
;	    - spiked ball on a chain (SBZ)

; spawned by:
;	ObjPosGHZ2, ObjPosGHZ3 - subtypes 6/7/8
;	ObjPosMZ2, ObjPosMZ3 - subtypes 4/5
;	ObjPosSLZ3 - subtype 7
;	ObjPosSBZ2 - subtypes 6/7
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Subroutine to detect collision with a platform, and update relevant flags
;
; input:
;	d1 = platform width
;	d3 = platform height
; ---------------------------------------------------------------------------

Swing_Solid:
		lea	(v_ost_player).w,a1
		tst.w	ost_y_vel(a1)			; is Sonic moving up/jumping?
		bmi.w	Plat_Exit			; if yes, branch

		move.w	ost_x_pos(a1),d0
		sub.w	ost_x_pos(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit			; branch if Sonic is left of the platform
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.w	Plat_Exit			; branch if Sonic is right of the platform
		move.w	ost_y_pos(a0),d0
		sub.w	d3,d0
		bra.w	Plat_NoXCheck_AltY
; End of function Swing_Solid

include_SwingingPlatform_1:	macro

SwingingPlatform:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Swing_Index(pc,d0.w),d1
		jmp	Swing_Index(pc,d1.w)
; ===========================================================================
Swing_Index:	index *,,2
		ptr Swing_Main
		ptr Swing_SetSolid
		ptr Swing_Action2
		ptr Swing_Delete
		ptr Swing_Delete
		ptr Swing_Display
		ptr Swing_Action

ost_swing_y_start:	equ $38				; original y-axis position (2 bytes)
ost_swing_x_start:	equ $3A				; original x-axis position (2 bytes)
ost_swing_radius:	equ $3C				; distance of chainlink from anchor

Swing_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Swing_GHZ
		dc.b so_write_word,ost_tile
		dc.w $6B0+tile_pal3
		dc.b ost_render,render_rel
		dc.b ost_priority,3
		dc.b ost_actwidth,32
		dc.b ost_height,8
		dc.b so_copy_word,ost_y_pos,ost_swing_y_start
		dc.b so_copy_word,ost_x_pos,ost_swing_x_start
		dc.b so_end
		even
SwSLZ_Settings:	dc.b so_write_long,ost_mappings
		dc.l Map_Swing_SLZ
		dc.b so_write_word,ost_tile
		dc.w $3D9+tile_pal3
		dc.b ost_height,16
		dc.b ost_col_type,id_col_32x8+id_col_hurt
		dc.b so_end
		even
SwSBZ_Settings:	dc.b so_write_long,ost_mappings
		dc.l Map_BBall
		dc.b so_write_word,ost_tile
		dc.w $8BC0/32
		dc.b ost_height,24
		dc.b ost_col_type,id_col_16x16+id_col_hurt
		dc.b ost_routine,id_Swing_Action
		dc.b so_end
		even
Swing_Settings2:
		dc.b ost_routine,id_Swing_Display
		dc.b so_inherit_long,ost_mappings
		dc.b so_inherit_word,ost_tile
		dc.b ost_render,render_rel
		dc.b ost_priority,4
		dc.b ost_actwidth,8
		dc.b ost_frame,id_frame_swing_chain
		dc.b so_end
		even
		
Swing_Setupbra:	bra.w	SetupObject
; ===========================================================================

Swing_Main:	; Routine 0
		lea	Swing_Settings(pc),a2
		bsr.s	Swing_Setupbra
		cmpi.b	#id_SLZ,(v_zone).w		; check if level is SLZ
		bne.s	@notSLZ

		lea	SwSLZ_Settings(pc),a2
		bsr.s	Swing_Setupbra

	@notSLZ:
		cmpi.b	#id_SBZ,(v_zone).w		; check if level is SBZ
		bne.s	@length

		lea	SwSBZ_Settings(pc),a2
		bsr.s	Swing_Setupbra

@length:
		move.b	ost_id(a0),d4
		moveq	#0,d2
		lea	ost_subtype(a0),a3		; (a3) = chain length, followed by child OST indices
		move.b	(a3),d2				; d2 = chain length
		andi.w	#$F,d2				; max length is 15
		move.b	#0,(a3)+			; clear subtype
		move.w	d2,d3
		lsl.w	#4,d3				; d3 = chain length in pixels
		addq.b	#8,d3
		move.b	d3,ost_swing_radius(a0)		; relative position of parent (the platform itself)
		subq.b	#8,d3
		tst.b	ost_frame(a0)
		beq.s	@makechain
		addq.b	#8,d3
		subq.w	#1,d2

@makechain:
		bsr.w	FindFreeObj			; find free OST slot
		bne.s	@fail				; branch if not found
		addq.b	#1,ost_subtype(a0)
		move.w	a1,d5
		subi.w	#v_ost_all&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5				; convert child OST address to index
		move.b	d5,(a3)+			; save child OST index to byte list in parent OST
		lea	Swing_Settings2(pc),a2
		bsr.w	SetupChild
		move.b	d4,ost_id(a1)			; load swinging	object
		bclr	#tile_pal34_bit,ost_tile(a1)
		move.b	d3,ost_swing_radius(a1)		; radius is smaller for chainlinks closer to top
		subi.b	#$10,d3				; each one is 16px higher
		bcc.s	@notanchor			; branch if not the highest link
		move.b	#id_frame_swing_anchor,ost_frame(a1) ; use anchor sprite
		move.b	#3,ost_priority(a1)
		bset	#tile_pal34_bit,ost_tile(a1)

	@notanchor:
		dbf	d2,@makechain			; repeat d2 times (chain length)

	@fail:
		move.w	a0,d5				; get parent OST address
		subi.w	#v_ost_all&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5				; convert to index
		move.b	d5,(a3)+			; save to end of child OST list
		cmpi.b	#id_SBZ,(v_zone).w		; is zone SBZ?
		beq.s	Swing_Action			; if yes, branch

Swing_SetSolid:	; Routine 2
		moveq	#0,d1
		move.b	ost_actwidth(a0),d1
		moveq	#0,d3
		move.b	ost_height(a0),d3
		bsr.w	Swing_Solid			; detect collision with Sonic, goto Swing_Action2 in that case

Swing_Action:	; Routine $C
		bsr.w	Swing_Move			; update positions of chainlinks and platform
		bra.s	Swing_Action2_sub
; ===========================================================================

Swing_Action2:	; Routine 4
		moveq	#0,d1
		move.b	ost_actwidth(a0),d1
		bsr.w	ExitPlatform
		move.w	ost_x_pos(a0),-(sp)
		bsr.w	Swing_Move			; update positions of chainlinks and platform
		move.w	(sp)+,d2
		moveq	#0,d3
		move.b	ost_height(a0),d3
		addq.b	#1,d3
		bsr.w	MoveWithPlatform

Swing_Action2_sub:
		bsr.w	DisplaySprite
		bra.w	Swing_ChkDel
		
		endm

; ---------------------------------------------------------------------------
; Object 15 - swinging platforms (GHZ, MZ, SLZ)
;	    - spiked ball on a chain (SBZ), part 2
; ---------------------------------------------------------------------------

include_SwingingPlatform_2:	macro

; ---------------------------------------------------------------------------
; Subroutine to update positions of all chainlinks and platform
; ---------------------------------------------------------------------------

Swing_Move:
		move.b	(v_oscillating_table+$18).w,d0
		move.w	#$80,d1
		btst	#status_xflip_bit,ost_status(a0)
		beq.s	@no_xflip
		neg.w	d0				; invert if xflipped
		add.w	d1,d0				; d0 = oscillating value, same for all platforms

	@no_xflip:
		bra.s	Swing_MoveAll
; End of function Swing_Move

		endm

; ---------------------------------------------------------------------------
; Object 15 - swinging platforms (GHZ, MZ, SLZ)
;	    - spiked ball on a chain (SBZ), part 3
; ---------------------------------------------------------------------------

include_SwingingPlatform_3:	macro

; ---------------------------------------------------------------------------
; Subroutine to convert angle to position for all chain links

; input:
;	d0 = current swing angle
; ---------------------------------------------------------------------------

Swing_MoveAll:
		bsr.w	CalcSine			; convert d0 to sine
		move.w	ost_swing_y_start(a0),d2
		move.w	ost_swing_x_start(a0),d3
		lea	ost_subtype(a0),a2		; (a2) = chain length, followed by child OST index list
		moveq	#0,d6
		move.b	(a2)+,d6			; get chain length

	@loop:
		moveq	#0,d4
		move.b	(a2)+,d4			; get child OST index
		lsl.w	#6,d4
		addi.l	#v_ost_all&$FFFFFF,d4		; convert to RAM address
		movea.l	d4,a1
		moveq	#0,d4
		move.b	ost_swing_radius(a1),d4		; get distance of object from anchor
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,ost_y_pos(a1)		; update position
		move.w	d5,ost_x_pos(a1)
		dbf	d6,@loop			; repeat for all chainlinks and platform
		rts	
; End of function Swing_MoveAll

; ===========================================================================

Swing_ChkDel:
		out_of_range	Swing_DelAll,ost_swing_x_start(a0)
		rts	
; ===========================================================================

Swing_DelAll:
		moveq	#0,d2
		lea	ost_subtype(a0),a2
		move.b	(a2)+,d2

	@loop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_ost_all&$FFFFFF,d0
		movea.l	d0,a1
		bsr.w	DeleteChild
		dbf	d2,@loop			; repeat for length of chain
		rts	
; ===========================================================================

Swing_Delete:	; Routine 6, 8
		bra.w	DeleteObject
; ===========================================================================

Swing_Display:	; Routine $A
		bra.w	DisplaySprite

		endm
		
