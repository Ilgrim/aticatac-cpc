init_doors
;
;   ix + 2
;   bit 7           0 = open, 1 = closed or locked
;   bit 6           0 = keyed door, 1 = revolving door
;   bit 5, 4, 3     open / close time (0 = 3, 1 = 4, 2 = 5, 3 = 6)
;   bit 2, 1, 0     current time

    SELECT_BANK room_bank_config

    ld bc, (end_room_bank_item_list - room_bank_item_list) / 16 ; (8 bytes per item, but they're in pairs so do both together)
    ld ix, room_bank_item_list
    ld de, 16
    ld iyl, 0

    ld a, r
    ld (random_seed), a    

init_door_loop
    push bc

    ld a, (ix + 7)              ; is this item actually a type of door?
    and a
    jr z, init_next_door

    set 7, (ix + 2)
    set 7, (ix + 10)            ; lock and close all doors...

    ld a, (ix + 0)              ; item type
    cp active_door_trapdoor
    jr z, revolving_door

    ld c, a
    RANDOM_IN_A
    cp 179                                 ; randomly select roughly 70% of the automatic doors to work 
    jp c, skip_revolving_door_this_time    

    ld a, c
    cp active_door_cave
    jr z, revolving_door

    cp active_door_normal
    jr z, revolving_door

skip_revolving_door_this_time
    res 6, (ix + 2)
    res 6, (ix + 10)
    jr init_next_door

revolving_door
    set 6, (ix + 2)
    set 6, (ix + 10)

    RANDOM_IN_A
    and 0x07
    sla a
    sla a
    sla a

    or iyl

    or (ix + 2)
    ld (ix + 2), a
    ld (ix + 10), a

    inc iyl
    ld a, iyl
    and 0x07
    ld iyl, a

init_next_door
    add ix, de

    pop bc
    dec bc
    ld a, b
    or c
    jr nz, init_door_loop

    ret

check_doors
    ld hl, (collision_info)          ; only check doors if all corners of player are touching same object.
    ld a, l
    and a
    ret z

    cp h
    ret nz

    ld hl, (collision_info + 2)

    cp l
    ret nz
    cp h
    ret nz

    dec a                           ; a is the door index in this_rooms_door_list we're fully stood on...
    ld ixl, a
    ld ixh, 0
    add ix, ix
    add ix, ix
    add ix, ix
    ld de, this_rooms_door_list
    add ix, de

    ld a, (ix + 0)
    cp active_door_trapdoor
    jp z, trapdoor_collision

    ld a, (keys_pressed)            ; can't exit if not pressing any direction key...
    ld c, a
    and 0x0f
    ret z

    ld e, (ix + 3)                  ; get orientation of door
    ld d, (ix + 4)
    ld hl, 5
    add hl, de

    SELECT_BANK room_bank_config
    ld a, (hl)

    cp rotation_right
    jp z, check_left_down

    cp rotation_left
    jp z, check_right_down

    cp rotation_bottom
    jp z, check_up_down

    cp rotation_top
    jp z, check_down_down
    ret

check_left_down
    bit player_left_bit, c
    jp z, do_collision
    ret

check_right_down
    bit player_right_bit, c
    jp z, do_collision
    ret

check_up_down
    bit player_up_bit, c
    jp z, do_collision
    ret

check_down_down
    bit player_down_bit, c
    jp z, do_collision
    ret

trapdoor_collision
    ld e, (ix + 3)
    ld d, (ix + 4)
    inc de
    inc de

    SELECT_BANK room_bank_config
    ld a, (de)

    bit 7, a
    ret nz

    ld l, (ix + 3)
    ld h, (ix + 4)

    ld bc, -8               ; We want this items twin now to work out new position of player
    ld a, (ix + 7)
    and a
    jp nz, trapdoor_coll_1
    ld bc, 8

trapdoor_coll_1    
    add hl, bc              ; hl now points to item to move to 1 = room number, 3 = x, 4 = y, 5 = rotation, etc
    inc hl

    ld a, (hl)              ; move to room this item is in
    ld (room_number), a
    
    ld b, state_falling
    call switch_game_state
    ret

do_collision
    ld l, (ix + 3)
    ld h, (ix + 4)          ; hl is pointer to item in room_bank_item_list

    ld bc, -8               ; We want this items twin now to work out new position of player
    ld a, (ix + 7)
    and a
    jp nz, collide1
    ld bc, 8

collide1
    add hl, bc              ; hl now points to item to move to 1 = room number, 3 = x, 4 = y, 5 = rotation, etc

    call get_new_door_dimensions

    ld a, (room_number)
    ld (last_room_number), a

    inc hl
    ld a, (hl)              ; move to room this item is in
    ld (room_number), a
    
    ld a, 1
    ld (room_changed), a
    ld (screen_transition_in_progress), a

    inc hl
    inc hl
    ld b, (hl)              ; x of new door
    srl b                   ; divide by 2
    inc hl
    ld c, (hl)              ; y of new door (bottom y)
    inc hl

    ld a, (hl)              ; rotation of new door
    and 0xfe                ; ignore smallest bit

    ld hl, collision_info   ; clear collision info
    ld (hl), 0
    ld hl, collision_info + 2
    ld (hl), 0

; b has new door x, c has new door bottom y, a has new door rotation, hl pointer to new door
    cp rotation_top
    jp z, portrait_coll_top
    cp rotation_bottom
    jp z, portrait_coll_bot
    cp rotation_left    
    jp z, landscape_coll_left

landscape_coll_right
    ld a, b
    sub player_width - 1
    add 2
    ld (player_x), a

    ld a, (this_item_width)
    sla a
    ld b, a
    ld a, c
    sub b
    sub average_player_height / 2
    ld (player_y), a
    ret    

landscape_coll_left
    ld a, (this_item_height)
    srl a
    srl a
    add b
    ld (player_x), a

    ld a, (this_item_width)
    sla a
    ld b, a
    ld a, c
    sub b
    sub average_player_height / 2
    ld (player_y), a
    ret    

portrait_coll_bot
    ld a, (this_item_height)
    ld d, a
    ld a, c
    sub d
    sub average_player_height
    add 12
    ld (player_y), a

    ld a, (this_item_width)
    add b
    sub player_width
    inc a
    ld (player_x), a
    ret    

portrait_coll_top
    ld a, c
    sub 12
    ld (player_y), a

    ld a, (this_item_width)
    add b   
    sub player_width
    inc a
    ld (player_x), a
    ret

get_new_door_dimensions             ; hl is pointer to item in room_bank_item_list
    push hl
    push bc
    
    ld a, (hl)      ; item type
    ld l, a
    ld h, 0
    add hl, hl
    ld de, item_bank_items
    add hl, de

    SELECT_BANK item_bank_config

    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a         ; hl now has our item

    ld a, (hl)
    ld (this_item_width), a
    inc hl
    ld a, (hl)
    ld (this_item_height), a

    SELECT_BANK room_bank_config

    pop bc
    pop hl
    ret

;
;   ix + 2
;
;   bit 7           0 = open, 1 = closed or locked
;   bit 6           0 = keyed door, 1 = revolving door
;   bit 5, 4, 3     open / close time (0 = 3, 1 = 4, 2 = 5, 3 = 6)
;   bit 2, 1, 0     current time    
    
update_doors
    ld a, (this_rooms_door_count)
    ld b, a
    ld ix, this_rooms_door_list         ; list of items in 'exploded' format

update_doors_loop
    ld l, (ix + 3)
    ld h, (ix + 4)              ; get real item pointer
    inc hl
    inc hl                      ; increment by 2 to get to door control byte (eg. ix + 2)

    ld a, (hl)
    bit 6, a                   ; is door a revolving door
    jp z, do_next_door

    ld e, a
    ld c, a

    inc a
    and 0x07

    ld d, a
    ld a, c
    and %00111000
    srl a
    srl a
    srl a
    cp d
    jp nz, door_not_hit_counter

    ld a, e
    and %11111000               ; keep the original values, set count to 0
    xor %10000000               ; and toggle the open/close status
    ld (hl), a

    ld e, (ix + 3)
    ld d, (ix + 4)

    ld ixh, d
    ld ixl, e

    ld a, (ix + 0)                  ; special case for trapdoor - have to xor the grill image
    cp active_door_trapdoor
    jp z, xor_the_trapdoor_grill

    ld (door_to_toggle), de    
    jp draw_item

door_not_hit_counter
    ld a, e
    and %11111000
    or d
    ld (hl), a

do_next_door
    ld de, 8
    add ix, de
    djnz update_doors_loop
    ret

xor_the_trapdoor_grill
    ld a, (ix + 4)
    sub 22
    ld h, 0
    ld l, a
    add hl, hl
    ld de, (scr_addr_table)
    add hl, de

    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a

    ld a, (ix + 3)
    srl a
    srl a
    add 2
    ld e, a
    ld d, 0
    add hl, de

    SELECT_BANK item_bank_config

    push hl
    call do_the_grill

    pop hl
    ld a, h
    xor 0x40
    ld h, a

do_the_grill
    ld de, trapdoor_grill
    ld b, 14

xor_grill_loop
    ld a, (de)
    xor (hl)
    ld (hl), a
    inc l
    inc de

    ld a, (de)
    xor (hl)
    ld (hl), a
    inc l
    inc de

    ld a, (de)
    xor (hl)
    ld (hl), a
    inc l
    inc de

    ld a, (de)
    xor (hl)
    ld (hl), a
    inc de    

    dec l
    dec l
    dec l
    GET_NEXT_SCR_LINE
    djnz xor_grill_loop        
    ret

door_to_toggle
    defw 0x0000