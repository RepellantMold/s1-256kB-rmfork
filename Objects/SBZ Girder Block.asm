; ---------------------------------------------------------------------------
; Object 70 - large girder block (SBZ)

; spawned by:
;	ObjPos_SBZ1
; ---------------------------------------------------------------------------

Girder:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Gird_Index(pc,d0.w),d1
		jmp	Gird_Index(pc,d1.w)
; ===========================================================================
Gird_Index:	index *,,2
		ptr Gird_Main
		ptr Gird_Action

ost_girder_y_start:	equ $30				; original y-axis position (2 bytes)
ost_girder_x_start:	equ $32				; original x-axis position (2 bytes)
ost_girder_move_time:	equ $34				; duration for movement in a direction (2 bytes)
ost_girder_setting:	equ $38				; which movement settings to use, increments by 8
ost_girder_wait_time:	equ $3A				; delay for movement (2 bytes)

Gird_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Gird
		dc.b so_write_word,ost_tile
		dc.w $2D9+tile_pal3
		dc.b ost_priority,4
		dc.b ost_actwidth,$60
		dc.b ost_height,$18
		dc.b so_copy_word,ost_x_pos,ost_girder_x_start
		dc.b so_render_rel
		dc.b so_end
		even
; ===========================================================================

Gird_Main:	; Routine 0
		lea	Gird_Settings(pc),a2
		bsr.w	SetupObject
		bsr.w	Gird_ChgDir			; set initial speed & direction

Gird_Action:	; Routine 2
		move.w	ost_x_pos(a0),-(sp)
		tst.w	ost_girder_wait_time(a0)	; has time delay hit 0?
		beq.s	@beginmove			; if yes, branch
		subq.w	#1,ost_girder_wait_time(a0)	; decrement delay timer
		bne.s	@skip_move			; skip movement update

	@beginmove:
		jsr	(SpeedToPos).l			; update position
		subq.w	#1,ost_girder_move_time(a0)	; decrement movement timer
		bne.s	@skip_chg			; if time remains, branch
		bsr.w	Gird_ChgDir			; if time is 0, set new speed & direction

	@skip_move:
	@skip_chg:
		move.w	(sp)+,d4
		tst.b	ost_render(a0)			; is object on-screen?
		bpl.s	@chkdel				; if not, branch
		moveq	#0,d1
		move.b	ost_actwidth(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	ost_height(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	SolidObject

	@chkdel:
		out_of_range.s	@delete,ost_girder_x_start(a0)
		jmp	(DisplaySprite).l

	@delete:
		jmp	(DeleteObject).l

; ---------------------------------------------------------------------------
; Subroutine to change the speed/direction the girder is moving
; ---------------------------------------------------------------------------

Gird_ChgDir:
		move.b	ost_girder_setting(a0),d0	; get current setting
		andi.w	#$18,d0
		lea	(@settings).l,a1
		lea	(a1,d0.w),a1			; jump to relevant settings
		move.w	(a1)+,ost_x_vel(a0)		; speed/direction
		move.w	(a1)+,ost_y_vel(a0)
		move.w	(a1)+,ost_girder_move_time(a0)	; how long to move in that direction
		addq.b	#8,ost_girder_setting(a0)	; use next settings
		move.w	#7,ost_girder_wait_time(a0)	; set time until it starts moving again
		rts	
; ===========================================================================
@settings:	;   x vel,   y vel, duration
		dc.w   $100,	 0,   $60,     0	; right
		dc.w	  0,  $100,   $30,     0	; down
		dc.w  -$100,  -$40,   $60,     0	; up/left
		dc.w	  0, -$100,   $18,     0	; up
