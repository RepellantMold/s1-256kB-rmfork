; ---------------------------------------------------------------------------
; Special Stage
; ---------------------------------------------------------------------------

jmp_LoadTiles:	
		moveq	#9-1,d1
jmp_LoadTiles2:
		jmp	LoadTiles

GM_Special:
		play.w	1, bsr.w, sfx_EnterSS		; play special stage entry sound
		bsr.w	PaletteWhiteOut			; fade to white from previous gamemode
		disable_ints
		bsr.w	LoadVDPSettings
		move.w	#$8A00+175,(v_vdp_hint_counter).w
		move.w	#$9011,(a6)			; 64x64 cell plane size
		disable_display
		bsr.w	ClearScreen
		enable_ints
		dma_fill	0,$6FFF,$5000

	@wait_for_dma:
		move.w	(a5),d1				; read control port ($C00004)
		btst	#1,d1				; is DMA running?
		bne.s	@wait_for_dma			; if yes, branch
		
		move.w	#$8F02,(a5)			; set VDP increment to 2 bytes
		bsr.w	SS_BGLoad
		moveq	#id_KPLC_Special,d0
		bsr.w	KosPLC
		
		locVRAM	$5E00,(a5)
		lea	($FF4D00).l,a1
		bsr.w	jmp_LoadTiles
		locVRAM	$7E00,(a5)
		bsr.w	jmp_LoadTiles
		locVRAM	$8E00,(a5)
		bsr.w	jmp_LoadTiles
		locVRAM	$9E00,(a5)
		bsr.w	jmp_LoadTiles
		locVRAM	$BE00,(a5)
		bsr.w	jmp_LoadTiles
		locVRAM	$EE00,(a5)
		moveq	#16-1,d1
		bsr.w	jmp_LoadTiles2

		move.l	#(v_ost_all&$FFFF)+((((sizeof_ost*countof_ost)/4)-1)<<16),d0
		bsr.w	ClearRAM
		move.l	#(v_camera_x_pos&$FFFF)+(((($100)/4)-1)<<16),d0
		bsr.w	ClearRAM
		move.l	#(v_oscillating_table&$FFFF)+(((($A0)/4)-1)<<16),d0
		bsr.w	ClearRAM
		move.l	#(v_ss_bubble_x_pos&$FFFF)+(((($200)/4)-1)<<16),d0
		bsr.w	ClearRAM

		clr.b	(f_water_pal_full).w
		clr.w	(f_restart).w
		moveq	#id_Pal_Special,d0
		bsr.w	PalLoad_Next			; load special stage palette
		jsr	(SS_Load).l			; load SS layout data
		move.l	#0,(v_camera_x_pos).w
		move.l	#0,(v_camera_y_pos).w
		move.b	#id_SonicSpecial,(v_ost_player).w ; load special stage Sonic object
		bsr.w	PalCycle_SS
		clr.w	(v_ss_angle).w			; set stage angle to "upright"
		move.w	#$40,(v_ss_rotation_speed).w	; set stage rotation speed
		play.w	0, bsr.w, mus_SpecialStage	; play special stage BG	music
		move.w	#0,(v_demo_input_counter).w
		lea	(DemoDataPtr).l,a1
		moveq	#6,d0				; use demo #6
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1			; jump to SS demo data
		move.b	1(a1),(v_demo_input_time).w	; load 1st button press duration
		subq.b	#1,(v_demo_input_time).w
		clr.w	(v_rings).w
		clr.b	(v_ring_reward).w
		move.w	#1800,(v_countdown).w		; set timer to 30 seconds (used for demo)
		enable_display
		bsr.w	PaletteWhiteIn

; ---------------------------------------------------------------------------
; Main Special Stage loop
; ---------------------------------------------------------------------------

SS_MainLoop:
		bsr.w	PauseGame
		move.b	#id_VBlank_Special,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		bsr.w	MoveSonicInDemo
		move.w	(v_joypad_hold_actual).w,(v_joypad_hold).w
		jsr	(ExecuteObjects).l		; run objects (Sonic is the only one)
		jsr	(BuildSprites).l
		jsr	(SS_ShowLayout).l		; display layout
		bsr.w	SS_BGAnimate			; animate background
		tst.w	(v_demo_mode).w			; is demo mode on?
		beq.s	@not_demo			; if not, branch
		tst.w	(v_countdown).w			; is there time left on the demo?
		beq.w	SS_ToSegaScreen			; if not, branch

	@not_demo:
		cmpi.b	#id_Special,(v_gamemode).w	; is game mode $10 (special stage)?
		beq.w	SS_MainLoop			; if yes, branch

		tst.w	(v_demo_mode).w			; is demo mode on?
		bne.w	SS_ToLevel
		move.b	#id_Level,(v_gamemode).w	; set screen mode to $0C (level)
		cmpi.w	#(id_SBZ<<8)+3,(v_zone).w	; is level number higher than FZ?
		blo.s	@level_ok			; if not, branch
		clr.w	(v_zone).w			; set to GHZ1

	@level_ok:
		move.w	#60,(v_countdown).w		; set delay time to 1 second
		move.w	#palfade_all,(v_palfade_start).w ; $3F
		clr.w	(v_palfade_time).w

SS_FinishLoop:
		move.b	#id_VBlank_Continue,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		bsr.w	MoveSonicInDemo
		move.w	(v_joypad_hold_actual).w,(v_joypad_hold).w
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		jsr	(SS_ShowLayout).l
		bsr.w	SS_BGAnimate
		subq.w	#1,(v_palfade_time).w
		bpl.s	@leave_palette			; branch if palette timer is 0 or higher
		move.w	#2,(v_palfade_time).w		; set palette update delay to 2 frames
		bsr.w	WhiteOut_ToWhite		; fade to white in increments

	@leave_palette:
		tst.w	(v_countdown).w			; has timer hit 0?
		bne.s	SS_FinishLoop			; if not, branch

		disable_ints
		lea	(vdp_control_port).l,a6
		move.w	#$8200+(vram_fg>>10),(a6)	; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6)	; set background nametable address
		move.w	#$9001,(a6)			; 64x32 cell plane size
		bsr.w	ClearScreen
		locVRAM	vram_Nem_TitleCard		; $B000 - Pattern Load Cues.asm
		lea	(Nem_TitleCard).l,a0		; load title card patterns
		bsr.w	NemDec
		bsr.w	LoadHUDArt
		jsr	(Hud_Base).l
		enable_ints
		moveq	#id_Pal_SSResult,d0
		bsr.w	PalLoad_Now			; load results screen palette
		moveq	#id_KPLC_Main,d0
		bsr.w	KosPLC
		moveq	#id_PLC_SSResult,d0
		bsr.w	AddPLC				; load results screen patterns
		move.b	#1,(f_hud_score_update).w	; update score counter
		move.b	#1,(f_pass_bonus_update).w	; update ring bonus counter
		move.w	(v_rings).w,d0
		mulu.w	#10,d0				; multiply rings by 10
		move.w	d0,(v_ring_bonus).w		; set rings bonus
		play.w	1, jsr, mus_HasPassed		; play end-of-level music

		move.l	#(v_ost_all&$FFFF)+((((sizeof_ost*countof_ost)/4)-1)<<16),d0
		bsr.w	ClearRAM

		move.b	#id_SSResult,(v_ost_ssresult1).w ; load results screen object

SS_NormalExit:
		bsr.w	PauseGame
		move.b	#id_VBlank_TitleCard,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		bsr.w	RunPLC
		tst.w	(f_restart).w
		beq.s	SS_NormalExit
		tst.l	(v_plc_buffer).w
		bne.s	SS_NormalExit
		play.w	1, bsr.w, sfx_EnterSS		; play special stage exit sound
		bsr.w	PaletteWhiteOut
		rts	
; ===========================================================================

SS_ToSegaScreen:
		move.b	#id_Sega,(v_gamemode).w		; goto Sega screen
		rts

	SS_ToLevel:	cmpi.b	#id_Level,(v_gamemode).w
			beq.s	SS_ToSegaScreen
			rts

; ---------------------------------------------------------------------------
; Special stage	background mappings loading subroutine

;	uses d0, d1, d2, d3, d4, d5, d6, d7, a0, a1, a2
; ---------------------------------------------------------------------------

; Fish/bird dimensions in cells
fish_width:	equ 8
fish_height:	equ 8
sizeof_fish:	equ fish_width*fish_height*2

SS_BGLoad:
		lea	(v_ss_enidec_buffer).l,a1	; buffer
		lea	(Eni_SSBg1).l,a0		; load mappings for the birds and fish
		move.w	#$51+tile_pal3,d0		; add this to each tile
		bsr.w	EniDec				; decompress fish/bird mappings to RAM

		locVRAM	$5000,d3			; d3 = VDP address for $5000 in VRAM
		lea	(v_ss_enidec_buffer+sizeof_fish).l,a2
		moveq	#7-1,d7				; number of canvases for frames of bird/fish and in-between

; Each frame of bird/fish animation is stored as a canvas in VRAM. The game switches between them by changing the bg nametable register.
@loop_canvas:
		move.l	d3,d0				; copy VDP command
		moveq	#4-1,d6				; number of rows visible
		moveq	#0,d4				; first square is blank (i.e. blank-bird-blank-bird-etc.)
		cmpi.w	#3,d7
		bhs.s	@loop_rows			; branch if canvas is bird
		moveq	#1,d4				; first square is fish (i.e. fish-blank-fish-blank-etc.)

@loop_rows:
		moveq	#8-1,d5				; number of squares in a row

@loop_birdfish:
		movea.l	a2,a1				; get address of tilemap as stored in RAM
		eori.b	#1,d4				; switch between blank square and bird/fish
		bne.s	@is_birdfish			; branch if set to bird/fish
		cmpi.w	#6,d7
		bne.s	@skip_birdfish			; branch if not first frame
		lea	(v_ss_enidec_buffer).l,a1	; use tilemap for checkerboard pattern

	@is_birdfish:
		movem.l	d0-d4,-(sp)
		moveq	#fish_width-1,d1
		moveq	#fish_height-1,d2
		bsr.w	TilemapToVRAM			; copy tilemap for 1 bird or fish from RAM to VRAM
		movem.l	(sp)+,d0-d4

	@skip_birdfish:
		addi.l	#(fish_width*2)<<16,d0		; skip 8 cells ($10 bytes)
		dbf	d5,@loop_birdfish		; repeat for all squares in 1 row

		addi.l	#((fish_height-1)*$80)<<16,d0	; skip 7 rows ($380 byes)
		eori.b	#1,d4				; stagger blank/birdfish pattern
		dbf	d6,@loop_rows			; repeat for all rows (4 in total)

		addi.l	#$1000<<16,d3			; add $1000 to VRAM address
		bpl.s	@vdp_ok				; branch if valid VDP command
		swap	d3
		addi.l	#$C000,d3			; fix VDP command
		swap	d3

	@vdp_ok:
		adda.w	#sizeof_fish,a2			; read from next tilemap
		dbf	d7,@loop_canvas			; repeat for all canvases
		
		lea	(v_ss_enidec_buffer).l,a1
		lea	(Eni_SSBg2).l,a0		; load mappings for clouds/bubbles
		move.w	#0+tile_pal3,d0
		bsr.w	EniDec				; decompress to buffer in RAM

		lea	(v_ss_enidec_buffer).l,a1
		locVRAM	$C000,d0
		moveq	#$3F,d1
		moveq	#$1F,d2
		bsr.w	TilemapToVRAM			; copy tilemap for bubbles to VRAM
		lea	(v_ss_enidec_buffer).l,a1
		locVRAM	$D000,d0
		moveq	#$3F,d1
		moveq	#$3F,d2
		bsr.w	TilemapToVRAM			; copy tilemap for clouds to VRAM
		rts

