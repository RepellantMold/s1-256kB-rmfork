;  =========================================================================
; |           Sonic the Hedgehog Disassembly for Sega Mega Drive            |
;  =========================================================================

; Disassembly created by Hivebrain
; thanks to drx, Stealth, Esrael L.G. Neto and the Sonic Retro Github

; ===========================================================================

		opt	l@					; @ is the local label symbol
		opt	ae-					; automatic evens are disabled by default
		opt	ws+					; allow statements to contain white-spaces
		opt	w+					; print warnings
		opt	m+					; do not expand macros - if enabled, this can break assembling

		include "Mega Drive.asm"
		include "Macros - More CPUs.asm"
		include "Macros - 68k Extended.asm"
		include "Macros - General.asm"
		include "Macros - Sonic.asm"
		include "sound\Sounds.asm"
		include "sound\Sound Equates.asm"
		include "Constants.asm"
		include "RAM Addresses.asm"
		include	"Start Positions.asm"
		include "Includes\Compatibility.asm"

		cpu	68000

EnableSRAM:	equ 0						; change to 1 to enable SRAM
BackupSRAM:	equ 1
AddressSRAM:	equ 3						; 0 = odd+even; 2 = even only; 3 = odd only

; Change to 0 to build the original version of the game, dubbed REV00
; Change to 1 to build the later version, dubbed REV01, which includes various bugfixes and enhancements
; Change to 2 to build the version from Sonic Mega Collection, dubbed REVXB, which fixes the infamous "spike bug"
	if ~def(Revision)					; bit-perfect check will automatically set this variable
Revision:	equ 1
	endc

ZoneCount:	equ 6						; discrete zones are: GHZ, MZ, SYZ, LZ, SLZ, and SBZ

		include "Nemesis File List.asm"
; ===========================================================================

StartOfRom:
Vectors:	dc.l v_stack_pointer&$FFFFFF			; Initial stack pointer value
		dc.l EntryPoint					; Start of program
		dc.l BusError					; Bus error
		dc.l AddressError				; Address error
		dc.l IllegalInstr				; Illegal instruction
		dc.l ZeroDivide					; Division by zero
		dc.l ChkInstr					; CHK exception
		dc.l TrapvInstr					; TRAPV exception
		dc.l PrivilegeViol				; Privilege violation
		dc.l Trace					; TRACE exception
		dc.l Line1010Emu				; Line-A emulator
		dc.l Line1111Emu				; Line-F emulator
		dcb.l 2,ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Format error
		dc.l ErrorExcept				; Uninitialized interrupt
		dcb.l 8,ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Spurious exception
		dc.l ErrorTrap					; IRQ level 1
		dc.l ErrorTrap					; IRQ level 2
		dc.l ErrorTrap					; IRQ level 3
		dc.l HBlank					; IRQ level 4 (horizontal retrace interrupt)
		dc.l ErrorTrap					; IRQ level 5
		dc.l VBlank					; IRQ level 6 (vertical retrace interrupt)
		dc.l ErrorTrap					; IRQ level 7
		dcb.l 16,ErrorTrap				; TRAP #00..#15 exceptions
		dcb.l 8,ErrorTrap				; Unused (reserved)
		if Revision<>2
			dcb.l 8,ErrorTrap			; Unused (reserved)
		else
	Spike_Bugfix:
								; Relocated code from Spike_Hurt. REVXB was a nasty hex-edit.
			move.l	ost_y_pos(a0),d3
			move.w	ost_y_vel(a0),d0
			ext.l	d0
			asl.l	#8,d0
			jmp	(Spike_Resume).l

			dc.w ErrorTrap
			dcb.l 3,ErrorTrap
		endc
Console:	dc.b "SEGA MEGA DRIVE "				; Hardware system ID (Console name)
Date:		dc.b "(C)SEGA 1991.APR"				; Copyright holder and release date (generally year)
Title_Local:	dc.b "SONIC THE               HEDGEHOG                " ; Domestic name
Title_Int:	dc.b "SONIC THE               HEDGEHOG                " ; International name

Serial:
	if Revision=0
		dc.b "GM 00001009-00"				; Serial/version number (Rev 0)
	else
		dc.b "GM 00004049-01"				; Serial/version number (Rev non-0)
	endc

Checksum: 	dc.w $0
		dc.b "J               "				; I/O support
RomStartLoc:	dc.l StartOfRom					; Start address of ROM
RomEndLoc:	dc.l EndOfRom-1					; End address of ROM
RamStartLoc:	dc.l $FF0000					; Start address of RAM
RamEndLoc:	dc.l $FFFFFF					; End address of RAM

SRAMSupport:
	if EnableSRAM=1
		dc.b "RA", $A0+(BackupSRAM<<6)+(AddressSRAM<<3), $20
		dc.l $200001					; SRAM start
		dc.l $200FFF					; SRAM end
	else
		dc.l $20202020					; dummy values (SRAM disabled)
		dc.l $20202020					; SRAM start
		dc.l $20202020					; SRAM end
	endc

Notes:		dc.b "                                                    " ; Notes (unused, anything can be put in this space, but it has to be 52 bytes.)
Region:		dc.b "JUE             "				; Region (Country code)
EndOfHeader:

; ===========================================================================
; Crash/Freeze the 68000. Unlike Sonic 2, Sonic 1 uses the 68000 for playing music, so it stops too

ErrorTrap:
		nop
		nop
		bra.s	ErrorTrap
; ===========================================================================

		include	"Includes\Mega Drive Setup.asm"		; EntryPoint

GameProgram:
		tst.w	(vdp_control_port).l
		btst	#6,(port_e_control).l
		beq.s	CheckSumCheck
		cmpi.l	#'init',(v_checksum_pass).w		; has checksum routine already run?
		beq.w	GameInit				; if yes, branch

CheckSumCheck:
		movea.l	#EndOfHeader,a0				; start	checking bytes after the header	($200)
		movea.l	#RomEndLoc,a1				; stop at end of ROM
		move.l	(a1),d0
		moveq	#0,d1

	@loop:
		add.w	(a0)+,d1
		cmp.l	a0,d0
		bhs.s	@loop
		movea.l	#Checksum,a1				; read the checksum
		cmp.w	(a1),d1					; compare checksum in header to ROM
		bne.w	CheckSumError				; if they don't match, branch

	CheckSumOk:
		lea	(v_keep_after_reset).w,a6		; $FFFFFE00
		moveq	#0,d7
		move.w	#(($FFFFFFFF-v_keep_after_reset+1)/4)-1,d6
	@clearRAM:
		move.l	d7,(a6)+
		dbf	d6,@clearRAM				; clear RAM ($FE00-$FFFF)

		move.b	(console_version).l,d0
		andi.b	#$C0,d0
		move.b	d0,(v_console_region).w			; get region setting
		move.l	#'init',(v_checksum_pass).w		; set flag so checksum won't run again

GameInit:
		lea	($FF0000).l,a6
		moveq	#0,d7
		move.w	#((v_keep_after_reset&$FFFF)/4)-1,d6
	@clearRAM:
		move.l	d7,(a6)+
		dbf	d6,@clearRAM				; clear RAM ($0000-$FDFF)

		bsr.w	VDPSetupGame				; clear CRAM and set VDP registers
		bsr.w	DacDriverLoad
		bsr.w	JoypadInit				; initialise joypads
		move.b	#id_Sega,(v_gamemode).w			; set Game Mode to Sega Screen

MainGameLoop:
		move.b	(v_gamemode).w,d0			; load Game Mode
		andi.w	#$1C,d0					; limit Game Mode value to $1C max (change to a maximum of 7C to add more game modes)
		jsr	GameModeArray(pc,d0.w)			; jump to apt location in ROM
		bra.s	MainGameLoop				; loop indefinitely
; ===========================================================================
; ---------------------------------------------------------------------------
; Main game mode array
; ---------------------------------------------------------------------------
gmptr:		macro
		id_\1:	equ *-GameModeArray
		if narg=1
		bra.w	GM_\1
		else
		bra.w	GM_\2
		endc
		endm

GameModeArray:
		gmptr Sega					; Sega Screen ($00)
		gmptr Title					; Title	Screen ($04)
		gmptr Demo, Level				; Demo Mode ($08)
		gmptr Level					; Normal Level ($0C)
		gmptr Special					; Special Stage	($10)
		gmptr Continue					; Continue Screen ($14)
		gmptr Ending					; End of game sequence ($18)
		gmptr Credits					; Credits ($1C)
		rts
; ===========================================================================

CheckSumError:
		bsr.w	VDPSetupGame
		move.l	#$C0000000,(vdp_control_port).l		; set VDP to CRAM write
		moveq	#(sizeof_pal_all/2)-1,d7

	@fillred:
		move.w	#cRed,(vdp_data_port).l			; fill palette with red
		dbf	d7,@fillred				; repeat $3F more times

	@endlessloop:
		bra.s	@endlessloop
; ===========================================================================

		include	"Includes\Errors.asm"

