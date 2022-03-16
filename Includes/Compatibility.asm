; Sonic 1 Github
obRender:		equ ost_render
obGfx:			equ ost_tile
obMap:			equ ost_mappings
obX:			equ ost_x_pos
obScreenY:		equ ost_y_screen
obY:			equ ost_y_pos
obVelX:			equ ost_x_vel
obVelY:			equ ost_y_vel
obInertia:		equ ost_inertia
obWidth:		equ ost_width
obHeight:		equ ost_height
obPriority:		equ ost_priority
obActWid:		equ ost_actwidth
obFrame:		equ ost_frame
obAniFrame:		equ ost_anim_frame
obAnim:			equ ost_anim
obNextAni:		equ ost_anim_restart
obTimeFrame:		equ ost_anim_time
obDelayAni:		equ ost_anim_delay
obColType:		equ ost_col_type
obColProp:		equ ost_col_property
obStatus:		equ ost_status
obRespawnNo:		equ ost_respawn
obRoutine:		equ ost_routine
ob2ndRout:		equ ost_routine2
obAngle:		equ ost_angle
obSubtype:		equ ost_subtype
obSolid:		equ ost_solid
v_256x256:		equ v_256x256_tiles
v_lvllayout:		equ v_level_layout
v_ngfx_buffer:		equ v_nem_gfx_buffer
v_spritequeue:		equ v_sprite_queue
v_16x16:		equ v_16x16_tiles
v_sgfx_buffer:		equ v_sonic_gfx_buffer
v_tracksonic:		equ v_sonic_pos_tracker
v_hscrolltablebuffer:	equ v_hscroll_buffer
v_objspace:		equ v_ost_all
v_player:		equ v_ost_player
v_lvlobjspace:		equ v_ost_level_obj
v_jpadhold2:		equ v_joypad_hold
v_jpadpress2:		equ v_joypad_press
v_jpadhold1:		equ v_joypad_hold_actual
v_jpadpress1:		equ v_joypad_press_actual
v_vdp_buffer1:		equ v_vdp_mode_buffer
v_demolength:		equ v_countdown
v_scrposy_dup:		equ v_fg_y_pos_vsram
v_scrposx_dup:		equ v_fg_x_pos_hscroll
v_hbla_hreg:		equ v_vdp_hint_counter
v_hbla_line:		equ v_vdp_hint_line
v_pfade_start:		equ v_palfade_start
v_pfade_size:		equ v_palfade_size
v_vbla_routine:		equ v_vblank_routine
v_pcyc_num:		equ v_palcycle_num
v_pcyc_time:		equ v_palcycle_time
v_vdp_buffer2:		equ v_vdp_dma_buffer
f_hbla_pal:		equ f_hblank_pal_change
v_waterpos1:		equ v_water_height_actual
v_waterpos2:		equ v_water_height_normal
v_waterpos3:		equ v_water_height_next
f_water:		equ v_water_direction
v_wtr_routine:		equ v_water_routine
f_wtr_state:		equ f_water_pal_full
v_pal_buffer:		equ v_palcycle_buffer
v_ptrnemcode:		equ v_nem_mode_ptr
f_plc_execute:		equ v_nem_tile_count
v_screenposx:		equ v_camera_x_pos
v_screenposy:		equ v_camera_y_pos
v_limitleft1:		equ v_boundary_left_next
v_limitright1:		equ v_boundary_right_next
v_limittop1:		equ v_boundary_top_next
v_limitbtm1:		equ v_boundary_bottom_next
v_limitleft2:		equ v_boundary_left
v_limitright2:		equ v_boundary_right
v_limittop2:		equ v_boundary_top
v_limitbtm2:		equ v_boundary_bottom
v_limitleft3:		equ v_boundary_left_unused
v_scrshiftx:		equ v_camera_x_diff
v_lookshift:		equ v_camera_y_shift
f_nobgscroll:		equ f_disable_scrolling
v_bgscroll1:		equ v_fg_redraw_direction
v_bgscroll2:		equ v_bg1_redraw_direction
v_bgscroll3:		equ v_bg2_redraw_direction
f_bgscrollvert:		equ f_boundary_bottom_change
v_sonspeedmax:		equ v_sonic_max_speed
v_sonspeedacc:		equ v_sonic_acceleration
v_sonspeeddec:		equ v_sonic_deceleration
v_sonframenum:		equ v_sonic_last_frame_id
f_sonframechg:		equ f_sonic_dma_gfx
v_anglebuffer:		equ v_angle_right
v_opl_screen:		equ v_opl_screen_x_pos
v_opl_data:		equ v_opl_ptr_right
v_ssangle:		equ v_ss_angle
v_ssrotate:		equ v_ss_rotation_speed
v_btnpushtime1:		equ v_demo_input_counter
v_btnpushtime2:		equ v_demo_input_time
v_palchgspeed:		equ v_palfade_time
v_collindex:		equ v_collision_index_ptr
v_palss_num:		equ v_palcycle_ss_num
v_palss_time:		equ v_palcycle_ss_time
v_obj31ypos:		equ v_cstomp_y_pos
v_bossstatus:		equ v_boss_status
v_trackpos:		equ v_sonic_pos_tracker_num
v_trackbyte:		equ v_sonic_pos_tracker_num_low
f_lockscreen:		equ f_boss_boundary
v_256loop1:		equ v_256x256_with_loop_1
v_256loop2:		equ v_256x256_with_loop_2
v_256roll1:		equ v_256x256_with_tunnel_1
v_256roll2:		equ v_256x256_with_tunnel_2
v_lani0_frame:		equ v_levelani_0_frame
v_lani0_time:		equ v_levelani_0_time
v_lani1_frame:		equ v_levelani_1_frame
v_lani1_time:		equ v_levelani_1_time
v_lani2_frame:		equ v_levelani_2_frame
v_lani2_time:		equ v_levelani_2_time
v_lani3_frame:		equ v_levelani_3_frame
v_lani3_time:		equ v_levelani_3_time
v_lani4_frame:		equ v_levelani_4_frame
v_lani4_time:		equ v_levelani_4_time
v_lani5_frame:		equ v_levelani_5_frame
v_lani5_time:		equ v_levelani_5_time
v_gfxbigring:		equ v_giantring_gfx_offset
f_conveyrev:		equ f_convey_reverse
v_obj63:		equ v_convey_init_list
f_wtunnelmode:		equ f_water_tunnel_now
f_lockmulti:		equ v_lock_multi
f_wtunnelallow:		equ f_water_tunnel_disable
f_jumponly:		equ f_jump_only
v_obj6B:		equ f_stomp_sbz3_init
f_lockctrl:		equ f_lock_controls
f_bigring:		equ f_giantring_collected
v_itembonus:		equ v_enemy_combo
v_timebonus:		equ v_time_bonus
v_ringbonus:		equ v_ring_bonus
f_endactbonus:		equ f_pass_bonus_update
v_sonicend:		equ v_end_sonic_routine
f_switch:		equ v_button_state
v_spritetablebuffer:	equ v_sprite_buffer
v_pal_water_dup:	equ v_pal_water_next
v_pal_dry_dup:		equ v_pal_dry_next
v_objstate:		equ v_respawn_list
v_framecount:		equ v_frame_counter
v_framebyte:		equ v_frame_counter_low
v_debugitem:		equ v_debug_item_index
v_debuguse:		equ v_debug_active
v_debugxspeed:		equ v_debug_move_delay
v_debugyspeed:		equ v_debug_move_speed
v_vbla_count:		equ v_vblank_counter
v_vbla_word:		equ v_vblank_counter_word
v_vbla_byte:		equ v_vblank_counter_byte
v_airbyte:		equ v_air+1
v_lastspecial:		equ v_last_ss_levelid
f_timeover:		equ f_time_over
v_lifecount:		equ v_ring_reward
f_lifecount:		equ f_hud_lives_update
f_ringcount:		equ v_hud_rings_update
f_timecount:		equ f_hud_time_update
f_scorecount:		equ f_hud_score_update
v_ringbyte:		equ v_rings+1
v_timemin:		equ v_time_min
v_timesec:		equ v_time_sec
v_timecent:		equ v_time_frames
v_invinc:		equ v_invincibility
v_lastlamp:		equ v_last_lamppost
v_lamp_xpos:		equ v_sonic_x_pos_lampcopy
v_lamp_ypos:		equ v_sonic_y_pos_lampcopy
v_lamp_rings:		equ v_rings_lampcopy
v_lamp_time:		equ v_time_lampcopy
v_lamp_dle:		equ v_dle_routine_lampcopy
v_lamp_limitbtm:	equ v_boundary_bottom_lampcopy
v_lamp_scrx:		equ v_camera_x_pos_lampcopy
v_lamp_scry:		equ v_camera_y_pos_lampcopy
v_lamp_wtrpos:		equ v_water_height_normal_lampcopy
v_lamp_wtrrout:		equ v_water_routine_lampcopy
v_lamp_wtrstat:		equ f_water_pal_full_lampcopy
v_lamp_lives:		equ v_ring_reward_lampcopy
v_emldlist:		equ v_emerald_list
v_oscillate:		equ v_oscillating_direction
v_ani0_time:		equ v_syncani_0_time
v_ani0_frame:		equ v_syncani_0_frame
v_ani1_time:		equ v_syncani_1_time
v_ani1_frame:		equ v_syncani_1_frame
v_ani2_time:		equ v_syncani_2_time
v_ani2_frame:		equ v_syncani_2_frame
v_ani3_time:		equ v_syncani_3_time
v_ani3_frame:		equ v_syncani_3_frame
v_ani3_buf:		equ v_syncani_3_accumulator
v_limittopdb:		equ v_boundary_top_debugcopy
v_limitbtmdb:		equ v_boundary_bottom_debugcopy
v_levseldelay:		equ v_levelselect_hold_delay
v_levselitem:		equ v_levelselect_item
v_levselsound:		equ v_levelselect_sound
v_scorecopy:		equ v_highscore
v_scorelife:		equ v_score_next_life
f_levselcheat:		equ f_levelselect_cheat
f_slomocheat:		equ f_slowmotion_cheat
f_debugcheat:		equ f_debug_cheat
f_creditscheat:		equ f_credits_cheat
v_title_dcount:		equ v_title_d_count
v_title_ccount:		equ v_title_c_count
f_demo:			equ v_demo_mode
v_demonum:		equ v_demo_num
v_creditsnum:		equ v_credits_num
v_megadrive:		equ v_console_region
f_debugmode:		equ f_debug_enable
v_init:			equ v_checksum_pass
;AddPoints
;AnimateSprite
;CalcSine
;CalcAngle
ChkObjectVisible:	equ CheckOffScreen
ChkPartiallyVisible:	equ CheckOffScreen_Wide
;CollectRing
;DebugMode
;DeleteObject
;DeleteChild
RememberState:		equ DespawnObject
PlatformObject:		equ DetectPlatform
;Plat_NoXCheck
Platform3:		equ Plat_NoXCheck_AltY
loc_74AE:		equ Plat_NoCheck
;DisplaySprite
DisplaySprite1:		equ DisplaySprite_a1
;ExitPlatform
;ExitPlatform2
ObjFloorDist:		equ FindFloorObj
ObjFloorDist2:		equ FindFloorObj2
ObjHitWallRight:	equ FindWallRightObj
ObjHitCeiling:		equ FindCeilingObj
ObjHitWallLeft:		equ FindWallLeftObj
;FindFreeObj
;FindNextFreeObj
;FindNearestTile
;FindFloor
;FindFloor2
;FindWall
;FindWall2
MvSonicOnPtfm:		equ MoveWithPlatform
MvSonicOnPtfm2:		equ MoveWithPlatform2
;ObjectFall
;SpeedToPos
;RandomNumber
;ReactToItem
;HurtSonic
;KillSonic
;ResumeMusic
;SlopeObject
SlopeObject2:		equ SlopeObject_NoChk
;SolidObject
SolidObject71:		equ SolidObject_NoRenderChk
SolidObject2F:		equ SolidObject_Heightmap
;SmashObject
;Sonic_Main
;Sonic_Control
;Sonic_Hurt
;Sonic_Death
;Sonic_ResetLevel
Sonic_MdNormal:		equ Sonic_Mode_Normal
Sonic_MdJump:		equ Sonic_Mode_Air
Sonic_MdRoll:		equ Sonic_Mode_Roll
Sonic_MdJump2:		equ Sonic_Mode_Jump
;Sonic_Display
;Sonic_RecordPosition
;Sonic_Water
;Sonic_Animate
Sonic_Loops:		equ Sonic_LoopPlane
;Sonic_LoadGfx
;Sonic_Jump
;Sonic_SlopeResist
;Sonic_Move
;Sonic_Roll
;Sonic_LevelBound
;Sonic_AnglePos
;Sonic_SlopeRepel
;Sonic_JumpHeight
;Sonic_JumpDirection
;Sonic_JumpAngle
Sonic_Floor:		equ Sonic_JumpCollision
;Sonic_RollRepel
;Sonic_RollSpeed
;Sonic_ResetOnFloor
;Sonic_HurtStop
;GameOver
;Sonic_Angle
;Sonic_WalkVertR
;Sonic_WalkCeiling
;Sonic_WalkVertL
Sonic_WalkSpeed:	equ Sonic_CalcRoomAhead
sub_14D48:		equ Sonic_CalcHeadroom
Sonic_HitFloor:		equ Sonic_FindFloor
loc_14DF0:		equ Sonic_FindFloor_Quick
loc_14E0A:		equ Sonic_SnapAngle
sub_14E50:		equ Sonic_FindWallRight
sub_14EB4:		equ Sonic_FindWallRight_Quick_UsePos
loc_14EBC:		equ Sonic_FindWallRight_Quick
Sonic_DontRunOnWalls:	equ Sonic_FindCeiling
loc_14F7C:		equ Sonic_FindCeiling_Quick
loc_14FD6:		equ Sonic_FindWallLeft
Sonic_HitWall:		equ Sonic_FindWallLeft_Quick_UsePos
loc_1504A:		equ Sonic_FindWallLeft_Quick

