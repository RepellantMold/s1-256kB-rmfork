; ---------------------------------------------------------------------------
; Add points subroutine
;
; input:
;	d0 = points to add (appears as *10 larger on the HUD)

; output:
;	d0 = score
;	(a2) = high score (REV00 only)
;	(a3) = score
;	uses d1
; ---------------------------------------------------------------------------

AddPoints:
		move.b	#1,(f_hud_score_update).w		; set score counter to update

		lea     (v_score).w,a3
		add.l   d0,(a3)
		move.l  #999999,d1
		cmp.l   (a3),d1					; is score below 999999?
		bhi.s   @belowmax				; if yes, branch
		move.l  d1,(a3)					; reset score to 999999

	@belowmax:
		move.l  (a3),d0
		cmp.l   (v_score_next_life).w,d0		; has Sonic got 50000+ points?
		blo.s   @noextralife				; if not, branch

		addi.l  #5000,(v_score_next_life).w		; increase requirement by 50000
		tst.b   (v_console_region).w
		bmi.s   @noextralife				; branch if Mega Drive is Japanese
		addq.b  #1,(v_lives).w				; give extra life
		addq.b  #1,(f_hud_lives_update).w
		play.w	0, jmp, mus_ExtraLife			; play extra life music

@nohighscore:
@noextralife:
		rts