Art_Text:	incbin	"Graphics\Level Select & Debug Text.bin" ; text used in level select and debug mode
		even

		include	"Includes\VBlank & HBlank.asm"
		include	"Includes\JoypadInit & ReadJoypads.asm"
		include	"Includes\VDPSetupGame.asm"
		include	"Includes\ClearScreen.asm"
		include	"sound\PlaySound + DacDriverLoad.asm"
		include	"Includes\PauseGame.asm"
		include	"Includes\TilemapToVRAM.asm"

		include "Includes\Nemesis Decompression.asm"
		include "Includes\AddPLC, NewPLC, RunPLC, ProcessPLC & QuickPLC.asm"

		include "Includes\Enigma Decompression.asm"
		include "Includes\Kosinski Decompression.asm"

; ---------------------------------------------------------------------------
; Palette data & routines
; ---------------------------------------------------------------------------
		include "Includes\PaletteCycle.asm"
Pal_TitleCyc:	incbin	"Palettes\Cycle - Title Screen Water.bin"
Pal_GHZCyc:	incbin	"Palettes\Cycle - GHZ.bin"
Pal_LZCyc1:	incbin	"Palettes\Cycle - LZ Waterfall.bin"
Pal_LZCyc2:	incbin	"Palettes\Cycle - LZ Conveyor Belt.bin"
Pal_LZCyc3:	incbin	"Palettes\Cycle - LZ Conveyor Belt Underwater.bin"
Pal_SBZ3Cyc1:	incbin	"Palettes\Cycle - SBZ3 Waterfall.bin"
Pal_SLZCyc:	incbin	"Palettes\Cycle - SLZ.bin"
Pal_SYZCyc1:	incbin	"Palettes\Cycle - SYZ1.bin"
Pal_SYZCyc2:	incbin	"Palettes\Cycle - SYZ2.bin"
		include_Pal_SBZCycList				; "Includes\PaletteCycle.asm"
Pal_SBZCyc1:	incbin	"Palettes\Cycle - SBZ 1.bin"
Pal_SBZCyc2:	incbin	"Palettes\Cycle - SBZ 2.bin"
Pal_SBZCyc3:	incbin	"Palettes\Cycle - SBZ 3.bin"
Pal_SBZCyc4:	incbin	"Palettes\Cycle - SBZ 4.bin"
Pal_SBZCyc5:	incbin	"Palettes\Cycle - SBZ 5.bin"
Pal_SBZCyc6:	incbin	"Palettes\Cycle - SBZ 6.bin"
Pal_SBZCyc7:	incbin	"Palettes\Cycle - SBZ 7.bin"
Pal_SBZCyc8:	incbin	"Palettes\Cycle - SBZ 8.bin"
Pal_SBZCyc9:	incbin	"Palettes\Cycle - SBZ 9.bin"
Pal_SBZCyc10:	incbin	"Palettes\Cycle - SBZ 10.bin"
		include	"Includes\PaletteFadeIn, PaletteFadeOut, PaletteWhiteIn & PaletteWhiteOut.asm"
		include	"Includes\GM_Sega.asm"
Pal_Sega1:	incbin	"Palettes\Sega1.bin"
Pal_Sega2:	incbin	"Palettes\Sega2.bin"
		include "Includes\PalLoad & PalPointers.asm"
Pal_SegaBG:	incbin	"Palettes\Sega Background.bin"
Pal_Title:	incbin	"Palettes\Title Screen.bin"
Pal_LevelSel:	incbin	"Palettes\Level Select.bin"
Pal_Sonic:	incbin	"Palettes\Sonic.bin"
Pal_GHZ:	incbin	"Palettes\Green Hill Zone.bin"
Pal_LZ:		incbin	"Palettes\Labyrinth Zone.bin"
Pal_LZWater:	incbin	"Palettes\Labyrinth Zone Underwater.bin"
Pal_MZ:		incbin	"Palettes\Marble Zone.bin"
Pal_SLZ:	incbin	"Palettes\Star Light Zone.bin"
Pal_SYZ:	incbin	"Palettes\Spring Yard Zone.bin"
Pal_SBZ1:	incbin	"Palettes\SBZ Act 1.bin"
Pal_SBZ2:	incbin	"Palettes\SBZ Act 2.bin"
Pal_Special:	incbin	"Palettes\Special Stage.bin"
Pal_SBZ3:	incbin	"Palettes\SBZ Act 3.bin"
Pal_SBZ3Water:	incbin	"Palettes\SBZ Act 3 Underwater.bin"
Pal_LZSonWater:	incbin	"Palettes\Sonic - LZ Underwater.bin"
Pal_SBZ3SonWat:	incbin	"Palettes\Sonic - SBZ3 Underwater.bin"
Pal_SSResult:	incbin	"Palettes\Special Stage Results.bin"
Pal_Continue:	incbin	"Palettes\Special Stage Continue Bonus.bin"
Pal_Ending:	incbin	"Palettes\Ending.bin"

		include "Includes\WaitForVBlank.asm"
		include "Objects\_RandomNumber.asm"
		include "Objects\_CalcSine & CalcAngle.asm"
Sine_Data:	incbin	"Misc Data\Sine & Cosine Waves.bin"	; values for a 256 degree sine wave
		incbin	"Misc Data\Sine & Cosine Waves.bin",,$80 ; contains duplicate data at the end!
		include_CalcAngle				; "Objects\_CalcSine & CalcAngle.asm"
Angle_Data:	incbin	"Misc Data\Angle Table.bin"

		include_Sega					; "Includes\GM_Sega.asm"
		include "Includes\GM_Title.asm"

		include "Includes\GM_Level.asm"
		include "Includes\LZWaterFeatures.asm"

		include "Includes\MoveSonicInDemo & DemoRecorder.asm"

; ---------------------------------------------------------------------------
; Demo sequence	pointers
; ---------------------------------------------------------------------------
DemoDataPtr:	dc.l Demo_GHZ					; demos run after the title screen
		dc.l Demo_GHZ
		dc.l Demo_MZ
		dc.l Demo_MZ
		dc.l Demo_SYZ
		dc.l Demo_SYZ
		dc.l Demo_SS
		dc.l Demo_SS

DemoEndDataPtr:	dc.l Demo_EndGHZ1				; demos run during the credits
		dc.l Demo_EndMZ
		dc.l Demo_EndSYZ
		dc.l Demo_EndLZ
		dc.l Demo_EndSLZ
		dc.l Demo_EndSBZ1
		dc.l Demo_EndSBZ2
		dc.l Demo_EndGHZ2

		; unused demo data
		dc.b   0, $8B,   8, $37,   0, $42,   8, $5C,   0, $6A,   8, $5F,   0, $2F,   8, $2C
		dc.b   0, $21,   8,   3, $28, $30,   8,   8,   0, $2E,   8, $15,   0,  $F,   8, $46
		dc.b   0, $1A,   8, $FF,   8, $CA,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0
		even

		include_Level_colptrs				; Includes\GM_Level.asm
		include "Includes\OscillateNumInit & OscillateNumDo.asm"
		include "Includes\SynchroAnimate.asm"
	
		include_Level_signpost				; Includes\GM_Level.asm

; ---------------------------------------------------------------------------
; Normal demo data
; ---------------------------------------------------------------------------
Demo_GHZ:	incbin	"Demos\Intro - GHZ.bin"
		even
Demo_MZ:	incbin	"Demos\Intro - MZ.bin"
		even
Demo_SYZ:	incbin	"Demos\Intro - SYZ.bin"
		even
Demo_SS:	incbin	"Demos\Intro - Special Stage.bin"
		even

		include "Includes\GM_Special.asm"

Pal_SSCyc1:	incbin	"Palettes\Cycle - Special Stage 1.bin"
		even
Pal_SSCyc2:	incbin	"Palettes\Cycle - Special Stage 2.bin"
		even

		include_Special_2				; Includes\GM_Special.asm

		include "Includes\GM_Continue.asm"

		include "Objects\Continue Screen Items.asm"	; ContScrItem
		include "Objects\Continue Screen Sonic.asm"	; ContSonic
		include "Objects\Continue Screen [Mappings].asm" ; Map_ContScr

		include "Includes\GM_Ending.asm"

		include "Objects\Ending Sonic.asm"		; EndSonic
		include "Objects\Ending Chaos Emeralds.asm"	; EndChaos
		include "Objects\Ending StH Text.asm"		; EndSTH

		include "Objects\Ending Sonic [Mappings].asm"	; Map_ESon
		include "Objects\Ending Chaos Emeralds [Mappings].asm" ; Map_ECha
		include "Objects\Ending StH Text [Mappings].asm" ; Map_ESth

		include "Includes\GM_Credits.asm"

		include "Objects\Ending Eggman Try Again.asm"	; EndEggman
		include "Objects\Ending Chaos Emeralds Try Again.asm" ; TryChaos
		include "Objects\Ending Eggman Try Again [Mappings].asm" ; Map_EEgg

; ---------------------------------------------------------------------------
; Ending demo data
; ---------------------------------------------------------------------------
Demo_EndGHZ1:	incbin	"Demos\Ending - GHZ1.bin"
		even
Demo_EndMZ:	incbin	"Demos\Ending - MZ.bin"
		even
Demo_EndSYZ:	incbin	"Demos\Ending - SYZ.bin"
		even
Demo_EndLZ:	incbin	"Demos\Ending - LZ.bin"
		even
Demo_EndSLZ:	incbin	"Demos\Ending - SLZ.bin"
		even
Demo_EndSBZ1:	incbin	"Demos\Ending - SBZ1.bin"
		even
