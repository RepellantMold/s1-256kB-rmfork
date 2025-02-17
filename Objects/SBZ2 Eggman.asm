; ---------------------------------------------------------------------------
; Object 82 - Eggman (SBZ2)

; spawned by:
;	DynamicLevelEvents - routine 0
;	ScrapEggman - routines 2/4
; ---------------------------------------------------------------------------

ScrapEggman:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	SEgg_Index(pc,d0.w),d1
		jmp	SEgg_Index(pc,d1.w)
; ===========================================================================
SEgg_Index:	index *,,2
		ptr SEgg_Main
		ptr SEgg_Eggman
		ptr SEgg_Button

ost_eggman_parent:	equ $34				; address of OST of parent object (4 bytes)
ost_eggman_wait_time:	equ $3C				; time delay between events (2 bytes)

SEgg_Settings:	dc.b so_write_word,ost_x_pos
		dc.w $2160
		dc.b so_write_word,ost_y_pos
		dc.w $5A4
		dc.b ost_col_type,id_col_24x24
		dc.b ost_col_property,16
		dc.b ost_routine,id_SEgg_Eggman
		dc.b ost_priority,3
		dc.b so_write_long,ost_mappings
		dc.l Map_SEgg
		dc.b so_write_word,ost_tile
		dc.w tile_Nem_Sbz2Eggman
		dc.b ost_render,render_rel+render_onscreen
		dc.b ost_actwidth,32
		dc.b so_end
		even
SEgg_Settings2:	dc.b ost_id,id_ScrapEggman
		dc.b so_write_word,ost_x_pos
		dc.w $2130
		dc.b so_write_word,ost_y_pos
		dc.w $5BC
		dc.b ost_routine,id_SEgg_Button
		dc.b ost_priority,3
		dc.b so_write_long,ost_mappings
		dc.l Map_But
		dc.b so_write_word,ost_tile
		dc.w vram_button/32
		dc.b ost_render,render_rel+render_onscreen
		dc.b ost_actwidth,16
		dc.b so_set_parent,ost_eggman_parent
		dc.b so_end
		even
; ===========================================================================

SEgg_Main:	; Routine 0
		lea	SEgg_Settings(pc),a2
		jsr	SetupObject
		bclr	#status_xflip_bit,ost_status(a0)

		jsr	(FindNextFreeObj).l		; find free OST slot
		bne.s	SEgg_Eggman			; branch if not found
		lea	SEgg_Settings2(pc),a2
		jsr	SetupChild

SEgg_Eggman:	; Routine 2
		moveq	#0,d0
		move.b	ost_routine2(a0),d0
		move.w	SEgg_EggIndex(pc,d0.w),d1
		jsr	SEgg_EggIndex(pc,d1.w)
		lea	Ani_SEgg(pc),a1
		jsr	(AnimateSprite).l
		bra.w	SEgg_BtnDisplay
; ===========================================================================
SEgg_EggIndex:	index *,,2
		ptr SEgg_ChkSonic
		ptr SEgg_PreLeap
		ptr SEgg_Leap
		ptr SEgg_Move
; ===========================================================================

SEgg_ChkSonic:
		move.w	ost_x_pos(a0),d0
		sub.w	(v_ost_player+ost_x_pos).w,d0
		cmpi.w	#128,d0				; is Sonic within 128 pixels of	Eggman?
		bcc.s	SEgg_Move			; if not, branch
		addq.b	#2,ost_routine2(a0)		; goto SEgg_PreLeap next
		move.w	#180,ost_eggman_wait_time(a0)	; set delay to 3 seconds
		move.b	#id_ani_eggman_laugh,ost_anim(a0)

SEgg_Move:
		jmp	(SpeedToPos).l			; update position
; ===========================================================================

SEgg_PreLeap:
		subq.w	#1,ost_eggman_wait_time(a0)	; decrement timer
		bne.s	@wait				; if time remains, branch
		addq.b	#2,ost_routine2(a0)		; goto SEgg_Leap next
		move.b	#id_ani_eggman_jump1,ost_anim(a0)
		addq.w	#4,ost_y_pos(a0)
		move.w	#15,ost_eggman_wait_time(a0)	; wait quarter of a second before jumping

	@wait:
		bra.s	SEgg_Move
; ===========================================================================

