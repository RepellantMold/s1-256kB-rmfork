; ---------------------------------------------------------------------------
; Object 2B - Chopper enemy (GHZ)

; spawned by:
;	ObjPos_GHZ1, ObjPos_GHZ2
; ---------------------------------------------------------------------------

Chopper:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Chop_Index(pc,d0.w),d1
		jsr	Chop_Index(pc,d1.w)
		bra.w	DespawnObject
; ===========================================================================
Chop_Index:	index *,,2
		ptr Chop_Main
		ptr Chop_ChgSpeed

ost_chopper_y_start:	equ $30				; original y position (2 bytes)

Chop_Settings:	dc.b ost_routine,2
		dc.b ost_render,render_rel
		dc.b ost_priority,4
		dc.b ost_col_type,id_col_12x16
		dc.b ost_actwidth,16
		dc.b so_write_word,ost_tile
		dc.w $3CC
		dc.b so_write_long,ost_mappings
		dc.l Map_Chop
		dc.b so_write_word,ost_y_vel
		dc.w -$700
		dc.b so_copy_word,ost_y_pos,ost_chopper_y_start
		dc.b so_end
		even
; ===========================================================================

Chop_Main:	; Routine 0
		lea	Chop_Settings(pc),a2
		bsr.w	SetupObject

Chop_ChgSpeed:	; Routine 2
		lea	(Ani_Chop).l,a1
		bsr.w	AnimateSprite
		bsr.w	SpeedToPos
		addi.w	#$18,ost_y_vel(a0)		; reduce speed
		move.w	ost_chopper_y_start(a0),d0
		cmp.w	ost_y_pos(a0),d0		; has Chopper returned to its original position?
		bcc.s	@chganimation			; if not, branch
		move.w	d0,ost_y_pos(a0)
		move.w	#-$700,ost_y_vel(a0)		; set vertical speed

	@chganimation:
		move.b	#id_ani_chopper_fast,ost_anim(a0) ; use fast animation
		subi.w	#$C0,d0
		cmp.w	ost_y_pos(a0),d0
		bcc.s	@nochg
		move.b	#id_ani_chopper_slow,ost_anim(a0) ; use slow animation
		tst.w	ost_y_vel(a0)			; is Chopper at	its highest point?
		bmi.s	@nochg				; if not, branch
		move.b	#id_ani_chopper_still,ost_anim(a0) ; use stationary animation

	@nochg:
		rts	

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Chop:	index *
		ptr ani_chopper_slow
		ptr ani_chopper_fast
		ptr ani_chopper_still
		
ani_chopper_slow:
		dc.b 7
		dc.b id_frame_chopper_shut
		dc.b id_frame_chopper_open
		dc.b afEnd

ani_chopper_fast:
		dc.b 3
		dc.b id_frame_chopper_shut
		dc.b id_frame_chopper_open
		dc.b afEnd

ani_chopper_still:
		dc.b 7
		dc.b id_frame_chopper_shut
		dc.b afEnd
		even
