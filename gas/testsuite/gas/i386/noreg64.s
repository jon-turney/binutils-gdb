	.text
noreg:
	adc	$1, (%rax)
	adc	$0x89, (%rax)
	adc	$0x1234, (%rax)
	adc	$0x12345678, (%rax)
	add	$1, (%rax)
	add	$0x89, (%rax)
	add	$0x1234, (%rax)
	add	$0x12345678, (%rax)
	and	$1, (%rax)
	and	$0x89, (%rax)
	and	$0x1234, (%rax)
	and	$0x12345678, (%rax)
	bt	$1, (%rax)
	btc	$1, (%rax)
	btr	$1, (%rax)
	bts	$1, (%rax)
	call	*(%rax)
	cmp	$1, (%rax)
	cmp	$0x89, (%rax)
	cmp	$0x1234, (%rax)
	cmp	$0x12345678, (%rax)
	cmps
	cmps	%es:(%rdi), (%rsi)
	crc32	(%rax), %eax
	crc32	(%rax), %rax
	dec	(%rax)
	div	(%rax)
	fadd	(%rax)
	fcom	(%rax)
	fcomp	(%rax)
	fdiv	(%rax)
	fdivr	(%rax)
	fiadd	(%rax)
	ficom	(%rax)
	ficomp	(%rax)
	fidiv	(%rax)
	fidivr	(%rax)
	fild	(%rax)
	fimul	(%rax)
	fist	(%rax)
	fistp	(%rax)
	fisttp	(%rax)
	fisub	(%rax)
	fisubr	(%rax)
	fld	(%rax)
	fmul	(%rax)
	fst	(%rax)
	fstp	(%rax)
	fsub	(%rax)
	fsubr	(%rax)
	idiv	(%rax)
	imul	(%rax)
	in	$0
	in	%dx
	inc	(%rax)
	ins
	ins	%dx, %es:(%rdi)
	iret
	jmp	*(%rax)
	lcall	*(%rax)
	lgdt	(%rax)
	lidt	(%rax)
	ljmp	*(%rax)
	lldt	(%rax)
	lmsw	(%rax)
	lods
	lods	(%rsi)
	lret
	lret	$4
	ltr	(%rax)
	mov	$0x12, (%rax)
	mov	$0x1234, (%rax)
	mov	$0x12345678, (%rax)
	mov	%es, (%rax)
	mov	(%rax), %es
	movs
	movs	(%rsi), %es:(%rdi)
	movsx	(%rax), %ax
	movsx	(%rax), %eax
	movsx	(%rax), %rax
	movzx	(%rax), %ax
	movzx	(%rax), %eax
	movzx	(%rax), %rax
	mul	(%rax)
	neg	(%rax)
	nop	(%rax)
	not	(%rax)
	or	$1, (%rax)
	or	$0x89, (%rax)
	or	$0x1234, (%rax)
	or	$0x12345678, (%rax)
	out	$0
	out	%dx
	outs
	outs	(%rsi), %dx
	pop	(%rax)
	pop	%fs
	ptwrite	(%rax)
	push	(%rax)
	push	%fs
	rcl	$1, (%rax)
	rcl	$2, (%rax)
	rcl	%cl, (%rax)
	rcl	(%rax)
	rcr	$1, (%rax)
	rcr	$2, (%rax)
	rcr	%cl, (%rax)
	rcr	(%rax)
	rol	$1, (%rax)
	rol	$2, (%rax)
	rol	%cl, (%rax)
	rol	(%rax)
	ror	$1, (%rax)
	ror	$2, (%rax)
	ror	%cl, (%rax)
	ror	(%rax)
	sbb	$1, (%rax)
	sbb	$0x89, (%rax)
	sbb	$0x1234, (%rax)
	sbb	$0x12345678, (%rax)
	scas
	scas	%es:(%rdi)
	sal	$1, (%rax)
	sal	$2, (%rax)
	sal	%cl, (%rax)
	sal	(%rax)
	sar	$1, (%rax)
	sar	$2, (%rax)
	sar	%cl, (%rax)
	sar	(%rax)
	shl	$1, (%rax)
	shl	$2, (%rax)
	shl	%cl, (%rax)
	shl	(%rax)
	shr	$1, (%rax)
	shr	$2, (%rax)
	shr	%cl, (%rax)
	shr	(%rax)
	stos
	stos	%es:(%rdi)
	sub	$1, (%rax)
	sub	$0x89, (%rax)
	sub	$0x1234, (%rax)
	sub	$0x12345678, (%rax)
	sysret
	test	$0x89, (%rax)
	test	$0x1234, (%rax)
	test	$0x12345678, (%rax)
	xor	$1, (%rax)
	xor	$0x89, (%rax)
	xor	$0x1234, (%rax)
	xor	$0x12345678, (%rax)