Demo_EndSBZ2:	incbin	"Demos\Ending - SBZ2.bin"
		even
Demo_EndGHZ2:	incbin	"Demos\Ending - GHZ2.bin"
		even

		include	"Includes\LevelParameterLoad.asm"
		include	"Includes\DeformLayers.asm"
		include	"Includes\DrawTilesWhenMoving, DrawTilesAtStart & DrawChunks.asm"

		include "Includes\LevelDataLoad, LevelLayoutLoad & LevelHeaders.asm"
		include "Includes\DynamicLevelEvents.asm"

		include "Objects\GHZ Bridge.asm"		; Bridge

		include "Objects\_DetectPlatform.asm"
		include "Objects\_SlopeObject.asm"

		include "Objects\GHZ, MZ & SLZ Swinging Platforms, SBZ Ball on Chain.asm" ; SwingingPlatform
		
		include_Bridge_2				; Objects\GHZ Bridge.asm

		include "Objects\_ExitPlatform.asm"

		include_Bridge_3				; Objects\GHZ Bridge.asm
		include "Objects\GHZ Bridge [Mappings].asm"	; Map_Bri

		include_SwingingPlatform_1			; Objects\GHZ, MZ & SLZ Swinging Platforms, SBZ Ball on Chain.asm

		include "Objects\_MoveWithPlatform.asm"

		include_SwingingPlatform_2			; Objects\GHZ, MZ & SLZ Swinging Platforms, SBZ Ball on Chain.asm

		include "Objects\GHZ Boss Ball.asm"		; BossBall
		include_BossBall_2

		include_SwingingPlatform_3			; Objects\GHZ, MZ & SLZ Swinging Platforms, SBZ Ball on Chain.asm
		
		include "Objects\GHZ & MZ Swinging Platforms [Mappings].asm" ; Map_Swing_GHZ
		include "Objects\SLZ Swinging Platforms [Mappings].asm" ; Map_Swing_SLZ

		include "Objects\GHZ Spiked Helix Pole.asm"	; Helix
		include "Objects\GHZ Spiked Helix Pole [Mappings].asm" ; Map_Hel

		include "Objects\Platforms.asm"			; BasicPlatform
		include "Objects\Platforms [Mappings].asm"	; Map_Plat_Unused, Map_Plat_GHZ, Map_Plat_SYZ, Map_Plat_SLZ

Obj19:
		rts						; blank object
		
		include "Objects\GHZ Giant Ball [Mappings].asm"	; Map_GBall

		include "Objects\GHZ Collapsing Ledge.asm"	; CollapseLedge
		include "Objects\MZ, SLZ & SBZ Collapsing Floors.asm" ; CollapseFloor
		include_CollapseLedge_2				; Objects\GHZ Collapsing Ledge.asm

		include_CollapseFloor_fragtiming

		include_SlopeObject_NoChk			; Objects\_SlopeObject.asm

Ledge_SlopeData:
		incbin	"Collision\GHZ Collapsing Ledge Heightmap.bin" ; used by CollapseLedge
		even

		include "Objects\GHZ Collapsing Ledge [Mappings].asm" ; Map_Ledge
		include "Objects\MZ, SLZ & SBZ Collapsing Floors [Mappings].asm" ; Map_CFlo

		include "Objects\GHZ Bridge Stump & SLZ Fireball Launcher.asm" ; Scenery
		include "Objects\SLZ Fireball Launcher [Mappings].asm" ; Map_Scen

		include "Objects\Unused Switch.asm"		; MagicSwitch
		include "Objects\Unused Switch [Mappings].asm"	; Map_Switch

		include "Objects\SBZ Door.asm"			; AutoDoor
		include "Objects\SBZ Door [Mappings].asm"	; Map_ADoor

		include "Objects\GHZ Walls.asm"			; EdgeWalls
		include_EdgeWalls_2

		include "Objects\Ball Hog.asm"			; BallHog
		include "Objects\Ball Hog Cannonball.asm"	; Cannonball

		include "Objects\Buzz Bomber Missile Vanishing.asm" ; MissileDissolve

		include "Objects\Explosions.asm"		; ExplosionItem & ExplosionBomb
		include_BallHog_animation
		include "Objects\Ball Hog [Mappings].asm"	; Map_Hog
		include "Objects\Buzz Bomber Missile Vanishing [Mappings].asm" ; Map_MisDissolve
		include "Objects\Explosions [Mappings].asm"	; Map_ExplodeItem & Map_ExplodeBomb

		include "Objects\Animals.asm"			; Animals
		include "Objects\Points.asm"			; Points
		include "Objects\Animals [Mappings].asm"	; Map_Animal1, Map_Animal2 & Map_Animal3
		include "Objects\Points [Mappings].asm"		; Map_Points

		include "Objects\Crabmeat.asm"			; Crabmeat
		include "Objects\Crabmeat [Mappings].asm"	; Map_Crab

		include "Objects\Buzz Bomber.asm"		; BuzzBomber
		include "Objects\Buzz Bomber Missile.asm"	; Missile
		include_BuzzBomber_animation
		include_Missile_animation
		include "Objects\Buzz Bomber [Mappings].asm"	; Map_Buzz
		include "Objects\Buzz Bomber Missile [Mappings].asm" ; Map_Missile

		include "Objects\Rings.asm"			; Rings
		include "Objects\_CollectRing.asm"
		include "Objects\Ring Loss.asm"			; RingLoss
		include "Objects\Giant Ring.asm"		; GiantRing
		include "Objects\Giant Ring Flash.asm"		; RingFlash
		include_Rings_animation
		include "Objects\Ring [Mappings].asm"		; Map_Ring
		include "Objects\Giant Ring [Mappings].asm"	; Map_GRing
		include "Objects\Giant Ring Flash [Mappings].asm" ; Map_Flash

		include "Objects\Monitors.asm"			; Monitor
		include "Objects\Monitor Contents.asm"		; PowerUp
		include_Monitor_2				; Objects\Monitors.asm
		include_Monitor_animation
		include "Objects\Monitors [Mappings].asm"	; Map_Monitor

		include "Objects\Title Screen Sonic.asm"	; TitleSonic
		include "Objects\Title Screen Press Start & TM.asm" ; PSBTM

		include_TitleSonic_animation
		include_PSBTM_animation

		include "Objects\_AnimateSprite.asm"

		include "Objects\Title Screen Press Start & TM [Mappings].asm" ; Map_PSB
		include "Objects\Title Screen Sonic [Mappings].asm" ; Map_TSon

		include "Objects\Chopper.asm"			; Chopper
		include "Objects\Chopper [Mappings].asm"	; Map_Chop

		include "Objects\Jaws.asm"			; Jaws
		include "Objects\Jaws [Mappings].asm"		; Map_Jaws

		include "Objects\Burrobot.asm"			; Burrobot
		include "Objects\Burrobot [Mappings].asm"	; Map_Burro

		include "Objects\MZ Grass Platforms.asm"	; LargeGrass
LGrass_Coll_Wide:
		incbin	"Collision\MZ Grass Platforms Heightmap (Wide).bin" ; used by LargeGrass
		even
LGrass_Coll_Narrow:
		incbin	"Collision\MZ Grass Platforms Heightmap (Narrow).bin" ; used by LargeGrass
		even
LGrass_Coll_Sloped:
		incbin	"Collision\MZ Grass Platforms Heightmap (Sloped).bin" ; used by LargeGrass
		even
		include "Objects\MZ Burning Grass.asm"		; GrassFire
		include "Objects\MZ Grass Platforms [Mappings].asm" ; Map_LGrass
		include "Objects\Fireballs [Mappings].asm"	; Map_Fire

		include "Objects\MZ Green Glass Blocks.asm"	; GlassBlock
		include "Objects\MZ Green Glass Blocks [Mappings].asm" ; Map_Glass

		include "Objects\MZ Chain Stompers.asm"		; ChainStomp
		include "Objects\MZ Unused Sideways Stomper.asm" ; SideStomp
		include "Objects\MZ Chain Stompers [Mappings].asm" ; Map_CStom
		include "Objects\MZ Unused Sideways Stomper [Mappings].asm" ; Map_SStom

		include "Objects\Button.asm"			; Button
		include "Objects\Button [Mappings].asm"		; Map_But

		include "Objects\MZ & LZ Pushable Blocks.asm"	; PushBlock
		include "Objects\MZ & LZ Pushable Blocks [Mappings].asm" ; Map_Push

		include "Objects\Title Cards.asm"		; TitleCard
		include "Objects\Game Over & Time Over.asm"	; GameOverCard
		include "Objects\Sonic Has Passed Title Card.asm" ; HasPassedCard

		include "Objects\Special Stage Results.asm"	; SSResult
		include "Objects\Special Stage Results Chaos Emeralds.asm" ; SSRChaos
		include "Objects\Title Cards [Mappings].asm"	; Map_Card
		include "Objects\Game Over & Time Over [Mappings].asm" ; Map_Over
		include "Objects\Title Cards Sonic Has Passed [Mappings].asm" ; Map_Has
		include "Objects\Special Stage Results [Mappings].asm" ; Map_SSR
		include "Objects\Special Stage Results Chaos Emeralds [Mappings].asm" ; Map_SSRC

		include "Objects\Spikes.asm"			; Spikes
		include "Objects\Spikes [Mappings].asm"		; Map_Spike

		include "Objects\GHZ Purple Rock.asm"		; PurpleRock
		include "Objects\GHZ Waterfall Sound.asm"	; WaterSound
		include "Objects\GHZ Purple Rock [Mappings].asm" ; Map_PRock

		include "Objects\GHZ & SLZ Smashable Walls & SmashObject.asm" ; SmashWall
		include "Objects\GHZ & SLZ Smashable Walls [Mappings].asm" ; Map_Smash

		include "Includes\ExecuteObjects & Object Pointers.asm"

NullObject:
		;jmp	(DeleteObject).l ; It would be safer to have this instruction here, but instead it just falls through to ObjectFall

		include "Objects\_ObjectFall & SpeedToPos.asm"

		include "Objects\_DisplaySprite.asm"
		include "Objects\_DeleteObject & DeleteChild.asm"

		include "Includes\BuildSprites.asm"

		include "Objects\_CheckOffScreen.asm"

		include "Includes\ObjPosLoad.asm"
		include "Objects\_FindFreeObj & FindNextFreeObj.asm"

		include "Objects\Springs.asm"			; Springs
		include "Objects\Springs [Mappings].asm"	; Map_Spring

		include "Objects\Newtron.asm"			; Newtron
		include "Objects\Newtron [Mappings].asm"	; Map_Newt

		include "Objects\Roller.asm"			; Roller
		include "Objects\Roller [Mappings].asm"		; Map_Roll

		include_EdgeWalls_1				; Objects\GHZ Walls.asm
		include "Objects\GHZ Walls [Mappings].asm"	; Map_Edge

		include "Objects\MZ & SLZ Fireball Launchers.asm"
		include "Objects\Fireballs.asm"			; FireBall

		include "Objects\SBZ Flamethrower.asm"		; Flamethrower
		include "Objects\SBZ Flamethrower [Mappings].asm" ; Map_Flame

		include "Objects\MZ Purple Brick Block.asm"	; MarbleBrick
		include "Objects\MZ Purple Brick Block [Mappings].asm" ; Map_Brick

		include "Objects\SYZ Lamp.asm"			; SpinningLight
		include "Objects\SYZ Lamp [Mappings].asm"	; Map_Light

		include "Objects\SYZ Bumper.asm"		; Bumper
		include "Objects\SYZ Bumper [Mappings].asm"	; Map_Bump

		include "Objects\Signpost & HasPassedAct.asm"	; Signpost & HasPassedAct
		include "Objects\Signpost [Mappings].asm"	; Map_Sign

		include "Objects\MZ Lava Geyser Maker.asm"	; GeyserMaker
		include "Objects\MZ Lava Geyser.asm"		; LavaGeyser
		include "Objects\MZ Lava Wall.asm"		; LavaWall
		include "Objects\MZ Invisible Lava Tag.asm"	; LavaTag
		include "Objects\MZ Invisible Lava Tag [Mappings].asm" ; Map_LTag
		include_LavaGeyser_animation
		include_LavaWall_animation
		include "Objects\MZ Lava Geyser [Mappings].asm"	; Map_Geyser
		include "Objects\MZ Lava Wall [Mappings].asm"	; Map_LWall

		include "Objects\Moto Bug.asm"			; MotoBug
		include "Objects\_DespawnObject.asm"
		include_MotoBug_1
		include "Objects\Moto Bug [Mappings].asm"	; Map_Moto

Obj4F:
		rts						; blank object

		include "Objects\Yadrin.asm"			; Yadrin
		include "Objects\Yadrin [Mappings].asm"		; Map_Yad

		include "Objects\_SolidObject.asm"

		include "Objects\MZ Smashable Green Block.asm"	; SmashBlock
		include "Objects\MZ Smashable Green Block [Mappings].asm" ; Map_Smab

		include "Objects\MZ, LZ & SBZ Moving Blocks.asm" ; MovingBlock
		include "Objects\MZ, LZ & SBZ Moving Blocks [Mappings].asm" ; Map_MBlock, Map_MBlockLZ

		include "Objects\Batbrain.asm"			; Batbrain
		include "Objects\Batbrain [Mappings].asm"	; Map_Bat

		include "Objects\SYZ & SLZ Floating Blocks, LZ Doors.asm" ; FloatingBlock
		include "Objects\SYZ & SLZ Floating Blocks, LZ Doors [Mappings].asm" ; Map_FBlock

		include "Objects\SYZ & LZ Spike Ball Chain.asm"	; SpikeBall
		include "Objects\SYZ & LZ Spike Ball Chain [Mappings].asm" ; Map_SBall, Map_SBall2

		include "Objects\SYZ Large Spike Balls.asm"	; BigSpikeBall
		include "Objects\SYZ & SBZ Large Spike Balls [Mappings].asm" ; Map_BBall

		include "Objects\SLZ Elevator.asm"		; Elevator
		include "Objects\SLZ Elevator [Mappings].asm"	; Map_Elev

		include "Objects\SLZ Circling Platform.asm"	; CirclingPlatform
		include "Objects\SLZ Circling Platform [Mappings].asm" ; Map_Circ

		include "Objects\SLZ Stairs.asm"		; Staircase
		include "Objects\SLZ Stairs [Mappings].asm"	; Map_Stair

		include "Objects\SLZ Pylon.asm"			; Pylon
		include "Objects\SLZ Pylon [Mappings].asm"	; Map_Pylon

		include "Objects\LZ Water Surface.asm"		; WaterSurface
		include "Objects\LZ Water Surface [Mappings].asm" ; Map_Surf

		include "Objects\LZ Pole.asm"			; Pole
		include "Objects\LZ Pole [Mappings].asm"	; Map_Pole

		include "Objects\LZ Flapping Door.asm"		; FlapDoor
		include "Objects\LZ Flapping Door [Mappings].asm" ; Map_Flap

		include "Objects\Invisible Solid Blocks.asm"	; Invisibarrier
		include "Objects\Invisible Solid Blocks [Mappings].asm" ; Map_Invis

		include "Objects\SLZ Fans.asm"			; Fan
		include "Objects\SLZ Fans [Mappings].asm"	; Map_Fan

		include "Objects\SLZ Seesaw.asm"		; Seesaw
See_DataSlope:	incbin	"Collision\SLZ Seesaw Heightmap (Sloped).bin" ; used by Seesaw
		even
