section .data
    menu db "----------------------------------", 10
         db "MENU", 10
         db "[A]dd", 10
         db "[S]ubtract", 10
         db "[M]ultiply", 10
         db "[D]ivide", 10
         db "----------------------------------", 10
         db "Enter your choice: "
    menu_len equ $ - menu

    prompt1 db "Enter first number: "
    prompt1_len equ $ - prompt1
    prompt2 db "Enter second number: "
    prompt2_len equ $ - prompt2
    again db 10, "Do you want to try again (Y/N): "
    again_len equ $ - again

    sum_msg db "The sum is "
    sum_len equ $ - sum_msg
    sub_msg db "The difference is "
    sub_len equ $ - sub_msg
    mul_msg db "The product is "
    mul_len equ $ - mul_msg
    div_msg db "The quotient is "
    div_len equ $ - div_msg
    rem_msg db "The remainder is "
    rem_len equ $ - rem_msg

    invalid_msg db "Invalid choice. Please select A, S, M, or D.", 10
    invalid_len equ $ - invalid_msg
    number_error db "Invalid number. Enter an integer.", 10
    number_error_len equ $ - number_error
    zero_error db "Error: division by zero is not allowed.", 10
    zero_error_len equ $ - zero_error

    newline db 10
    clear_screen db 27, "[2J", 27, "[H"
    clear_len equ $ - clear_screen

section .bss
    input resb 64
    choice resb 1
    num1 resd 1
    num2 resd 1
    result resd 1
    remainder resd 1
    outbuf resb 16

section .text
global _start

_start:

menu_loop:
    ; Clear the terminal
    mov eax, 4
    mov ebx, 1
    mov ecx, clear_screen
    mov edx, clear_len
    int 0x80

    ; Display menu
    mov eax, 4
    mov ebx, 1
    mov ecx, menu
    mov edx, menu_len
    int 0x80

    call read_line
    mov al, [input]

    ; Convert lowercase to uppercase
    cmp al, 'a'
    jb check_choice
    cmp al, 'z'
    ja check_choice
    sub al, 32

check_choice:
    mov [choice], al

    cmp al, 'A'
    je get_numbers
    cmp al, 'S'
    je get_numbers
    cmp al, 'M'
    je get_numbers
    cmp al, 'D'
    je get_numbers

    mov ecx, invalid_msg
    mov edx, invalid_len
    call print_string
    jmp ask_again

get_numbers:
    ; Read first number
    mov ecx, prompt1
    mov edx, prompt1_len
    call print_string

    call read_line
    call parse_integer
    jc invalid_number_input
    mov [num1], eax

    ; Read second number
    mov ecx, prompt2
    mov edx, prompt2_len
    call print_string

    call read_line
    call parse_integer
    jc invalid_number_input
    mov [num2], eax

    mov eax, [num1]
    mov ebx, [num2]

    cmp byte [choice], 'A'
    je do_add
    cmp byte [choice], 'S'
    je do_subtract
    cmp byte [choice], 'M'
    je do_multiply
    cmp byte [choice], 'D'
    je do_divide

do_add:
    add eax, ebx
    mov [result], eax
    mov ecx, sum_msg
    mov edx, sum_len
    jmp show_result

do_subtract:
    sub eax, ebx
    mov [result], eax
    mov ecx, sub_msg
    mov edx, sub_len
    jmp show_result

do_multiply:
    imul ebx
    mov [result], eax
    mov ecx, mul_msg
    mov edx, mul_len
    jmp show_result

do_divide:
    cmp ebx, 0
    je division_by_zero

    cdq
    idiv ebx

    mov [result], eax
    mov [remainder], edx

    mov ecx, div_msg
    mov edx, div_len
    call print_string

    mov eax, [result]
    call print_integer
    call print_newline

    mov ecx, rem_msg
    mov edx, rem_len
    call print_string

    mov eax, [remainder]
    call print_integer
    call print_newline

    jmp ask_again

show_result:
    call print_string
    mov eax, [result]
    call print_integer
    call print_newline
    jmp ask_again

invalid_number_input:
    mov ecx, number_error
    mov edx, number_error_len
    call print_string
    jmp ask_again

division_by_zero:
    mov ecx, zero_error
    mov edx, zero_error_len
    call print_string
    jmp ask_again

ask_again:
    mov ecx, again
    mov edx, again_len
    call print_string

    call read_line
    mov al, [input]

    cmp al, 'Y'
    je menu_loop
    cmp al, 'y'
    je menu_loop
    cmp al, 'N'
    je exit_program
    cmp al, 'n'
    je exit_program
    jmp ask_again

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; Read a line from keyboard
read_line:
    mov eax, 3
    mov ebx, 0
    mov ecx, input
    mov edx, 64
    int 0x80
    ret

; Convert decimal input into a signed integer in EAX
; Carry flag indicates invalid input
parse_integer:
    push ebx
    push ecx
    push edx
    push esi

    mov esi, input
    xor eax, eax
    xor ebx, ebx

    mov cl, [esi]
    cmp cl, '-'
    jne check_plus
    mov bl, 1
    inc esi
    jmp parse_digits

check_plus:
    cmp cl, '+'
    jne parse_digits
    inc esi

parse_digits:
    xor ecx, ecx

digit_loop:
    mov dl, [esi]

    cmp dl, 10
    je digits_done
    cmp dl, 13
    je digits_done
    cmp dl, 0
    je digits_done

    cmp dl, '0'
    jb parse_error
    cmp dl, '9'
    ja parse_error

    imul eax, eax, 10
    jo parse_error

    sub dl, '0'
    movzx edx, dl
    add eax, edx
    jo parse_error

    inc ecx
    inc esi
    jmp digit_loop

digits_done:
    cmp ecx, 0
    je parse_error

    cmp bl, 0
    je parse_valid
    neg eax

parse_valid:
    clc
    jmp parse_finish

parse_error:
    stc

parse_finish:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; Display a string: ECX = address, EDX = length
print_string:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

; Display signed integer stored in EAX
print_integer:
    push ebx
    push ecx
    push edx
    push esi

    mov esi, outbuf + 15
    mov byte [esi], 0
    mov ebx, 10

    cmp eax, 0
    jne integer_nonzero

    dec esi
    mov byte [esi], '0'
    jmp integer_print

integer_nonzero:
    cmp eax, 0
    jge integer_positive

    neg eax
    push dword 1
    jmp integer_digits

integer_positive:
    push dword 0

integer_digits:
    xor edx, edx
    div ebx
    add dl, '0'
    dec esi
    mov [esi], dl
    test eax, eax
    jnz integer_digits

    pop ecx
    cmp ecx, 0
    je integer_print

    dec esi
    mov byte [esi], '-'

integer_print:
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    mov edx, outbuf + 15
    sub edx, esi
    int 0x80

    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

print_newline:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret