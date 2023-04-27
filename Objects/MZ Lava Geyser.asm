; ---------------------------------------------------------------------------
; Object 4D - lava geyser / lavafall (MZ)

; spawned by:
;	GeyserMaker, LavaGeyser - subtype inherited from parent
; ---------------------------------------------------------------------------

LavaGeyser:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Geyser_Index(pc,d0.w),d1
		jsr	Geyser_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
Geyser_Index:	index *,,2
		ptr Geyser_Main
		ptr Geyser_Action
		ptr Geyser_Middle
		ptr Geyser_Delete

Geyser_Speeds:	dc.w -$500				; 0 - geyser
		dc.w 0					; 1 - lavafall

ost_geyser_y_start:	equ $30				; original y position (2 bytes)
ost_geyser_parent:	equ $3C				; address of OST of parent object (4 bytes)

Geyser_Settings:
		dc.b ost_id,id_LavaGeyser
		dc.b so_write_long,ost_mappings
		dc.l Map_Geyser
		dc.b so_write_word,ost_tile
		dc.w $34A+tile_pal4
		dc.b ost_render,render_rel
		dc.b ost_actwidth,32
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b so_inherit_byte,ost_subtype
		dc.b ost_priority,1
		dc.b ost_anim,id_ani_geyser_bubble4
		dc.b so_end
		even
; ===========================================================================

Geyser_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)		; goto Geyser_Action next
		move.w	ost_y_pos(a0),ost_geyser_y_start(a0)
		tst.b	ost_subtype(a0)			; is this a geyser or lavafall?
		beq.s	@isgeyser			; branch if geyser
		subi.w	#$250,ost_y_pos(a0)		; start from above

	@isgeyser:
		moveq	#0,d0
		move.b	ost_subtype(a0),d0
		add.w	d0,d0
		move.w	Geyser_Speeds(pc,d0.w),ost_y_vel(a0) ; set y speed based on subtype
		movea.l	a0,a1
		moveq	#1,d2
		bsr.s	@makelava
		bra.s	@activate
; ===========================================================================

	@loop:
		bsr.w	FindNextFreeObj
		bne.s	@fail

@makelava:
		lea	Geyser_Settings(pc),a2
		bsr.w	SetupChild
		tst.b	ost_subtype(a0)
		beq.s	@fail				; branch if geyser
		move.b	#id_ani_geyser_end,ost_anim(a1)	; use different animation for lavafall

	@fail:
		dbf	d2,@loop			; repeat once for middle section
		rts
; ===========================================================================

@activate:
		addi.w	#$60,ost_y_pos(a1)		; move 2nd object down 96px
		move.w	ost_geyser_y_start(a0),ost_geyser_y_start(a1)
		addi.w	#$60,ost_geyser_y_start(a1)
		move.b	#id_col_32x112+id_col_hurt,ost_col_type(a1)
		move.b	#$80,ost_height(a1)
		bset	#render_useheight_bit,ost_render(a1)
		addq.b	#id_Geyser_Middle,ost_routine(a1) ; goto Geyser_Middle next
		move.l	a0,ost_geyser_parent(a1)
		tst.b	ost_subtype(a0)
		beq.s	@sound				; branch if geyser

		moveq	#0,d2
		bsr.w	@loop				; load one more object
		addq.b	#2,ost_routine(a1)		; goto Geyser_Action next
		bset	#tile_yflip_bit,ost_tile(a1)
		addi.w	#$100,ost_y_pos(a1)
		move.b	#0,ost_priority(a1)
		move.w	ost_geyser_y_start(a0),ost_geyser_y_start(a1)
		move.l	ost_geyser_parent(a0),ost_geyser_parent(a1)
		move.b	#0,ost_subtype(a0)

	@sound:
		play.w	1, jsr, sfx_Burning		; play flame sound

