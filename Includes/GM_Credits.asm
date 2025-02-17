; ---------------------------------------------------------------------------
; Credits ending sequence
; ---------------------------------------------------------------------------

GM_Credits:
		bsr.w	ClearPLC			; clear PLC buffer
		bsr.w	PaletteFadeOut			; fade out from previous gamemode
		bsr.w	LoadVDPSettings
		move.w	#$8720,(a6)			; set background colour (line 3; colour 0)
		clr.b	(f_water_pal_full).w
		bsr.w	ClearScreen

		move.l	#(v_ost_all&$FFFF)+((((sizeof_ost*countof_ost)/4)-1)<<16),d0
		bsr.w	ClearRAM

		locVRAM	vram_credits
		lea	(Nem_CreditText).l,a0		; load credits alphabet graphics
		bsr.w	NemDec

		move.l	#(v_pal_dry_next&$FFFF)+((((sizeof_pal_all)/4)-1)<<16),d0
		bsr.w	ClearRAM

		moveq	#id_Pal_Sonic,d0
		bsr.w	PalLoad_Next			; load Sonic's palette
		move.b	#id_CreditsText,(v_ost_credits).w ; load credits object
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		bsr.w	EndDemoSetup			; setup for next mini-demo
		bsr.w	LoadAnimArt
		bsr.w	LoadLevelPLC
		move.w	#120,(v_countdown).w		; display a credit for 2 seconds
		bsr.w	PaletteFadeIn			; fade credits text in from black

; ---------------------------------------------------------------------------
; Credits loop - runs while a credit is being shown
; ---------------------------------------------------------------------------

Cred_WaitLoop:
		move.b	#id_VBlank_Title,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		bsr.w	RunPLC
		tst.w	(v_countdown).w			; have 2 seconds elapsed?
		bne.s	Cred_WaitLoop			; if not, branch
		tst.l	(v_plc_buffer).w		; have level gfx finished decompressing?
		bne.s	Cred_WaitLoop			; if not, branch
		cmpi.w	#(sizeof_EndDemoList/2)+1,(v_credits_num).w ; have the credits finished?
		beq.w	TryAgainEnd			; if yes, branch
		rts					; goto demo next

; ---------------------------------------------------------------------------
; Subroutine to setup an ending sequence demo

;	uses d0, a1, a2
; ---------------------------------------------------------------------------

EndDemoSetup:
		move.w	(v_credits_num).w,d0
		andi.w	#$F,d0				; get credits id
		add.w	d0,d0
		move.w	EndDemoList(pc,d0.w),d0		; get zone/act number from list
		move.w	d0,(v_zone).w			; set zone/act number
		addq.w	#1,(v_credits_num).w		; increment credits number
		cmpi.w	#(sizeof_EndDemoList/2)+1,(v_credits_num).w ; have credits finished? (+1 because v_credits_num is already incremented)
		bhs.s	@exit				; if yes, branch
		move.w	#$8001,(v_demo_mode).w		; set demo+ending mode
		move.b	#id_Demo,(v_gamemode).w		; set game mode to 8 (demo)
		move.b	#3,(v_lives).w			; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w			; clear rings
		move.l	d0,(v_time).w			; clear time
		move.l	d0,(v_score).w			; clear score
		move.b	d0,(v_last_lamppost).w		; clear lamppost counter
		cmpi.w	#4,(v_credits_num).w		; is LZ demo running?
		bne.s	@exit				; if not, branch

		lea	(EndDemo_LampVar).l,a1		; load lamppost variables
		lea	(v_last_lamppost).w,a2
		move.w	#((EndDemo_LampVar_end-EndDemo_LampVar)/4)-1,d0

	@lamppost_loop:
		move.l	(a1)+,(a2)+			; copy lamppost variables to RAM
		dbf	d0,@lamppost_loop

@exit:
		rts

; ---------------------------------------------------------------------------
; Ending demo level array

; Lists levels used in ending demos
; ---------------------------------------------------------------------------

