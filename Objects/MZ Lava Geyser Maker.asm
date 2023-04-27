; ---------------------------------------------------------------------------
; Object 4C - lava geyser / lavafall producer (MZ)

; spawned by:
;	ObjPos_MZ2, ObjPos_MZ3 - subtype 1
;	PushBlock - subtype 0
; ---------------------------------------------------------------------------

GeyserMaker:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	GMake_Index(pc,d0.w),d1
		jsr	GMake_Index(pc,d1.w)
		bra.w	Geyser_ChkDel
; ===========================================================================
GMake_Index:	index *,,2
		ptr GMake_Main
		ptr GMake_Wait
		ptr GMake_ChkType
		ptr GMake_MakeLava
		ptr GMake_Display
		ptr GMake_Delete

ost_gmake_wait_time:	equ $32				; current time remaining (2 bytes)
ost_gmake_wait_total:	equ $34				; time delay (2 bytes)
ost_gmake_parent:	equ $3C				; address of OST of parent object (4 bytes)

GMake_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Geyser
		dc.b so_write_word,ost_tile
		dc.w $34A+tile_pal4+tile_hi
		dc.b ost_render,render_rel
		dc.b ost_priority,1
		dc.b ost_actwidth,$38
		dc.b ost_gmake_wait_total+1,120
		dc.b so_end
		even
; ===========================================================================

GMake_Main:	; Routine 0
		lea	GMake_Settings(pc),a2
		bsr.w	SetupObject

GMake_Wait:	; Routine 2
		subq.w	#1,ost_gmake_wait_time(a0)	; decrement timer
		bpl.s	@cancel				; if time remains, branch

		move.w	ost_gmake_wait_total(a0),ost_gmake_wait_time(a0) ; reset timer
		move.w	(v_ost_player+ost_y_pos).w,d0
		move.w	ost_y_pos(a0),d1
		cmp.w	d1,d0
		bcc.s	@cancel				; branch if Sonic is to the right
		subi.w	#$170,d1
		cmp.w	d1,d0
		bcs.s	@cancel				; branch if Sonic is more than 368px to the left
		addq.b	#2,ost_routine(a0)		; if Sonic is within range, goto GMake_ChkType next

	@cancel:
		rts
; ===========================================================================

GMake_Settings2:
		dc.b ost_id,id_LavaGeyser
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b so_inherit_byte,ost_subtype
		dc.b so_set_parent,ost_geyser_parent
		dc.b so_end
		even

GMake_MakeLava:	; Routine 6
		addq.b	#2,ost_routine(a0)		; goto GMake_Display next
		bsr.w	FindNextFreeObj			; find free OST slot
		bne.s	@fail				; branch if not found
		lea	GMake_Settings2(pc),a2
		bsr.w	SetupChild

	@fail:
		move.b	#id_ani_geyser_bubble2,ost_anim(a0)
		tst.b	ost_subtype(a0)			; is object type 0 (geyser) ?
		beq.s	@isgeyser			; if yes, branch
		move.b	#id_ani_geyser_blank,ost_anim(a0)
		bra.s	GMake_Display
; ===========================================================================

	@isgeyser:
		movea.l	ost_gmake_parent(a0),a1		; copy address of parent OST (from PushBlock)
		bset	#status_yflip_bit,ost_status(a1)
		move.w	#-$580,ost_y_vel(a1)
		bra.s	GMake_Display
; ===========================================================================

GMake_ChkType:	; Routine 4
		tst.b	ost_subtype(a0)			; is object type 0 (geyser) ?
		beq.s	GMake_Display			; if yes, branch
		addq.b	#2,ost_routine(a0)		; goto GMake_MakeLava next
		rts	
; ===========================================================================

GMake_Display:	; Routine 8
		lea	(Ani_Geyser).l,a1
		bsr.w	AnimateSprite			; animate and goto next routine if specified
		bsr.w	DisplaySprite
		rts	
; ===========================================================================

GMake_Delete:	; Routine $A
		move.b	#id_ani_geyser_bubble1,ost_anim(a0)
		move.b	#id_GMake_Wait,ost_routine(a0)
		tst.b	ost_subtype(a0)
		beq.w	DeleteObject
		rts	
