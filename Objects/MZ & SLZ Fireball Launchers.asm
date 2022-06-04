; ---------------------------------------------------------------------------
; Object 13 - fireball maker (MZ, SLZ)

; spawned by:
;	ObjPos_MZ1, ObjPos_MZ2, ObjPos_MZ3 - subtypes x0/x1/x2/x5/x7
;	ObjPos_SLZ1, ObjPos_SLZ2, ObjPos_SLZ3 - subtypes x6/x7
; ---------------------------------------------------------------------------

FireMaker:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	FireM_Index(pc,d0.w),d1
		jsr	FireM_Index(pc,d1.w)
		bra.w	FBall_ChkDel
; ===========================================================================
FireM_Index:	index *,,2
		ptr FireM_Main
		ptr FireM_MakeFire

FireM_Settings:	dc.b ost_id,id_FireBall
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b so_inherit_byte,ost_subtype
		dc.b so_end
		even
; ===========================================================================

FireM_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto FireM_MakeFire next
		move.b	ost_subtype(a0),d0
		lsr.b	#4,d0
		addq.b	#1,d0
		mulu.w	#30,d0
		move.b	d0,ost_anim_delay(a0)
		move.b	ost_anim_delay(a0),ost_anim_time(a0)	; set time delay for fireballs
		andi.b	#$F,ost_subtype(a0)			; get low nybble of subtype (speed/direction)

FireM_MakeFire:	; Routine 2
		subq.b	#1,ost_anim_time(a0)			; decrement timer
		bne.s	@wait					; if time remains, branch
		move.b	ost_anim_delay(a0),ost_anim_time(a0)	; reset time delay
		bsr.w	CheckOffScreen				; is object on-screen?
		bne.s	@wait					; if not, branch
		bsr.w	FindFreeObj				; find free OST slot
		bne.s	@wait					; branch if not found
		lea	FireM_Settings(pc),a2
		bsr.w	SetupChild

	@wait:
		rts	