; ---------------------------------------------------------------------------
; Palette cycling routine - special stage

; output:
;	a6 = vdp_control_port
;	uses d0, d1, a0, a1, a2
; ---------------------------------------------------------------------------

PalCycle_SS:
		tst.w	(f_pause).w			; is game paused?
		bne.s	@exit				; if yes, branch
		subq.w	#1,(v_palcycle_ss_time).w	; decrement timer
		bpl.s	@exit				; branch if time remains
		lea	(vdp_control_port).l,a6
		move.w	(v_palcycle_ss_num).w,d0	; get cycle index counter
		addq.w	#1,(v_palcycle_ss_num).w	; increment
		andi.w	#$1F,d0				; read only bits 0-4
		lsl.w	#2,d0				; multiply by 4
		lea	(SS_Timing_Values).l,a0
		adda.w	d0,a0
		move.b	(a0)+,d0			; get time byte
		bpl.s	@use_time			; branch if not -1
		move.w	#$1FF,d0			; use $1FF if -1

	@use_time:
		move.w	d0,(v_palcycle_ss_time).w	; set time until next palette change
		moveq	#0,d0
		move.b	(a0)+,d0			; get bg mode byte
		move.w	d0,(v_ss_bg_mode).w
		lea	(SS_BG_Modes).l,a1
		lea	(a1,d0.w),a1			; jump to mode data
		move.w	#$8200,d0			; VDP register - fg nametable address
		move.b	(a1)+,d0			; apply address from mode data
		move.w	d0,(a6)				; send VDP instruction
		move.b	(a1),(v_fg_y_pos_vsram).w	; get byte to send to VSRAM
		move.w	#$8400,d0			; VDP register - bg nametable address
		move.b	(a0)+,d0			; apply address from list
		move.w	d0,(a6)				; send VDP instruction
		move.l	#$40000010,(vdp_control_port).l	; set VDP to VSRAM write mode
		move.l	(v_fg_y_pos_vsram).w,(vdp_data_port).l ; update VSRAM
		moveq	#0,d0
		move.b	(a0)+,d0			; get palette offset
		bmi.s	PalCycle_SS_2			; branch if $80+
		lea	(Pal_SSCyc1).l,a1		; use palette cycle set 1
		adda.w	d0,a1
		lea	(v_pal_dry+$4E).w,a2
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+			; write palette

	@exit:
		rts	
; ===========================================================================

PalCycle_SS_2:
		move.w	(v_palcycle_ss_unused).w,d1	; this is always 0
		cmpi.w	#$8A,d0				; is offset $80-$89?
		blo.s	@offset_80_89			; if yes, branch
		addq.w	#1,d1

	@offset_80_89:
		mulu.w	#$2A,d1				; d1 = always 0 or $2A
		lea	(Pal_SSCyc2).l,a1		; use palette cycle set 2
		adda.w	d1,a1
		andi.w	#$7F,d0				; ignore bit 7
		bclr	#0,d0				; clear bit 0
		beq.s	@offset_even			; branch if already clear
		lea	(v_pal_dry+$6E).w,a2
		move.l	(a1),(a2)+
		move.l	4(a1),(a2)+
		move.l	8(a1),(a2)+			; write palette

	@offset_even:
		adda.w	#$C,a1
		lea	(v_pal_dry+$5A).w,a2
		cmpi.w	#$A,d0				; is offset 0-8?
		blo.s	@offset_0_8			; if yes, branch
		subi.w	#$A,d0
		lea	(v_pal_dry+$7A).w,a2

	@offset_0_8:
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0				; multiply d0 by 3
		adda.w	d0,a1
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+			; write palette
		rts

; ===========================================================================
SS_Timing_Values:
		; time until next, bg mode, bg namespace address in VRAM, palette offset
		dc.b 3,	0, $E000>>13, $92
		dc.b 3, 0, $E000>>13, $90
		dc.b 3, 0, $E000>>13, $8E
		dc.b 3, 0, $E000>>13, $8C
		dc.b 3,	0, $E000>>13, $8B
		dc.b 3, 0, $E000>>13, $80
		dc.b 3, 0, $E000>>13, $82
		dc.b 3, 0, $E000>>13, $84
		dc.b 3,	0, $E000>>13, $86
		dc.b 3, 0, $E000>>13, $88
		dc.b 7, 8, $E000>>13, 0
		dc.b 7,	$A, $E000>>13, $C
		dc.b -1, $C, $E000>>13, $18
		dc.b -1, $C, $E000>>13, $18
		dc.b 7, $A, $E000>>13, $C
		dc.b 7,	8, $E000>>13, 0
		dc.b 3,	0, $C000>>13, $88
		dc.b 3, 0, $C000>>13, $86
		dc.b 3, 0, $C000>>13, $84
		dc.b 3, 0, $C000>>13, $82
		dc.b 3,	0, $C000>>13, $81
		dc.b 3, 0, $C000>>13, $8A
		dc.b 3, 0, $C000>>13, $8C
		dc.b 3, 0, $C000>>13, $8E
		dc.b 3,	0, $C000>>13, $90
		dc.b 3, 0, $C000>>13, $92
		dc.b 7, 2, $C000>>13, $24
		dc.b 7, 4, $C000>>13, $30
		dc.b -1, 6, $C000>>13, $3C
		dc.b -1, 6, $C000>>13, $3C
		dc.b 7,	4, $C000>>13, $30
		dc.b 7, 2, $C000>>13, $24
		even
SS_BG_Modes:
		; fg namespace address in VRAM, VScroll value
		dc.b $4000>>10, 1			; 0 - grid
		dc.b $6000>>10, 0			; 2 - fish morph 1
		dc.b $6000>>10, 1			; 4 - fish morph 2
		dc.b $8000>>10, 0			; 6 - fish
		dc.b $8000>>10, 1			; 8 - bird morph 1
		dc.b $A000>>10, 0			; $A - bird morph 2
		dc.b $A000>>10, 1			; $C - bird
		even

; ---------------------------------------------------------------------------
; Special Stage, part 2
; ---------------------------------------------------------------------------

include_Special_2:	macro

; ---------------------------------------------------------------------------
; Subroutine to	make the special stage background animated

;	uses d0, d1, d2, d3, a1, a3
; ---------------------------------------------------------------------------

SS_BGAnimate:
		move.w	(v_ss_bg_mode).w,d0		; get frame for fish/bird animation
		bne.s	@not_0				; branch if not 0
		move.w	#0,(v_bg1_y_pos).w
		move.w	(v_bg1_y_pos).w,(v_bg_y_pos_vsram).w ; reset vertical scroll for bubble/cloud layer

	@not_0:
		cmpi.w	#8,d0
		bhs.s	SS_BGBirdCloud			; branch if d0 is 8-$C (birds and clouds)
		cmpi.w	#6,d0
		bne.s	@not_6				; branch if d0 isn't 6
		addq.w	#1,(v_bg3_x_pos).w
		addq.w	#1,(v_bg1_y_pos).w
		move.w	(v_bg1_y_pos).w,(v_bg_y_pos_vsram).w ; scroll bubble layer

	@not_6:
		moveq	#0,d0
		move.w	(v_bg1_x_pos).w,d0
		neg.w	d0
		swap	d0
		lea	(SS_Bubble_WobbleData).l,a1
		lea	(v_ss_bubble_x_pos).w,a3
		moveq	#9,d3

SS_BGWobbleLoop:
		move.w	2(a3),d0			; get next value from buffer
		bsr.w	CalcSine			; convert to sine
		moveq	#0,d2
		move.b	(a1)+,d2			; read 1st byte
		muls.w	d2,d0				; multiply by sine
		asr.l	#8,d0				; divide by $10
		move.w	d0,(a3)+			; write to 1st word of buffer
		move.b	(a1)+,d2			; read 2nd byte
		ext.w	d2
		add.w	d2,(a3)+			; add to 2nd word of buffer
		dbf	d3,SS_BGWobbleLoop
		
		lea	(v_ss_bubble_x_pos).w,a3
		lea	(SS_Bubble_ScrollBlocks).l,a2
		bra.s	SS_Scroll_CloudsBubbles
; ===========================================================================

SS_BGBirdCloud:
		cmpi.w	#$C,d0
		bne.s	@not_C				; branch if d0 isn't $C
		subq.w	#1,(v_bg3_x_pos).w
		lea	(v_ss_cloud_x_pos).w,a3
		move.l	#$18000,d2
		moveq	#6,d1

	@loop:
		move.l	(a3),d0
		sub.l	d2,d0
		move.l	d0,(a3)+
		subi.l	#$2000,d2
		dbf	d1,@loop

	@not_C:
		lea	(v_ss_cloud_x_pos).w,a3
		lea	(SS_Cloud_ScrollBlocks).l,a2

SS_Scroll_CloudsBubbles:
		lea	(v_hscroll_buffer).w,a1
		move.w	(v_bg3_x_pos).w,d0
		neg.w	d0
		swap	d0
		moveq	#0,d3
		move.b	(a2)+,d3
		move.w	(v_bg1_y_pos).w,d2
		neg.w	d2
		andi.w	#$FF,d2
		lsl.w	#2,d2

	@loop_block:
		move.w	(a3)+,d0
		addq.w	#2,a3
		moveq	#0,d1
		move.b	(a2)+,d1
		subq.w	#1,d1

	@loop_line:
		move.l	d0,(a1,d2.w)
		addq.w	#4,d2
		andi.w	#$3FC,d2
		dbf	d1,@loop_line
		dbf	d3,@loop_block
		rts

; ===========================================================================
SS_Bubble_ScrollBlocks:
		dc.b @end-@start-1
	@start:	dc.b $28, $18, $10, $28, $18, $10, $30, $18, 8, $10
	@end:
		even
SS_Cloud_ScrollBlocks:
		dc.b @end-@start-1
	@start:	dc.b $30, $30, $30, $28, $18, $18, $18
	@end:
		even
SS_Bubble_WobbleData:
		dc.b 8, 2
		dc.b 4, -1
		dc.b 2, 3
		dc.b 8, -1
		dc.b 4, 2
		dc.b 2, 3
		dc.b 8, -3
		dc.b 4, 2
		dc.b 2, 3
		dc.b 2, -1
		even
		
		endm

; ---------------------------------------------------------------------------
; Special Stage, part 3
; ---------------------------------------------------------------------------

include_Special_3:	macro

; ---------------------------------------------------------------------------
; Subroutine to	show the special stage layout

; input:
;	d5 = sprite count (from BuildSprites)

;	uses d0, d2, d3, d4, d5, d1, d7, a0, a1
; ---------------------------------------------------------------------------

SS_ShowLayout:
		bsr.w	SS_AniWallsRings		; animate walls and rings
		bsr.w	SS_UpdateItems

; Calculate x/y positions of each cell in a 16x16 grid when rotated
		move.w	d5,-(sp)			; save sprite count to stack
		lea	(v_ss_sprite_grid_plot).w,a1	; address to write grid coords
		move.b	(v_ss_angle).w,d0
		andi.b	#$FC,d0				; round down angle to nearest 4
		jsr	(CalcSine).l			; convert to sine/cosine
		move.w	d0,d4
		move.w	d1,d5
		muls.w	#$18,d4
		muls.w	#$18,d5
		moveq	#0,d2
		move.w	(v_camera_x_pos).w,d2
		divu.w	#$18,d2
		swap	d2
		neg.w	d2
		addi.w	#-$B4,d2
		moveq	#0,d3
		move.w	(v_camera_y_pos).w,d3
		divu.w	#$18,d3
		swap	d3
		neg.w	d3
		addi.w	#-$B4,d3
		move.w	#$F,d7

	@loop_gridrow:
		movem.w	d0-d2,-(sp)
		movem.w	d0-d1,-(sp)
		neg.w	d0
		muls.w	d2,d1
		muls.w	d3,d0
		move.l	d0,d6
		add.l	d1,d6
		movem.w	(sp)+,d0-d1
		muls.w	d2,d0
		muls.w	d3,d1
		add.l	d0,d1
		move.l	d6,d2
		move.w	#$F,d6

	@loop_gridcell:
		move.l	d2,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		move.l	d1,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		add.l	d5,d2
		add.l	d4,d1
		dbf	d6,@loop_gridcell

		movem.w	(sp)+,d0-d2
		addi.w	#$18,d3
		dbf	d7,@loop_gridrow

; Populate the 16x16 grid with sprites based on the level layout
		move.w	(sp)+,d5
		lea	(v_ss_layout).l,a0
		moveq	#0,d0
		move.w	(v_camera_y_pos).w,d0		; get camera y pos
		divu.w	#$18,d0				; divide by size of wall sprite (24 pixels)
		mulu.w	#$80,d0				; muliply by width of level
		adda.l	d0,a0				; jump to correct row in level
		moveq	#0,d0
		move.w	(v_camera_x_pos).w,d0		; get camera x pos
		divu.w	#$18,d0				; divide by size of wall sprite (24 pixels)
		adda.w	d0,a0				; jump to correct block in level
		lea	(v_ss_sprite_grid_plot).w,a4	; transformation grid
		move.w	#$F,d7

	@loop_spriterow:
		move.w	#$F,d6

	@loop_sprite:
		moveq	#0,d0
		move.b	(a0)+,d0			; get level block
		beq.s	@skip				; branch if 0 (blank)
		cmpi.b	#(SS_ItemIndex_end-SS_ItemIndex)/6,d0
		bhi.s	@skip				; branch if above $4E (invalid)
		move.w	(a4),d3				; get grid x pos
		addi.w	#$120,d3				
		cmpi.w	#$70,d3
		blo.s	@skip				; branch if off screen
		cmpi.w	#$1D0,d3
		bhs.s	@skip
		move.w	2(a4),d2			; get grid y pos
		addi.w	#$F0,d2
		cmpi.w	#$70,d2
		blo.s	@skip
		cmpi.w	#$170,d2
		bhs.s	@skip
		lea	(v_ss_sprite_info).l,a5
		lsl.w	#3,d0
		lea	(a5,d0.w),a5
		movea.l	(a5)+,a1			; get mappings pointer
		move.w	(a5)+,d1			; get frame id
		add.w	d1,d1
		adda.w	(a1,d1.w),a1			; apply frame id to mappings pointer
		movea.w	(a5)+,a3			; get tile id
		moveq	#0,d1
		move.b	(a1)+,d1			; get number of sprite pieces from mappings
		subq.b	#1,d1
		bmi.s	@skip				; branch if 0
		jsr	(BuildSpr_Normal).l		; build sprites from mappings

	@skip:
		addq.w	#4,a4				; next sprite
		dbf	d6,@loop_sprite

		lea	$70(a0),a0			; next row
		dbf	d7,@loop_spriterow

		move.b	d5,(v_spritecount).w
		cmpi.b	#$50,d5
		beq.s	@spritelimit
		move.l	#0,(a2)
		rts	
; ===========================================================================

@spritelimit:
		move.b	#0,-5(a2)			; set last sprite link
		rts

; ---------------------------------------------------------------------------
; Subroutine to	animate	walls and rings	in the special stage

;	uses d0, d1, a0, a1
; ---------------------------------------------------------------------------

SS_AniWallsRings:
		lea	(v_ss_sprite_info+$C).l,a1	; frame id of first wall
		moveq	#0,d0
		move.b	(v_ss_angle).w,d0		; get angle
		lsr.b	#2,d0				; divide by 4
		andi.w	#$F,d0				; read only low nybble
		moveq	#((SS_ItemIndex_wall_end-SS_ItemIndex)/6)-1,d1 ; $23

	@wall_loop:
		move.w	d0,(a1)				; change frame id to appropriately rotated wall
		addq.w	#8,a1
		dbf	d1,@wall_loop

		lea	(v_ss_sprite_info+5).l,a1	; frame id of first sprite (it's blank, but that doesn't matter)
		subq.b	#1,(v_syncani_1_time).w		; decrement animation timer
		bpl.s	@not0_1				; branch if time remains
		move.b	#7,(v_syncani_1_time).w		; reset to 7
		addq.b	#1,(v_syncani_1_frame).w	; increment frame
		andi.b	#3,(v_syncani_1_frame).w	; there are 4 frames max

	@not0_1:
		move.b	(v_syncani_1_frame).w,(id_SS_Item_Ring*8)(a1) ; $1D0(a1) ; update ring frame
		
		subq.b	#1,(v_syncani_2_time).w
		bpl.s	@not0_2
		move.b	#7,(v_syncani_2_time).w
		addq.b	#1,(v_syncani_2_frame).w
		andi.b	#1,(v_syncani_2_frame).w

	@not0_2:
		move.b	(v_syncani_2_frame).w,d0
		move.b	d0,(id_SS_Item_GOAL*8)(a1)	; $138(a1)
		move.b	d0,(id_SS_Item_RedWhi*8)(a1)	; $160(a1)
		move.b	d0,(id_SS_Item_Up*8)(a1)	; $148(a1)
		move.b	d0,(id_SS_Item_Down*8)(a1)	; $150(a1)
		move.b	d0,(id_SS_Item_Em1*8)(a1)	; $1D8(a1)
		move.b	d0,(id_SS_Item_Em2*8)(a1)	; $1E0(a1)
		move.b	d0,(id_SS_Item_Em3*8)(a1)	; $1E8(a1)
		move.b	d0,(id_SS_Item_Em4*8)(a1)	; $1F0(a1)
		move.b	d0,(id_SS_Item_Em5*8)(a1)	; $1F8(a1)
		move.b	d0,(id_SS_Item_Em6*8)(a1)	; $200(a1)
		
		subq.b	#1,(v_syncani_3_time).w
		bpl.s	@not0_3
		move.b	#4,(v_syncani_3_time).w
		addq.b	#1,(v_syncani_3_frame).w
		andi.b	#3,(v_syncani_3_frame).w

	@not0_3:
		move.b	(v_syncani_3_frame).w,d0
		move.b	d0,(id_SS_Item_Glass1*8)(a1)	; $168(a1)
		move.b	d0,(id_SS_Item_Glass2*8)(a1)	; $170(a1)
		move.b	d0,(id_SS_Item_Glass3*8)(a1)	; $178(a1)
		move.b	d0,(id_SS_Item_Glass4*8)(a1)	; $180(a1)
		
		subq.b	#1,(v_syncani_0_time).w
		bpl.s	@not0_0
		move.b	#7,(v_syncani_0_time).w
		subq.b	#1,(v_syncani_0_frame).w
		andi.b	#7,(v_syncani_0_frame).w

	@not0_0:
		lea	(v_ss_sprite_info+$16).l,a1
		lea	(SS_Wall_Vram_Settings).l,a0
		moveq	#0,d0
		move.b	(v_syncani_0_frame).w,d0
		add.w	d0,d0
		lea	(a0,d0.w),a0
		moveq	#3,d2
	@loop:
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		dbf	d2,@loop
		rts

; ===========================================================================
SS_Wall_Vram_Settings:
		dc.w $142
		dc.w $142+tile_pal4
		dc.w $142
		dc.w $142
		dc.w $142
		dc.w $142
		dc.w $142
		dc.w $142+tile_pal4
		dc.w $142
		dc.w $142+tile_pal4
		dc.w $142
		dc.w $142
		dc.w $142
		dc.w $142
		dc.w $142
		dc.w $142+tile_pal4
		dc.w $142+tile_pal2
		dc.w $142
		dc.w $142+tile_pal2
		dc.w $142+tile_pal2
		dc.w $142+tile_pal2
		dc.w $142+tile_pal2
		dc.w $142+tile_pal2
		dc.w $142
		dc.w $142+tile_pal2
		dc.w $142
		dc.w $142+tile_pal2
		dc.w $142+tile_pal2
		dc.w $142+tile_pal2
		dc.w $142+tile_pal2
		dc.w $142+tile_pal2
		dc.w $142
		dc.w $142+tile_pal3
		dc.w $142+tile_pal2
		dc.w $142+tile_pal3
		dc.w $142+tile_pal3
		dc.w $142+tile_pal3
		dc.w $142+tile_pal3
		dc.w $142+tile_pal3
		dc.w $142+tile_pal2
		dc.w $142+tile_pal3
		dc.w $142+tile_pal2
		dc.w $142+tile_pal3
		dc.w $142+tile_pal3
		dc.w $142+tile_pal3
		dc.w $142+tile_pal3
		dc.w $142+tile_pal3
		dc.w $142+tile_pal2
		dc.w $142+tile_pal4
		dc.w $142+tile_pal3
		dc.w $142+tile_pal4
		dc.w $142+tile_pal4
		dc.w $142+tile_pal4
		dc.w $142+tile_pal4
		dc.w $142+tile_pal4
		dc.w $142+tile_pal3
		dc.w $142+tile_pal4
		dc.w $142+tile_pal3
		dc.w $142+tile_pal4
		dc.w $142+tile_pal4
		dc.w $142+tile_pal4
		dc.w $142+tile_pal4
		dc.w $142+tile_pal4
		dc.w $142+tile_pal3

