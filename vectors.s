# If we use the floating-point registers like this:
# <0,2,4> <6,8,10> <12,14,16> <18,20,22> <24,26,28> 30
# then we can talk about five 3-vectors and one scalar at once.

# If we use the floating-point registers like this:
# <0,2,4,6> <8,10,12,14> <16,18,20,22> <24,26,28,30>
# then we can talk about four 4-vectors at once.

	.text
	.globl add.v
	.globl sub.v
	.globl mag2.v
	.globl mag.v
	.globl dot.v
	.globl cross.v
	.globl unit.v
	.globl scalar.v

# Vector addition <f0,f2,f4> + <f6,f8,f10>
# Output: <f24,f26,f28>
add.v:
	add.d $f24, $f0, $f6
	add.d $f26, $f2, $f8
	add.d $f28, $f4, $f10
	jr $ra

# Vector subtraction: <f0,f2,f4> - <f6,f8,f10>
# Output: <f24,f26,f28>
sub.v:
	sub.d $f24, $f0, $f6
	sub.d $f26, $f2, $f8
	sub.d $f28, $f4, $f10
	jr $ra

# Vector magnitude squared: ||<f0,f2,f4>||^2
# Uses f28
# Output: f30
mag2.v:
	mul.d $f30, $f0, $f0 # first component
	mul.d $f28, $f2, $f2 # second component
	add.d $f30, $f30, $f28
	mul.d $f28, $f4, $f4 # third component
	add.d $f30, $f30, $f28
	jr $ra

# Vector magnitude: ||<f0,f2,f4>||
# Uses f28
# Output: f30
mag.v:
	mul.d $f30, $f0, $f0 # first component
	mul.d $f28, $f2, $f2 # second component
	add.d $f30, $f30, $f28
	mul.d $f28, $f4, $f4 # third component
	add.d $f30, $f30, $f28
	sqrt.d $f30, $f30
	jr $ra

# Vector dot product: <f0,f2,f4> . <f6,f8,f10>
# Uses f28
# Output: f30
dot.v:
	mul.d $f30, $f0, $f6 # first component
	mul.d $f28, $f2, $f8 # second component
	add.d $f30, $f30, $f28
	mul.d $f28, $f4, $f10 # third component
	add.d $f30, $f30, $f28
	jr $ra

# Vector cross product: <f0,f2,f4> x <f6,f8,f10>
# Output: <f24, f26, f28>
cross.v:
	# TODO
	jr $ra

# Unit Vector in direction of: <f0,f2,f4>
# Uses f30
# Output: <f24,f26,f28>
unit.v:
	#Calculate Magnitude
	mul.d $f30, $f0, $f0 # first component
	mul.d $f28, $f2, $f2 # second component
	add.d $f30, $f30, $f28
	mul.d $f28, $f4, $f4 # third component
	add.d $f30, $f30, $f28
	sqrt.d $f30, $f30
	mtc1 $zero, $f28
	cvt.d.w $f28, $f28
	c.eq.d $f30, $f28
	bc1f thereisone
	# No Corresponding Unit Vector, return input
	mov.d $f24, $f0
	mov.d $f26, $f2
	mov.d $f28, $f4
	jr $ra
thereisone:
	# Return Unit Vector
	div.d $f24, $f0, $f30
	div.d $f26, $f2, $f30
	div.d $f28, $f4, $f30
	jr $ra

# Scalar Multiplication: f30*<f0,f2,f4>
# Output: <f24,f26,f28>
scalar.v:
	mul.d $f24, $f30, $f0 # first component
	mul.d $f26, $f30, $f2 # second component
	mul.d $f28, $f30, $f4 # third component
	jr $ra