; Sonic 1 2005
ChkObjOnScreen:		equ CheckOffScreen
ChkObjOnScreen2:	equ CheckOffScreen_Wide
DeleteObject2:		equ DeleteChild
MarkObjGone:		equ DespawnObject
Platform2:		equ Plat_NoXCheck
DisplaySprite2:		equ DisplaySprite_a1
ObjHitFloor:		equ FindFloorObj
ObjHitFloor2:		equ FindFloorObj2
SingleObjLoad:		equ FindFreeObj
SingleObjLoad2:		equ FindNextFreeObj
Floor_ChkTile:		equ FindNearestTile
TouchResponse:		equ ReactToItem
Obj01_Main:		equ Sonic_Main
Obj01_Control:		equ Sonic_Control
Obj01_Hurt:		equ Sonic_Hurt
Obj01_Death:		equ Sonic_Death
Obj01_ResetLevel:	equ Sonic_ResetLevel
Obj01_MdNormal:		equ Sonic_Mode_Normal
Obj01_MdJump:		equ Sonic_Mode_Air
Obj01_MdRoll:		equ Sonic_Mode_Roll
Obj01_MdJump2:		equ Sonic_Mode_Jump
Sonic_RecordPos:	equ Sonic_RecordPosition
LoadSonicDynPLC:	equ Sonic_LoadGfx
Sonic_ChgJumpDir:	equ Sonic_JumpDirection