; ---------------------------------------------------------------------------
; Subroutine to	find a free slot in sprite update list

; output:
;	a2 = address of free slot in sprite update list
;	uses d0
; ---------------------------------------------------------------------------

SS_FindFreeUpdate:
		lea	(v_ss_sprite_update_list).l,a2	; address of sprite update list
		move.w	#$20-1,d0			; up to $20 slots

	@loop:
		tst.b	(a2)				; is slot free?
		beq.s	@free				; if yes, branch
		addq.w	#8,a2				; try next slot
		dbf	d0,@loop

	@free:
		rts

; ---------------------------------------------------------------------------
; Subroutine to	update special stage items after they've been touched

;	uses d0, d7, a0, a1
; ---------------------------------------------------------------------------

ss_update_id:		equ 0				; sprite id (1-6)
ss_update_time:		equ 2				; time until next frame update
ss_update_frame:	equ 3				; frame within update data
ss_update_levelptr:	equ 4				; pointer to item in level layout being updated

SS_UpdateItems:
		lea	(v_ss_sprite_update_list).l,a0	; sprite update list
		move.w	#$20-1,d7

	@loop:
		moveq	#0,d0
		move.b	(a0),d0				; read update id
		beq.s	@no_update			; branch if 0
		lsl.w	#2,d0
		movea.l	SS_UpdateIndex-4(pc,d0.w),a1
		jsr	(a1)				; run appropriate routine

	@no_update:
		addq.w	#8,a0				; next slot in list
		dbf	d7,@loop

		rts

; ===========================================================================
SS_UpdateIndex:	index.l 0,1
		ptr SS_UpdateRing			; 1
		ptr SS_UpdateBumper			; 2
		ptr SS_UpdateR				; 4
		ptr SS_UpdateEmerald			; 5
		ptr SS_UpdateGlass			; 6
; ===========================================================================

SS_UpdateRing:
		subq.b	#1,ss_update_time(a0)		; decrement timer
		bpl.s	@wait				; branch if positive
		move.b	#5,ss_update_time(a0)		; 5 frames until next update
		moveq	#0,d0
		move.b	ss_update_frame(a0),d0		; get current frame
		addq.b	#1,ss_update_frame(a0)		; increment frame
		movea.l	ss_update_levelptr(a0),a1	; get pointer to level layout
		move.b	SS_RingData(pc,d0.w),d0		; get new item id
		move.b	d0,(a1)				; update level layout
		bne.s	@wait				; branch if id isn't 0
		clr.l	(a0)				; free slot in update list
		clr.l	ss_update_levelptr(a0)

	@wait:
		rts	
; ===========================================================================
SS_RingData:	dc.b id_SS_Item_Spark1, id_SS_Item_Spark2, id_SS_Item_Spark3, id_SS_Item_Spark4, 0
		even
; ===========================================================================

SS_UpdateBumper:
		subq.b	#1,ss_update_time(a0)
		bpl.s	@wait
		move.b	#7,ss_update_time(a0)
		moveq	#0,d0
		move.b	ss_update_frame(a0),d0
		addq.b	#1,ss_update_frame(a0)
		movea.l	ss_update_levelptr(a0),a1
		move.b	SS_BumperData(pc,d0.w),d0
		bne.s	@update
		clr.l	(a0)
		clr.l	ss_update_levelptr(a0)
		move.b	#id_SS_Item_Bumper,(a1)
		rts	
; ===========================================================================

@update:
		move.b	d0,(a1)

@wait:
		rts	
; ===========================================================================
SS_BumperData:	dc.b id_SS_Item_Bump1, id_SS_Item_Bump2, id_SS_Item_Bump1, id_SS_Item_Bump2, 0
		even
; ===========================================================================

SS_UpdateR:
		subq.b	#1,ss_update_time(a0)
		bpl.s	locret_1B5CC
		move.b	#7,ss_update_time(a0)
		moveq	#0,d0
		move.b	ss_update_frame(a0),d0
		addq.b	#1,ss_update_frame(a0)
		movea.l	ss_update_levelptr(a0),a1
		move.b	SS_RData(pc,d0.w),d0
		bne.s	loc_1B5CA
		clr.l	(a0)
		clr.l	ss_update_levelptr(a0)
		move.b	#id_SS_Item_R,(a1)
		rts	
; ===========================================================================

loc_1B5CA:
		move.b	d0,(a1)

locret_1B5CC:
		rts	
; ===========================================================================
SS_RData:	dc.b id_SS_Item_R, id_SS_Item_R2, id_SS_Item_R, id_SS_Item_R2, 0
		even
; ===========================================================================

SS_UpdateEmerald:
		subq.b	#1,ss_update_time(a0)
		bpl.s	locret_1B60C
		move.b	#5,ss_update_time(a0)
		moveq	#0,d0
		move.b	ss_update_frame(a0),d0
		addq.b	#1,ss_update_frame(a0)
		movea.l	ss_update_levelptr(a0),a1
		move.b	SS_EmeraldData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B60C
		clr.l	(a0)
		clr.l	ss_update_levelptr(a0)
		move.b	#id_SSS_ExitStage,(v_ost_player+ost_routine).w
		play.w	1, jsr, sfx_Goal		; play special stage GOAL sound