SEgg_Leap:
		subq.w	#1,ost_eggman_wait_time(a0)	; decrement timer
		bgt.s	@update_pos
		bne.s	@wait
		move.w	#-$FC,ost_x_vel(a0)		; make Eggman leap
		move.w	#-$3C0,ost_y_vel(a0)

	@wait:
		cmpi.w	#$2132,ost_x_pos(a0)		; has Eggman reach the button?
		bgt.s	@not_at_btn			; if not, branch
		clr.w	ost_x_vel(a0)			; stop moving horizontally

	@not_at_btn:
		addi.w	#$24,ost_y_vel(a0)		; apply gravity
		tst.w	ost_y_vel(a0)			; is Eggman moving downwards?
		bmi.s	@find_blocks			; if not, branch
		cmpi.w	#$595,ost_y_pos(a0)		; has Eggman passed $595 on y axis?
		bcs.s	@find_blocks			; if not, branch
		move.w	#$5357,ost_subtype(a0)		; set flag for button to change to pressed
		cmpi.w	#$59B,ost_y_pos(a0)		; has Eggman passed $59B on y axis?
		bcs.s	@find_blocks			; if not, branch
		move.w	#$59B,ost_y_pos(a0)		; stop at $59B
		clr.w	ost_y_vel(a0)			; stop falling

@find_blocks:
		move.w	ost_x_vel(a0),d0
		or.w	ost_y_vel(a0),d0
		bne.s	@update_pos			; branch if Eggman is moving at all
		lea	(v_ost_all).w,a1		; start at the first OST slot
		moveq	#$3E,d0
		moveq	#sizeof_ost,d1			; $40

	@loop:	
		adda.w	d1,a1				; next OST slot
		cmpi.b	#id_FalseFloor,(a1)		; is object a block? (id $83)
		dbeq	d0,@loop			; if not, repeat (max $3E times)

		bne.s	@update_pos
		move.w	#$474F,ost_subtype(a1)		; set block to disintegrate
		addq.b	#2,ost_routine2(a0)		; goto SEgg_Move next
		move.b	#id_ani_eggman_laugh,ost_anim(a0)

@update_pos:
		bra.w	SEgg_Move
; ===========================================================================

SEgg_Button:	; Routine 4
		moveq	#0,d0
		move.b	ost_routine2(a0),d0
		move.w	SEgg_BtnIndex(pc,d0.w),d0
		jmp	SEgg_BtnIndex(pc,d0.w)
; ===========================================================================
SEgg_BtnIndex:	index *,,2
		ptr SEgg_BtnChk
		ptr SEgg_BtnDisplay
; ===========================================================================

SEgg_BtnChk:
		movea.l	ost_eggman_parent(a0),a1	; get address of parent OST (Eggman)
		cmpi.w	#$5357,ost_subtype(a1)		; has subtype been changed?
		bne.s	SEgg_BtnDisplay			; if not, branch
		move.b	#id_frame_button_down,ost_frame(a0) ; use pressed frame
		addq.b	#2,ost_routine2(a0)		; goto SEgg_BtnDisplay next

SEgg_BtnDisplay:
		jmp	(DisplaySprite).l

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_SEgg:	index *
		ptr ani_eggman_stand
		ptr ani_eggman_laugh
		ptr ani_eggman_jump1
		ptr ani_eggman_intube
		ptr ani_eggman_running
		ptr ani_eggman_jump2
		ptr ani_eggman_jump
		
ani_eggman_stand:
		dc.b $7E
		dc.b id_frame_eggman_stand
		dc.b afEnd
		even

ani_eggman_laugh:
		dc.b 6
		dc.b id_frame_eggman_laugh1
		dc.b id_frame_eggman_laugh2
		dc.b afEnd

ani_eggman_jump1:
		dc.b $E
		dc.b id_frame_eggman_jump1
		dc.b id_frame_eggman_jump2
		dc.b id_frame_eggman_jump2
		dc.b id_frame_eggman_stand
		dc.b id_frame_eggman_stand
		dc.b id_frame_eggman_stand
		dc.b afEnd

ani_eggman_intube:
		dc.b 0
		dc.b id_frame_eggman_surprise
		dc.b id_frame_eggman_intube
		dc.b afEnd

ani_eggman_running:
		dc.b 6
		dc.b id_frame_eggman_running1
		dc.b id_frame_eggman_jump2
		dc.b id_frame_eggman_running2
		dc.b id_frame_eggman_jump2
		dc.b afEnd

ani_eggman_jump2:
		dc.b $F
		dc.b id_frame_eggman_jump2
		dc.b id_frame_eggman_jump1
		dc.b id_frame_eggman_jump1
		dc.b afEnd
		even

ani_eggman_jump:
		dc.b $7E
		dc.b id_frame_eggman_jump
		dc.b afEnd
		even
