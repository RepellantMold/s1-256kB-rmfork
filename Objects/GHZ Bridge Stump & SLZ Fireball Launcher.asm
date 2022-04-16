; ---------------------------------------------------------------------------
; Object 1C - scenery (GHZ bridge stump, SLZ lava thrower)

; spawned by:
;	ObjPos_GHZ1, ObjPos_GHZ2, ObjPos_GHZ3 - subtype 3
;	ObjPos_SLZ1, ObjPos_SLZ2, ObjPos_SLZ3 - subtype 0
; ---------------------------------------------------------------------------

Scenery:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Scen_Index(pc,d0.w),d1
		jmp	Scen_Index(pc,d1.w)
; ===========================================================================
Scen_Index:	index *
		ptr Scen_Main
		ptr Scen_ChkDel
; ===========================================================================

Scen_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Scen_ChkDel next
		moveq	#0,d0
		move.b	ost_subtype(a0),d0			; copy object subtype to d0
		lea	Scen_Values(pc,d0.w),a1
		move.l	(a1)+,ost_mappings(a0)
		move.w	(a1)+,ost_tile(a0)
		ori.b	#render_rel,ost_render(a0)
		move.b	(a1)+,ost_frame(a0)
		move.b	(a1)+,ost_actwidth(a0)
		move.b	(a1)+,ost_priority(a0)

Scen_ChkDel:	; Routine 2
		out_of_range	DeleteObject
		bra.w	DisplaySprite
		
; ---------------------------------------------------------------------------
; Variables for	object $1C are stored in an array
; ---------------------------------------------------------------------------
Scen_Values:
Scen_Values_0:	dc.l Map_Scen					; mappings address
		dc.w $3F9+tile_pal3		; VRAM setting
		dc.b id_frame_scen_cannon, 8, 2, 0		; frame, width, priority, collision response
		
Scen_Values_3:	dc.l Map_Bri
		dc.w $33E+tile_pal3
		dc.b id_frame_bridge_stump, $10, 1, 0
		even
