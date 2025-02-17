; ---------------------------------------------------------------------------
; Object 69 - spinning platforms and trapdoors (SBZ)

; spawned by:
;	ObjPos_SBZ1, ObjPos_SBZ2 - subtypes 1/2, $80-$83, $90-$9E
; ---------------------------------------------------------------------------

SpinPlatform:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Spin_Index(pc,d0.w),d1
		jmp	Spin_Index(pc,d1.w)
; ===========================================================================
Spin_Index:	index *,,2
		ptr Spin_Main
		ptr Spin_Trapdoor
		ptr Spin_Spinner

ost_spin_wait_time:	equ $30				; time until change (2 bytes)
ost_spin_wait_master:	equ $32				; time between changes (2 bytes)
ost_spin_flag:		equ $34				; 1 = switch between animations, spinning platforms only
ost_spin_sync:		equ $36				; bitmask used to synchronise timing: subtype $8x = $3F; subtype $9x = $7F (2 bytes)

Spin_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Trap
		dc.b so_write_word,ost_tile
		dc.w $3E1+tile_pal3
		dc.b ost_actwidth,128
		dc.b so_render_rel
		dc.b so_end
		even
SpinS_Settings:	dc.b ost_routine,4
		dc.b so_write_long,ost_mappings
		dc.l Map_Spin
		dc.b so_write_word,ost_tile
		dc.w $42E
		dc.b ost_actwidth,16
		dc.b ost_anim,id_ani_spin_1
		dc.b so_end
		even
; ===========================================================================

Spin_Main:	; Routine 0
		lea	Spin_Settings(pc),a2
		bsr.w	SetupObject
		moveq	#0,d0
		move.b	ost_subtype(a0),d0		; get subtype
		andi.w	#$F,d0				; read only low nybble
		mulu.w	#60,d0				; multiply by 60 (1 second)
		move.w	d0,ost_spin_wait_master(a0)
		tst.b	ost_subtype(a0)			; is subtype $8x?
		bpl.s	Spin_Trapdoor			; if not, branch

		lea	SpinS_Settings(pc),a2
		bsr.w	SetupObject
		moveq	#0,d0
		move.b	ost_subtype(a0),d0		; get object type
		move.w	d0,d1
		andi.w	#$F,d0				; read only low nybble
		mulu.w	#6,d0				; multiply by 6
		move.w	d0,ost_spin_wait_time(a0)
		move.w	d0,ost_spin_wait_master(a0)	; set time delay
		andi.w	#$70,d1				; read high nybble (e.g. $80/$90), ignore high bit ($00/$10)
		addi.w	#$10,d1				; add $10 ($10/$20)
		lsl.w	#2,d1				; multiply by 4 ($40/$80)
		subq.w	#1,d1				; subtract 1 ($3F/$7F)
		move.w	d1,ost_spin_sync(a0)
		bra.s	Spin_Spinner
; ===========================================================================

Spin_Trapdoor:	; Routine 2
		subq.w	#1,ost_spin_wait_time(a0)	; decrement timer
		bpl.s	@animate			; if time remains, branch

		move.w	ost_spin_wait_master(a0),ost_spin_wait_time(a0)
		bchg	#0,ost_anim(a0)			; switch between opening/closing animations
		tst.b	ost_render(a0)
		bpl.s	@animate
		play.w	1, jsr, sfx_Door		; play door sound

	@animate:
		lea	(Ani_Spin).l,a1
		jsr	(AnimateSprite).l
		tst.b	ost_frame(a0)			; is frame number 0 displayed?
		bne.s	@notsolid			; if not, branch
		move.w	#$4B,d1
		move.w	#$C,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	ost_x_pos(a0),d4
		bsr.w	SolidObject
		bra.s	Spin_Trapdoor_despawn
; ===========================================================================

@notsolid:
		btst	#status_platform_bit,ost_status(a0) ; is Sonic standing on the trapdoor?
		beq.s	Spin_Trapdoor_despawn		; if not, branch
		lea	(v_ost_player).w,a1
		bclr	#status_platform_bit,ost_status(a1)
		bclr	#status_platform_bit,ost_status(a0)
		clr.b	ost_solid(a0)

Spin_Trapdoor_despawn:
		bra.w	DespawnObject
; ===========================================================================

Spin_Spinner:	; Routine 4
		move.w	(v_frame_counter).w,d0		; read frame counter
		and.w	ost_spin_sync(a0),d0		; apply bitmask ($3F or $7F)
		bne.s	@delay				; branch if not 0
		move.b	#1,ost_spin_flag(a0)		; set flag (occurs every 64 or 128 frames)

	@delay:
		tst.b	ost_spin_flag(a0)		; is flag set?
		beq.s	@animate			; if not, branch
		subq.w	#1,ost_spin_wait_time(a0)	; decrement timer
		bpl.s	@animate			; branch if time remains
		move.w	ost_spin_wait_master(a0),ost_spin_wait_time(a0) ; reset timer
		clr.b	ost_spin_flag(a0)
		move.b	#1,ost_anim_restart(a0)		; restart animation (switches between identical animations)

	@animate:
		lea	(Ani_Spin).l,a1
		jsr	(AnimateSprite).l
		tst.b	ost_frame(a0)			; check	if frame number	0 is displayed
		bne.s	@notsolid2			; if not, branch
		move.w	#$1B,d1
		move.w	#7,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	ost_x_pos(a0),d4
		bsr.w	SolidObject
		bra.s	Spin_Trapdoor_despawn
; ===========================================================================

@notsolid2:
		btst	#status_platform_bit,ost_status(a0) ; is Sonic on the platform?
		beq.s	Spin_Trapdoor_despawn		; if not, branch
		lea	(v_ost_player).w,a1
		bclr	#status_platform_bit,ost_status(a1)
		bclr	#status_platform_bit,ost_status(a0)
		clr.b	ost_solid(a0)

	@display:
		bra.s	Spin_Trapdoor_despawn

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Spin:	index *
		ptr ani_spin_trapopen
		ptr ani_spin_trapclose
		ptr ani_spin_1
		
ani_spin_trapopen:
		dc.b 3
		dc.b id_frame_trap_closed
		dc.b id_frame_trap_half
		dc.b id_frame_trap_open
		dc.b afBack, 1

ani_spin_trapclose:
		dc.b 3
		dc.b id_frame_trap_open
		dc.b id_frame_trap_half
		dc.b id_frame_trap_closed
		dc.b afBack, 1

ani_spin_1:
		dc.b 1
		dc.b id_frame_spin_flat
		dc.b id_frame_spin_1
		dc.b id_frame_spin_2
		dc.b id_frame_spin_3
		dc.b id_frame_spin_4
		dc.b id_frame_spin_3+afyflip
		dc.b id_frame_spin_2+afyflip
		dc.b id_frame_spin_1+afyflip
		dc.b id_frame_spin_flat+afyflip
		dc.b id_frame_spin_1+afxflip+afyflip
		dc.b id_frame_spin_2+afxflip+afyflip
		dc.b id_frame_spin_3+afxflip+afyflip
		dc.b id_frame_spin_4+afxflip+afyflip
		dc.b id_frame_spin_3+afxflip
		dc.b id_frame_spin_2+afxflip
		dc.b id_frame_spin_1+afxflip
		dc.b id_frame_spin_flat
		dc.b afBack, 1
		even
