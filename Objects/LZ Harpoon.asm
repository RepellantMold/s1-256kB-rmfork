; ---------------------------------------------------------------------------
; Object 16 - harpoon (LZ)

; spawned by:
;	ObjPos_LZ1, ObjPos_LZ2, ObjPos_LZ3, ObjPos_SBZ3 - subtypes 0/2
; ---------------------------------------------------------------------------

Harpoon:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Harp_Index(pc,d0.w),d1
		jmp	Harp_Index(pc,d1.w)
; ===========================================================================
Harp_Index:	index *,,2
		ptr Harp_Main
		ptr Harp_Move
		ptr Harp_Wait

ost_harp_time:	equ $30					; time between stabbing/retracting (2 bytes)

Harp_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Harp
		dc.b so_write_word,ost_tile
		dc.w $3AB
		dc.b ost_priority,4
		dc.b ost_actwidth,20
		dc.b ost_harp_time+1,60
		dc.b so_copy_byte,ost_subtype,ost_anim
		dc.b so_render_rel
		dc.b so_end
		even
; ===========================================================================

Harp_Main:	; Routine 0
		lea	Harp_Settings(pc),a2
		bsr.w	SetupObject

Harp_Move:	; Routine 2
		lea	(Ani_Harp).l,a1
		bsr.w	AnimateSprite			; animate and goto Harp_Wait next
		moveq	#0,d0
		move.b	ost_frame(a0),d0		; get frame number
		move.b	Harp_types(pc,d0.w),ost_col_type(a0) ; get collision type
		bra.s	Harp_Despawn

	Harp_types:
		dc.b id_col_8x4+id_col_hurt		; horizontal, short
		dc.b id_col_24x4+id_col_hurt		; horizontal, middle
		dc.b id_col_40x4+id_col_hurt		; horizontal, extended
		dc.b id_col_4x8+id_col_hurt		; vertical, short
		dc.b id_col_4x24+id_col_hurt		; vertical, middle
		dc.b id_col_4x40+id_col_hurt		; vertical, extended
		even

Harp_Wait:	; Routine 4
		subq.w	#1,ost_harp_time(a0)		; decrement timer
		bpl.s	@chkdel				; branch if time remains
		move.w	#60,ost_harp_time(a0)		; reset timer
		subq.b	#2,ost_routine(a0)		; goto Harp_Move next
		bchg	#0,ost_anim(a0)			; reverse animation

	@chkdel:
Harp_Despawn:
		bra.w	DespawnObject

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Harp:	index *
		ptr ani_harp_h_extending
		ptr ani_harp_h_retracting
		ptr ani_harp_v_extending
		ptr ani_harp_v_retracting
		
ani_harp_h_extending:
		dc.b 3
		dc.b id_frame_harp_h_middle
		dc.b id_frame_harp_h_extended
		dc.b afRoutine

ani_harp_h_retracting:
		dc.b 3
		dc.b id_frame_harp_h_middle
		dc.b id_frame_harp_h_retracted
		dc.b afRoutine

ani_harp_v_extending:
		dc.b 3
		dc.b id_frame_harp_v_middle
		dc.b id_frame_harp_v_extended
		dc.b afRoutine

ani_harp_v_retracting:
		dc.b 3
		dc.b id_frame_harp_v_middle
		dc.b id_frame_harp_v_retracted
		dc.b afRoutine
		even
