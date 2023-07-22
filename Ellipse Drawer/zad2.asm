; Andrzej Waclawik

    .387

code_ segment

; ----------------------
input1  db 202 dup('$')

error_text  db "Blad w argumentach", 10, 13, "$"
endl    db  10, 13, "$"

arg1    db  30 dup('$')
arg2    db  30 dup('$')

x       dw  ?
y       dw  ?
k       db  ?

a       dw  ?
b       dw  ?

tmp1    dw  ?
; ----------------------

program_:
    mov dx, seg stack_
    mov ss, dx
    mov sp, offset wstack_

; input part --------v
    mov ax, seg input1
    mov es, ax
    mov si, 082h                    ; si - input iterator
    mov di, offset input1           ; di - buffer iterator
    xor cx, cx
    mov cl, byte ptr ds:[080h]      ; cx - num of bytes in input
    
    cmp cl, 0d
    je print_error_and_end          ; check if empty input
    cmp cl, 200d
    ja print_error_and_end          ; check if input is too big
    
input_loop:
    push cx
    mov al, byte ptr ds:[si]
    mov byte ptr es:[di], al
    inc si
    inc di
    pop cx
    loop input_loop
    mov byte ptr es:[di], '$'
;input_loop
    ; now input is in input1

    mov ax, seg code_               ; from now ds refers to code segment
    mov ds, ax

    ;mov dx, offset input1          ; debug print arguments
    ;call print_dx
    ;mov dx, offset endl
    ;call print_dx

    call parse_input
    ; now two first args are in arg1 and arg2

    mov bx, offset arg1
    call extract_number
    push ax
    
    mov bx, offset arg2
    call extract_number
    push ax

    pop ax
    mov dl, 2d
    div dl
    xor ah, ah          ; ax= b
    cmp ax, 100d
    jne do_not_dec_b
    dec ax
do_not_dec_b:
    mov di, ax          ; di= b

    pop ax
    mov dl, 2d
    div dl
    xor ah, ah
    mov si, ax          ; si= a

    ; call end_program

; VGA part ----------v

    mov al, 13h     ; VGA mode (320x200 256 col)
    mov ah, 0
    int 10h

    ; si <- a
    ; di <- b
    mov word ptr ds:[k], 0fh    ; white color
    jmp make_drawing

drawing_place:

    pressed_up_arrow:
        call clear_screen
        cmp di, 99d
        jae make_drawing
        inc di
        jmp make_drawing

    pressed_down_arrow:
        call clear_screen
        cmp di, 1d
        jbe make_drawing
        dec di
        jmp make_drawing

    pressed_left_arrow:
        call clear_screen
        cmp si, 1d
        jbe make_drawing
        dec si
        jmp make_drawing

    pressed_right_arrow:
        call clear_screen
        cmp si, 159d
        jae make_drawing
        inc si
        jmp make_drawing
    
    pressed_r_key:
        call clear_screen
        xchg di, si
        cmp di, 99d
        jbe make_drawing
        mov di, 99d
        jmp make_drawing

    pressed_x_key:
        call clear_screen
        mov si, 159d
        mov di, 99d
        jmp make_drawing

    pressed_0_key:
        mov word ptr ds:[k], 0fh    ; white
        jmp make_drawing
    
    pressed_1_key:
        mov word ptr ds:[k], 28h    ; red
        jmp make_drawing

    pressed_2_key:
        mov word ptr ds:[k], 2fh    ; green
        jmp make_drawing

    pressed_3_key:
        mov word ptr ds:[k], 20h    ; blue
        jmp make_drawing

    pressed_4_key:
        mov word ptr ds:[k], 0bh    ; cyan
        jmp make_drawing

    pressed_5_key:
        mov word ptr ds:[k], 24h    ; magenta
        jmp make_drawing

    pressed_6_key:
        mov word ptr ds:[k], 2ch    ; yellow
        jmp make_drawing
    

    make_drawing:
        call draw_elipse

        xor ax, ax
        int 16h         ; wait for key

        cmp ah, 1d      ; check if ESC
        je stop_drawing

        cmp ah, 48h
        je pressed_up_arrow

        cmp ah, 50h
        je pressed_down_arrow
        
        cmp ah, 4bh
        je pressed_left_arrow

        cmp ah, 4dh
        je pressed_right_arrow

        cmp ah, 19d
        je pressed_r_key

        cmp ah, 45d
        je pressed_x_key

        cmp ah, 11d
        je pressed_0_key

        cmp ah, 2d
        je pressed_1_key

        cmp ah, 3d
        je pressed_2_key
        
        cmp ah, 4d
        je pressed_3_key

        cmp ah, 5d
        je pressed_4_key

        cmp ah, 6d
        je pressed_5_key

        cmp ah, 7d
        je pressed_6_key
    
        jmp make_drawing


stop_drawing:
    mov al, 3h      ; tryb tekstowy
    mov ah, 0
    int 10h

    call end_program

; ---------------------------------------
; FUNCTIONS -----------------------------

print_dx::       ; print text from ds:dx
    mov ah, 09h
    int 21h
    ret
;print_dx


print_error_and_end::
    mov ax, seg code_
    mov ds, ax
    mov dx, offset error_text
    call print_dx
    call end_program
;print_error_and_end


clear_screen::
    push word ptr ds:[k]
    mov word ptr ds:[k], 0h
    call draw_elipse
    pop word ptr ds:[k]
    ret
;call_screen


parse_input::
    xor si, si

    call skip_whitespace_characters
    mov ah, byte ptr es:[si]
    cmp ah, 24h                 ; ah <> '$'
    je print_error_and_end

    mov bx, offset arg1
    xor di, di
    call inject_word

    call skip_whitespace_characters
    mov ah, byte ptr es:[si]
    cmp ah, 24h                 ; ah <> '$'
    je print_error_and_end

    mov bx, offset arg2
    xor di, di
    call inject_word

    call skip_whitespace_characters
    mov ah, byte ptr es:[si]
    cmp ah, 24h                 ; ah <> '$'
    jne print_error_and_end

    ret
;parse_input


skip_whitespace_characters::     ; check from si pointer
    mov ah, byte ptr es:[si]

    cmp ah, 20h         ; check ' '
    je continue

    cmp ah, 9h          ; check TAB
    je continue

    ; cmp ah, 24h         ; check '$'
    ; je continue

    cmp ah, 0dh          ; check CR
    je continue

    ret

continue:
    inc si
    jmp skip_whitespace_characters

;skip_whitespace_characters


inject_word::                    ; while not whitespace: save characters
; using: ax, bx, cx, si, di

    mov ah, byte ptr es:[si]    ; ah= byte in iteration
    inc si

    cmp ah, 20h         ; check ' '
    je end_inject_word

    cmp ah, 09h          ; check TAB
    je end_inject_word

    cmp ah, 24h         ; check '$'
    je end_inject_word

    cmp ah, 0dh         ; check CR
    je end_inject_word

    mov byte ptr ds:[bx + di], ah   ; write byte
    inc di

    jmp inject_word
    ret

end_inject_word:
    dec cx
    ret

;inject_word


extract_number::        ; input offset in bx
    xor ax, ax
    xor dx, dx
    xor si, si
    mov cx, 3d

loop2:
    mov dl, byte ptr ds:[bx + si]
    cmp dl, '$'
    je after_loop2

    sub dl, 48d         ; dl = digit
    cmp dl, 0d
    jl print_error_and_end
    cmp dl, 9d
    jg print_error_and_end

    mov dh, 10d
    mul dh              ; ax= ax * 10 ...
    xor dh, dh
    add ax, dx          ; ... + [new digit]
    inc si
    loop loop2
;loop2

after_loop2:

    cmp byte ptr ds:[bx + si], '$'
    jne print_error_and_end

    ; cmp ax, 0d
    ; je print_error_and_end

    cmp ax, 200d
    ja print_error_and_end

    ret
;extract_number


draw_elipse::       ; a and b in si and di
    xor ax, ax
    mov cx, 6282d   ; cx= 2 * pi * 1000
    
loop1:
    mov word ptr ds:[a], si
    mov word ptr ds:[b], di

    finit
    mov word ptr ds:[tmp1], ax
    fild word ptr ds:[tmp1]
    mov word ptr ds:[tmp1], 1000d
    fidiv word ptr ds:[tmp1]
    fcos
    fild word ptr ds:[a]
    fmul
    fist word ptr ds:[x]

    finit
    mov word ptr ds:[tmp1], ax
    fild word ptr ds:[tmp1]
    mov word ptr ds:[tmp1], 1000d
    fidiv word ptr ds:[tmp1]
    fsin
    fild word ptr ds:[b]
    fmul
    fist word ptr ds:[y]

    push ax
    add word ptr ds:[x], 160d       ; v-----------
    neg word ptr ds:[y]
    add word ptr ds:[y], 100d       ; ^----- centering result
    call light_pixel
    pop ax
    inc ax
    loop loop1

    ret
;draw_elipse


light_pixel::       ; data in x and y offsets
    mov ax, 0a000h
    mov es, ax
    mov ax, word ptr ds:[y]
    mov bx, 320d
    mul bx      ; result in ax
    mov bx, word ptr ds:[x]
    add bx, ax
    mov al, byte ptr ds:[k]
    mov byte ptr es:[bx], al
    ret
;light_pixel

end_program::
    mov al, 0
    mov ah, 4ch
    int 21h
;end_program

code_ ends


stack_ segment stack
        dw 300 dup(?)
wstack_ dw ?
stack_ ends


end program_