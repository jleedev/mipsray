# Note:
# The bmp header is little endian, and our box is little endian,
# so don't try to run this on a big endian machine.

	.data
	# The bmp header is not word aligned
	.align 0

# Length of this header: 0x36 bytes
head.start:     .byte 0x42 0x4d # "BM"
head.filesize:  .word 0         # file size
                .half 0         # unused 1
                .half 0         # unused 2
                .word 0x36      # offset of bitmap data
                .word 0x28      # size of the info subheader
head.width:     .word 0         # width in pixels
head.height:    .word 0         # height in pixels
                .half 1         # number of color planes
                .half 0x18      # bits per pixel
                .word 0         # compression
head.imagesize: .word 0         # size of image data in bytes
                .word 0xb13     # x res in pixels per meter
                .word 0xb13     # y res in pixels per meter
                .word 0         # number of colors
                .word 0         # number of important colors

	# Restore alignment
	.align 2

# Here we record the number of padding bytes
# that are needed per row of pixels.
padding:
	.word 0

# Keep track of how far we are in the row.
# When the row is finished, the row is padded and this counter is reset.
column:
	.word 0

# Used by bmp.write_pixel
buffer:
	.word 0

	.text
	.globl bmp.write_header
	.globl bmp.write_pixel

# Inputs:
# $a0 file descriptor
# $a1 image width
# $a2 image height
bmp.write_header:
	usw $a1, head.width
	sw $a1, column
	usw $a2, head.height
	# Compute the size of the image data,
	# assuming 3 bytes per pixel

	sll $t0, $a1, 1
	add $t0, $t0, $a1
	# To see how many padding bytes are needed,
	# subtract the bottom two bits of $t0 from 4,
	# then and the result with 3
	andi $t1, $t0, 3
	addi $t1, $t1, -4
	neg $t1, $t1
	andi $t1, $t1, 3
	sw $t1, padding

	# Now, compute
	# image_size = (image_width*3 + padding) * image_height
	add $t0, $t0, $t1
	mul $t0, $t0, $a2
	usw $t0, head.imagesize

	# Calculate the size of the file.
	# file_size = image_size + 54
	addi $t0, $t0, 54
	usw $t0, head.filesize

	# Finally, write the entire header structure to the file.
	la    $a1, head.start
	li    $a2, 54
	li    $v0, 15 # write
	syscall

	jr $ra

# Inputs:
# $a0 file descriptor
# <R,G,B> in <$a1, $a2, $a3>
bmp.write_pixel:
	move $t2, $a2

	# First write the pixel
	# B
	sw $a1, buffer
	li $v0, 15 # write
	la $a1, buffer
	li $a2, 1
	syscall

	# G
	sw $t2, buffer
	li $v0, 15
	syscall

	# R
	sw $a3, buffer
	li $v0, 15
	syscall

	# Then see if we're done with the column

	lw $t0, column
	addi $t0, $t0, -1
	bne $t0, $0, bmp.write_pixel.done

	sw $0, buffer
	# Write <padding> zeroes from <buffer>
	la $a1, buffer
	lw $a2, padding
	li $v0, 15 # write
	syscall

	ulw $t0, head.width # Reset the column counter
bmp.write_pixel.done:
	sw $t0, column
	jr $ra