See_DataFlat:	incbin	"Collision\SLZ Seesaw Heightmap (Flat).bin" ; used by Seesaw
		even
		include "Objects\SLZ Seesaw [Mappings].asm"	; Map_Seesaw
		include "Objects\SLZ Seesaw Spike Ball [Mappings].asm" ; Map_SSawBall

		include "Objects\Bomb Enemy.asm"		; Bomb
		include "Objects\Bomb Enemy [Mappings].asm"	; Map_Bomb

		include "Objects\Orbinaut.asm"			; Orbinaut
		include "Objects\Orbinaut [Mappings].asm"	; Map_Orb

		include "Objects\LZ Harpoon.asm"		; Harpoon
		include "Objects\LZ Harpoon [Mappings].asm"	; Map_Harp

		include "Objects\LZ Blocks.asm"			; LabyrinthBlock
		include "Objects\LZ Blocks [Mappings].asm"	; Map_LBlock

		include "Objects\LZ Gargoyle Head.asm"		; Gargoyle
		include "Objects\LZ Gargoyle Head [Mappings].asm" ; Map_Gar

		include "Objects\LZ Conveyor Belt Platforms.asm" ; LabyrinthConvey
		include "Objects\LZ Conveyor Belt Platforms [Mappings].asm" ; Map_LConv

		include "Objects\LZ Bubbles.asm"		; Bubble
		include "Objects\LZ Bubbles [Mappings].asm"	; Map_Bub

		include "Objects\LZ Waterfall.asm"		; Waterfall
		include "Objects\LZ Waterfall [Mappings].asm"	; Map_WFall

		include "Objects\Sonic.asm"			; SonicPlayer
		include "Objects\Sonic [Animations].asm"	; Ani_Sonic
		include_Sonic_1

		include "Objects\LZ Drowning Numbers.asm"	; DrownCount
		include "Objects\_ResumeMusic.asm"

		include_DrownCount_animation
		include "Objects\LZ Sonic's Drowning Face [Mappings].asm" ; Map_Drown

		include "Objects\Shield & Invincibility.asm"	; ShieldItem
		include "Objects\Unused Special Stage Warp.asm"	; VanishSonic
		include "Objects\LZ Water Splash.asm"		; Splash
		include_ShieldItem_animation
		include "Objects\Shield & Invincibility [Mappings].asm" ; Map_Shield
		include_VanishSonic_animation
		include "Objects\Unused Special Stage Warp [Mappings].asm" ; Map_Vanish
		include_Splash_animation
		include "Objects\LZ Water Splash [Mappings].asm" ; Map_Splash

		include_Sonic_2					; Objects\Sonic.asm
		include "Objects\_FindNearestTile, FindFloor & FindWall.asm"

		include	"Includes\ConvertCollisionArray.asm"

		include_Sonic_3					; Objects\Sonic.asm
		include "Objects\_FindFloorObj, FindWallRightObj, FindCeilingObj & FindWallLeftObj.asm"
		include_Sonic_4					; Objects\Sonic.asm
		include_FindWallRightObj			; Objects\_FindFloorObj, FindWallRightObj, FindCeilingObj & FindWallLeftObj.asm
		include_Sonic_5					; Objects\Sonic.asm
		include_FindCeilingObj				; Objects\_FindFloorObj, FindWallRightObj, FindCeilingObj & FindWallLeftObj.asm
		include_Sonic_6					; Objects\Sonic.asm
		include_FindWallLeftObj				; Objects\_FindFloorObj, FindWallRightObj, FindCeilingObj & FindWallLeftObj.asm

		include "Objects\SBZ Rotating Disc Junction.asm" ; Junction
		include "Objects\SBZ Rotating Disc Junction [Mappings].asm" ; Map_Jun

		include "Objects\SBZ Running Disc.asm"		; RunningDisc
		include "Objects\SBZ Running Disc [Mappings].asm" ; Map_Disc

		include "Objects\SBZ Conveyor Belt.asm"		; Conveyor
		include "Objects\SBZ Trapdoor & Spinning Platforms.asm" ; SpinPlatform
		include "Objects\SBZ Trapdoor & Spinning Platforms [Mappings].asm" ; Map_Trap, Map_Spin

		include "Objects\SBZ Saws.asm"			; Saws
		include "Objects\SBZ Saws [Mappings].asm"	; Map_Saw

		include "Objects\SBZ Stomper & Sliding Doors.asm" ; ScrapStomp
		include "Objects\SBZ Stomper & Sliding Doors [Mappings].asm" ; Map_Stomp

		include "Objects\SBZ Vanishing Platform.asm"	; VanishPlatform
		include "Objects\SBZ Vanishing Platform [Mappings].asm" ; Map_VanP

		include "Objects\SBZ Electric Orb.asm"		; Electro
		include "Objects\SBZ Electric Orb [Mappings].asm" ; Map_Elec

		include "Objects\SBZ Conveyor Belt Platforms.asm" ; SpinConvey

		include "Objects\SBZ Girder Block.asm"		; Girder
		include "Objects\SBZ Girder Block [Mappings].asm" ; Map_Gird

		include "Objects\SBZ Teleporter.asm"		; Teleport

		include "Objects\Caterkiller.asm"		; Caterkiller
		include "Objects\Caterkiller [Mappings].asm"	; Map_Cat

		include "Objects\Lamppost.asm"			; Lamppost
		include "Objects\Lamppost [Mappings].asm"	; Map_Lamp

		include "Objects\Hidden Bonus Points.asm"	; HiddenBonus
		include "Objects\Hidden Bonus Points [Mappings].asm" ; Map_Bonus

		include "Objects\Credits & Sonic Team Presents.asm" ; CreditsText
		include "Objects\Credits & Sonic Team Presents [Mappings].asm" ; Map_Cred

		include "Objects\GHZ Boss, BossExplode & BossMove.asm" ; BossGreenHill
		include_BossBall_1				; Objects\GHZ Boss Ball.asm; BossBall
		include "Objects\Bosses [Animations].asm"	; Ani_Bosses
		include "Objects\Bosses [Mappings].asm"		; Map_Bosses, Map_BossItems

		include "Objects\LZ Boss.asm"			; BossLabyrinth
		include "Objects\MZ Boss.asm"			; BossMarble
		include "Objects\MZ Boss Fire.asm"		; BossFire
		include "Objects\SLZ Boss.asm"			; BossStarLight
		include "Objects\SLZ Boss Spikeballs.asm"	; BossSpikeball
		include "Objects\SLZ Boss Spikeballs [Mappings].asm" ; Map_BSBall
		include "Objects\SYZ Boss.asm"			; BossSpringYard
		include "Objects\SYZ Blocks at Boss.asm"	; BossBlock
		include "Objects\SYZ Blocks at Boss [Mappings].asm" ; Map_BossBlock

		include "Objects\SBZ2 Blocks That Eggman Breaks.asm" ; FalseFloor
		include "Objects\SBZ2 Eggman.asm"		; ScrapEggman
		include "Objects\SBZ2 Eggman [Mappings].asm"	; Map_SEgg
		include_FalseFloor_1				; Objects\SBZ2 Blocks That Eggman Breaks.asm
		include "Objects\SBZ2 Blocks That Eggman Breaks [Mappings].asm" ; Map_FFloor

		include "Objects\FZ Boss.asm"			; BossFinal
		include "Objects\FZ Eggman in Damaged Ship [Mappings].asm" ; Map_FZDamaged
		include "Objects\FZ Eggman Ship Legs [Mappings].asm" ; Map_FZLegs

		include "Objects\FZ Cylinders.asm"		; EggmanCylinder
		include "Objects\FZ Cylinders [Mappings].asm"	; Map_EggCyl

		include "Objects\FZ Plasma Balls.asm"		; BossPlasma
		include "Objects\FZ Plasma Launcher [Mappings].asm" ; Map_PLaunch
		include_BossPlasma_animation
		include "Objects\FZ Plasma Balls [Mappings].asm" ; Map_Plasma

		include "Objects\Prison Capsule.asm"		; Prison
		include "Objects\Prison Capsule [Mappings].asm"	; Map_Pri

		include "Objects\_ReactToItem, HurtSonic & KillSonic.asm"

		include_Special_3				; Includes\GM_Special.asm

; ---------------------------------------------------------------------------
; Special stage	mappings and VRAM pointers
; ---------------------------------------------------------------------------

ss_sprite:	macro *,map,tile,frame
		if strlen("\*")>0
		\*: equ *
		id_\*: equ ((*-SS_ItemIndex)/6)+1
		endc
		dc.l map+(frame*$1000000)
		dc.w tile
		endm
		
SS_ItemIndex:
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0	; 1
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal2,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal3,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
		ss_sprite Map_SSWalls,tile_Nem_SSWalls+tile_pal4,0
	SS_ItemIndex_wall_end:
SS_Item_Bumper:	ss_sprite Map_Bump,tile_Nem_Bumper_SS,0		; $25 - bumper
		ss_sprite Map_SS_R,tile_Nem_SSWBlock,0		; $26 - W
SS_Item_GOAL:	ss_sprite Map_SS_R,tile_Nem_SSGOAL,0		; $27 - GOAL
SS_Item_1Up:	ss_sprite Map_SS_R,tile_Nem_SS1UpBlock,0	; $28 - 1UP
SS_Item_Up:	ss_sprite Map_SS_Up,tile_Nem_SSUpDown,0		; $29 - Up
SS_Item_Down:	ss_sprite Map_SS_Down,tile_Nem_SSUpDown,0	; $2A - Down
SS_Item_R:	ss_sprite Map_SS_R,tile_Nem_SSRBlock+tile_pal2,0 ; $2B - R
SS_Item_RedWhi:	ss_sprite Map_SS_Glass,tile_Nem_SSRedWhite,0	; $2C - red/white
SS_Item_Glass1:	ss_sprite Map_SS_Glass,tile_Nem_SSGlass,0	; $2D - breakable glass gem
SS_Item_Glass2:	ss_sprite Map_SS_Glass,tile_Nem_SSGlass+tile_pal4,0
SS_Item_Glass3:	ss_sprite Map_SS_Glass,tile_Nem_SSGlass+tile_pal2,0
SS_Item_Glass4:	ss_sprite Map_SS_Glass,tile_Nem_SSGlass+tile_pal3,0
SS_Item_R2:	ss_sprite Map_SS_R,tile_Nem_SSRBlock,0		; $31 - R
SS_Item_Bump1:	ss_sprite Map_Bump,tile_Nem_Bumper_SS,id_frame_bump_bumped1
SS_Item_Bump2:	ss_sprite Map_Bump,tile_Nem_Bumper_SS,id_frame_bump_bumped2
		ss_sprite Map_SS_R,tile_Nem_SSZone1,0		; $34 - Zone 1
		ss_sprite Map_SS_R,tile_Nem_SSZone2,0		; $35 - Zone 2
		ss_sprite Map_SS_R,tile_Nem_SSZone3,0		; $36 - Zone 3
		ss_sprite Map_SS_R,tile_Nem_SSZone1,0		; $37 - Zone 4
		ss_sprite Map_SS_R,tile_Nem_SSZone2,0		; $38 - Zone 5
		ss_sprite Map_SS_R,tile_Nem_SSZone3,0		; $39 - Zone 6
SS_Item_Ring:	ss_sprite Map_Ring,tile_Nem_Ring+tile_pal2,0	; $3A - ring
SS_Item_Em1:	ss_sprite Map_SS_Chaos3,tile_Nem_SSEmerald,0	; $3B - emerald
SS_Item_Em2:	ss_sprite Map_SS_Chaos3,tile_Nem_SSEmerald+tile_pal2,0 ; $3C - emerald
SS_Item_Em3:	ss_sprite Map_SS_Chaos3,tile_Nem_SSEmerald+tile_pal3,0 ; $3D - emerald
SS_Item_Em4:	ss_sprite Map_SS_Chaos3,tile_Nem_SSEmerald+tile_pal4,0 ; $3E - emerald
SS_Item_Em5:	ss_sprite Map_SS_Chaos1,tile_Nem_SSEmerald,0	; $3F - emerald
SS_Item_Em6:	ss_sprite Map_SS_Chaos2,tile_Nem_SSEmerald,0	; $40 - emerald
SS_Item_Ghost:	ss_sprite Map_SS_R,tile_Nem_SSGhost,0		; $41 - ghost block
SS_Item_Spark1:	ss_sprite Map_Ring,tile_Nem_Ring+tile_pal2,id_frame_ring_sparkle1 ; $42 - sparkle
SS_Item_Spark2:	ss_sprite Map_Ring,tile_Nem_Ring+tile_pal2,id_frame_ring_sparkle2 ; $43 - sparkle
SS_Item_Spark3:	ss_sprite Map_Ring,tile_Nem_Ring+tile_pal2,id_frame_ring_sparkle3 ; $44 - sparkle
SS_Item_Spark4:	ss_sprite Map_Ring,tile_Nem_Ring+tile_pal2,id_frame_ring_sparkle4 ; $45 - sparkle
SS_Item_EmSp1:	ss_sprite Map_SS_Glass,tile_Nem_SSEmStars+tile_pal2,0 ; $46 - emerald sparkle
SS_Item_EmSp2:	ss_sprite Map_SS_Glass,tile_Nem_SSEmStars+tile_pal2,1 ; $47 - emerald sparkle
SS_Item_EmSp3:	ss_sprite Map_SS_Glass,tile_Nem_SSEmStars+tile_pal2,2 ; $48 - emerald sparkle
SS_Item_EmSp4:	ss_sprite Map_SS_Glass,tile_Nem_SSEmStars+tile_pal2,3 ; $49 - emerald sparkle
SS_Item_Ghost2:	ss_sprite Map_SS_R,tile_Nem_SSGhost,2
SS_Item_Glass5:	ss_sprite Map_SS_Glass,tile_Nem_SSGlass,0	; $4B
SS_Item_Glass6:	ss_sprite Map_SS_Glass,tile_Nem_SSGlass+tile_pal4,0 ; $4C
SS_Item_Glass7:	ss_sprite Map_SS_Glass,tile_Nem_SSGlass+tile_pal2,0 ; $4D
SS_Item_Glass8:	ss_sprite Map_SS_Glass,tile_Nem_SSGlass+tile_pal3,0 ; $4E
	SS_ItemIndex_end:

		include "Objects\Special Stage R [Mappings].asm" ; Map_SS_R
		include "Objects\Special Stage Breakable & Red-White Blocks [Mappings].asm" ; Map_SS_Glass
		include "Objects\Special Stage Up [Mappings].asm" ; Map_SS_Up
		include "Objects\Special Stage Down [Mappings].asm" ; Map_SS_Down
		include "Objects\Special Stage Chaos Emeralds [Mappings].asm" ; Map_SS_Chaos1, Map_SS_Chaos2 & Map_SS_Chaos3

		include "Objects\Special Stage Sonic.asm"	; SonicSpecial

Obj10:
		rts						; blank object

		include "Includes\AnimateLevelGfx.asm"

		include "Objects\HUD.asm"			; HUD
		include "Objects\HUD Score, Time & Rings [Mappings].asm" ; Map_HUD

		include "Objects\_AddPoints.asm"

		include "Includes\HUD_Update, HUD_Base & ContScrCounter.asm"

; ---------------------------------------------------------------------------
; Uncompressed graphics	- HUD and lives counter
; ---------------------------------------------------------------------------
Art_Hud:	incbin	"Graphics\HUD Numbers.bin"		; 8x16 pixel numbers on HUD
		even
Art_LivesNums:	incbin	"Graphics\Lives Counter Numbers.bin"	; 8x8 pixel numbers on lives counter
		even

		include "Objects\_DebugMode.asm"

		include_levelheaders				; Includes\LevelDataLoad, LevelLayoutLoad & LevelHeaders.asm
		include "Pattern Load Cues.asm"

		align	$200,$FF
		if Revision=0
			nemfile	Nem_SegaLogo
	Eni_SegaLogo:	incbin	"Tilemaps\Sega Logo.eni"	; large Sega logo (mappings)
			even
		else
			dcb.b	$300,$FF
			nemfile	Nem_SegaLogo
	Eni_SegaLogo:	incbin	"Tilemaps\Sega Logo (JP1).eni"	; large Sega logo (mappings)
			even
		endc
Eni_Title:	incbin	"Tilemaps\Title Screen.eni"		; title screen foreground (mappings)
		even
		nemfile	Nem_TitleFg
		nemfile	Nem_TitleSonic
		nemfile	Nem_TitleTM
Eni_JapNames:	incbin	"Tilemaps\Hidden Japanese Credits.eni"	; Japanese credits (mappings)
		even
		nemfile	Nem_JapNames

		include "Objects\Sonic [Mappings].asm"		; Map_Sonic
		include "Objects\Sonic DPLCs.asm"		; SonicDynPLC

; ---------------------------------------------------------------------------
; Uncompressed graphics	- Sonic
; ---------------------------------------------------------------------------
Art_Sonic:	incbin	"Graphics\Sonic.bin"			; Sonic
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
		if Revision=0
			nemfile	Nem_Smoke
			nemfile	Nem_SyzSparkle
		endc
		nemfile	Nem_Shield
		nemfile	Nem_Stars
		if Revision=0
			nemfile	Nem_LzSonic
			nemfile	Nem_UnkFire
			nemfile	Nem_Warp
			nemfile	Nem_Goggle
		endc

		include "Objects\Special Stage Walls [Mappings].asm" ; Map_SSWalls

; ---------------------------------------------------------------------------
; Compressed graphics - special stage
; ---------------------------------------------------------------------------
		nemfile	Nem_SSWalls
Eni_SSBg1:	incbin	"Tilemaps\SS Background 1.eni"		; special stage background (mappings)
		even
		nemfile	Nem_SSBgFish
Eni_SSBg2:	incbin	"Tilemaps\SS Background 2.eni"		; special stage background (mappings)
		even
		nemfile	Nem_SSBgCloud
		nemfile	Nem_SSGOAL
		nemfile	Nem_SSRBlock
		nemfile	Nem_SS1UpBlock
		nemfile	Nem_SSEmStars
		nemfile	Nem_SSRedWhite
		nemfile	Nem_SSZone1
		nemfile	Nem_SSZone2
		nemfile	Nem_SSZone3
		nemfile	Nem_SSZone4
		nemfile	Nem_SSZone5
		nemfile	Nem_SSZone6
		nemfile	Nem_SSUpDown
		nemfile	Nem_SSEmerald
		nemfile	Nem_SSGhost
		nemfile	Nem_SSWBlock
		nemfile	Nem_SSGlass
		nemfile	Nem_ResultEm
; ---------------------------------------------------------------------------
; Compressed graphics - GHZ stuff
; ---------------------------------------------------------------------------
		nemfile	Nem_Stalk
		nemfile	Nem_Swing
		nemfile	Nem_Bridge
		nemfile	Nem_GhzUnkBlock
		nemfile	Nem_Ball
		nemfile	Nem_Spikes
		nemfile	Nem_GhzLog
		nemfile	Nem_SpikePole
		nemfile	Nem_PplRock
		nemfile	Nem_GhzWall1
		nemfile	Nem_GhzWall2
; ---------------------------------------------------------------------------
; Compressed graphics - LZ stuff
; ---------------------------------------------------------------------------
		nemfile	Nem_Water
		nemfile	Nem_Splash
		nemfile	Nem_LzSpikeBall
		nemfile	Nem_FlapDoor
		nemfile	Nem_Bubbles
		nemfile	Nem_LzBlock3
		nemfile	Nem_LzDoor1
		nemfile	Nem_Harpoon
		nemfile	Nem_LzPole
		nemfile	Nem_LzDoor2
		nemfile	Nem_LzWheel
		nemfile	Nem_Gargoyle
		nemfile	Nem_LzBlock2
		nemfile	Nem_LzPlatfm
		nemfile	Nem_Cork
		nemfile	Nem_LzBlock1
; ---------------------------------------------------------------------------
; Compressed graphics - MZ stuff
; ---------------------------------------------------------------------------
		nemfile	Nem_MzMetal
		nemfile	Nem_MzSwitch
		nemfile	Nem_MzGlass
		nemfile	Nem_UnkGrass
		nemfile	Nem_Fireball
		nemfile	Nem_Lava
		nemfile	Nem_MzBlock
		nemfile	Nem_MzUnkBlock
; ---------------------------------------------------------------------------
; Compressed graphics - SLZ stuff
; ---------------------------------------------------------------------------
		nemfile	Nem_Seesaw
		nemfile	Nem_SlzSpike
		nemfile	Nem_Fan
		nemfile	Nem_SlzWall
		nemfile	Nem_Pylon
		nemfile	Nem_SlzSwing
		nemfile	Nem_SlzBlock
		nemfile	Nem_SlzCannon
; ---------------------------------------------------------------------------
; Compressed graphics - SYZ stuff
; ---------------------------------------------------------------------------
		nemfile	Nem_Bumper
		nemfile	Nem_SmallSpike
		nemfile	Nem_LzSwitch
		nemfile	Nem_BigSpike
