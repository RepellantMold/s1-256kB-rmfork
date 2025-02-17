; ---------------------------------------------------------------------------
; Object 30 - large green glass blocks (MZ)

; spawned by:
;	ObjPos_MZ1, ObjPos_MZ2, ObjPos_MZ3 - subtypes 1/2/4/$14
;	GlassBlock - subtype inherited from parent, +8
; ---------------------------------------------------------------------------

GlassBlock:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Glass_Index(pc,d0.w),d1
		jsr	Glass_Index(pc,d1.w)
		out_of_range	Glass_Delete
		bra.w	DisplaySprite
; ===========================================================================

Glass_Delete:
		bra.w	DeleteObject
; ===========================================================================
Glass_Index:	index *,,2
		ptr Glass_Main
		ptr Glass_Block012
		ptr Glass_Reflect012
		ptr Glass_Block34
		ptr Glass_Reflect34

Glass_Vars012:	dc.b id_Glass_Block012,	id_frame_glass_tall ; routine num, frame num
		dc.b id_Glass_Reflect012, id_frame_glass_shine
Glass_Vars34:	dc.b id_Glass_Block34, id_frame_glass_short
		dc.b id_Glass_Reflect34, id_frame_glass_shine

ost_glass_y_start:	equ $30				; original y position (2 bytes)
ost_glass_y_dist:	equ $32				; distance block moves when switch is pressed (2 bytes)
ost_glass_move_mode:	equ $34				; 1 when block moves after switch is pressed
ost_glass_jump_init:	equ $35				; 1 when block has been jumped on at least once
ost_glass_sink_dist:	equ $36				; distance to make block sink when jumped on; unused type 3 block (2 bytes)
ost_glass_sink_delay:	equ $38				; time to delay block sinking
ost_glass_parent:	equ $3C				; address of OST of parent object (4 bytes)

Glass_Settings:	dc.b ost_id,id_GlassBlock
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b so_write_long,ost_mappings
		dc.l Map_Glass
		dc.b so_write_word,ost_tile
		dc.w $2AF+tile_pal3+tile_hi
		dc.b ost_render,render_rel
		dc.b so_copy_word,ost_y_pos,ost_glass_y_start
		dc.b so_inherit_byte,ost_subtype
		dc.b ost_actwidth,32
		dc.b ost_priority,4
		dc.b so_set_parent,ost_glass_parent
		dc.b so_end
		even
; ===========================================================================

Glass_Main:	; Routine 0
		lea	(Glass_Vars012).l,a3
		moveq	#1,d2
		move.b	#$48,ost_height(a0)
		cmpi.b	#2,ost_subtype(a0)		; is object type 0/1/2 ?
		bcs.s	@type012			; if yes, branch
		lea	(Glass_Vars34).l,a3
		move.b	#$38,ost_height(a0)

	@type012:
		movea.l	a0,a1
		bra.s	@load				; load main object
; ===========================================================================

	@repeat:
		bsr.w	FindNextFreeObj
		bne.s	@fail

@load:
		lea	Glass_Settings(pc),a2
		bsr.w	SetupChild
		move.b	(a3)+,ost_routine(a1)		; goto Glass_Block012/Glass_Reflect012/Glass_Block34/Glass_Reflect34 next
		move.b	(a3)+,ost_frame(a1)		; get frame
		dbf	d2,@repeat			; repeat once to load "reflection object"

		move.b	#$10,ost_actwidth(a1)
		move.b	#3,ost_priority(a1)
		addq.b	#8,ost_subtype(a1)		; +8 to reflection object subtype
		andi.b	#$F,ost_subtype(a1)		; clear high nybble of subtype

	@fail:
		move.w	#$90,ost_glass_y_dist(a0)
		bset	#render_useheight_bit,ost_render(a0)

