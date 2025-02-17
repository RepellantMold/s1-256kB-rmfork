; ---------------------------------------------------------------------------
; Object 59 - platforms	that move when you stand on them (SLZ)

; spawned by:
;	ObjPos_SLZ1, ObjPos_SLZ2, ObjPos_SLZ3 - subtypes 0/1/3/$C/$8A
;	Elevator - subtype $E
; ---------------------------------------------------------------------------

Elevator:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Elev_Index(pc,d0.w),d1
		jsr	Elev_Index(pc,d1.w)
		out_of_range	DeleteObject,ost_elev_x_start(a0)
		bra.w	DisplaySprite
; ===========================================================================
Elev_Index:	index *,,2
		ptr Elev_Main
		ptr Elev_Platform
		ptr Elev_StoodOn
		ptr Elev_MakeMulti

Elev_Var2:	; distance to move (div 8), action type
Elev_Var2_0:	dc.b $10, id_Elev_Up
Elev_Var2_1:	dc.b $20, id_Elev_Up
Elev_Var2_3:	dc.b $10, id_Elev_Down
Elev_Var2_C:	dc.b $20, id_Elev_UpRight
Elev_Var2_E:	dc.b $30, id_Elev_UpVanish

sizeof_Elev_Var2:	equ Elev_Var2_1-Elev_Var2

ost_elev_y_start:	equ $30				; original y-axis position (2 bytes)
ost_elev_x_start:	equ $32				; original x-axis position (2 bytes)
ost_elev_moved:		equ $34				; distance moved (2 bytes)
ost_elev_acceleration:	equ $38				; acceleration - i.e. its movement is not linear (2 bytes)
ost_elev_dec_flag:	equ $3A				; 1 = decelerate
ost_elev_distance:	equ $3C				; half distance to move (2 bytes)
ost_elev_dist_master:	equ $3E				; master copy of ost_elev_distance (2 bytes)

Elev_Settings:	dc.b ost_routine,2
		dc.b ost_actwidth,$28
		dc.b so_write_long,ost_mappings
		dc.l Map_Elev
		dc.b so_write_word,ost_tile
		dc.w 0+tile_pal3
		dc.b ost_render,render_rel
		dc.b ost_priority,4
		dc.b so_copy_word,ost_x_pos,ost_elev_x_start
		dc.b so_copy_word,ost_y_pos,ost_elev_y_start
		dc.b so_end
		even
; ===========================================================================

Elev_Main:	; Routine 0
		moveq	#0,d0
		move.b	ost_subtype(a0),d0		; get subtype
		bpl.s	@normal				; branch for types 0-$7F

		addq.b	#6,ost_routine(a0)		; goto Elev_MakeMulti next
		move.w	#60,ost_elev_distance(a0)	; set as time between platform spawns
		move.w	#60,ost_elev_dist_master(a0)
		addq.l	#4,sp
		rts	
; ===========================================================================

	@normal:
		lea	Elev_Settings(pc),a2
		bsr.w	SetupObject
		add.w	d0,d0
		andi.w	#$1E,d0				; read only low nybble
		lea	Elev_Var2(pc,d0.w),a2
		move.b	(a2)+,d0			; get distance value
		lsl.w	#2,d0				; multiply by 4
		move.w	d0,ost_elev_distance(a0)	; set distance to move
		move.b	(a2)+,ost_subtype(a0)		; set type

Elev_Platform:	; Routine 2
		moveq	#0,d1
		move.b	ost_actwidth(a0),d1
		jsr	(DetectPlatform).l		; detect collision and goto Elev_StoodOn next if true
		bra.w	Elev_Types
; ===========================================================================

Elev_StoodOn:	; Routine 4
		moveq	#0,d1
		move.b	ost_actwidth(a0),d1
		jsr	(ExitPlatform).l		; goto Elev_Platform next if Sonic leaves platform
		move.w	ost_x_pos(a0),-(sp)
		bsr.w	Elev_Types
		move.w	(sp)+,d2
		tst.b	ost_id(a0)			; does object still exist?
		beq.s	@deleted			; if not, branch
		jmp	(MoveWithPlatform2).l		; update Sonic's position

	@deleted:
		rts	
; ===========================================================================

Elev_Types:
		moveq	#0,d0
		move.b	ost_subtype(a0),d0		; subtype has changed by now, see Elev_Var2
		andi.w	#$F,d0				; read only low nybble
		add.w	d0,d0
		move.w	Elev_Type_Index(pc,d0.w),d1
		jmp	Elev_Type_Index(pc,d1.w)
; ===========================================================================
Elev_Type_Index:
		index *
		ptr Elev_Still				; 0 - doesn't move
		ptr Elev_Up				; 1 - rises when stood on
		ptr Elev_Up_Now	
		ptr Elev_Down				; 3 - falls when stood on
		ptr Elev_Down_Now
		ptr Elev_UpRight			; 5 - rises diagonally when stood on
		ptr Elev_UpRight_Now
		ptr Elev_DownLeft			; 7 - falls diagonally when stood on
		ptr Elev_DownLeft_Now
		ptr Elev_UpVanish			; 9 - rises and vanishes
; ===========================================================================

; Moves when stood on - serves types 1, 3, 5 and 7
Elev_Up:
Elev_Down:
Elev_UpRight:
Elev_DownLeft:
		cmpi.b	#id_Elev_StoodOn,ost_routine(a0) ; check if Sonic is standing on the object
		bne.s	@notstanding
		addq.b	#1,ost_subtype(a0)		; if yes, add 1 to type (goes to 2, 4, 6 or 8)

	@notstanding:
Elev_Still:
		rts	
; ===========================================================================

; Type 2
Elev_Up_Now:
		bsr.s	Elev_Move			; update distance moved
		move.w	ost_elev_moved(a0),d0		; get distance moved
		neg.w	d0				; invert
		bra.s	Elev_updatey
; ===========================================================================

; Type 4
Elev_Down_Now:
		bsr.s	Elev_Move			; update distance moved
		move.w	ost_elev_moved(a0),d0

Elev_updatey:
		add.w	ost_elev_y_start(a0),d0
		move.w	d0,ost_y_pos(a0)		; update y position
		rts	
; ===========================================================================

; Type 6
Elev_UpRight_Now:
		bsr.s	Elev_Move			; update distance moved
		move.w	ost_elev_moved(a0),d0		; get distance moved
		asr.w	#1,d0				; divide by 2
		neg.w	d0				; invert
		bsr.s	Elev_updatey
		move.w	ost_elev_moved(a0),d0		; get distance moved
		bra.s	Elev_updatex
; ===========================================================================

; Type 8
Elev_DownLeft_Now:
		bsr.s	Elev_Move			; update distance moved
		move.w	ost_elev_moved(a0),d0
		asr.w	#1,d0
		bsr.s	Elev_updatey
		move.w	ost_elev_moved(a0),d0
		neg.w	d0

Elev_updatex:
		add.w	ost_elev_x_start(a0),d0
		move.w	d0,ost_x_pos(a0)
		rts	
; ===========================================================================

; Type 9
Elev_UpVanish:
		bsr.s	Elev_Move			; update distance moved
		move.w	ost_elev_moved(a0),d0
		neg.w	d0
		bsr.s	Elev_updatey
		tst.b	ost_subtype(a0)			; has platform reached destination and stopped?
		beq.w	@typereset			; if yes, branch
		rts	
; ===========================================================================

	@typereset:
		btst	#status_platform_bit,ost_status(a0) ; is platform being stood on?
		beq.s	@delete				; if not, branch
		bset	#status_air_bit,ost_status(a1)
		bclr	#status_platform_bit,ost_status(a1)
		move.b	#id_Sonic_Control,ost_routine(a1)

	@delete:
		bra.w	DeleteObject

; ---------------------------------------------------------------------------
; Subroutine to update the distance moved value
; ---------------------------------------------------------------------------

Elev_Move:
		move.w	ost_elev_acceleration(a0),d0	; get current acceleration
		tst.b	ost_elev_dec_flag(a0)		; is platform in deceleration phase?
		bne.s	@decelerate			; if yes, branch
		cmpi.w	#$800,d0			; is acceleration at or above max?
		bcc.s	@update_acc			; if yes, branch
		addi.w	#$10,d0				; increase acceleration
		bra.s	@update_acc
; ===========================================================================

@decelerate:
		tst.w	d0				; is acceleration 0?
		beq.s	@update_acc			; if yes, branch
		subi.w	#$10,d0				; decrease acceleration

@update_acc:
		move.w	d0,ost_elev_acceleration(a0)	; set new acceleration
		ext.l	d0
		asl.l	#8,d0				; multiply by $100
		add.l	ost_elev_moved(a0),d0		; add total previous movement
		move.l	d0,ost_elev_moved(a0)		; update movement
		swap	d0
		move.w	ost_elev_distance(a0),d2	; get target distance
		cmp.w	d2,d0				; has distance been covered?
		bls.s	@dont_dec			; if not, branch
		move.b	#1,ost_elev_dec_flag(a0)	; set deceleration flag

	@dont_dec:
		add.w	d2,d2
		cmp.w	d2,d0				; has complete distance been covered? (including deceleration phase)
		bne.s	@keep_type			; if not, branch
		clr.b	ost_subtype(a0)			; convert to type 0 (non-moving)

	@keep_type:
		rts	
; End of function Elev_Move

; ===========================================================================

Elev_MakeMulti:	; Routine 6
		subq.w	#1,ost_elev_distance(a0)	; decrement timer
		bne.s	@chkdel				; branch if time remains

		move.w	ost_elev_dist_master(a0),ost_elev_distance(a0) ; reset timer
		bsr.w	FindFreeObj			; find free OST slot
		bne.s	@chkdel				; branch if not found
		lea	Elev_Settings2(pc),a2
		bsr.w	SetupObject

	@chkdel:
		addq.l	#4,sp
		out_of_range	DeleteObject
		rts	

Elev_Settings2:	dc.b ost_id,id_Elevator
		dc.b so_inherit_word,ost_x_pos
		dc.b so_inherit_word,ost_y_pos
		dc.b ost_subtype,type_elev_up_vanish_1
		dc.b so_end
		even
		
