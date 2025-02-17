; ---------------------------------------------------------------------------
; Object 20 - cannonball that Ball Hog throws (SBZ)

; spawned by:
;	BallHog - subtype inherited from parent
; ---------------------------------------------------------------------------

Cannonball:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Cbal_Index(pc,d0.w),d1
		jmp	Cbal_Index(pc,d1.w)
; ===========================================================================
Cbal_Index:	index *,,2
		ptr Cbal_Main
		ptr Cbal_Bounce

ost_ball_time:	equ $30					; time until the cannonball explodes (2 bytes)

Cbal_Settings:	dc.b ost_height,7
		dc.b ost_render,render_rel
		dc.b ost_priority,3
		dc.b ost_col_type,id_col_6x6+id_col_hurt
		dc.b ost_actwidth,8
		dc.b ost_routine,2
		dc.b so_write_word,ost_tile
		dc.w $2EB+tile_pal2
		dc.b so_write_long,ost_mappings
		dc.l Map_Hog
		dc.b so_end
		even
; ===========================================================================

Cbal_Main:	; Routine 0
		lea	Cbal_Settings(pc),a2
		bsr.w	SetupObject
		moveq	#0,d0
		move.b	ost_subtype(a0),d0		; move subtype to d0
		mulu.w	#60,d0				; multiply by 60 frames	(1 second)
		move.w	d0,ost_ball_time(a0)		; set explosion time
		move.b	#id_frame_hog_ball1,ost_frame(a0)

Cbal_Bounce:	; Routine 2
		jsr	(ObjectFall).l
		tst.w	ost_y_vel(a0)
		bmi.s	Cbal_ChkExplode
		jsr	(FindFloorObj).l
		tst.w	d1				; has ball hit the floor?
		bpl.s	Cbal_ChkExplode			; if not, branch

		add.w	d1,ost_y_pos(a0)		; align to floor
		move.w	#-$300,ost_y_vel(a0)		; bounce
		tst.b	d3				; test floor angle
		beq.s	Cbal_ChkExplode			; branch if perfectly flat
		bmi.s	@down_left			; branch if sloping up-right or down-left

		tst.w	ost_x_vel(a0)
		bpl.s	Cbal_ChkExplode			; branch if ball is moving right
		neg.w	ost_x_vel(a0)			; reverse direction (ball hits down-right slope while moving left)
		bra.s	Cbal_ChkExplode
; ===========================================================================

@down_left:
		tst.w	ost_x_vel(a0)
		bmi.s	Cbal_ChkExplode			; branch if ball is moving left
		neg.w	ost_x_vel(a0)			; reverse direction (ball hits down-left slope while moving right)

Cbal_ChkExplode:
		subq.w	#1,ost_ball_time(a0)		; subtract 1 from explosion time
		bpl.s	Cbal_Animate			; if time is > 0, branch

	Cbal_Explode:
		move.b	#id_ExplosionBomb,ost_id(a0)	; change object	to an explosion	($3F)
		move.b	#id_ExBom_Main,ost_routine(a0)	; reset routine counter
		bra.w	ExplosionBomb			; jump to explosion code
; ===========================================================================

Cbal_Animate:
		subq.b	#1,ost_anim_time(a0)		; subtract 1 from frame duration
		bpl.s	Cbal_Display
		move.b	#5,ost_anim_time(a0)		; set frame duration to 5 frames
		bchg	#0,ost_frame(a0)		; change frame

Cbal_Display:
		bsr.w	DisplaySprite
		move.w	(v_boundary_bottom).w,d0
		addi.w	#224,d0
		cmp.w	ost_y_pos(a0),d0		; has object fallen off the level?
		bcs.w	DeleteObject			; if yes, branch
		rts	