Geyser_Action:	; Routine 2
		addi.w	#$18,ost_y_vel(a0)		; apply gravity
		move.w	ost_geyser_y_start(a0),d0
		cmp.w	ost_y_pos(a0),d0		; is geyser back at start position?
		bcc.s	@exit				; if not, branch
		addq.b	#4,ost_routine(a0)		; goto Geyser_Delete next
		movea.l	ost_geyser_parent(a0),a1
		move.b	ost_subtype(a0),d0
		add.b	#1,d0
		move.b	d0,ost_anim(a1)

	@exit:
		bsr.w	SpeedToPos			; update position
		lea	(Ani_Geyser).l,a1
		bsr.w	AnimateSprite

Geyser_ChkDel:
		out_of_range	DeleteObject
		rts
; ===========================================================================

Geyser_Middle:	; Routine 4
		movea.l	ost_geyser_parent(a0),a1
		cmpi.b	#id_Geyser_Delete,ost_routine(a1) ; is parent set to delete?
		beq.w	Geyser_Delete			; if yes, branch
		move.w	ost_y_pos(a1),d0
		addi.w	#$60,d0
		move.w	d0,ost_y_pos(a0)		; set y position 96px below parent
		sub.w	ost_geyser_y_start(a0),d0
		neg.w	d0
		moveq	#id_frame_geyser_medcolumn1,d1
		cmpi.w	#$40,d0
		bge.s	@not_short			; branch if object is more than 64px from position
		moveq	#id_frame_geyser_shortcolumn1,d1

	@not_short:
		cmpi.w	#$80,d0
		ble.s	@not_long			; branch if object is less than 128px from position
		moveq	#id_frame_geyser_longcolumn1,d1

	@not_long:
		subq.b	#1,ost_anim_time(a0)		; decrement animation timer
		bpl.s	@update_frame			; branch if time remains
		move.b	#7,ost_anim_time(a0)		; reset timer
		addq.b	#1,ost_anim_frame(a0)		; next frame
		cmpi.b	#2,ost_anim_frame(a0)
		bcs.s	@update_frame			; branch if valid frame
		move.b	#0,ost_anim_frame(a0)		; reset frame to 0 if past max

	@update_frame:
		move.b	ost_anim_frame(a0),d0
		add.b	d1,d0
		move.b	d0,ost_frame(a0)		; set frame based on animation and initial frame (d1)
		bra.w	Geyser_ChkDel
; ===========================================================================

Geyser_Delete:	; Routine 6
		bra.w	DeleteObject

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

include_LavaGeyser_animation:	macro

Ani_Geyser:	index *
		ptr ani_geyser_bubble1
		ptr ani_geyser_bubble3
		ptr ani_geyser_bubble2
		ptr ani_geyser_end
		ptr ani_geyser_blank
		ptr ani_geyser_bubble4
		
ani_geyser_bubble1:
		dc.b 2
		dc.b id_frame_geyser_bubble1
		dc.b id_frame_geyser_bubble2
		dc.b id_frame_geyser_bubble1
		dc.b id_frame_geyser_bubble2
		dc.b id_frame_geyser_bubble5
		dc.b id_frame_geyser_bubble6
		dc.b id_frame_geyser_bubble5
		dc.b id_frame_geyser_bubble6
		dc.b afRoutine

ani_geyser_bubble2:
		dc.b 2
		dc.b id_frame_geyser_bubble3
		dc.b id_frame_geyser_bubble4
		dc.b afEnd

ani_geyser_end:
		dc.b 2
		dc.b id_frame_geyser_end1
		dc.b id_frame_geyser_end2
		dc.b afEnd

ani_geyser_bubble3:
		dc.b 2
		dc.b id_frame_geyser_bubble3
		dc.b id_frame_geyser_bubble4
		dc.b id_frame_geyser_bubble1
		dc.b id_frame_geyser_bubble2
		dc.b id_frame_geyser_bubble1
		dc.b id_frame_geyser_bubble2
		dc.b afRoutine

ani_geyser_blank:
		dc.b $F
		dc.b id_frame_geyser_blank
		dc.b afEnd
		even

ani_geyser_bubble4:
		dc.b 2
		dc.b id_frame_geyser_bubble7
		dc.b id_frame_geyser_bubble8
		dc.b afEnd
		even

		endm
