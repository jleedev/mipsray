	.data
# Length of this header: 0x36 bytes
head.start:     .byte 0x42 0x4d     # "BM"
head.filesize:  .word 0             # file size
                .half 0             # unused 1
                .half 0             # unused 2
                .byte 0x36 0 0 0    # offset of bitmap data
                .byte 0x28 0 0 0    # size of the info subheader
head.width:     .word 0             # width in pixels
head.height:    .word 0             # height in pixels
                .byte 1 0           # number of color planes
                .byte 0x18 0        # bits per pixel
                .word 0             # compression
head.imagesize: .word 0             # size of image data in bytes
                .byte 0x13 0x0b 0 0 # x res in pixels per meter
                .byte 0x13 0x0b 0 0 # y res in pixels per meter
                .word 0             # number of colors
                .word 0             # number of important colors

# Here we record the 
padding:
	.byte 0

bmp1:
	# offset 6: 4 bytes
	# reserved
	.word 0

	.text
	.globl bmp.write_header
	.globl bmp.write_pixel
# Inputs:
# $a0 file descriptor
# $a1 image width
# $a2 image height
bmp.write_header:
	# Compute the size of the image data,
	# assuming 3 bytes per pixel

	# image_size = round_up_to_multiple_of_four(image_width*3)*image_height
	sll $t0, $a1, 1
	add $t0, $t0, $a1
	# To see how many padding bytes are needed,
	# subtract the bottom two bits of $t0 from 4.

	# Calculate the size of the file.

	# Store the size values in the header structure in memory,
	# remembering to get the endianness correct.

	# Finally, write the entire header structure to the file.

# Inputs:
# <R,G,B> in <$a0, $a1, $a2>
bmp.write_pixel:
