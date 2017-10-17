%macro print_debug 1
	cmp 	byte [d_flag], 0
	je 		%%print_no_debug
	push 	%1
	push 	str_frmt
	push 	DWORD [stderr]
	call 	fprintf
	add 	esp, 12
%%print_no_debug:
%endmacro

%macro my_malloc 1
	push 	%1
	call 	malloc
	add 	esp, 4
	mov 	dword[eax+lnk_lst_data], 0
	mov 	dword[eax+lnk_lst_next], 0
	mov 	dword[eax+lnk_lst_prev], 0
%endmacro

section .rodata
err_stk_ovr_txt:	DB ">>Error: Operand Stack Overflow", 10, 0
err_ins_args_txt:	DB ">>Error: Insufficient Number of Arguments on Stack", 10, 0
err_ill_inpt_txt:	DB ">>Error: Illegal Input", 10, 0
str_frmt:			DB "%s", 10, 0
chr_frmt:			DB "%c", 0
d_frmt:				DB "%d", 10, 0
calc: 				DB ">>calc: " , 0
clc_frmt: 			DB "%s", 0
arrows: 			DB ">>", 0
my_stck_size		equ 5
lnk_lst_data		equ 0
lnk_lst_next		equ 1
lnk_lst_prev		equ 5
lnk_lst_size 		equ 9
input_size			equ 82

section .data
my_esp: 			DB 0

section .bss
my_stack:			RESB my_stck_size*4
input: 				RESB input_size
d_flag:				RESB 1
number: 			RESB 1

section .text
	align 16
	global main
	extern fgets
	extern stdin
    extern free
	extern printf
	extern stdout
	extern malloc
    extern fprintf
    extern stderr

main:
	mov 	byte [number], 0	
	mov 	byte [d_flag], 0
	cmp 	dword [esp+4], 2
	jb 		main_no_debug

	mov 	eax, [esp+8]
	mov 	eax, [eax+4]
	mov 	eax, [eax]
	
	cmp 	al, '-'
	jne 	main_no_debug

	cmp 	ah, 'd'
	jne 	main_no_debug
	add 	byte [d_flag], 1

main_no_debug:
	pushad
main_loop:	
	call 	get_input	
	call 	execute

	jmp 	main_loop

	popad
	ret

get_input:
	pushad

	push 	calc 
	push 	clc_frmt 
	call 	printf 
	add 	esp, 8

	push 	DWORD [stdin]
	push 	input_size
	push 	DWORD input
	call 	fgets
	add 	esp, 12
	popad
	ret

execute:
	pushad
	cmp 	byte [input], 'q'
	je 		execute_q
	cmp 	byte [input], '+'
	je 		execute_plus
	cmp 	byte [input], 'p'
	je 		execute_p
	cmp 	byte [input], 'd'
	je 		execute_d
	cmp 	byte [input], '&'
	je 		execute_amper
	cmp		byte [input], '9'
	ja 		err_ill_inpt
	cmp 	byte [input], '0'
	jl		err_ill_inpt
	call 	execute_n
	popad 	
	ret 	

execute_q:
	cmp 	byte [my_esp], 0
	je 		execute_q_do_not_free_linked_lists
	mov 	eax, 0
	mov 	al, [my_esp]
	dec 	al
	shl 	al, 2
	push 	dword [eax+my_stack]
	call 	free_link_list_to_the_end
	add 	esp, 4
	dec 	byte [my_esp]
	jmp 	execute_q
execute_q_do_not_free_linked_lists:
	popad
	add 	esp, 4 					; the last ret
	mov		eax, 0
	mov		eax, [number]
	push 	eax
	push 	d_frmt
	call 	printf
	add 	esp, 8
	popad							; returns the program who called this program his registers
	ret 


execute_plus:
	cmp 	byte [my_esp], 2
	jb 		err_ins_args

	mov 	edx, 0 					; stores the address which will be overriden so we can free it in the end
	mov 	dl, [my_esp]
	sub 	dl, 2
	shl 	dl, 2
	push 	dword [edx+my_stack]

	mov 	edx, 0
	mov 	dl, [my_esp]			; bring the first number
	dec 	dl
	shl 	dl, 2
	mov 	edx, [my_stack+edx]
	
	mov 	ecx, 0
	mov 	cl, [my_esp]			; bring the next number
	sub 	cl, 2
	shl 	cl, 2
	mov 	ecx, [my_stack+ecx]

	mov 	bl, 0
	push 	0 						; holds pointer to last inserted link, so we can connect them with each other
	push 	edx 					; save the two pointers
	push 	ecx
execute_plus_next:
	mov 	ecx, [esp]				; holds pointer to one of the numbers
	mov 	edx, [esp+4]			; hold pointer to the other
	mov 	eax, 0

	cmp 	ecx, 0
	je 		execute_plus_next_al_0
	mov 	al, [ecx]
execute_plus_next_al_0:
	cmp 	edx, 0
	je 		execute_plus_next_ah_0
	mov 	ah, [edx]
execute_plus_next_ah_0:

	call 	execute_plus_data
	push 	ebx
	my_malloc lnk_lst_size
	pop 	ebx

	cmp 	dword [esp+8], 0
	jne 	execute_plus_next_do_not_my_stack
	sub 	dword [my_esp], 2		; store the first (which eventually is the last) link 
	push 	ebx
	mov 	ebx, [my_esp]
	shl 	ebx, 2
	mov 	[my_stack+ebx], eax 	
	pop 	ebx
execute_plus_next_do_not_my_stack:
	mov 	[eax+lnk_lst_data], bh
	cmp 	dword [esp+8], 0
	je 		execute_plus_next_do_not_link
	mov 	ecx, [esp+8] 			; get the last link
	mov 	[ecx+lnk_lst_next], eax
	mov 	[eax+lnk_lst_prev], ecx
execute_plus_next_do_not_link:
	mov 	[esp+8], eax
	mov 	ecx, [esp] 				; retrieve the pointers
	mov 	edx, [esp+4]			; retrieve the pointers
	cmp 	ecx, 0
	je 		execute_plus_next_ecx_0
	push 	eax
	mov 	eax, [ecx+lnk_lst_next]
	mov 	[esp+4], eax
	pop 	eax
execute_plus_next_ecx_0:
	cmp 	edx, 0
	je 		execute_plus_next_edx_0
	push 	eax
	mov 	eax, [edx+lnk_lst_next]
	mov 	[esp+8], eax
	pop 	eax
execute_plus_next_edx_0:
	mov		edx, [esp]
	add 	edx, [esp+4]
	add 	dl, bl
	cmp 	edx, 0
	jne 	execute_plus_next
	mov 	edx, [esp+8]
	mov 	al, [edx+lnk_lst_data]
	shr 	al, 4
	cmp 	al, 0
	jne 	execute_plus_next_no_need_to_remove_leading_0
	add 	byte [edx+lnk_lst_data], 160
execute_plus_next_no_need_to_remove_leading_0:
	add 	esp, 12
	inc 	byte [my_esp]

	call 	free_link_list_to_the_end
	add 	esp, 4
	mov 	eax, 0
	mov 	al, [my_esp]
	shl 	al, 2
	push 	dword [eax+my_stack]
	call 	free_link_list_to_the_end
	add 	esp, 4
	
	print_debug input
	inc 	byte [number]

	popad
	ret


execute_plus_data: 					; pre-condition: al and ah got the datas and bl got the carry, post-condition bh is the answer, bl is the carry
	push 	eax
	shl 	al, 4
	shl 	ah, 4
	shr 	al, 4
	shr 	ah, 4
	mov 	cl, al
	add 	cl, ah
	add 	cl, bl
	mov 	bl, 0
	cmp 	cl, 10
	jb 		execute_plus_data_no_carry
	mov 	bl, 1					; carry is one
	sub 	cl, 10
execute_plus_data_no_carry:
	pop 	eax
	shr 	al, 4
	shr 	ah, 4

	cmp 	al, 10
	je 		execute_plus_data_al_10
	cmp 	ah, 10
	je 		execute_plus_data_ah_10
	mov 	ch, al
	add 	ch, ah
	add 	ch, bl
	mov		bl, 0
	cmp 	ch, 10
	jb 		execute_plus_data_finish
	sub 	ch, 10
	mov 	bl, 1
	jmp 	execute_plus_data_finish	

execute_plus_data_al_10:
	cmp 	bl, 1
	je 		execute_plus_data_al_10_bl_1
	cmp 	ah, 10
	jne		execute_plus_data_al_10_bl_0
	mov 	ch, 10
	jmp 	execute_plus_data_finish

execute_plus_data_al_10_bl_0:
	mov 	ch, ah
	jmp 	execute_plus_data_finish

execute_plus_data_al_10_bl_1:
	cmp 	ah, 10
	je 		execute_plus_data_al_10_ah_10_bl_1
	mov 	ch, ah
	add 	ch, bl
	mov 	bl, 0
	cmp 	ch, 10
	jne 	execute_plus_data_finish
	sub 	ch, 10
	mov 	bl, 1
	jmp 	execute_plus_data_finish	

execute_plus_data_al_10_ah_10_bl_1:
	mov 	ch, bl
	mov 	bl, 0
	jmp 	execute_plus_data_finish

execute_plus_data_ah_10:
	mov 	ch, al
	add 	ch, bl
	mov 	bl, 0
	cmp 	ch, 10
	jne 	execute_plus_data_finish
	sub 	ch, 10
	inc 	bl
	jmp 	execute_plus_data_finish		

execute_plus_data_finish:
	shl 	ch, 4
	add 	cl, ch
	mov 	bh, cl
	ret





execute_p:
	pushad
	push 	arrows
	push 	clc_frmt
	call 	printf
	add 	esp, 8
	popad	
	cmp 	byte [my_esp], 0
	je 		err_ins_args
	
	print_debug input
	inc 	byte [number]

	mov 	eax, 0
	mov 	al, [my_esp]
	dec 	al
	shl 	eax, 2
	mov 	eax, [my_stack+eax]
	call 	execute_p_set_eax_last
	call 	execute_p_print_backward
	dec 	byte [my_esp]
	push 	10
	push 	chr_frmt
	call 	printf
	add 	esp, 8
	
	mov 	al, [my_esp]
	shl 	al, 2
	push 	dword [eax+my_stack]
	call 	free_link_list_to_the_end
	add 	esp, 4
	popad
	ret

execute_p_set_eax_last:
	cmp 	dword [eax+lnk_lst_next], 0
	je		execute_p_ret
	mov 	eax, [eax+lnk_lst_next]
	jmp 	execute_p_set_eax_last

execute_p_print_backward:
	cmp 	eax, 0
	je		execute_p_ret
	call 	execute_p_print_data
	mov 	eax, [eax+lnk_lst_prev]
	jmp		execute_p_print_backward

execute_p_print_data:
	push 	eax

	mov 	ebx, 0
	mov 	bl, [eax+lnk_lst_data]
	shr 	bl, 4
	cmp 	bl, 10
	je 		execute_p_print_data_do_not_print
	add 	bl, '0'
	push 	ebx
	push 	chr_frmt
	call 	printf
	add 	esp, 8

execute_p_print_data_do_not_print:
	mov 	eax, [esp]
	mov		ebx, 0
	mov 	bl, [eax+lnk_lst_data]
	shl 	bl, 4
	shr 	bl, 4
	add 	bl, '0'
	push 	ebx
	push 	chr_frmt
	call 	printf
	add 	esp, 8
	pop 	eax
execute_p_ret:
	ret


execute_d:
	mov 	bl, my_stck_size

	cmp 	byte [my_esp], bl
	je 		err_ovr_flw
	cmp 	byte [my_esp], 0
	je 		err_ins_args
	
	my_malloc lnk_lst_size

	mov 	ebx, [my_esp]
	shl		ebx, 2
	add 	ebx, my_stack
	mov 	[ebx], eax 				; store the pointer in my_stack
	inc 	byte [my_esp]

	sub 	ebx, 4
	mov 	ebx, [ebx]

	push 	ebx
	push 	0
	push 	eax
execute_d_next:						; pre-condition: [esp] stores the last inserted data pointer while [esp+4] stores the previous and [esp+8] holds the copied lnk_lst
	mov 	eax, [esp]				; copy values
	mov 	ebx, [esp+8]
	mov 	cl, [ebx+lnk_lst_data]
	mov 	[eax+lnk_lst_data], cl
	
	cmp 	dword [esp+4], 0
	je 		execute_d_next_dont_link_previous
	mov 	ebx, [esp+4]
	add 	ebx, lnk_lst_next
	mov 	ecx, [esp]
	mov 	[ebx], ecx		; link new with previous
	mov 	ebx, [esp]
	add 	ebx, lnk_lst_prev 
	mov 	ecx, [esp+4]
	mov 	[ebx], ecx
execute_d_next_dont_link_previous:
	mov 	ebx, [esp+8]
	add 	ebx, lnk_lst_next 
	mov 	ebx, [ebx]
	cmp 	ebx, 0
	je 		execute_d_finish
	my_malloc lnk_lst_size
	
	mov 	ecx, [esp]
	mov 	[esp+4], ecx
	mov 	[esp], eax

	mov 	ebx, [esp+8]
	add 	ebx, lnk_lst_next
	mov 	ebx, [ebx]
	mov 	[esp+8], ebx
	jmp 	execute_d_next
execute_d_finish:
	add 	esp, 12
	print_debug input
	inc 	byte [number]

	popad
	ret
	

execute_amper:						
	cmp 	byte [my_esp], 2
	jb 		err_ill_inpt

	mov 	edx, 0
	mov 	dl, [my_esp]			; bring the first number
	dec 	dl
	shl 	dl, 2
	mov 	edx, [my_stack+edx]
	
	mov 	ecx, 0
	mov 	cl, [my_esp]			; bring the next number
	sub 	cl, 2
	shl 	cl, 2
	mov 	ecx, [my_stack+ecx]

execute_amper_and:					; edx points to last number, ecx point to one before
	mov 	eax, 0
	mov 	al, [ecx + lnk_lst_data]
	mov 	ah, [edx + lnk_lst_data]
	shr		al, 4
	shr		ah, 4
	cmp		al, 10
	je 		execute_amper_and_al10
	cmp 	ah, 10
	je 		execute_amper_and_ah10

	mov 	al, [ecx + lnk_lst_data]
	mov 	ah, [edx + lnk_lst_data]
	and 	ah, al
	mov 	[ecx+lnk_lst_data], ah 				; ecx points to the answer

	cmp 	dword [ecx + lnk_lst_next], 0
	je 		execute_amper_and_goToEnd
	cmp 	dword [edx + lnk_lst_next], 0
	je 		execute_amper_and_edx0

	mov 	edx, [edx + lnk_lst_next]
	mov 	ecx, [ecx + lnk_lst_next]

	jmp 	execute_amper_and

execute_amper_and_edx0:
	mov 	dword [ecx + lnk_lst_next], 0
	jmp     execute_amper_and_goToEnd
execute_amper_and_al10:
	mov 	al, [ecx + lnk_lst_data]
	shl 	al, 4
	shr		al, 4
	cmp 	ah, 10
	je 		execute_amper_and_ah10
	mov 	ah, [edx + lnk_lst_data]
	and 	ah, al
	mov 	[ecx+lnk_lst_data], ah 				; ecx points to the answer	
	mov 	dword [ecx + lnk_lst_next], 0
	jmp 	execute_amper_and_goToEnd

execute_amper_and_ah10:
	mov 	al, [ecx + lnk_lst_data]
	mov 	ah, [edx + lnk_lst_data]
	shl   	ah, 4
	shr 	ah, 4
	and 	ah, al
	mov 	[ecx+lnk_lst_data], ah
	mov 	dword [ecx + lnk_lst_next], 0
	jmp 	execute_amper_and_goToEnd	

execute_amper_and_goToEnd:
	cmp 	dword [ecx + lnk_lst_next], 0
	je 		execute_amper_and_removeZeroes
	mov 	ecx, [ecx + lnk_lst_next]
	jmp 	execute_amper_and_goToEnd

execute_amper_and_removeZeroes:
	cmp 	dword [ecx + lnk_lst_prev], 0
	je		execute_amper_and_removeZeroes_check1number
	cmp 	byte [ecx + lnk_lst_data], 0
	jne		execute_amper_and_removeZeroes_prev
	cmp 	dword [ecx + lnk_lst_prev], 0
	je 		execute_amper_and_removeZeroes_end

execute_amper_and_removeZeroes_prev:
	cmp  	byte [ecx + lnk_lst_data], 0
	jne		execute_amper_and_removeZeroes_check1number
	mov 	dword ecx, [ecx + lnk_lst_prev]
	jmp 	execute_amper_and_removeZeroes
execute_amper_and_removeZeroes_end:
	mov 	dword [ecx + lnk_lst_next], 0
	jmp 	execute_amper_and_finish

execute_amper_and_removeZeroes_check1number:
	mov 	bl, [ecx + lnk_lst_data]
	shr 	byte [ecx + lnk_lst_data], 4
	shl 	byte [ecx + lnk_lst_data], 4
	cmp 	byte [ecx + lnk_lst_data], 0
	jne 	execute_amper_and_finish_bl
	mov 	[ecx + lnk_lst_data], bl
	shl 	byte [ecx + lnk_lst_data], 4
	shr 	byte [ecx + lnk_lst_data], 4
	add 	byte [ecx + lnk_lst_data], 160
	mov 	dword [ecx + lnk_lst_next], 0
	jmp 	execute_amper_and_finish
