; ---------------------------------------------------------------------------
; Object 5F - walking bomb enemy (SLZ, SBZ)

; spawned by:
;	ObjPos_SLZ1, ObjPos_SLZ2, ObjPos_SLZ3, ObjPos_SBZ1, ObjPos_SBZ2 - subtype 0
;	Bomb - subtype 4 (fuse), subtype 6 (shrapnel)
; ---------------------------------------------------------------------------

Bomb:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Bom_Index(pc,d0.w),d1
		jmp	Bom_Index(pc,d1.w)
; ===========================================================================
Bom_Index:	index *,,2
		ptr Bom_Main
		ptr Bom_Action
		ptr Bom_Fuse
		ptr Bom_Shrapnel

ost_bomb_fuse_time:	equ $30				; time left on fuse - also used for change direction timer (2 bytes)
ost_bomb_y_start:	equ $34				; original y-axis position (2 bytes)
ost_bomb_parent:	equ $3C				; address of OST of parent object (4 bytes)

Bom_Settings:	dc.b ost_priority,3
		dc.b ost_actwidth,12
		dc.b ost_routine,2
		dc.b so_write_word,ost_tile
		dc.w vram_bomb/32
		dc.b so_write_long,ost_mappings
		dc.l Map_Bomb
		dc.b so_render_rel,so_end
		even
; ===========================================================================

Bom_Main:	; Routine 0
		lea	Bom_Settings(pc),a2
		bsr.w	SetupObject
		cmpi.b	#id_SBZ,(v_zone).w
		bne.s	@not_sbz
		move.w	#$492,ost_tile(a0)
	@not_sbz:
		move.b	ost_subtype(a0),d0
		beq.s	@type0				; branch if subtype = 0
		move.b	d0,ost_routine(a0)		; copy subtype to routine (4 = Bom_Fuse; 6 = Bom_Shrapnel)
		rts	
; ===========================================================================

@type0:
		move.b	#id_col_12x12+id_col_hurt,ost_col_type(a0)
		bchg	#status_xflip_bit,ost_status(a0)

Bom_Action:	; Routine 2
		moveq	#0,d0
		move.b	ost_routine2(a0),d0
		move.w	Bom_Action_Index(pc,d0.w),d1
		jsr	Bom_Action_Index(pc,d1.w)
		lea	(Ani_Bomb).l,a1
		bsr.w	AnimateSprite
		bra.w	DespawnObject
; ===========================================================================
Bom_Action_Index:
		index *,,2
		ptr Bom_Action_Walk
		ptr Bom_Action_Wait
		ptr Bom_Action_Explode
; ===========================================================================

Bom_Action_Walk:
		bsr.w	Bom_ChkDist
		subq.w	#1,ost_bomb_fuse_time(a0)	; subtract 1 from time delay
		bpl.s	@noflip				; if time remains, branch
		addq.b	#2,ost_routine2(a0)		; goto Bom_Action_Wait next
		move.w	#1535,ost_bomb_fuse_time(a0)	; set time delay to 25.5 seconds
		move.w	#$10,ost_x_vel(a0)
		move.b	#id_ani_bomb_walk,ost_anim(a0)	; use walking animation
		bchg	#status_xflip_bit,ost_status(a0)
		beq.s	@noflip
		neg.w	ost_x_vel(a0)			; change direction

	@noflip:
		rts	
; ===========================================================================

Bom_Action_Wait:
		bsr.w	Bom_ChkDist
		subq.w	#1,ost_bomb_fuse_time(a0)	; subtract 1 from time delay
		bmi.s	@stopwalking			; if time expires, branch
		bsr.w	SpeedToPos
		rts

	@stopwalking:
		subq.b	#2,ost_routine2(a0)		; goto Bom_Action_Walk next
		move.w	#179,ost_bomb_fuse_time(a0)	; set time delay to 3 seconds
		clr.w	ost_x_vel(a0)			; stop walking
		move.b	#id_ani_bomb_stand,ost_anim(a0)	; use waiting animation
		rts	
; ===========================================================================

Bom_Action_Explode:
		subq.w	#1,ost_bomb_fuse_time(a0)	; subtract 1 from time delay
		bpl.s	@noexplode			; if time remains, branch
		move.b	#id_ExplosionBomb,ost_id(a0)	; change bomb into an explosion
		move.b	#id_ExBom_Main,ost_routine(a0)

	@noexplode:
		rts

; ---------------------------------------------------------------------------
; Subroutine to check Sonic's distance and load fuse object
; ---------------------------------------------------------------------------

