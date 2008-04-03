	.data
filename:
	.asciiz "output.bmp"

	.text
main:
	# Stack usage: 52 bytes
	# 0($sp) camera ray (48 bytes)
	# - 0($sp) location vector (0,8,16)
	# - 24($sp) direction vector (24,32,40)
	# 48($sp) return address (4 bytes)
	addi $sp, $sp, -52
	sw $ra, 48($sp)

	# Open the output file
	la $a0, filename
	li $a1, 0x8101 # _O_WRONLY | _O_CREAT | _O_BINARY
	li $a2, 0x0180 # _S_IREAD | _S_IWRITE
	li $v0, 13 # open
	syscall
	move $s4, $v0 # save the file descriptor into $s4

	# Write the bitmap header
	move $a0, $s4
	li $a1, 10 # width
	li $a2, 10 # height
	move $s0, $a1 # save the width
	move $s1, $a2 # and height

	jal bmp.write_header

	# The camera ray's position never changes, so load it here.
	la $t0, location
	l.d $f0, 0($t0)
	s.d $f0, 0($sp)
	l.d $f0, 8($t0)
	s.d $f0, 8($sp)
	l.d $f0, 16($t0)
	s.d $f0, 16($sp)

	# For each pixel in the image:
	li $s3, 0 # y coord of current pixel
main.loop1:
	li $s2, 0 # x coord of current pixel

main.loop2:

	# Compute the camera ray
	# the ray's position was loaded above
	# the ray's direction is
	# a * right + b * up + direction
	# a = (x/w-1/2), b = (y/h-1/2)
	mtc1 $s0, $f30 # width
	cvt.d.w $f30, $f30
	mtc1 $s2, $f28 # x
	div.d $f30, $f28, $f30
	lui $t0, 0x3fc0 # 0.5
	mtc1 $t0, $f29
	mtc1 $0, $f28
	sub.d $f30, $f30, $f28 # $f30 = a
	# load right into <f0,f2,f4> and call scalar.v
	la $t0, right
	l.d $f0, 0($t0)
	l.d $f2, 8($t0)
	l.d $f4, 16($t0)
	jal scalar.v
	# store this part temporarily
	s.d $f0, 32($sp)
	s.d $f2, 40($sp)
	s.d $f4, 48($sp)
	# TODO ...

	# Trace that ray to get a color
	# Output that pixel to the output file
	move $a0, $s4 # file descriptor
	li $a1, 0xff # R
	li $a2, 0xff # G
	li $a3, 0xff # B
	jal bmp.write_pixel

	addi $s2, $s2, 1 # move to the next column
	bne $s2, $s0 main.loop2

	addi $s3, $s3, 1 # move to the next row
	bne $s3, $s1 main.loop1
	# End for

	# Close the file and exit
	move $a0, $s4
	li $v0, 16 # close
	syscall
	
	lw $ra, 48($sp)
	addi $sp, $sp, 52
	jr $ra

# Inputs:
# $a0 pointer to a ray
# $a1 recursion levels left
# Output:
# <f0, f2, f4> 3-vector for the color
raytrace:
