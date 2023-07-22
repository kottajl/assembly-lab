; Andrzej Waclawik

data_ segment

buf1        db 40, ?, 41 dup('$') ; input bufor
buf2        db 11 dup('$') ; word (first digit) bufor
buf3        db 11 dup('$') ; word (operator) bufor
buf4        db 11 dup('$') ; word (second digit) bufor
prompt1     db "Wprowadz slowny opis dzialania: $"
prompt2     db "Wynikiem jest: $"
error_text  db "Blad danych wejsciowych!", 10, 13, "$"
endl        db 10, 13, "$"

digit0      db "zero$"
digit1      db "jeden$"
digit2      db "dwa$"
digit3      db "trzy$"
digit4      db "cztery$"
digit5      db "piec$"
digit6      db "szesc$"
digit7      db "siedem$"
digit8      db "osiem$"
digit9      db "dziewiec$"

num10       db "dziesiec$"
num11       db "jedenascie$"
num12       db "dwanascie$"
num13       db "trzynascie$"
num14       db "czternascie$"
num15       db "pietnascie$"
num16       db "szesnascie$"
num17       db "siedemnascie$"
num18       db "osiemnascie$"
num19       db "dziewietnascie$"

num20       db "dwadziescia$"
num30       db "trzydziesci$"
num40       db "czterdziesci$"
num50       db "piedziesiat$"
num60       db "szescdziesiat$"
num70       db "siedemdziesiat$"
num80       db "osiemdziesiat$"

op1         db "plus$"
op2         db "minus$"
op3         db "razy$"

small_numbers    dw offset digit0, offset digit1, offset digit2, offset digit3, offset digit4,
                    offset digit5, offset digit6, offset digit7, offset digit8, offset digit9, 
                    offset num10,  offset num11,  offset num12,  offset num13,  offset num14,
                    offset num15,  offset num16,  offset num17,  offset num18

big_numbers      dw offset num20,  offset num30,  offset num40,  offset num50,  offset num60, 
                    offset num70,  offset num80

data_ ends


code_ segment
program_:

    mov ax, stack_
    mov ss, ax
    mov sp, offset wstack_

    mov ax, data_
    mov ds, ax

    mov dx, offset prompt1
    call print_dx
    mov dx, offset buf1
    call input_dx             ; first input
    mov dx, offset endl
    call print_dx

    ; injecting words from output -----v

    mov bx, offset buf1
    mov cl, byte ptr [bx + 1]        ; cx= len( actual input )
    xor ch, ch
    xor si, si              ; si= 0

    mov dx, offset buf2
    call get_word_from_buffer1

    mov dx, offset buf3
    call get_word_from_buffer1

    mov dx, offset buf4
    call get_word_from_buffer1

    ; ---------------------------------^
    ; understanding input + count -----------------v

    mov dx, offset buf2
    call find_digit
    xor ah, ah
    push ax         ; push first val to stack

    mov dx, offset buf4
    call find_digit
    mov dl, al      ; safe copy of al (second val)
    pop ax          ; get first val
    mov ah, al      ; ah= first val
    mov al, dl      ; al= second val
    ;   now first number is in ah, and second in al
    
    call find_and_make_calculation
    ;   now result is in al; sign is in s-flag

    mov dx, offset prompt2
    call print_dx

    jns skip_minus
    mov dx, offset op2              ; print 'minus' if negative
    push ax
    call print_dx
    call print_space
    pop ax
    neg al

skip_minus:
    xor ah, ah
    ; --------------------------------^

    ; generate output ----------------v
    ;   (result is stored in al)
    cmp al, 19d
    ja gen_big_result               ; skip if al > 19

gen_small_result:
    mov di, offset small_numbers
    mov dl, al      ; safe copy of al

    xor ah, ah
    mov dh, 2d       ; dh= 2
    mul dh           ; ax= al * 2
    mov bx, ax       ; bx is now val of translation
    mov al, dl       ; fix al value
    mov dx, word ptr ds:[di + bx]
    call print_dx
    jmp after_output

gen_big_result:
    call print_big_result
    jmp after_output
    ; --------------------------------^

after_output:
    mov dx, offset endl
    call print_dx
    call end_program
; -----------------------------------------

; FUNCTIONS

input_dx::       ; input to buf1, requires offset of buffer in dx
    mov ah, 0ah
    int 21h
    ret
;input_dx


print_space::
    mov dl, 20h
    mov ah, 02h
    int 21h
    ret
;print_dl


print_dx::       ; print text from ds:dx
    mov ah, 09h
    int 21h
    ret
;print_dx


print_error_and_end::
    mov dx, offset error_text
    call print_dx
    call end_program
;print_error_and_end


get_word_from_buffer1::       ; get from buf1 (+ si pointer) to bx

    push dx                 ; push on stack offset to output
    mov dx, offset buf1 + 2
    push dx                 ; push on stack offset to input

    cmp cx, 0
    je error1

    mov bx, dx
    call skip_whitespace_characters

    xor di, di                  ; di= 0
    call inject_word

    pop dx
    pop dx                  ; clear stack
    ret

