; ---------------------------------------------------------------------------
; Object 35 - fireball that sits on the	floor (MZ)
; (appears when	you walk on sinking platforms)

; spawned by:
;	LargeGrass - subtype 0
;	GrassFire - subtype 1
; ---------------------------------------------------------------------------

GrassFire:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	GFire_Index(pc,d0.w),d1
		jmp	GFire_Index(pc,d1.w)
; ===========================================================================
GFire_Index:	index *,,2
		ptr GFire_Main
		ptr GFire_Spread
		ptr GFire_Move

ost_burn_x_start:	equ $2A				; original x position (2 bytes)
ost_burn_y_start:	equ $2C				; original y position (2 bytes)
ost_burn_coll_ptr:	equ $30				; pointer to collision data (4 bytes)
ost_burn_parent:	equ $38				; address of OST of parent object (4 bytes)
ost_burn_sink:		equ $3C				; pixels the platform has sunk when stood on

GFire_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Fire
		dc.b so_write_word,ost_tile
		dc.w $3E6
		dc.b ost_render,render_rel
		dc.b ost_priority,1
		dc.b ost_col_type,id_col_8x8+id_col_hurt
		dc.b ost_actwidth,8
		dc.b so_copy_word,ost_x_pos,ost_burn_x_start
		dc.b so_end
		even
; ===========================================================================

GFire_Main:	; Routine 0
		lea	GFire_Settings(pc),a2
		bsr.w	SetupObject
		play.w	1, jsr, sfx_Burning		; play burning sound
		tst.b	ost_subtype(a0)			; is this the first fireball?
		beq.s	GFire_Spread			; if yes, branch
		addq.b	#2,ost_routine(a0)		; goto GFire_Move next
		bra.w	GFire_Move
; ===========================================================================

GFire_Spread:	; Routine 2
		movea.l	ost_burn_coll_ptr(a0),a1	; a1 = pointer to platform heightmap
		move.w	ost_x_pos(a0),d1
		sub.w	ost_burn_x_start(a0),d1		; d1 = relative x position on platform
		addi.w	#$C,d1
		move.w	d1,d0
		lsr.w	#1,d0
		move.b	(a1,d0.w),d0			; get value from heightmap
		neg.w	d0
		add.w	ost_burn_y_start(a0),d0		; get initial y position
		move.w	d0,d2
		add.w	ost_burn_sink(a0),d0		; add difference when platform sinks
		move.w	d0,ost_y_pos(a0)		; update y position
		cmpi.w	#$84,d1
		bcc.s	@no_fire			; branch if beyond right edge of platform
		addi.l	#$10000,ost_x_pos(a0)		; move 1px right
		cmpi.w	#$80,d1
		bcc.s	@no_fire
		move.l	ost_x_pos(a0),d0
		addi.l	#$80000,d0
		andi.l	#$FFFFF,d0
		bne.s	@no_fire
		bsr.w	FindNextFreeObj			; find free OST slot
		bne.s	@no_fire			; branch if not found
		lea	GFire_Settings2(pc),a2
		bsr.w	SetupChild
		move.w	d2,ost_burn_y_start(a1)		; initial y pos (ignores platform sinking)
		movea.l	ost_burn_parent(a0),a2
		bsr.w	LGrass_AddChildToList		; add to list in parent's OST

	@no_fire:
		bra.s	GFire_Animate

GFire_Settings2:
		dc.b ost_id,id_GrassFire
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_burn_sink
		dc.b ost_subtype,1
		dc.b so_end
		even
; ===========================================================================

GFire_Move:	; Routine 4
		move.w	ost_burn_y_start(a0),d0
		add.w	ost_burn_sink(a0),d0
		move.w	d0,ost_y_pos(a0)		; update position

GFire_Animate:
		lea	(Ani_GFire).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_GFire:	index *
		ptr ani_gfire_0
		
ani_gfire_0:	dc.b 5
		dc.b id_frame_fire_vertical1
		dc.b id_frame_fire_vertical1+afxflip
		dc.b id_frame_fire_vertical2
		dc.b id_frame_fire_vertical2+afxflip
		dc.b afEnd
		even
