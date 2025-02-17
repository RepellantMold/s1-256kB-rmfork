; ---------------------------------------------------------------------------
; Object 1B - water surface (LZ)

; spawned by:
;	GM_Level (loads 2 at x positions $60 and $120)
; ---------------------------------------------------------------------------

WaterSurface:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Surf_Index(pc,d0.w),d1
		jmp	Surf_Index(pc,d1.w)
; ===========================================================================
Surf_Index:	index *,,2
		ptr Surf_Main
		ptr Surf_Action

ost_surf_x_start:	equ $30				; original x-axis position (2 bytes)
ost_surf_freeze:	equ $32				; flag to freeze animation

Surf_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Surf
		dc.b ost_actwidth,128
		dc.b so_write_word,ost_tile
		dc.w $2DF+tile_pal3+tile_hi
		dc.b ost_render,render_rel
		dc.b so_copy_word,ost_x_pos,ost_surf_x_start
		dc.b so_end
		even
; ===========================================================================

Surf_Main:	; Routine 0
		lea	Surf_Settings(pc),a2
		bsr.w	SetupObject

Surf_Action:	; Routine 2
		move.w	(v_camera_x_pos).w,d1		; get camera x position
		andi.w	#$FFE0,d1			; round down to $20
		add.w	ost_surf_x_start(a0),d1		; add initial position
		btst	#0,(v_frame_counter_low).w
		beq.s	@even				; branch on even frames
		addi.w	#$20,d1				; add $20 every other frame to create flicker

	@even:
		move.w	d1,ost_x_pos(a0)		; match x position to screen position
		move.w	(v_water_height_actual).w,d1
		move.w	d1,ost_y_pos(a0)		; match y position to water height
		tst.b	ost_surf_freeze(a0)
		bne.s	@stopped
		btst	#bitStart,(v_joypad_press_actual).w ; is Start button pressed?
		beq.s	@animate			; if not, branch
		addq.b	#id_frame_surf_paused1,ost_frame(a0) ; use different frames
		move.b	#1,ost_surf_freeze(a0)		; stop animation
		bra.s	@display
; ===========================================================================

@stopped:
		tst.w	(f_pause).w			; is the game paused?
		bne.s	@display			; if yes, branch
		move.b	#0,ost_surf_freeze(a0)		; resume animation
		subq.b	#id_frame_surf_paused1,ost_frame(a0) ; use normal frames

@animate:
		subq.b	#1,ost_anim_time(a0)		; decrement animation timer
		bpl.s	@display			; branch if time remains
		move.b	#7,ost_anim_time(a0)		; reset timer
		addq.b	#1,ost_frame(a0)		; next frame
		cmpi.b	#id_frame_surf_normal3+1,ost_frame(a0)
		bcs.s	@display
		move.b	#0,ost_frame(a0)		; reset to frame 0 when animation finishes

@display:
		bra.w	DisplaySprite
