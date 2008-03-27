	.data
filename:
	.asciiz "output.bmp"

	.text
main:
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

	# For each pixel in the image:
	li $s3, 0 # y coord of current pixel
main.loop1:
	li $s2, 0 # x coord of current pixel

main.loop2:

	# <<< do stuff here >>>
	# Compute the ray from the camera to that pixel

	# the ray's position is the camera's position
	# the ray's direction is as follows
	# (x-w/2)/w * right + (y-h/2)/h * up + direction

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

	# Close the file and exit
	move $a0, $s4
	li $v0, 16 # close
	syscall
	
	li $v0, 10 # exit
	syscall

# Inputs:
# $a0 pointer to a ray
# $a1 recursion levels left
# Output:
# <f0, f2, f4> 3-vector for the color
raytrace:
