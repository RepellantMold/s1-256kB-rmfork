; ---------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------

sizeof_ost:		equ $40					; size of one OST in bytes
countof_ost:		equ $80					; number of OSTs in RAM
countof_ost_inert:	equ $20					; number of OSTs that don't interact with Sonic (including Sonic himself)
countof_ost_ert:	equ countof_ost-countof_ost_inert	; number of OSTs that do interact with Sonic ($60)
sizeof_plc:		equ 6					; size of one pattern load cue
countof_plc:		equ $10					; number of pattern load cues in RAM
sizeof_priority:	equ $80					; size of one priority section in sprite queue

level_max_width:	equ $40
level_max_height:	equ 8
sizeof_levelrow:	equ level_max_width*2			; level row, followed by background row
sizeof_level:		equ sizeof_levelrow*level_max_height	; includes background in $40 byte alternating strips

; VRAM data
vram_window:	equ $A000	; window nametable - unused
vram_fg:	equ $C000	; foreground nametable ($1000 bytes)
vram_bg:	equ $E000	; background nametable ($1000 bytes)
vram_sonic:	equ $F000	; Sonic graphics ($2E0 bytes)
vram_sprites:	equ $F800	; sprite table ($280 bytes)
vram_hscroll:	equ $FC00	; horizontal scroll table ($380 bytes)

draw_base:	equ vram_fg			; base address for nametables, used by Calc_VRAM_Pos (must be multiple of $4000)
draw_fg:	equ $4000+(vram_fg-draw_base)	; VRAM write command + fg nametable address relative to base
draw_bg:	equ $4000+(vram_bg-draw_base)	; VRAM write command + bg nametable address relative to base

vram_crabmeat:	equ $8000	; crabmeat graphics
vram_bomb:	equ $8000	; bomb enemy graphics
vram_giantring:	equ $8000	; giant ring graphics
vram_orbinaut:	equ $8520	; orbinaut graphics
vram_buzz:	equ $8880	; buzz bomber graphics
vram_yadrin:	equ $8F60	; yadrin graphics
vram_cater:	equ $9FE0	; caterkiller graphics
vram_button:	equ $A1E0	; button graphics
vram_spikes:	equ $A360	; spikes graphics
vram_hspring:	equ $A460	; horizontal spring graphics
vram_vspring:	equ $A660	; vertical spring graphics
vram_animal1:	equ $B000	; animal graphics
vram_animal2:	equ $B240	; animal graphics
vram_credits:	equ $B400	; credits font graphics

vram_title_credits:	equ $14C0	; "Sonic Team Presents" title screen graphics
vram_title:		equ $4000	; main title screen graphics
vram_title_sonic:	equ $6000	; Sonic title screen graphics
vram_title_tm:		equ $A200	; "TM" graphics
vram_text:		equ $D000	; level select text graphics
vram_cont_sonic:	equ $A000	; oval & Sonic continue screen graphics
vram_cont_minisonic:	equ $AA20	; mini Sonic continue screen graphics
vram_error:		equ $F800	; error text graphics

sizeof_cell:		equ $20
sizeof_vram_fg:		equ sizeof_vram_row*32	; fg nametable, assuming 64x32 ($1000 bytes)
sizeof_vram_bg:		equ sizeof_vram_row*32	; bg nametable, assuming 64x32 ($1000 bytes)
sizeof_vram_sonic:	equ $17*sizeof_cell	; Sonic's graphics ($2E0 bytes)
sizeof_vram_sprites:	equ $280
sizeof_vram_hscroll:	equ $380
sizeof_vram_hscroll_padded:	equ $400
sizeof_vram_row:	equ 64*2		; single row of fg/bg nametable, assuming 64 wide
sizeof_art_text:	equ filesize("Graphics\Level Select & Debug Text.bin")
sizeof_art_flowers:	equ filesize("Graphics - Compressed\Ending Flowers.unc")
sizeof_art_giantring:	equ filesize("Graphics\Giant Ring.bin")

countof_color:		equ 16				; colours per palette line
countof_colour:		equ countof_color
countof_pal:		equ 4				; palette lines
sizeof_pal:		equ countof_color*2		; bytes in 1 palette line
sizeof_pal_all:		equ sizeof_pal*countof_pal	; bytes in all palette lines
palfade_line2:		equ sizeof_pal<<8
palfade_line3:		equ (sizeof_pal*2)<<8
palfade_line4:		equ (sizeof_pal*3)<<8
palfade_1:		equ countof_color-1
palfade_2:		equ (countof_color*2)-1
palfade_3:		equ (countof_color*3)-1
palfade_all:		equ (countof_color*4)-1

; Levels
id_GHZ:		equ 0
id_LZ:		equ 1
id_MZ:		equ 2
id_SLZ:		equ 3
id_SYZ:		equ 4
id_SBZ:		equ 5
id_EndZ:	equ 6
id_SS:		equ 7

; Colours
cBlack:		equ $000		; colour black
cWhite:		equ $EEE		; colour white
cBlue:		equ $E00		; colour blue
cGreen:		equ $0E0		; colour green
cRed:		equ $00E		; colour red
cYellow:	equ cGreen+cRed		; colour yellow
cAqua:		equ cGreen+cBlue	; colour aqua
cMagenta:	equ cBlue+cRed		; colour magenta

; Joypad input
btnStart:	equ %10000000 ; Start button	($80)
btnA:		equ %01000000 ; A		($40)
btnC:		equ %00100000 ; C		($20)
btnB:		equ %00010000 ; B		($10)
btnR:		equ %00001000 ; Right		($08)
btnL:		equ %00000100 ; Left		($04)
btnDn:		equ %00000010 ; Down		($02)
btnUp:		equ %00000001 ; Up		($01)
btnDir:		equ %00001111 ; Any direction	($0F)
btnABC:		equ %01110000 ; A, B or C	($70)
bitStart:	equ 7
bitA:		equ 6
bitC:		equ 5
bitB:		equ 4
bitR:		equ 3
bitL:		equ 2
bitDn:		equ 1
bitUp:		equ 0

; Sonic physics
sonic_max_speed:		equ $600
sonic_max_speed_roll:		equ $1000			; rolling
sonic_acceleration:		equ $C
sonic_deceleration:		equ $80
sonic_max_speed_water:		equ sonic_max_speed/2		; underwater
sonic_acceleration_water:	equ sonic_acceleration/2
sonic_deceleration_water:	equ sonic_deceleration/2
sonic_max_speed_shoes:		equ sonic_max_speed*2		; with speed shoes
sonic_acceleration_shoes:	equ sonic_acceleration*2
sonic_deceleration_shoes:	equ sonic_deceleration
sonic_ss_max_speed:		equ $800			; special stage
sonic_jump_power:		equ $680			; initial jump power
sonic_jump_power_water:		equ $380			; initial jump power underwater
sonic_jump_release:		equ $400			; jump speed after releasing A/B/C
sonic_jump_release_water:	equ sonic_jump_release/2

sonic_width:			equ 9				; half width while standing
sonic_height:			equ $13				; half height while standing
sonic_width_roll:		equ 7				; half width while rolling
sonic_height_roll:		equ $E				; half height while rolling

; Object variables
			rsset 0
ost_id:			rs.b 1	; 0 ; object id
ost_render:		rs.b 1	; 1 ; bitfield for x/y flip, display mode
	render_xflip:		equ 1	; xflip
	render_yflip:		equ 2	; yflip
	render_rel:		equ 4	; relative screen position - coordinates are based on the level
	render_abs:		equ 0	; absolute screen position - coordinates are based on the screen (e.g. the HUD)
	render_bg:		equ 8	; align to background
	render_useheight:	equ $10	; use ost_height to decide if object is on screen, otherwise height is assumed to be $20 (used for large objects)
	render_rawmap:		equ $20	; sprites use raw mappings - i.e. object consists of a single sprite instead of multipart sprite mappings (e.g. broken block fragments)
	render_behind:		equ $40	; object is behind a loop (Sonic only)
	render_onscreen:	equ $80	; object is on screen
	render_xflip_bit:	equ 0
	render_yflip_bit:	equ 1
	render_rel_bit:		equ 2
	render_bg_bit:		equ 3
	render_useheight_bit:	equ 4
	render_rawmap_bit:	equ 5
	render_behind_bit:	equ 6
	render_onscreen_bit:	equ 7
ost_tile:		rs.w 1	; 2 ; palette line & VRAM setting (2 bytes)
	tile_xflip:	equ $800
	tile_yflip:	equ $1000
	tile_pal1:	equ 0
	tile_pal2:	equ $2000
	tile_pal3:	equ $4000
	tile_pal4:	equ $6000
	tile_hi:	equ $8000
	tile_xflip_bit:	equ 3
	tile_yflip_bit:	equ 4
	tile_pal12_bit:	equ 5
	tile_pal34_bit:	equ 6
	tile_hi_bit:	equ 7