; ---------------------------------------------------------------------------
; Compressed graphics - SBZ stuff
; ---------------------------------------------------------------------------
		nemfile	Nem_SbzWheel1
		nemfile	Nem_SbzWheel2
		nemfile	Nem_Cutter
		nemfile	Nem_Stomper
		nemfile	Nem_SpinPform
		nemfile	Nem_TrapDoor
		nemfile	Nem_SbzFloor
		nemfile	Nem_Electric
		nemfile	Nem_SbzBlock
		nemfile	Nem_FlamePipe
		nemfile	Nem_SbzDoor1
		nemfile	Nem_SlideFloor
		nemfile	Nem_SbzDoor2
		nemfile	Nem_Girder
; ---------------------------------------------------------------------------
; Compressed graphics - enemies
; ---------------------------------------------------------------------------
		nemfile	Nem_BallHog
		nemfile	Nem_Crabmeat
		nemfile	Nem_Buzz
		nemfile	Nem_UnkExplode
		nemfile	Nem_Burrobot
		nemfile	Nem_Chopper
		nemfile	Nem_Jaws
		nemfile	Nem_Roller
		nemfile	Nem_Motobug
		nemfile	Nem_Newtron
		nemfile	Nem_Yadrin
		nemfile	Nem_Batbrain
		nemfile	Nem_Splats
		nemfile	Nem_Bomb
		nemfile	Nem_Orbinaut
		nemfile	Nem_Cater
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
		nemfile	Nem_TitleCard
		nemfile	Nem_Hud
		nemfile	Nem_Lives
		nemfile	Nem_Ring
		nemfile	Nem_Monitors
		nemfile	Nem_Explode
		nemfile	Nem_Points
		nemfile	Nem_GameOver
		nemfile	Nem_HSpring
		nemfile	Nem_VSpring
		nemfile	Nem_SignPost
		nemfile	Nem_Lamp
		nemfile	Nem_BigFlash
		nemfile	Nem_Bonus
; ---------------------------------------------------------------------------
; Compressed graphics - continue screen
; ---------------------------------------------------------------------------
		nemfile	Nem_ContSonic
		nemfile	Nem_MiniSonic
; ---------------------------------------------------------------------------
; Compressed graphics - animals
; ---------------------------------------------------------------------------
		nemfile	Nem_Rabbit
		nemfile	Nem_Chicken
		nemfile	Nem_BlackBird
		nemfile	Nem_Seal
		nemfile	Nem_Pig
		nemfile	Nem_Flicky
		nemfile	Nem_Squirrel
; ---------------------------------------------------------------------------
; Compressed graphics - primary patterns and block mappings
; ---------------------------------------------------------------------------
Blk16_GHZ:	incbin	"16x16 Mappings\GHZ.eni"
		even
		nemfile	Nem_GHZ_1st
		nemfile	Nem_GHZ_2nd
Blk256_GHZ:	incbin	"256x256 Mappings\GHZ.kos"
		even
Blk16_LZ:	incbin	"16x16 Mappings\LZ.eni"
		even
		nemfile	Nem_LZ
Blk256_LZ:	incbin	"256x256 Mappings\LZ.kos"
		even
Blk16_MZ:	incbin	"16x16 Mappings\MZ.eni"
		even
		nemfile	Nem_MZ
Blk256_MZ:	if Revision=0
			incbin	"256x256 Mappings\MZ.kos"
		else
			incbin	"256x256 Mappings\MZ (JP1).kos"
		endc
		even
Blk16_SLZ:	incbin	"16x16 Mappings\SLZ.eni"
		even
		nemfile	Nem_SLZ
Blk256_SLZ:	incbin	"256x256 Mappings\SLZ.kos"
		even
Blk16_SYZ:	incbin	"16x16 Mappings\SYZ.eni"
		even
		nemfile	Nem_SYZ
Blk256_SYZ:	incbin	"256x256 Mappings\SYZ.kos"
		even
Blk16_SBZ:	incbin	"16x16 Mappings\SBZ.eni"
		even
		nemfile	Nem_SBZ
Blk256_SBZ:	if Revision=0
			incbin	"256x256 Mappings\SBZ.kos"
		else
			incbin	"256x256 Mappings\SBZ (JP1).kos"
		endc
		even
; ---------------------------------------------------------------------------
; Compressed graphics - bosses and ending sequence
; ---------------------------------------------------------------------------
		nemfile	Nem_Eggman
		nemfile	Nem_Weapons
		nemfile	Nem_Prison
		nemfile	Nem_Sbz2Eggman
		nemfile	Nem_FzBoss
		nemfile	Nem_FzEggman
		nemfile	Nem_Exhaust
		nemfile	Nem_EndEm
		nemfile	Nem_EndSonic
		nemfile	Nem_TryAgain
		if Revision=0
			nemfile	Nem_EndEggman
		endc
Kos_EndFlowers:	incbin	"Graphics - Compressed\Ending Flowers.kos" ; ending sequence animated flowers
		even
		nemfile	Nem_EndFlower
		nemfile	Nem_CreditText
		nemfile	Nem_EndStH

		if Revision=0
			dcb.b $104,$FF				; why?
		else
			dcb.b $40,$FF
		endc
; ---------------------------------------------------------------------------
; Collision data
; ---------------------------------------------------------------------------
AngleMap:	incbin	"Collision\Angle Map.bin"
		even
CollArray1:	incbin	"Collision\Collision Array (Normal).bin"
		even
CollArray2:	incbin	"Collision\Collision Array (Rotated).bin"
		even
Col_GHZ:	incbin	"Collision\GHZ.bin"			; GHZ index
		even
Col_LZ:		incbin	"Collision\LZ.bin"			; LZ index
		even
Col_MZ:		incbin	"Collision\MZ.bin"			; MZ index
		even
Col_SLZ:	incbin	"Collision\SLZ.bin"			; SLZ index
		even
Col_SYZ:	incbin	"Collision\SYZ.bin"			; SYZ index
		even
Col_SBZ:	incbin	"Collision\SBZ.bin"			; SBZ index
		even
; ---------------------------------------------------------------------------
; Special Stage layouts
; ---------------------------------------------------------------------------
SS_1:		incbin	"Special Stage Layouts\1.eni"
		even
SS_2:		incbin	"Special Stage Layouts\2.eni"
		even
SS_3:		incbin	"Special Stage Layouts\3.eni"
		even
SS_4:		incbin	"Special Stage Layouts\4.eni"
		even
		if Revision=0
	SS_5:		incbin	"Special Stage Layouts\5.eni"
			even
	SS_6:		incbin	"Special Stage Layouts\6.eni"
		else
	SS_5:		incbin	"Special Stage Layouts\5 (JP1).eni"
			even
	SS_6:		incbin	"Special Stage Layouts\6 (JP1).eni"
		endc
		even
; ---------------------------------------------------------------------------
; Animated uncompressed graphics
; ---------------------------------------------------------------------------
Art_GhzWater:	incbin	"Graphics\GHZ Waterfall.bin"
		even
Art_GhzFlower1:	incbin	"Graphics\GHZ Flower Large.bin"
		even
Art_GhzFlower2:	incbin	"Graphics\GHZ Flower Small.bin"
		even
Art_MzLava1:	incbin	"Graphics\MZ Lava Surface.bin"
		even
Art_MzLava2:	incbin	"Graphics\MZ Lava.bin"
		even
Art_MzTorch:	incbin	"Graphics\MZ Background Torch.bin"
		even
Art_SbzSmoke:	incbin	"Graphics\SBZ Background Smoke.bin"
		even

; ---------------------------------------------------------------------------
; Level	layout index
; ---------------------------------------------------------------------------
Level_Index:	index *
		; GHZ
		ptr Level_GHZ1
		ptr Level_GHZbg
		ptr byte_68D70
		
		ptr Level_GHZ2
		ptr Level_GHZbg
		ptr byte_68E3C
		
		ptr Level_GHZ3
		ptr Level_GHZbg
		ptr byte_68F84
		
		ptr byte_68F88
		ptr byte_68F88
		ptr byte_68F88
		
		; LZ
		ptr Level_LZ1
		ptr Level_LZbg
		ptr byte_69190
		
		ptr Level_LZ2
		ptr Level_LZbg
		ptr byte_6922E
		
		ptr Level_LZ3
		ptr Level_LZbg
		ptr byte_6934C
		
		ptr Level_SBZ3
		ptr Level_LZbg
		ptr byte_6940A
		
		; MZ
		ptr Level_MZ1
		ptr Level_MZ1bg
		ptr Level_MZ1
		
		ptr Level_MZ2
		ptr Level_MZ2bg
		ptr byte_6965C
		
		ptr Level_MZ3
		ptr Level_MZ3bg
		ptr byte_697E6
		
		ptr byte_697EA
		ptr byte_697EA
		ptr byte_697EA
		
		; SLZ
		ptr Level_SLZ1
		ptr Level_SLZbg
		ptr byte_69B84
		
		ptr Level_SLZ2
		ptr Level_SLZbg
		ptr byte_69B84
		
		ptr Level_SLZ3
		ptr Level_SLZbg
		ptr byte_69B84
		
		ptr byte_69B84
		ptr byte_69B84
		ptr byte_69B84
		
		; SYZ
		ptr Level_SYZ1
		ptr Level_SYZbg
		ptr byte_69C7E
		
		ptr Level_SYZ2
		ptr Level_SYZbg
		ptr byte_69D86
		
		ptr Level_SYZ3
		ptr Level_SYZbg
		ptr byte_69EE4
		
		ptr byte_69EE8
		ptr byte_69EE8
		ptr byte_69EE8
		
		; SBZ
		ptr Level_SBZ1
		ptr Level_SBZ1bg
		ptr Level_SBZ1bg
		
		ptr Level_SBZ2
		ptr Level_SBZ2bg
		ptr Level_SBZ2bg
		
		ptr Level_SBZ2
		ptr Level_SBZ2bg
		ptr byte_6A2F8
		
		ptr byte_6A2FC
		ptr byte_6A2FC
		ptr byte_6A2FC
		zonewarning Level_Index,24
		
		; Ending
		ptr Level_End
		ptr Level_GHZbg
		ptr byte_6A320
		
		ptr Level_End
		ptr Level_GHZbg
		ptr byte_6A320
		
		ptr byte_6A320
		ptr byte_6A320
		ptr byte_6A320
		
		ptr byte_6A320
		ptr byte_6A320
		ptr byte_6A320

