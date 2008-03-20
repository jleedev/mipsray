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

main:
	li $v0, 7 # read_double in $f0
	syscall
	jr $ra

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
