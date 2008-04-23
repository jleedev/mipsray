# vim: ft=mips fdm=marker cms=#\ %s
	.data
epsilon:
	.double 1.0e-9

	.text
	.globl linear
	.globl quadratic

# Compute the roots of a linear {{{1
# f0 x + f2 = 0
# Outputs: Number of roots (0,1) in $v0
# Root in $f28
linear:
	li $v0, 0
	mtc1 $v0, $f28
	cvt.d.w $f28, $f28
	c.eq.d $f0, $f28
	bc1t linear.none
	# Okey-dokey, we've got a root
	li $v0, 1
	neg.d $f2, $f2
	div.d $f28, $f2, $f0
linear.none:
	jr $ra

# Compute the roots of a quadratic {{{1
# f0 x^2 + f2 x + f4 = 0
# Temp: $f6
# Outputs:
# Number of roots (0,1,2) in $v0
# First root in $f28
# Second root in $f30
quadratic:
	# First see if this is just a linear
	li $v0, 0
	mtc1 $v0, $f28
	cvt.d.w $f28, $f28
	c.eq.d $f0, $f28 # If so,
	bc1f quadratic.really
	mov.d $f0, $f2 # then shift the coefficients
	mov.d $f2, $f4
	bc1t linear # so we can call the linear case

quadratic.really:
	# Compute the discriminant d = b^2 - 4ac, in $f6
	mul.d $f6, $f2, $f2 # b^2
	mul.d $f8, $f0, $f4 # ac
	li $t0, 4
	mtc1 $t0, $f28
	cvt.d.w $f28, $f28
	mul.d $f8, $f8, $f28 # 4ac
	sub.d $f6, $f6, $f8 # b^2 - 4ac

	# Case analysis on d:
	# > +epsilon: Two roots
	# < -epsilon: No roots
	# else: One root
	l.d $f28, epsilon
	c.le.d $f6, $f28
	bc1f quadratic.two

	neg.d $f28, $f28
	c.lt.d $f6, $f28
	bc1t quadratic.none
	# fall through

quadratic.one:
	# x = -b/2a
	# negate b
	neg.d $f28, $f2
	# double a
	add.d $f6, $f0, $f0
	# divide
	div.d $f28, $f28, $f6

	li $v0, 1
	jr $ra

quadratic.two:
	# put sqrt(d) in $f28 and -sqrt(d) in $f30
	sqrt.d $f28, $f6
	neg.d $f30, $f28
	# subtract b from both
	sub.d $f28, $f28, $f2
	sub.d $f30, $f30, $f2
	# double a
	add.d $f6, $f0, $f0
	# divide
	div.d $f28, $f28, $f6
	div.d $f30, $f30, $f6

	li $v0, 2
	jr $ra

quadratic.none:
	li $v0, 0
	jr $ra
