; ---------------------------------------------------------------------------
; Object 11 - GHZ bridge (max length $10)

; spawned by:
;	ObjPos_GHZ1, ObjPos_GHZ2, ObjPos_GHZ3 - subtype $C (12 logs)
; ---------------------------------------------------------------------------

Bridge:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Bri_Index(pc,d0.w),d1
		jmp	Bri_Index(pc,d1.w)
; ===========================================================================
Bri_Index:	index *,,2
		ptr Bri_Main
		ptr Bri_Action
		ptr Bri_Platform
		ptr Bri_Delete
		ptr Bri_Delete
		ptr Bri_Display

ost_bridge_child_list:	equ $29				; OST indices of child objects (up to 15 bytes)
ost_bridge_y_start:	equ $3C				; original y position (2 bytes)
ost_bridge_bend:	equ $3E				; number of pixels a log has been deflected
ost_bridge_current_log:	equ $3F				; log Sonic is currently standing on (left to right, starts at 0)

Bri_Settings:	dc.b ost_routine,2
		dc.b so_write_long,ost_mappings
		dc.l Map_Bri
		dc.b so_write_word,ost_tile
		dc.w $33E+tile_pal3
		dc.b ost_render,render_rel
		dc.b ost_priority,3
		dc.b ost_actwidth,128
		dc.b so_copy_word,ost_y_pos,ost_bridge_y_start
		dc.b so_end
		even
; ===========================================================================

Bri_Main:	; Routine 0
		lea	Bri_Settings(pc),a2
		bsr.w	SetupObject
		move.w	ost_x_pos(a0),d3
		lea	ost_subtype+1(a0),a3		; a3 = address of subtype id, followed by child list
		moveq	#10,d4
		sub.w	#6*16,d3			; d3 = x position of leftmost log

@buildloop:
		bsr.w	FindFreeObj			; find free OST slot
		bne.s	Bri_Action			; branch if not found
		cmp.w	ost_x_pos(a0),d3		; is this the middle log? (parent log is middle)
		bne.s	@notmiddle			; if not, branch
		; treat parent log as though it's the middle child log
		addi.w	#$10,d3
		move.w	a0,d5
		subi.w	#v_ost_all&$FFFF,d5		; get RAM address of parent OST
		lsr.w	#6,d5				; divide by $40
		andi.w	#$7F,d5
		move.b	d5,(a3)+			; add parent OST index to child list

	@notmiddle:
		move.w	a1,d5
		subi.w	#v_ost_all&$FFFF,d5		; get RAM address of child OST
		lsr.w	#6,d5				; divide by $40
		andi.w	#$7F,d5
		move.b	d5,(a3)+			; save child OST indices as series of bytes
		
		lea	Bri_Settings2(pc),a2
		bsr.w	SetupChild
		move.w	d3,ost_x_pos(a1)
		addi.w	#$10,d3				; x pos. of next log
		dbf	d4,@buildloop			; repeat d4 times (length of bridge)

Bri_Action:	; Routine 2
		bsr.s	Bri_Detect			; detect collision, goto Bri_Platform next when stood on
		tst.b	ost_bridge_bend(a0)
		beq.s	@display
		subq.b	#4,ost_bridge_bend(a0)		; move log back up
		bsr.w	Bri_UpdateY

	@display:
		bsr.w	DisplaySprite
		bra.w	Bri_ChkDel

Bri_Settings2:	dc.b ost_routine,id_Bri_Display
		dc.b so_inherit_byte,ost_id
		dc.b so_inherit_long,ost_mappings
		dc.b so_inherit_word,ost_tile
		dc.b so_inherit_word,ost_y_pos
		dc.b so_inherit_word,ost_bridge_y_start
		dc.b ost_render,render_rel
		dc.b ost_priority,3
		dc.b ost_actwidth,8
		dc.b so_end
		even
; ---------------------------------------------------------------------------
; Subroutine to detect collision between bridge and Sonic
; ---------------------------------------------------------------------------

Bri_Detect:
		move.w	#(12*8)+8,d1
		move.w	#(12*8)*2,d2
		lea	(v_ost_player).w,a1
		tst.w	ost_y_vel(a1)			; is Sonic moving up/jumping?
		bmi.w	Plat_Exit			; if yes, branch

		move.w	ost_x_pos(a1),d0
		sub.w	ost_x_pos(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit			; branch if Sonic is left of the bridge
		cmp.w	d2,d0
		bcc.w	Plat_Exit			; branch if Sonic is right of the bridge
		bra.s	Plat_NoXCheck			; y-axis check, update flags and routine counter
; End of function Bri_Detect

; ---------------------------------------------------------------------------
; Object 11 - GHZ bridge, part 2
; ---------------------------------------------------------------------------

include_Bridge_2:	macro

Bri_Platform:	; Routine 4
		bsr.s	Bri_ChkPosition
		bsr.w	DisplaySprite
		bra.w	Bri_ChkDel

; ---------------------------------------------------------------------------
; Subroutine checking if Sonic is still on bridge and on which log
; ---------------------------------------------------------------------------

Bri_ChkPosition:
		move.w	#(12*8)+8,d1
		move.w	#12*8,d2
		bsr.s	ExitPlatform2			; update flags, goto Bri_Action next if leaving the bridge
		bcc.s	@exit
		lsr.w	#4,d0				; d0 = relative position of log Sonic is standing on, divided by 16
		move.b	d0,ost_bridge_current_log(a0)
		move.b	ost_bridge_bend(a0),d0		; get current bend
		cmpi.b	#$40,d0
		beq.s	@max_bend			; branch if $40
		addq.b	#4,ost_bridge_bend(a0)		; increase bend

	@max_bend:
		bsr.w	Bri_UpdateY			; update y position of all logs
		bsr.w	Bri_MoveSonic			; update Sonic's position

	@exit:
		rts	
; End of function Bri_ChkPosition

		endm

; ---------------------------------------------------------------------------
; Object 11 - GHZ bridge, part 3
; ---------------------------------------------------------------------------

include_Bridge_3:	macro

; ---------------------------------------------------------------------------
; Subroutine updating Sonic's y position
; ---------------------------------------------------------------------------

Bri_MoveSonic:
		moveq	#0,d0
		move.b	ost_bridge_current_log(a0),d0	; get current log number
		move.b	ost_bridge_child_list(a0,d0.w),d0 ; get OST index for that log
		lsl.w	#6,d0
		addi.l	#v_ost_all&$FFFFFF,d0		; convert to RAM address
		movea.l	d0,a2
		lea	(v_ost_player).w,a1
		move.w	ost_y_pos(a2),d0
		subq.w	#8,d0
		moveq	#0,d1
		move.b	ost_height(a1),d1
		sub.w	d1,d0
		move.w	d0,ost_y_pos(a1)		; change Sonic's position on y-axis
		rts	
; End of function Bri_MoveSonic

; ---------------------------------------------------------------------------
; Subroutine to update y position of child logs when the bridge bends
; ---------------------------------------------------------------------------

Bri_UpdateY:
		move.b	ost_bridge_bend(a0),d0		; get bridge bend value
		bsr.w	CalcSine			; convert to sine
		move.w	d0,d4				; save to d4
		lea	(Bri_Data_Align).l,a4
		moveq	#0,d3
		move.b	ost_bridge_current_log(a0),d3	; log Sonic is standing on (left to right, starts at 0)
		move.w	d3,d2				; copy to d2
		moveq	#0,d5
		lea	(Bri_Data_Y_Max).l,a5		; log y bend distance array
		move.b	(a5,d3.w),d5			; get byte according to bridge length & log being stood on
		andi.w	#$F,d3				; d3 = log Sonic is standing on
		lsl.w	#4,d3				; multiply by $10
		lea	(a4,d3.w),a3
		lea	ost_bridge_child_list(a0),a2

	@loop_left:
		moveq	#0,d0
		move.b	(a2)+,d0			; get OST id of child log
		lsl.w	#6,d0
		addi.l	#v_ost_all&$FFFFFF,d0		; convert to RAM address
		movea.l	d0,a1				; a1 = address of child OST
		moveq	#0,d0
		move.b	(a3)+,d0			; get byte from log alignment array
		addq.w	#1,d0
		mulu.w	d5,d0				; multiply by max y value
		mulu.w	d4,d0				; multiply by sine of current bend value
		swap	d0				; swap high/low words
		add.w	ost_bridge_y_start(a1),d0	; add initial y position
		move.w	d0,ost_y_pos(a1)		; update y position
		dbf	d2,@loop_left			; repeat for all logs left of the one being stood on

		moveq	#0,d3
		move.b	ost_bridge_current_log(a0),d3	; log Sonic is standing on (left to right, starts at 0)
		sub.b	#11,d3
		neg.b	d3				; d3 = logs to the right
		bmi.s	@exit				; branch if invalid
		move.w	d3,d2
		lsl.w	#4,d3				; multiply by $10
		lea	(a4,d3.w),a3
		adda.w	d2,a3
		subq.w	#1,d2
		bcs.s	@exit

	@loop_right:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_ost_all&$FFFFFF,d0
		movea.l	d0,a1
		moveq	#0,d0
		move.b	-(a3),d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	ost_bridge_y_start(a1),d0
		move.w	d0,ost_y_pos(a1)
		dbf	d2,@loop_right

	@exit:
		rts	
; End of function Bri_UpdateY

; ---------------------------------------------------------------------------
; GHZ bridge-bending data
; ---------------------------------------------------------------------------

; Distance each log is moved down when stood on (only $C is used)
Bri_Data_Y_Max:
		dc.b  2,   4,   6,   8,  $A,  $C,  $C,  $A,   8,   6,   4,   2,   0,   0,   0,   0 ; $C logs
		even

; Values used to align logs to the left & right of the one being stood on
Bri_Data_Align:
		dc.b $FF,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
		dc.b $B5, $FF,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 ; standing on log 1
		dc.b $7E, $DB, $FF,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 ; standing on log 2
		dc.b $61, $B5, $EC, $FF,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 ; standing on log 3
		dc.b $4A, $93, $CD, $F3, $FF,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 ; standing on log 4
		dc.b $3E, $7E, $B0, $DB, $F6, $FF,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 ; standing on log 5
		dc.b $38, $6D, $9D, $C5, $E4, $F8, $FF,   0,   0,   0,   0,   0,   0,   0,   0,   0 ; standing on log 6
		dc.b $31, $61, $8E, $B5, $D4, $EC, $FB, $FF,   0,   0,   0,   0,   0,   0,   0,   0 ; standing on log 7
		dc.b $2B, $56, $7E, $A2, $C1, $DB, $EE, $FB, $FF,   0,   0,   0,   0,   0,   0,   0 ; standing on log 8
		dc.b $25, $4A, $73, $93, $B0, $CD, $E1, $F3, $FC, $FF,   0,   0,   0,   0,   0,   0 ; standing on log 9
		dc.b $1F, $44, $67, $88, $A7, $BD, $D4, $E7, $F4, $FD, $FF,   0,   0,   0,   0,   0 ; standing on log $A
		dc.b $1F, $3E, $5C, $7E, $98, $B0, $C9, $DB, $EA, $F6, $FD, $FF,   0,   0,   0,   0 ; standing on log $B
		dc.b $19, $38, $56, $73, $8E, $A7, $BD, $D1, $E1, $EE, $F8, $FE, $FF,   0,   0,   0 ; standing on log $C
		even

; ===========================================================================

Bri_ChkDel:
		out_of_range	@deletebridge
		rts

@deletebridge:
		moveq	#0,d2
		lea	ost_subtype(a0),a2		; get bridge length
		move.b	(a2)+,d2			; move bridge length to	d2
		subq.b	#1,d2				; subtract 1
		bcs.s	@delparent			; branch if there are no child objects

	@loop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_ost_all&$FFFFFF,d0
		movea.l	d0,a1
		cmp.w	a0,d0
		beq.s	@skipdel
		bsr.w	DeleteChild

	@skipdel:
		dbf	d2,@loop			; repeat d2 times (bridge length)

@delparent:
Bri_Delete:
		bra.w	DeleteObject
; ===========================================================================

Bri_Display:	; Routine $A
		bra.w	DisplaySprite
		
		endm
		