execute_amper_and_finish_bl:
	mov 	[ecx + lnk_lst_data], bl
	mov 	dword [ecx + lnk_lst_next], 0
execute_amper_and_finish:
	dec 	byte [my_esp]
	print_debug input
	inc 	byte [number]

	popad
	ret


execute_n:
	mov 	bl, my_stck_size
	add 	esp, 4
	cmp 	byte [my_esp], bl
	je 		err_ovr_flw
	sub 	esp, 4
	mov 	ecx, -1 					; counter over input

execute_n_jump_over_0:
	inc 	ecx
	cmp 	byte [input+ecx+1], 10
	je 		execute_n_stop_jumping
	cmp 	byte [input+ecx], '0'
	je 		execute_n_jump_over_0

execute_n_stop_jumping:
	mov 	edx, 0
execute_n_next_number:
	call 	execute_n_build_number 	; combine two chars to a single char => bl
	cmp		bl, 170					; means the last two bytes was the end of the input
	je 		execute_n_finish
	push 	edx
	push 	ecx 					; malloc call
	push 	ebx
	my_malloc lnk_lst_size
	pop 	ebx
	pop 	ecx
	pop 	edx
	mov		byte [eax+lnk_lst_data], bl
	cmp 	edx, 0
	je 		execute_n_edx_to_eax
	mov 	[edx+lnk_lst_prev], eax 				; it needs to point to this node
	; point this node->next to previous node
	mov		[eax+lnk_lst_next], edx
execute_n_edx_to_eax:
	push 	ebx
	push 	edx
	shl 	bl, 4
	shr 	bl, 4
	mov 	edx, eax
	cmp		bl, 10					; means the last byte was the end of the input
	je 		execute_n_fix_number
	pop 	edx

	pop 	ebx
	mov 	edx, eax
	jmp 	execute_n_next_number
execute_n_finish:
	; put this last node onto my_stack
	mov 	ecx, 0
	mov 	cl, [my_esp]
	shl 	cl, 2
	mov 	[my_stack + ecx], eax
	inc 	byte [my_esp]
	print_debug input
	ret

execute_n_build_number:
	mov 	ebx, 0
	mov 	bl, [input+ecx]
	cmp 	bl, 10 							; means we reach EOL
	je 		execute_n_build_number_eol_full
	sub 	bl, '0'
	shl 	bl, 4
	inc 	ecx
	add 	bl, [input+ecx]
	cmp 	byte [input+ecx], 10
	je 		execute_n_build_number_eol_half
	sub 	bl, '0'
execute_n_build_number_eol_half:
	inc 	ecx
	ret
execute_n_build_number_eol_full:
	inc 	ecx
	mov 	bl, 170 						; put \n \n at the byte
	ret
	
execute_n_fix_number:						; we want that the number, edx holds pointer to the head of the linked list
	mov 	bl, [edx] 						; get the data of 
	shr 	bl, 4
	add 	bl, 160 						; put \n at the end
	mov 	[edx], bl 						; put the data back
	add 	esp,8
	cmp 	dword [edx+1], 0 				; the next link does not exist
	je 		execute_n_finish
	sub 	esp, 8
	mov 	ecx, edx
	inc 	ecx
	mov 	ecx, [ecx] 						; point to the next link
	mov 	cl, [ecx] 						; get the data of next
	shl 	cl, 4
	sub 	bl, 160							; remove \n we put before
	add 	bl, cl
	mov 	[edx], bl 						; put the data back
	inc 	edx
	mov 	edx, [edx]
	jmp 	execute_n_fix_number


err_ins_args:
	push 	err_ins_args_txt
	push 	str_frmt
	call 	printf
	add 	esp, 8
	popad
	ret	

err_ovr_flw:
	push 	err_stk_ovr_txt
	push 	str_frmt
	call 	printf
	add 	esp, 8
	popad
	ret	

err_ill_inpt:
	push 	err_ill_inpt_txt
	push 	str_frmt
	call 	printf
	add 	esp, 8
	popad
	ret	

free_link_list_to_the_end: 		; free all linked list. pre-condition: [esp+4]
	mov 	eax, [esp+4]
	push 	eax

	cmp 	dword [eax+lnk_lst_next], 0
	je		free_link_list_to_the_end_not_next

	mov 	ebx, [eax+lnk_lst_next]
	push 	ebx
	call 	free_link_list_to_the_end
	add 	esp, 4
free_link_list_to_the_end_not_next:
	call 	free
	add 	esp, 4
	ret