ost_mappings:		rs.l 1	; 4 ; mappings address (4 bytes)
ost_x_pos:		rs.l 1	; 8 ; x-axis position (2 bytes)
ost_x_sub:		equ ost_x_pos+2	; $A ; x-axis subpixel position (2 bytes)
ost_y_screen:		equ ost_x_pos+2	; $A ; y-axis position for screen-fixed items (2 bytes)
ost_y_pos:		rs.l 1	; $C ; y-axis position (2 bytes)
ost_y_sub:		equ ost_y_pos+2	; $E ; y-axis subpixel position (2 bytes)
ost_x_vel:		rs.w 1	; $10 ; x-axis velocity (2 bytes)
ost_y_vel:		rs.w 1	; $12 ; y-axis velocity (2 bytes)
ost_inertia:		rs.w 1	; $14 ; potential speed (2 bytes)
ost_height:		rs.b 1	; $16 ; height/2
ost_width:		rs.b 1	; $17 ; width/2
ost_priority:		rs.b 1	; $18 ; sprite stack priority - 0 is highest, 7 is lowest
ost_actwidth:		rs.b 1	; $19 ; action width/2
ost_frame:		rs.b 1	; $1A ; current frame displayed
ost_anim_frame:		rs.b 1	; $1B ; current frame in animation script
ost_anim:		rs.b 1	; $1C ; current animation
ost_anim_restart:	rs.b 1	; $1D ; restart animation flag / next animation number (Sonic)
ost_anim_time:		rs.b 1	; $1E ; time to next frame
ost_anim_delay:		rs.b 1	; $1F ; time to delay animation
ost_col_type:		rs.b 1	; $20 ; collision response type - 0 = none; 1-$3F = enemy; $41-$7F = items; $81-BF = hurts; $C1-$FF = custom
ost_col_property:	rs.b 1	; $21 ; collision extra property
ost_status:		rs.b 1	; $22 ; orientation or mode
	status_xflip:		equ 1	; xflip
	status_yflip:		equ 2	; yflip (objects only)
	status_air:		equ 2	; Sonic is in the air (Sonic only)
	status_jump:		equ 4	; jumping or rolling (Sonic only)
	status_platform:	equ 8	; Sonic is standing on this (objects) / Sonic is standing on object (Sonic)
	status_rolljump:	equ $10	; Sonic is jumping after rolling (Sonic only)
	status_pushing:		equ $20	; Sonic is pushing this (objects) / Sonic is pushing an object (Sonic)
	status_underwater:	equ $40	; Sonic is underwater (Sonic only)
	status_broken:		equ $80	; object has been broken (enemies/bosses)
	status_xflip_bit:	equ 0
	status_yflip_bit:	equ 1
	status_air_bit:		equ 1
	status_jump_bit:	equ 2
	status_platform_bit:	equ 3
	status_rolljump_bit:	equ 4
	status_pushing_bit:	equ 5
	status_underwater_bit:	equ 6
	status_broken_bit:	equ 7
ost_respawn:		rs.b 1	; $23 ; respawn list index number
ost_routine:		rs.b 1	; $24 ; routine number
ost_routine2:		rs.b 1	; $25 ; secondary routine number
ost_solid:		equ ost_routine2 ; $25 ; solid status flag
ost_angle:		rs.w 1	; $26 ; angle of floor or rotation - 0 = flat; $40 = vertical left; $80 = ceiling; $C0 = vertical right
ost_subtype:		rs.b 1	; $28 ; object subtype
ost_enemy_combo:	equ $3E	; number of enemies broken in a row (0-$A) (2 bytes)

; Object variables used by Sonic
ost_sonic_flash_time:	equ $30	; time Sonic flashes for after getting hit (2 bytes)
ost_sonic_inv_time:	equ $32	; time left for invincibility (2 bytes)
ost_sonic_shoe_time:	equ $34	; time left for speed shoes (2 bytes)
ost_sonic_angle_right:	equ $36 ; angle of floor on Sonic's right side
ost_sonic_angle_left:	equ $37 ; angle of floor on Sonic's left side
ost_sonic_sbz_disc:	equ $38 ; 1 if Sonic is stuck to SBZ disc

ost_sonic_restart_time:	equ $3A ; time until level restarts (2 bytes)
ost_sonic_jump:		equ $3C ; 1 if Sonic is jumping
ost_sonic_on_obj:	equ $3D	; OST index of object Sonic stands on
ost_sonic_lock_time:	equ $3E	; time left for locked controls, e.g. after hitting a spring (2 bytes)

; Animation flags
afEnd:		equ $FF	; return to beginning of animation
afBack:		equ $FE	; go back (specified number) bytes
afChange:	equ $FD	; run specified animation
afRoutine:	equ $FC	; increment routine counter
afReset:	equ $FB	; reset animation and 2nd object routine counter
af2ndRoutine:	equ $FA	; increment 2nd routine counter
afxflip:	equ $20
afyflip:	equ $40

; 16x16 row/column redraw flags (v_fg_redraw_direction)
redraw_top:		equ 1
redraw_bottom:		equ 2
redraw_left:		equ 4
redraw_right:		equ 8
redraw_topall:		equ $10
redraw_bottomall:	equ $20
redraw_top_bit:		equ 0
redraw_bottom_bit:	equ 1
redraw_left_bit:	equ 2
redraw_right_bit:	equ 3
redraw_topall_bit:	equ 4
redraw_bottomall_bit:	equ 5
redraw_bg2_left_bit:	equ 0 ; REV01 only
redraw_bg2_right_bit:	equ 1 ; REV01 only

; 16x16 and 256x256 mappings
tilemap_xflip:		equ $800
tilemap_yflip:		equ $1000
tilemap_solid_top:	equ $2000
tilemap_solid_lrb:	equ $4000
tilemap_solid_all:	equ $6000
tilemap_xflip_bit:	equ $B
tilemap_yflip_bit:	equ $C
tilemap_solid_top_bit:	equ $D
tilemap_solid_lrb_bit:	equ $E