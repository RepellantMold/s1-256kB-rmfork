; ---------------------------------------------------------------------------
; Object 2A - small vertical door (SBZ)

; spawned by:
;	ObjPos_SBZ1, ObjPos_SBZ2
; ---------------------------------------------------------------------------

AutoDoor:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	ADoor_Index(pc,d0.w),d1
		jmp	ADoor_Index(pc,d1.w)
; ===========================================================================
ADoor_Index:	index *,,2
		ptr ADoor_Main
		ptr ADoor_OpenShut

ADoor_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_ADoor
		dc.b so_write_word,ost_tile
		dc.w $2D1+tile_pal3
		dc.b ost_actwidth,8
		dc.b ost_priority,4
		dc.b so_render_rel
		dc.b so_end
		even
; ===========================================================================

ADoor_Main:	; Routine 0
		lea	ADoor_Settings(pc),a2
		bsr.w	SetupObject

ADoor_OpenShut:	; Routine 2
		move.w	#$40,d1				; set range for door detection
		clr.b	ost_anim(a0)			; use "closing"	animation by default
		move.w	(v_ost_player+ost_x_pos).w,d0
		add.w	d1,d0				; d0 = 64px right of Sonic
		cmp.w	ost_x_pos(a0),d0		; is Sonic > 64px left of door?
		bcs.s	ADoor_Animate			; if yes, branch
		sub.w	d1,d0
		sub.w	d1,d0				; d0 = 64px left of Sonic
		cmp.w	ost_x_pos(a0),d0		; is Sonic > 64px right of door?
		bcc.s	ADoor_Animate			; if yes, branch

		add.w	d1,d0				; d0 = Sonic's x position
		cmp.w	ost_x_pos(a0),d0		; is Sonic left of the door?
		bcc.s	@sonic_is_left			; if yes, branch
		btst	#status_xflip_bit,ost_status(a0)
		bne.s	ADoor_Animate
		bra.s	ADoor_Open
; ===========================================================================

@sonic_is_left:
		btst	#status_xflip_bit,ost_status(a0)
		beq.s	ADoor_Animate

ADoor_Open:
		move.b	#id_ani_autodoor_open,ost_anim(a0) ; use "opening" animation if Sonic is on active side of door

ADoor_Animate:
		lea	(Ani_ADoor).l,a1
		bsr.w	AnimateSprite
		tst.b	ost_frame(a0)			; is the door open?
		bne.s	@remember			; if yes, branch
		move.w	#$11,d1
		move.w	#$20,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	ost_x_pos(a0),d4
		bsr.w	SolidObject

	@remember:
		bra.w	DespawnObject

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_ADoor:	index *
		ptr ani_autodoor_close
		ptr ani_autodoor_open
		
ani_autodoor_close:
		dc.b 0
		dc.b id_frame_autodoor_open
		dc.b id_frame_autodoor_07
		dc.b id_frame_autodoor_06
		dc.b id_frame_autodoor_05
		dc.b id_frame_autodoor_04
		dc.b id_frame_autodoor_03
		dc.b id_frame_autodoor_02
		dc.b id_frame_autodoor_01
		dc.b id_frame_autodoor_closed
		dc.b afBack, 1

ani_autodoor_open:
		dc.b 0
		dc.b id_frame_autodoor_closed
		dc.b id_frame_autodoor_01
		dc.b id_frame_autodoor_02
		dc.b id_frame_autodoor_03
		dc.b id_frame_autodoor_04
		dc.b id_frame_autodoor_05
		dc.b id_frame_autodoor_06
		dc.b id_frame_autodoor_07
		dc.b id_frame_autodoor_open
		dc.b afBack, 1
		even
