; ---------------------------------------------------------------------------
; Object 5E - seesaws (SLZ)

; spawned by:
;	ObjPos_SLZ2, ObjPos_SLZ3 - subtypes 0/$FF
;	Seesaw - routine 6 (spikeball)
; ---------------------------------------------------------------------------

Seesaw:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	See_Index(pc,d0.w),d1
		jsr	See_Index(pc,d1.w)
		move.w	ost_seesaw_x_start(a0),d0
		andi.w	#$FF80,d0
		move.w	(v_camera_x_pos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		bmi.w	DeleteObject
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================
See_Index:	index *,,2
		ptr See_Main
		ptr See_Slope
		ptr See_StoodOn
		ptr See_Spikeball
		ptr See_SpikeAction
		ptr See_SpikeFall

ost_seesaw_x_start:	equ $30					; original x-axis position (2 bytes)
ost_seesaw_y_start:	equ $34					; original y-axis position (2 bytes)
ost_seesaw_impact:	equ $38					; speed Sonic hits the seesaw (2 bytes)
ost_seesaw_state:	equ $3A					; seesaw: 0 = left raised; 2 = right raised; 1 = flat
								; spikeball: 0 = on/launched from right side; 2 = on/launched from left side
ost_seesaw_parent:	equ $3C					; address of OST of parent object (4 bytes)

See_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Seesaw
		dc.b so_write_word,ost_tile
		dc.w $35F
		dc.b ost_priority,4
		dc.b ost_actwidth,$30
		dc.b so_copy_word,ost_x_pos,ost_seesaw_x_start
		dc.b so_render_rel
		dc.b so_end
		even
See_Settings2:	dc.b ost_id,id_Seesaw
		dc.b ost_routine,id_See_Spikeball
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b so_inherit_byte,ost_status
		dc.b so_set_parent,ost_seesaw_parent
		dc.b so_end
		even
; ===========================================================================

See_Main:	; Routine 0
		lea	See_Settings(pc),a2
		bsr.w	SetupObject
		tst.b	ost_subtype(a0)				; is object type 0?
		bne.s	@noball					; if not, branch

		bsr.w	FindNextFreeObj				; find free OST slot
		bne.s	@noball					; branch if not found
		lea	See_Settings2(pc),a2
		bsr.w	SetupChild

	@noball:
		btst	#status_xflip_bit,ost_status(a0)	; is seesaw flipped?
		beq.s	@noflip					; if not, branch
		move.b	#id_frame_seesaw_sloping_rightup,ost_frame(a0) ; use different frame

	@noflip:
		move.b	ost_frame(a0),ost_seesaw_state(a0)	; set state to 0 or 2

See_Slope:	; Routine 2
		move.b	ost_seesaw_state(a0),d1			; get state
		bsr.w	See_ChgFrame				; update frame if needed
		lea	(See_DataSlope).l,a2			; heightmap for sloped seesaw
		btst	#0,ost_frame(a0)			; is seesaw flat?
		beq.s	@notflat				; if not, branch
		lea	(See_DataFlat).l,a2			; heightmap for flat seesaw

	@notflat:
		lea	(v_ost_player).w,a1
		move.w	ost_y_vel(a1),ost_seesaw_impact(a0)	; save speed at which Sonic landed on the seesaw
		move.w	#$30,d1
		jmp	(SlopeObject).l				; detect collision and goto See_StoodOn next if true
; ===========================================================================

See_StoodOn:	; Routine 4
		bsr.w	See_ChkSide				; check where Sonic is on seesaw and update frame
		lea	(See_DataSlope).l,a2
		btst	#0,ost_frame(a0)			; is seesaw flat?
		beq.s	@notflat				; if not, branch
		lea	(See_DataFlat).l,a2

	@notflat:
		move.w	#$30,d1
		jsr	(ExitPlatform).l			; goto See_Slope next if Sonic leaves seesaw
		move.w	#$30,d1
		move.w	ost_x_pos(a0),d2
		jmp	(SlopeObject_NoChk).l

; ---------------------------------------------------------------------------
; Subroutine to check which side Sonic is on, and update its frame

; input:
;	d1 = ost_seesaw_state (See_ChgFrame only)

; output:
;	d1 = ost_seesaw_state
;	uses d0
; ---------------------------------------------------------------------------

See_ChkSide:
		moveq	#id_frame_seesaw_sloping_rightup,d1	; right side is raised by default (2)
		lea	(v_ost_player).w,a1
		move.w	ost_x_pos(a0),d0
		sub.w	ost_x_pos(a1),d0			; is Sonic on the left side of the seesaw?
		bcc.s	@leftside				; if yes, branch
		neg.w	d0
		moveq	#id_frame_seesaw_sloping_leftup,d1	; left side is raised (0)

	@leftside:
		cmpi.w	#8,d0					; is Sonic more than 8px from centre?
		bcc.s	See_ChgFrame				; if yes, branch
		moveq	#id_frame_seesaw_flat,d1		; seesaw is flat (1)

See_ChgFrame:
		move.b	ost_frame(a0),d0
		cmp.b	d1,d0					; does frame need to change?
		beq.s	@noflip					; if not, branch
		bcc.s	@reduce_frame				; branch if previous frame is > new frame
		addq.b	#2,d0

	@reduce_frame:
		subq.b	#1,d0
		move.b	d0,ost_frame(a0)			; update frame
		move.b	d1,ost_seesaw_state(a0)
		bclr	#render_xflip_bit,ost_render(a0)
		btst	#1,ost_frame(a0)			; is frame 2 or 3?
		beq.s	@noflip					; if not, branch
		bset	#render_xflip_bit,ost_render(a0)

	@noflip:
		rts	
; ===========================================================================
See_Settings3:	dc.b ost_routine,id_See_SpikeAction
		dc.b so_write_long,ost_mappings
		dc.l Map_SSawBall
		dc.b so_write_word,ost_tile
		dc.w $38B
		dc.b ost_priority,4
		dc.b ost_col_type,id_col_8x8+id_col_hurt
		dc.b ost_actwidth,12
		dc.b so_copy_word,ost_x_pos,ost_seesaw_x_start
		dc.b so_copy_word,ost_y_pos,ost_seesaw_y_start
		dc.b ost_frame,id_frame_seesaw_silver
		dc.b so_render_rel
		dc.b so_end
		even

See_Spikeball:	; Routine 6
		lea	See_Settings3(pc),a2
		bsr.w	SetupObject
		addi.w	#$28,ost_x_pos(a0)			; move spikeball to right side
		btst	#status_xflip_bit,ost_status(a0)	; is seesaw flipped?
		beq.s	See_SpikeAction				; if not, branch
		subi.w	#$50,ost_x_pos(a0)			; move spikeball to left side
		move.b	#2,ost_seesaw_state(a0)			; spikeball is on left side

See_SpikeAction:
		; Routine 8
		movea.l	ost_seesaw_parent(a0),a1		; get parent OST address
		moveq	#0,d0
		move.b	ost_seesaw_state(a0),d0
		sub.b	ost_seesaw_state(a1),d0			; d0 = seesaw/spikeball state difference
		beq.s	@align_spike				; branch if same
		bcc.s	@spike_from_left			; branch if spikeball is launched from left
		neg.b	d0

	@spike_from_left:
		move.w	#-$818,d1				; spikeball speed from flat seesaw
		move.w	#-$114,d2
		cmpi.b	#1,d0					; is seesaw flat?
		beq.s	@launch_spikeball			; if yes, branch
		move.w	#-$AF0,d1				; moderate spikeball speed
		move.w	#-$CC,d2
		cmpi.w	#$A00,ost_seesaw_impact(a1)		; has Sonic landed on seesaw with > $A00 force?
		blt.s	@launch_spikeball			; if yes, branch
		move.w	#-$E00,d1				; max spikeball speed
		move.w	#-$A0,d2

	@launch_spikeball:
		move.w	d1,ost_y_vel(a0)			; set spikeball speed
		move.w	d2,ost_x_vel(a0)
		move.w	ost_x_pos(a0),d0
		sub.w	ost_seesaw_x_start(a0),d0
		bcc.s	@from_x_start				; branch if spikeball is in its starting position
		neg.w	ost_x_vel(a0)				; launch in opposite direction

	@from_x_start:
		addq.b	#2,ost_routine(a0)			; goto See_SpikeFall next
		bra.s	See_SpikeFall
; ===========================================================================

@align_spike:
		lea	(See_YPos).l,a2				; address for list of relative y positions
		moveq	#0,d0
		move.b	ost_frame(a1),d0			; get frame of parent seesaw
		move.w	#$28,d2					; x distance from centre
		move.w	ost_x_pos(a0),d1
		sub.w	ost_seesaw_x_start(a0),d1
		bcc.s	@spike_from_left2			; branch if spikeball is left of its start position
		neg.w	d2
		addq.w	#2,d0

	@spike_from_left2:
		add.w	d0,d0
		move.w	ost_seesaw_y_start(a0),d1		; get initial y position
		add.w	(a2,d0.w),d1				; add relative position
		move.w	d1,ost_y_pos(a0)			; update position
		add.w	ost_seesaw_x_start(a0),d2
		move.w	d2,ost_x_pos(a0)
		clr.w	ost_y_sub(a0)
		clr.w	ost_x_sub(a0)
See_SpikeFall_no_double_grav:
		rts	
; ===========================================================================

See_SpikeFall:	; Routine $A
		tst.w	ost_y_vel(a0)				; is spikeball falling downwards?
		bpl.s	@downwards				; if yes, branch
		bsr.w	ObjectFall				; apply gravity and update position
		move.w	ost_seesaw_y_start(a0),d0
		subi.w	#$2F,d0
		cmp.w	ost_y_pos(a0),d0			; is spikeball more than 47px above seesaw?
		bgt.s	See_SpikeFall_no_double_grav				; if not, branch
		bra.w	ObjectFall				; apply more gravity
; ===========================================================================

@downwards:
		bsr.w	ObjectFall				; apply gravity and update position
		movea.l	ost_seesaw_parent(a0),a1		; get parent OST address
		lea	(See_YPos).l,a2				; address for list of relative y positions
		moveq	#0,d0
		move.b	ost_frame(a1),d0			; get frame of parent seesaw
		move.w	ost_x_pos(a0),d1
		sub.w	ost_seesaw_x_start(a0),d1
		bcc.s	@spike_from_left			; branch if spikeball is left of its start position
		addq.w	#2,d0

	@spike_from_left:
		add.w	d0,d0
		move.w	ost_seesaw_y_start(a0),d1		; get initial y position
		add.w	(a2,d0.w),d1				; add relative position
		cmp.w	ost_y_pos(a0),d1			; has spikeball reached that position?
		bgt.s	@exit					; if not, branch

		movea.l	ost_seesaw_parent(a0),a1
		moveq	#2,d1
		tst.w	ost_x_vel(a0)				; is spikeball moving left?
		bmi.s	@moving_left				; if yes, branch
		moveq	#0,d1

	@moving_left:
		move.b	d1,ost_seesaw_state(a1)			; update state for seesaw and spikeball
		move.b	d1,ost_seesaw_state(a0)
		cmp.b	ost_frame(a1),d1			; get seesaw frame
		beq.s	@skip_spring				; branch if 0 (left side raised)
		bclr	#status_platform_bit,ost_status(a1)	; clear flag for Sonic standing on seesaw
		beq.s	@skip_spring				; branch if already clear

		clr.b	ost_routine2(a1)
		move.b	#id_See_Slope,ost_routine(a1)
		lea	(v_ost_player).w,a2
		move.w	ost_y_vel(a0),ost_y_vel(a2)		; bounce Sonic with same speed the spikeball fell
		neg.w	ost_y_vel(a2)				; spikeball down, Sonic up
		bset	#status_air_bit,ost_status(a2)
		bclr	#status_platform_bit,ost_status(a2)
		clr.b	ost_sonic_jump(a2)
		move.b	#id_Spring,ost_anim(a2)			; change Sonic's animation to "spring" ($10)
		move.b	#id_Sonic_Control,ost_routine(a2)
		play.w	1, jsr, sfx_Spring			; play spring sound

	@skip_spring:
		clr.w	ost_x_vel(a0)
		clr.w	ost_y_vel(a0)
		subq.b	#2,ost_routine(a0)			; goto See_SpikeAction next

@exit:
		rts	
; ===========================================================================
See_YPos:	dc.w -8						; on raised side
		dc.w -$1C					; on flat
		dc.w -$2F					; on low side
		dc.w -$1C
		dc.w -8
