; ---------------------------------------------------------------------------
; Object 3C - smashable	wall (GHZ, SLZ)

; spawned by:
;	ObjPos_GHZ2, ObjPos_GHZ3 - subtypes 0/1/2
;	ObjPos_SLZ1, ObjPos_SLZ3 - subtype 1
; ---------------------------------------------------------------------------

SmashWall:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Smash_Index(pc,d0.w),d1
		jsr	Smash_Index(pc,d1.w)
		bra.w	DespawnObject
; ===========================================================================
Smash_Index:	index *,,2
		ptr Smash_Main
		ptr Smash_Solid
		ptr Smash_FragMove

ost_smash_x_vel:	equ $30				; Sonic's horizontal speed (2 bytes)

Smash_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Smash
		dc.b so_write_word,ost_tile
		dc.w $348+tile_pal3
		dc.b ost_render,render_rel
		dc.b ost_actwidth,16
		dc.b ost_priority,4
		dc.b so_copy_byte,ost_subtype,ost_frame
		dc.b so_end
		even
; ===========================================================================

Smash_Main:	; Routine 0
		lea	Smash_Settings(pc),a2
		bsr.w	SetupObject
		cmpi.b	#id_SLZ,(v_zone).w
		bne.s	@not_slz
		move.w	#$411+tile_pal3,ost_tile(a0)
	@not_slz:

Smash_Solid:	; Routine 2
		move.w	(v_ost_player+ost_x_vel).w,ost_smash_x_vel(a0) ; load Sonic's horizontal speed
		move.w	#$1B,d1				; width
		move.w	#$20,d2				; height
		move.w	#$20,d3
		move.w	ost_x_pos(a0),d4
		bsr.w	SolidObject
		btst	#status_pushing_bit,ost_status(a0) ; is Sonic pushing against the wall?
		bne.s	@chkroll			; if yes, branch

@donothing:
		rts	
; ===========================================================================

@chkroll:
		cmpi.b	#id_Roll,ost_anim(a1)		; is Sonic rolling?
		bne.s	@donothing			; if not, branch
		move.w	ost_smash_x_vel(a0),d0		; get Sonic's speed
		bpl.s	@chkspeed			; branch if Sonic is moving right
		neg.w	d0				; convert -ve to +ve

	@chkspeed:
		cmpi.w	#$480,d0			; is Sonic's speed $480 or higher?
		bcs.s	@donothing			; if not, branch
		move.w	ost_smash_x_vel(a0),ost_x_vel(a1)
		addq.w	#4,ost_x_pos(a1)
		lea	(Smash_FragSpd1).l,a4		; use fragments that move right
		move.w	ost_x_pos(a0),d0
		cmp.w	ost_x_pos(a1),d0		; is Sonic to the right of the block?
		bcs.s	@smash				; if yes, branch
		subq.w	#8,ost_x_pos(a1)
		lea	(Smash_FragSpd2).l,a4		; use fragments that move left

	@smash:
		move.w	ost_x_vel(a1),ost_inertia(a1)
		bclr	#status_pushing_bit,ost_status(a0)
		bclr	#status_pushing_bit,ost_status(a1)
		moveq	#8-1,d3				; load 8 fragments
		move.w	#$70,d2
		bsr.s	SmashObject

Smash_FragMove:	; Routine 4
		bsr.w	SpeedToPos			; update position
		addi.w	#$70,ost_y_vel(a0)		; make fragment fall faster
		bsr.w	DisplaySprite
		tst.b	ost_render(a0)			; is fragment on-screen?
		bpl.w	DeleteObject			; if not, branch
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	smash a	block (GHZ walls and MZ	blocks)
;
; input:
;	d3 = number of fragments to load, minus 1
;	d2 = initial gravity (added to y speed of each fragment)
; ---------------------------------------------------------------------------

SmashObject:
		moveq	#0,d0
		move.b	ost_frame(a0),d0
		add.w	d0,d0
		movea.l	ost_mappings(a0),a3		; get mappings address
		adda.w	(a3,d0.w),a3			; jump to frame
		addq.w	#1,a3				; use first sprite piece from that frame
		bset	#render_rawmap_bit,ost_render(a0) ; raw sprite
		movea.l	a0,a1
		bra.s	@loadfrag
; ===========================================================================

	@loop:
		bsr.w	FindFreeObj			; find free OST slot
		bne.s	@playsnd			; branch if not found
		addq.w	#5,a3				; next sprite in mappings frame

@loadfrag:
		lea	Smash_Settings2(pc),a2
		bsr.w	SetupChild
		move.l	a3,ost_mappings(a1)
		move.w	(a4)+,ost_x_vel(a1)
		move.w	(a4)+,ost_y_vel(a1)
		cmpa.l	a0,a1				; is parent OST before fragment OST in RAM?
		bcc.s	@parent_earlier			; if yes, branch

		; fragment OST is before parent, so Smash_FragMove must be duplicated here
		move.l	a0,-(sp)
		movea.l	a1,a0
		bsr.w	SpeedToPos			; update position now
		add.w	d2,ost_y_vel(a0)		; apply gravity
		movea.l	(sp)+,a0
		bsr.w	DisplaySprite_a1

	@parent_earlier:
		dbf	d3,@loop

	@playsnd:
		play.w	1, jmp, sfx_Smash		; play smashing sound

; End of function SmashObject

; ===========================================================================
; Smashed block	fragment speeds
;
Smash_FragSpd1:	dc.w $400, -$500			; x speed, y speed
		dc.w $600, -$100
		dc.w $600, $100
		dc.w $400, $500
		dc.w $600, -$600
		dc.w $800, -$200
		dc.w $800, $200
		dc.w $600, $600

Smash_FragSpd2:	dc.w -$600, -$600
		dc.w -$800, -$200
		dc.w -$800, $200
		dc.w -$600, $600
		dc.w -$400, -$500
		dc.w -$600, -$100
		dc.w -$600, $100
		dc.w -$400, $500

Smash_Settings2:
		dc.b so_inherit_byte,ost_id
		dc.b so_inherit_byte,ost_render
		dc.b ost_routine,id_Smash_FragMove
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b so_inherit_word,ost_tile
		dc.b so_inherit_byte,ost_priority
		dc.b so_inherit_byte,ost_actwidth
		dc.b so_end
		even
