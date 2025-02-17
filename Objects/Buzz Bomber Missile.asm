; ---------------------------------------------------------------------------
; Object 23 - missile that Buzz	Bomber and Newtron throws

; spawned by:
;	BuzzBomber - subtype 0
;	Newtron - subtype 1
; ---------------------------------------------------------------------------

Missile:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Msl_Index(pc,d0.w),d1
		jmp	Msl_Index(pc,d1.w)
; ===========================================================================
Msl_Index:	index *,,2
		ptr Msl_Main
		ptr Msl_Animate
		ptr Msl_FromBuzz
		ptr Msl_Delete
		ptr Msl_FromNewt

ost_missile_wait_time:	equ $32				; time delay (2 bytes)
ost_missile_parent:	equ $3C				; address of OST of parent object (4 bytes)

Msl_Settings:	dc.b ost_routine,2
		dc.b ost_render,render_rel
		dc.b ost_priority,3
		dc.b ost_actwidth,8
		dc.b so_write_long,ost_mappings
		dc.l Map_Missile
		dc.b so_end
		even
; ===========================================================================

Msl_Main:	; Routine 0
		subq.w	#1,ost_missile_wait_time(a0)	; decrement timer
		bpl.s	Msl_ChkCancel			; branch if time remains
		lea	Msl_Settings(pc),a2
		bsr.w	SetupObject
		bset	#tile_pal12_bit,ost_tile(a0)
		andi.b	#status_xflip+status_yflip,ost_status(a0)
		tst.b	ost_subtype(a0)			; was object created by	a Newtron?
		beq.s	Msl_Animate			; if not, branch

		move.b	#id_Msl_FromNewt,ost_routine(a0) ; goto Msl_FromNewt next
		move.b	#id_col_6x6+id_col_hurt,ost_col_type(a0)
		move.b	#id_ani_buzz_missile,ost_anim(a0)
		bra.s	Msl_Animate2
; ===========================================================================

Msl_Animate:	; Routine 2
		bsr.s	Msl_ChkCancel
		bra.s	Msl_Animate2

; ---------------------------------------------------------------------------
; Subroutine to	check if the Buzz Bomber which fired the missile has been
; destroyed, and if it has, then cancel	the missile
; ---------------------------------------------------------------------------

Msl_ChkCancel:
		movea.l	ost_missile_parent(a0),a1
		cmpi.b	#id_ExplosionItem,ost_id(a1)	; has Buzz Bomber been destroyed?
		beq.s	Msl_Delete			; if yes, branch
		rts

; ===========================================================================

Msl_FromBuzz:	; Routine 4
		move.b	#id_col_6x6+id_col_hurt,ost_col_type(a0)
		move.b	#id_ani_buzz_missile,ost_anim(a0)
		bsr.w	SpeedToPos
		bsr.s	Msl_Animate2
		move.w	(v_boundary_bottom).w,d0
		addi.w	#224,d0
		cmp.w	ost_y_pos(a0),d0		; has object moved below the level boundary?
		bcs.s	Msl_Delete			; if yes, branch
		rts	
; ===========================================================================

Msl_Delete:	; Routine 6
		bra.w	DeleteObject
; ===========================================================================

Msl_FromNewt:	; Routine 8
		tst.b	ost_render(a0)			; is object on-screen?
		bpl.s	Msl_Delete			; if not, branch
		bsr.w	SpeedToPos			; update position

Msl_Animate2:
		lea	(Ani_Missile).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

include_Missile_animation:	macro

Ani_Missile:	index *
		ptr ani_buzz_flare
		ptr ani_buzz_missile
		
ani_buzz_flare:
		dc.b 7
		dc.b id_frame_buzz_flare1
		dc.b id_frame_buzz_flare2
		dc.b afRoutine
		even

ani_buzz_missile:
		dc.b 1
		dc.b id_frame_buzz_ball1
		dc.b id_frame_buzz_ball2
		dc.b afEnd
		even

		endm