error1:
    call print_error_and_end

;get_word_from_buffer1


skip_whitespace_characters::     ; check from si pointer
    mov ah, byte ptr ds:[bx + si]

    cmp ah, 20h         ; check ' '
    je continue

    cmp ah, 9h          ; check TAB
    je continue

    cmp ah, 24h         ; check '$'
    je continue

    cmp ah, 0dh          ; check CR
    je continue

    ret

continue:
    inc si
    loop skip_whitespace_characters


    call print_error_and_end
;skip_whitespace_characters


inject_word::                    ; while not whitespace: save characters
; using: ax, bx, cx, si, di
    mov bx, sp
    mov bx, word ptr ss:[bx + 2]    ; get input bufor offset to bx
    mov ah, byte ptr ds:[bx + si]   ; read character to ah
    inc si

    cmp ah, 20h         ; check ' '
    je end_inject_word

    cmp ah, 09h          ; check TAB
    je end_inject_word

    cmp ah, 24h         ; check '$'
    je end_inject_word

    cmp ah, 0dh         ; check CR
    je end_inject_word

    mov bx, sp
    mov bx, word ptr ss:[bx + 4]        ; get output bufor offset to bx
    mov byte ptr ds:[bx + di], ah       ; rewrite character
    inc di

    loop inject_word
    ret

end_inject_word:
    dec cx
    ret

;inject_word


check_equality::         ; requires string offsets in stack (two first cells)
; using: bx, cx, dx, si
    mov si, 0
    mov cx, 11d              ; cx = 11

    loop1:                                  ; do {

        mov bx, sp
        mov bx, word ptr ss:[bx + 2]
        mov dh, byte ptr ds:[bx + si]

        mov bx, sp
        mov bx, word ptr ss:[bx + 4]
        mov dl, byte ptr ds:[bx + si]

        inc si
        cmp dh, dl
        jne exit_check_equality

        cmp dh, 24h                         ; check if == '$'
        je exit_check_equality

        loop loop1                          ; } while (--cx);

exit_check_equality:
    ret                     ; now use "je" or "jne"

;check_equality


find_digit::             ; buffor offset in dx
; using: ax, bx, cx, dx, di
    push dx

    mov cx, 10
    xor al, al
check_digit:
    mov di, offset small_numbers
    mov dl, al      ; safe copy of al

    xor ah, ah
    mov dh, 2d       ; dh= 2
    mul dh           ; ax= al * 2
    mov bx, ax       ; bx is now val of translation
    mov al, dl       ; fix al value

    mov dx, word ptr ds:[di + bx]
    mov di, cx                      ; save counter in di
    push dx                         ; offset of al'th digit in stack
    call check_equality
    pop dx
    mov cx, di                      ; restore counter
    je return_digit
    inc al
    loop check_digit

    pop dx
    call print_error_and_end

return_digit:
    pop dx
    ret

;find_digit


find_and_make_calculation::
; using: ax, dx
    mov dx, offset buf3
    push dx                 ; offset of buf3 in stack

    ; check +
    mov dx, offset op1
    push dx
    call check_equality
    pop dx
    je add_numbers

    ; check -
    mov dx, offset op2
    push dx
    call check_equality
    pop dx
    je sub_numbers

    ; check *
    mov dx, offset op3
    push dx
    call check_equality
    pop dx
    je mul_numbers

    call print_error_and_end

add_numbers:
    add ah, al
    mov al, ah
    jmp end_make_calc

sub_numbers:
    sub ah, al
    mov al, ah
    jmp end_make_calc

mul_numbers:
    mul ah      ; ax= al * ah
    jmp end_make_calc

end_make_calc:
    pop dx
    ret             ; -> result stored in al
;find_and_make_calculation


print_big_result::
    mov cl, 10d
    div cl                   ; al= al `div` 10; ah= al `mod` 10
    push ax                  ; result of div to stack
    
    xor ah, ah
    mov si, ax
    sub si, 2                ; si - pointer to the right position in big_numbers
    add si, si               ; si*= 2, because of word ptr
    mov bx, offset big_numbers
    mov dx, word ptr ds:[bx + si]
    call print_dx

    pop ax
    cmp ah, 0
    je skip_second_digit      ; check if 0

    mov al, ah
    xor ah, ah
    mov si, ax               ; si - pointer to the right position in small_numbers
    add si, si               ; si*= 2, because of word ptr
    call print_space
    mov bx, offset small_numbers
    mov dx, word ptr ds:[bx + si]
    call print_dx
    
skip_second_digit:
    ret

;print_big_result


end_program::
    mov al, 0
    mov ah, 4ch
    int 21h
;end_program

code_ ends


stack_ segment stack
        dw  300 dup(?)
wstack_  dw  ?
stack_ ends


end program_