EndDemoList:
		dc.b id_GHZ, 0				; Green Hill Zone, act 1
		dc.b id_MZ, 1				; Marble Zone, act 2
		dc.b id_SYZ, 2				; Spring Yard Zone, act 3
		dc.b id_LZ, 2				; Labyrinth Zone, act 3
		dc.b id_SLZ, 2				; Star Light Zone, act 3
		dc.b id_SBZ, 0				; Scrap Brain Zone, act 1
		dc.b id_SBZ, 1				; Scrap Brain Zone, act 2
		dc.b id_GHZ, 0				; Green Hill Zone, act 1
	EndDemoList_end:

sizeof_EndDemoList:	equ EndDemoList_end-EndDemoList

; ---------------------------------------------------------------------------
; Lamppost variables in the end sequence demo (Labyrinth Zone)
; ---------------------------------------------------------------------------

EndDemo_LampVar:
		dc.b 1					; v_last_lamppost - id of last lamppost
		dc.b 1					; v_last_lamppost_lampcopy - id of last lamppost
		dc.w $A00, $62C				; v_sonic_x_pos_lampcopy/v_sonic_y_pos_lampcopy - x/y position
		dc.w 13					; v_rings_lampcopy
		dc.l 0					; v_time_lampcopy
		dc.b 0					; v_dle_routine_lampcopy - dynamic level event routine counter
		dc.b 0					; unused
		dc.w $800				; v_boundary_bottom_lampcopy - level bottom boundary
		dc.w $957, $5CC				; v_camera_x_pos_lampcopy/v_camera_y_pos_lampcopy - camera x/y position
		dc.w $4AB, $3A6				; v_bg1_x_pos_lampcopy/v_bg1_y_pos_lampcopy
		dc.w 0, $28C				; v_bg2_x_pos_lampcopy/v_bg2_y_pos_lampcopy
		dc.w 0, 0				; v_bg3_x_pos_lampcopy/v_bg3_y_pos_lampcopy
		dc.w $308				; v_water_height_normal_lampcopy - water height
		dc.b 1					; v_water_routine_lampcopy - water routine
		dc.b 1					; f_water_pal_full_lampcopy - water covers whole screen flag (1 = yes)
	EndDemo_LampVar_end:

; ---------------------------------------------------------------------------
; "TRY AGAIN" and "END"	screens
; ---------------------------------------------------------------------------

TryAgainEnd:
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut			; fade out from previous gamemode (demo)
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)			; normal colour mode
		move.w	#$8200+(vram_fg>>10),(a6)	; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6)	; set background nametable address
		move.w	#$9001,(a6)			; 64x32 cell plane size
		move.w	#$9200,(a6)			; window vertical position
		move.w	#$8B03,(a6)			; line scroll mode
		move.w	#$8720,(a6)			; set background colour (line 3; colour 0)
		clr.b	(f_water_pal_full).w
		bsr.w	ClearScreen

		move.l	#(v_ost_all&$FFFF)+((((sizeof_ost*countof_ost)/4)-1)<<16),d0
		bsr.w	ClearRAM

		moveq	#id_PLC_TryAgain,d0
		bsr.w	QuickPLC			; load "TRY AGAIN" or "END" patterns

		move.l	#(v_pal_dry_next&$FFFF)+((((sizeof_pal_all)/4)-1)<<16),d0
		bsr.w	ClearRAM

		moveq	#id_Pal_Ending,d0
		bsr.w	PalLoad_Next			; load ending palette
		clr.w	(v_pal_dry_next+$40).w		; set bg colour to black
		move.b	#id_EndEggman,(v_ost_endeggman).w ; load Eggman object
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		move.w	#1800,(v_countdown).w		; show screen for 30 seconds
		bsr.w	PaletteFadeIn			; fade in from black

; ---------------------------------------------------------------------------
; "TRY AGAIN" and "END"	screen main loop
; ---------------------------------------------------------------------------

TryAg_MainLoop:
		bsr.w	PauseGame
		move.b	#id_VBlank_Title,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		andi.b	#btnStart,(v_joypad_press_actual).w ; is Start button pressed?
		bne.s	@exit				; if yes, branch
		tst.w	(v_countdown).w			; has 30 seconds elapsed?
		beq.s	@exit				; if yes, branch
		cmpi.b	#id_Credits,(v_gamemode).w
		beq.s	TryAg_MainLoop

	@exit:
		move.b	#id_Sega,(v_gamemode).w		; goto Sega screen
		rts	