Level_GHZ1:	incbin	"Level Layouts\ghz1.bin"
		even
byte_68D70:	dc.b 0,	0, 0, 0
Level_GHZ2:	incbin	"Level Layouts\ghz2.bin"
		even
byte_68E3C:	dc.b 0,	0, 0, 0
Level_GHZ3:	incbin	"Level Layouts\ghz3.bin"
		even
Level_GHZbg:	incbin	"Level Layouts\ghzbg.bin"
		even
byte_68F84:	dc.b 0,	0, 0, 0
byte_68F88:	dc.b 0,	0, 0, 0

Level_LZ1:	incbin	"Level Layouts\lz1.bin"
		even
Level_LZbg:	incbin	"Level Layouts\lzbg.bin"
		even
byte_69190:	dc.b 0,	0, 0, 0
Level_LZ2:	incbin	"Level Layouts\lz2.bin"
		even
byte_6922E:	dc.b 0,	0, 0, 0
Level_LZ3:	incbin	"Level Layouts\lz3.bin"
		even
byte_6934C:	dc.b 0,	0, 0, 0
Level_SBZ3:	incbin	"Level Layouts\sbz3.bin"
		even
byte_6940A:	dc.b 0,	0, 0, 0

Level_MZ1:	incbin	"Level Layouts\mz1.bin"
		even
Level_MZ1bg:	incbin	"Level Layouts\mz1bg.bin"
		even
Level_MZ2:	incbin	"Level Layouts\mz2.bin"
		even
Level_MZ2bg:	incbin	"Level Layouts\mz2bg.bin"
		even
byte_6965C:	dc.b 0,	0, 0, 0
Level_MZ3:	incbin	"Level Layouts\mz3.bin"
		even
Level_MZ3bg:	incbin	"Level Layouts\mz3bg.bin"
		even
byte_697E6:	dc.b 0,	0, 0, 0
byte_697EA:	dc.b 0,	0, 0, 0

Level_SLZ1:	incbin	"Level Layouts\slz1.bin"
		even
Level_SLZbg:	incbin	"Level Layouts\slzbg.bin"
		even
Level_SLZ2:	incbin	"Level Layouts\slz2.bin"
		even
Level_SLZ3:	incbin	"Level Layouts\slz3.bin"
		even
byte_69B84:	dc.b 0,	0, 0, 0

Level_SYZ1:	incbin	"Level Layouts\syz1.bin"
		even
Level_SYZbg:	if Revision=0
			incbin	"Level Layouts\syzbg.bin"
		else
			incbin	"Level Layouts\syzbg (JP1).bin"
		endc
		even
byte_69C7E:	dc.b 0,	0, 0, 0
Level_SYZ2:	incbin	"Level Layouts\syz2.bin"
		even
byte_69D86:	dc.b 0,	0, 0, 0
Level_SYZ3:	incbin	"Level Layouts\syz3.bin"
		even
byte_69EE4:	dc.b 0,	0, 0, 0
byte_69EE8:	dc.b 0,	0, 0, 0

Level_SBZ1:	incbin	"Level Layouts\sbz1.bin"
		even
Level_SBZ1bg:	incbin	"Level Layouts\sbz1bg.bin"
		even
Level_SBZ2:	incbin	"Level Layouts\sbz2.bin"
		even
Level_SBZ2bg:	incbin	"Level Layouts\sbz2bg.bin"
		even
byte_6A2F8:	dc.b 0,	0, 0, 0
byte_6A2FC:	dc.b 0,	0, 0, 0
Level_End:	incbin	"Level Layouts\ending.bin"
		even
byte_6A320:	dc.b 0,	0, 0, 0


Art_BigRing:	incbin	"Graphics\Giant Ring.bin"
		even

		align	$100,$FF

; ---------------------------------------------------------------------------
; Object position index
; ---------------------------------------------------------------------------
ObjPos_Index:	index *
		; GHZ
		ptr ObjPos_GHZ1
		ptr ObjPos_Null
		ptr ObjPos_GHZ2
		ptr ObjPos_Null
		ptr ObjPos_GHZ3
		ptr ObjPos_Null
		ptr ObjPos_GHZ1
		ptr ObjPos_Null
		; LZ
		ptr ObjPos_LZ1
		ptr ObjPos_Null
		ptr ObjPos_LZ2
		ptr ObjPos_Null
		ptr ObjPos_LZ3
		ptr ObjPos_Null
		ptr ObjPos_SBZ3
		ptr ObjPos_Null
		; MZ
		ptr ObjPos_MZ1
		ptr ObjPos_Null
		ptr ObjPos_MZ2
		ptr ObjPos_Null
		ptr ObjPos_MZ3
		ptr ObjPos_Null
		ptr ObjPos_MZ1
		ptr ObjPos_Null
		; SLZ
		ptr ObjPos_SLZ1
		ptr ObjPos_Null
		ptr ObjPos_SLZ2
		ptr ObjPos_Null
		ptr ObjPos_SLZ3
		ptr ObjPos_Null
		ptr ObjPos_SLZ1
		ptr ObjPos_Null
		; SYZ
		ptr ObjPos_SYZ1
		ptr ObjPos_Null
		ptr ObjPos_SYZ2
		ptr ObjPos_Null
		ptr ObjPos_SYZ3
		ptr ObjPos_Null
		ptr ObjPos_SYZ1
		ptr ObjPos_Null
		; SBZ
		ptr ObjPos_SBZ1
		ptr ObjPos_Null
		ptr ObjPos_SBZ2
		ptr ObjPos_Null
		ptr ObjPos_FZ
		ptr ObjPos_Null
		ptr ObjPos_SBZ1
		ptr ObjPos_Null
		zonewarning ObjPos_Index,$10
		; Ending
		ptr ObjPos_End
		ptr ObjPos_Null
		ptr ObjPos_End
		ptr ObjPos_Null
		ptr ObjPos_End
		ptr ObjPos_Null
		ptr ObjPos_End
		ptr ObjPos_Null
		; --- Put extra object data here. ---
ObjPosLZPlatform_Index:
		ptr ObjPos_LZ1pf1
		ptr ObjPos_LZ1pf2
		ptr ObjPos_LZ2pf1
		ptr ObjPos_LZ2pf2
		ptr ObjPos_LZ3pf1
		ptr ObjPos_LZ3pf2
		ptr ObjPos_LZ1pf1
		ptr ObjPos_LZ1pf2
ObjPosSBZPlatform_Index:
		ptr ObjPos_SBZ1pf1
		ptr ObjPos_SBZ1pf2
		ptr ObjPos_SBZ1pf3
		ptr ObjPos_SBZ1pf4
		ptr ObjPos_SBZ1pf5
		ptr ObjPos_SBZ1pf6
		ptr ObjPos_SBZ1pf1
		ptr ObjPos_SBZ1pf2
		endobj
		
		include "Object Subtypes.asm"
		include	"Object Placement\GHZ1.asm"
		include	"Object Placement\GHZ2.asm"
		include	"Object Placement\GHZ3.asm"
		include	"Object Placement\LZ1.asm"
		include	"Object Placement\LZ2.asm"
		include	"Object Placement\LZ3.asm"
		include	"Object Placement\SBZ3.asm"
		include	"Object Placement\LZ Platforms.asm"
		include	"Object Placement\MZ1.asm"
		include	"Object Placement\MZ2.asm"
		include	"Object Placement\MZ3.asm"
		include	"Object Placement\SLZ1.asm"
		include	"Object Placement\SLZ2.asm"
		include	"Object Placement\SLZ3.asm"
		include	"Object Placement\SYZ1.asm"
		include	"Object Placement\SYZ2.asm"
		include	"Object Placement\SYZ3.asm"
		include	"Object Placement\SBZ1.asm"
		include	"Object Placement\SBZ2.asm"
		include	"Object Placement\FZ.asm"
		include	"Object Placement\SBZ Platforms.asm"
		include	"Object Placement\Ending.asm"
ObjPos_Null:	endobj

		if Revision=0
			dcb.b $62A,$FF
		else
			dcb.b $63C,$FF
		endc
		;dcb.b ($10000-(*%$10000))-(EndOfRom-SoundDriver),$FF

; ---------------------------------------------------------------------------
; Sound driver data
; ---------------------------------------------------------------------------
		include "sound/Sound Data.asm"

EndOfRom:
		END