locret_1B60C:
		rts	
; ===========================================================================
SS_EmeraldData:	dc.b id_SS_Item_EmSp1, id_SS_Item_EmSp2, id_SS_Item_EmSp3, id_SS_Item_EmSp4, 0
		even
; ===========================================================================

SS_UpdateGlass:
		subq.b	#1,ss_update_time(a0)		; decrement timer
		bpl.s	locret_1B640			; branch if time is positive
		move.b	#1,ss_update_time(a0)		; set timer to 1 frame
		moveq	#0,d0
		move.b	ss_update_frame(a0),d0		; get current frame
		addq.b	#1,ss_update_frame(a0)		; increment frame
		movea.l	ss_update_levelptr(a0),a1	; get pointer to level layout
		move.b	SS_GlassData(pc,d0.w),d0	; read new frame id
		move.b	d0,(a1)				; update level layout
		bne.s	locret_1B640			; branch if frame id isn't 0
		move.b	4(a0),(a1)			; change id to weakened glass
		clr.l	(a0)				; free update slot
		clr.l	ss_update_levelptr(a0)

locret_1B640:
		rts	
; ===========================================================================
SS_GlassData:	dc.b id_SS_Item_Glass5, id_SS_Item_Glass6, id_SS_Item_Glass7, id_SS_Item_Glass8, id_SS_Item_Glass5, id_SS_Item_Glass6, id_SS_Item_Glass7, id_SS_Item_Glass8, 0
		even

; ---------------------------------------------------------------------------
; Special stage	layout pointers
; ---------------------------------------------------------------------------
SS_LayoutIndex:
		dc.l SS_1
		dc.l SS_2
		dc.l SS_3
		dc.l SS_4
		dc.l SS_5
		dc.l SS_6
		even

; ---------------------------------------------------------------------------
; Special stage start locations
; ---------------------------------------------------------------------------
SpecialStartPosList:
		dc.l startpos_ss1
		dc.l startpos_ss2
		dc.l startpos_ss3
		dc.l startpos_ss4
		dc.l startpos_ss5
		dc.l startpos_ss6
		even

; ---------------------------------------------------------------------------
; Subroutine to	load special stage layout

;	uses d0, d1, d2, a0, a1, a3
; ---------------------------------------------------------------------------

SS_Load:
		moveq	#0,d0
		move.b	(v_last_ss_levelid).w,d0	; load number of last special stage entered
		addq.b	#1,(v_last_ss_levelid).w
		cmpi.b	#6,(v_last_ss_levelid).w
		blo.s	@ss_valid
		move.b	#0,(v_last_ss_levelid).w	; reset if higher than 6

	@ss_valid:
		cmpi.b	#6,(v_emeralds).w		; do you have all emeralds?
		beq.s	SS_LoadData			; if yes, branch
		moveq	#0,d1
		move.b	(v_emeralds).w,d1
		subq.b	#1,d1
		blo.s	SS_LoadData
		lea	(v_emerald_list).w,a3		; check which emeralds you have

SS_ChkEmldLoop:	
		cmp.b	(a3,d1.w),d0
		bne.s	SS_ChkEmldRepeat
		bra.s	SS_Load
; ===========================================================================

SS_ChkEmldRepeat:
		dbf	d1,SS_ChkEmldLoop

SS_LoadData:
		lsl.w	#2,d0
		lea	SpecialStartPosList(pc,d0.w),a1
		move.w	(a1)+,(v_ost_player+ost_x_pos).w ; set Sonic's start position
		move.w	(a1)+,(v_ost_player+ost_y_pos).w
		movea.l	SS_LayoutIndex(pc,d0.w),a0
		lea	(v_ss_layout_buffer).l,a1	; load level layout ($FF4000)
		jsr	(KosDec).l
		move.l	#(v_ss_layout&$FFFF)+(((($4000)/4)-1)<<16),d0
		jsr	ClearRAM

		lea	(v_ss_layout+$1020).l,a1
		lea	(v_ss_layout_buffer).l,a0
		moveq	#$40-1,d1

	@loop_row:
		moveq	#$40-1,d2

	@loop_bytes:
		move.b	(a0)+,(a1)+
		dbf	d2,@loop_bytes

		lea	$40(a1),a1
		dbf	d1,@loop_row			; copy layout to RAM in blocks of $40 bytes, with $40 blank between each block

		lea	(v_ss_sprite_info+8).l,a1
		lea	(SS_ItemIndex).l,a0
		moveq	#((SS_ItemIndex_end-SS_ItemIndex)/6)-1,d1

	@loop_map_ptrs:
		move.l	(a0)+,(a1)+			; copy mappings pointer
		move.w	#0,(a1)+			; create blank word
		move.b	-4(a0),-1(a1)			; copy frame id to low byte of blank word
		move.w	(a0)+,(a1)+			; copy tile id
		dbf	d1,@loop_map_ptrs		; copy mappings pointers & VRAM settings to RAM

		lea	(v_ss_sprite_update_list).l,a1
		move.w	#($100/4)-1,d1

	@loop_update_list:

		clr.l	(a1)+
		dbf	d1,@loop_update_list		; clear RAM ($4400-$44FF)

		rts

		endm