Glass_Block012:	; Routine 2
		bsr.w	Glass_Types			; update position
		move.w	#$2B,d1
		move.w	#$48,d2
		move.w	#$49,d3
		move.w	ost_x_pos(a0),d4
		bra.w	SolidObject
; ===========================================================================

Glass_Reflect012:
		; Routine 4
		movea.l	ost_glass_parent(a0),a1
		move.w	ost_glass_y_dist(a1),ost_glass_y_dist(a0)
		bra.w	Glass_Types			; update position
; ===========================================================================

Glass_Block34:	; Routine 6
		bsr.w	Glass_Types			; update position
		move.w	#$2B,d1
		move.w	#$38,d2
		move.w	#$39,d3
		move.w	ost_x_pos(a0),d4
		bra.w	SolidObject
; ===========================================================================

Glass_Reflect34:
		; Routine 8
		movea.l	ost_glass_parent(a0),a1
		move.w	ost_glass_y_dist(a1),ost_glass_y_dist(a0)
		move.w	ost_y_pos(a1),ost_glass_y_start(a0)
		bra.w	Glass_Types			; update position

; ---------------------------------------------------------------------------
; Subroutine to update block position
; ---------------------------------------------------------------------------

Glass_Types:
		moveq	#0,d0
		move.b	ost_subtype(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	Glass_TypeIndex(pc,d0.w),d1
		jmp	Glass_TypeIndex(pc,d1.w)
; End of function Glass_Types

; ===========================================================================
Glass_TypeIndex:index *
		ptr Glass_UpDown			; 1 - moves up and down
		ptr Glass_UpDown_Rev			; 2 - moves up and down, reversed
		ptr Glass_Drop_Button			; 4 - drops when button is pressed
; ===========================================================================

; Type 1 - moves up and down
Glass_UpDown:
		move.b	(v_oscillating_table+$10).w,d0
		move.w	#$40,d1
		bra.s	Glass_UpDown_Reflect
; ===========================================================================

; Type 2 - moves up and down, reversed
Glass_UpDown_Rev:
		move.b	(v_oscillating_table+$10).w,d0
		move.w	#$40,d1
		neg.w	d0				; reverse direction of movement
		add.w	d1,d0

Glass_UpDown_Reflect:
		btst	#3,ost_subtype(a0)		; is object a reflection?
		beq.s	@not_reflection			; if not, branch
		neg.w	d0				; reverse for reflection
		add.w	d1,d0
		lsr.b	#1,d0				; divide by 2
		addi.w	#$20,d0				; move down 32px

	@not_reflection:
		bra.w	Glass_Move
; ===========================================================================

; Type 4 - drops when button is pressed
Glass_Drop_Button:
		btst	#3,ost_subtype(a0)		; is object a reflection?
		beq.s	Glass_ChkBtn			; if not, branch
		move.b	(v_oscillating_table+$10).w,d0
		subi.w	#$10,d0
		bra.s	Glass_Move
; ===========================================================================

Glass_ChkBtn:
		tst.b	ost_glass_move_mode(a0)		; is block already moving?
		bne.s	@skip_button			; if yes, branch
		lea	(v_button_state).w,a2
		moveq	#0,d0
		move.b	ost_subtype(a0),d0		; load object type number
		lsr.w	#4,d0				; read only the	high nybble
		tst.b	(a2,d0.w)			; has button number d0 been pressed?
		beq.s	@no_dist			; if not, branch
		move.b	#1,ost_glass_move_mode(a0)	; set moving flag

	@skip_button:
		tst.w	ost_glass_y_dist(a0)		; does block still have distance to move?
		beq.s	@no_dist			; if not, branch
		subq.w	#2,ost_glass_y_dist(a0)		; decrement distance

	@no_dist:
		move.w	ost_glass_y_dist(a0),d0

Glass_Move:
		move.w	ost_glass_y_start(a0),d1	; get initial y position
		sub.w	d0,d1				; apply difference
		move.w	d1,ost_y_pos(a0)		; update y position
		rts	
