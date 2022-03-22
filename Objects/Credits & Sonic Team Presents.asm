; ---------------------------------------------------------------------------
; Object 8A - "SONIC TEAM PRESENTS" and	credits

; spawned by:
;	GM_Title, GM_Credits, EndEggman
; ---------------------------------------------------------------------------

CreditsText:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Cred_Index(pc,d0.w),d1
		jmp	Cred_Index(pc,d1.w)
; ===========================================================================
Cred_Index:	index *,,2
		ptr Cred_Main
		ptr Cred_Display
; ===========================================================================

Cred_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Cred_Display next
		move.w	#$120,ost_x_pos(a0)
		move.w	#$F0,ost_y_screen(a0)
		move.l	#Map_Cred,ost_mappings(a0)
		move.w	#tile_Nem_CreditText,ost_tile(a0)
		move.w	(v_credits_num).w,d0			; load credits index number
		move.b	d0,ost_frame(a0)			; display appropriate sprite
		move.b	#render_abs,ost_render(a0)
		move.b	#0,ost_priority(a0)

		cmpi.b	#id_Title,(v_gamemode).w		; is the mode #4 (title screen)?
		bne.s	Cred_Display				; if not, branch

		move.w	#vram_title_credits/sizeof_cell,ost_tile(a0)
		move.b	#id_frame_cred_sonicteam,ost_frame(a0)	; display "SONIC TEAM PRESENTS"

Cred_Display:	; Routine 2
		cmpi.b	#id_TitleSonic,(v_ost_titlesonic).w
		bne.s	@display
		jmp	DeleteObject
	@display:
		jmp	DisplaySprite