Bom_ChkDist:
		move.w	(v_ost_player+ost_x_pos).w,d0
		sub.w	ost_x_pos(a0),d0
		bcc.s	@isleft
		neg.w	d0

	@isleft:
		cmpi.w	#$60,d0				; is Sonic within $60 pixels?
		bcc.s	@outofrange			; if not, branch
		move.w	(v_ost_player+ost_y_pos).w,d0
		sub.w	ost_y_pos(a0),d0
		bcc.s	@isabove
		neg.w	d0

	@isabove:
		cmpi.w	#$60,d0
		bcc.s	@outofrange

		move.b	#id_Bom_Action_Explode,ost_routine2(a0)
		move.w	#143,ost_bomb_fuse_time(a0)	; set fuse time
		clr.w	ost_x_vel(a0)
		move.b	#id_ani_bomb_active,ost_anim(a0) ; use activated animation
		bsr.w	FindNextFreeObj
		bne.s	@outofrange
		lea	Bom_Settings2(pc),a2
		bsr.w	SetupChild
		btst	#status_yflip_bit,ost_status(a0) ; is bomb upside-down?
		beq.s	@normal				; if not, branch
		neg.w	ost_y_vel(a1)			; reverse direction for fuse

	@normal:

@outofrange:
		rts

Bom_Settings2:	dc.b ost_id,id_Bomb
		dc.b ost_subtype,id_Bom_Fuse
		dc.b ost_anim,id_ani_bomb_fuse
		dc.b ost_y_vel+1,16
		dc.b ost_bomb_fuse_time+1,143
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b so_copy_word,ost_y_pos,ost_bomb_y_start
		dc.b so_inherit_byte,ost_status
		dc.b so_set_parent,ost_bomb_parent
		dc.b so_end
		even
; ===========================================================================

Bom_Fuse:	; Routine 4
		bsr.s	Bom_Fuse_ChkTime
		lea	(Ani_Bomb).l,a1
		bsr.w	AnimateSprite
		bra.w	DespawnObject
; ===========================================================================

Bom_Fuse_ChkTime:
		subq.w	#1,ost_bomb_fuse_time(a0)	; decrement fuse timer
		bmi.s	@explode			; branch if fuse runs out
		bsr.w	SpeedToPos			; update position
		rts	
; ===========================================================================

@explode:
		clr.w	ost_bomb_fuse_time(a0)
		clr.b	ost_routine(a0)
		move.w	ost_bomb_y_start(a0),ost_y_pos(a0)
		moveq	#4-1,d3				; 4 shrapnel objects
		movea.l	a0,a1				; replace fuse object with 1st shrapnel object
		lea	(Bom_ShrSpeed).l,a3		; load shrapnel speed data
		bra.s	@makeshrapnel
; ===========================================================================

	@loop:
		bsr.w	FindNextFreeObj
		bne.s	@fail

@makeshrapnel:
		lea	Bom_Settings3(pc),a2
		bsr.w	SetupChild
		move.w	(a3)+,ost_x_vel(a1)
		move.w	(a3)+,ost_y_vel(a1)
		bset	#render_onscreen_bit,ost_render(a1)

	@fail:
		dbf	d3,@loop			; repeat 3 more	times

		move.b	#id_Bom_Shrapnel,ost_routine(a0)

Bom_Shrapnel:	; Routine 6
		bsr.w	SpeedToPos			; update position
		addi.w	#$18,ost_y_vel(a0)		; apply gravity
		lea	(Ani_Bomb).l,a1
		bsr.w	AnimateSprite
		tst.b	ost_render(a0)			; is object on-screen?
		bpl.w	DeleteObject			; if not, branch
		bra.w	DisplaySprite
; ===========================================================================
Bom_ShrSpeed:	dc.w -$200, -$300			; top left
		dc.w -$100, -$200			; bottom left
		dc.w $200, -$300			; top right
		dc.w $100, -$200			; bottom right

Bom_Settings3:	dc.b ost_id,id_Bomb
		dc.b ost_subtype,id_Bom_Shrapnel
		dc.b ost_anim,id_ani_bomb_shrapnel
		dc.b ost_col_type,id_col_4x4+id_col_hurt
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b so_end
		even

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Bomb:	index *
		ptr ani_bomb_stand
		ptr ani_bomb_walk
		ptr ani_bomb_active
		ptr ani_bomb_fuse
		ptr ani_bomb_shrapnel
		
ani_bomb_stand:
		dc.b $13
		dc.b id_frame_bomb_stand2
		dc.b id_frame_bomb_stand1
		dc.b afEnd

ani_bomb_walk:
		dc.b $13
		dc.b id_frame_bomb_walk4
		dc.b id_frame_bomb_walk3
		dc.b id_frame_bomb_walk2
		dc.b id_frame_bomb_walk1
		dc.b afEnd

ani_bomb_active:
		dc.b $13
		dc.b id_frame_bomb_activate2
		dc.b id_frame_bomb_activate1
		dc.b afEnd

ani_bomb_fuse:
		dc.b 3
		dc.b id_frame_bomb_fuse1
		dc.b id_frame_bomb_fuse2
		dc.b afEnd

ani_bomb_shrapnel:
		dc.b 3
		dc.b id_frame_bomb_shrapnel1
		dc.b id_frame_bomb_shrapnel2
		dc.b afEnd
		even