; Sonic 2 Github
id:			equ ost_id
render_flags:		equ ost_render
art_tile:		equ ost_tile
mappings:		equ ost_mappings
x_pos:			equ ost_x_pos
x_sub:			equ ost_x_sub
y_pos:			equ ost_y_pos
y_sub:			equ ost_y_sub
priority:		equ ost_priority
width_pixels:		equ ost_actwidth
mapping_frame:		equ ost_frame
x_vel:			equ ost_x_vel
y_vel:			equ ost_y_vel
y_radius:		equ ost_height
x_radius:		equ ost_width
anim_frame:		equ ost_anim_frame
anim:			equ ost_anim
prev_anim:		equ ost_anim_restart
anim_frame_duration:	equ ost_anim_time
status:			equ ost_status
routine:		equ ost_routine
routine_secondary:	equ ost_routine2
angle:			equ ost_angle
collision_flags:	equ ost_col_type
collision_property:	equ ost_col_property
respawn_index:		equ ost_respawn
subtype:		equ ost_subtype
inertia:		equ ost_inertia
flip_angle:		equ ost_angle+1
air_left:		equ ost_subtype
flip_turned:		equ $29
obj_control:		equ $2A
status_secondary:	equ $2B
flips_remaining:	equ $2C
flip_speed:		equ $2D
move_lock:		equ $2E
invulnerable_time:	equ ost_sonic_flash_time
invincibility_time:	equ ost_sonic_inv_time
speedshoes_time:	equ ost_sonic_shoe_time
next_tilt:		equ ost_sonic_angle_right
tilt:			equ ost_sonic_angle_left
stick_to_convex:	equ ost_sonic_sbz_disc
spindash_flag:		equ $39
pinball_mode:		equ spindash_flag
spindash_counter:	equ ost_sonic_restart_time
restart_countdown:	equ ost_sonic_restart_time
jumping:		equ ost_sonic_jump
interact:		equ ost_sonic_on_obj
top_solid_bit:		equ $3E
lrb_solid_bit:		equ $3F
y_pixel:		equ ost_y_screen
x_pixel:		equ ost_x_pos
parent:			equ $3E
button_up:		equ bitUp
button_down:		equ bitDn
button_left:		equ bitL
button_right:		equ bitR
button_B:		equ bitB
button_C:		equ bitC
button_A:		equ bitA
button_start:		equ bitStart
button_up_mask:		equ btnUp
button_down_mask:	equ btnDn
button_left_mask:	equ btnL
button_right_mask:	equ btnR
button_B_mask:		equ btnB
button_C_mask:		equ btnC
button_A_mask:		equ btnA
button_start_mask:	equ btnStart