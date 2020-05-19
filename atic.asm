include "includes.asm"

start
    xor a
    call scr_set_mode

    call wait_vsync
    call set_pens_off

    ld d, hw_black
    call set_border                ; border to black

    call set_screen_size
    call setup_game_data
    
    call install_interrupts

    jp $                            ; spin here, interrupts will handle flow

setup_game_data
    call make_scr_table
    ld hl, scr_addr_table_c0
    ld (scr_addr_table), hl

    ld a, mode_game
    call switch_mode

    ld ix, player_k1_p0
    ld de, player_k1_p1
    ld bc, 0x0436                   ; 4 bytes wide, 18 x 3 high
    call rotate_gfx

    ld ix, player_k1_pu0
    ld de, player_k1_pu1
    ld bc, 0x0436                   ; 4 bytes wide, 18 x 3 high
    call rotate_gfx

    ld ix, player_k1_l0
    ld de, player_k1_l1
    ld bc, 0x0436                   ; 4 bytes wide, 18 x 3 high
    call rotate_gfx

    ld ix, player_k1_r0
    ld de, player_k1_r1
    ld bc, 0x0436                   ; 4 bytes wide, 18 x 3 high
    call rotate_gfx

    ret

switch_mode
    ld b, a

    ld l, a
    ld h, 0
    add hl, hl
    ld de, mode_table
    add hl, de
    
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    
    ld (current_interrupts), hl

	ld a, interrupt_notReady
	ld (interrupt_index), a

    ld a, b
    cp mode_menu
    jp z, select_menu

    cp mode_game
    jp z, select_game

    cp mode_end
    jp z, select_end

    ret

select_menu
    call wait_vsync
    call set_pens_off

    call clear_screen

    call set_pens
    ret

select_game
    call wait_vsync
    call set_pens_off

    call clear_screen

    xor a
    ld (room_number), a
    ld (player_frame), a
    ld (player_orientation), a

    inc a
    ld (room_changed), a

    ld a, 0x2c
    ld (player_x), a

    ld a, 0x57
    ld (player_y), a    

    call draw_panel
    call set_pens
    ret

select_end
    ret

clear_screen
    ld hl, 0xc000
    ld de, 0xc001
    ld bc, 0x3fff
    ld (hl), 0
    ldir
    ret

mode_table
    defw menu_interrupts
    defw game_interrupts
