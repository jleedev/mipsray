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
	bgt $a1, $zero, cont1
	jr $ra			# Return if recursion levels left is <= 0
cont1:
	# Allocate Space on the Stack
	# Need 9 Additional Words on Stack (6 for color, 1 for $ra, 2 for $s0-1)
	# $fp := previous $fp, $sp := previous $sp (2 extra words on stack)
	sw $fp, -4($sp)
	addi $fp, $sp, -4
	sw $sp, -32($fp)
	addi $sp, $fp, -32
	
	sw $ra, -4($fp)		# Put $ra on stack
	sw $s0, -8($fp)		# Put $s0 on stack
	sw $s1, -12($fp)	# Put $s1 on stack
	
	# Use $s0 to store if an intersection has been found
	add $s0, $a1, $zero	# Store $a1
	# Use $s1 to store pointer to nearest object
	add $s1, $zero, $zero	# Initialize Nearest object to "NULL"
	
	jal nearestHit		# Get the closest hit object
	
	bne $v0, $zero, aHit	# Has there been a hit?
	# No hit, set color to black (or background color)
	la $t0, background
	l.d $f0, 0($t0)
	l.d $f2, 8($t0)
	l.d $f4, 16($t0)
	j endTrace
	
aHit:
	add $s1, $v1, $zero	# Store nearest object's address
	add $a1, $v1, $zero	# Set nearest object as argument for shadow
	jal shadow		# Calculate intensity
	# Load Object Color
	l.d $f6, ??($s1)
	l.d $f8, ??($s1)
	l.d $f10, ??($s1)
	# Multiply intensity times color
	mul.d $f0, $f0, $f6
	mul.d $f2, $f2, $f8
	mul.d $f4, $f4, $f10
	# Store point color to stack
	s.d $f0, -16($fp)
	s.d $f2, -24($fp)
	s.d $f4, -32($fp)
	# Generate a reflected ray, and call recursively on this ray
	add $a1, $s1, $zero	# Set argument for reflect
	jal reflect
	add $s1, $a0, $zero	# Save $a0
	add $a0, $v0, $zero	# Make reflected ray an argument
	addi $a1, $s0, -1	# Decrement $a1
	jal raytrace		# Call recursively on relfected ray
	addi $gp, $gp, -48	# Delete Reflected Ray From Memory
	# Given returned color, add to contribution from shadow/light appropriately
	l.d $f28, ??($s1)	# Get reflectivity of surface
	# Multiply reflectivity times returned value
	mul.d $f0, $f0, $f28
	mul.d $f2, $f2, $f28
	mul.d $f4, $f4, $f28
	# Get point color
	l.d $f6, -16($fp)
	l.d $f8, -24($fp)
	l.d $f10, -32($fp)
	add.v			# Add point color and reflected color
	# Move Result to f0-f4
	mov.d $f24, $f0
	mov.d $f26, $f2
	mov.d $f28, $f4
	# Normalize so that the max value is 1
	li $t0, 1
	mtc1 $t0, $f28
	cvt.d.w $f28, $f28
	c.lt.d $f0, $f28
	movf.d $f0, $f28
	c.lt.d $f2, $f28
	movf.d $f2, $f28
	c.lt.d $f4, $f28
	movf.d $f4, $f28
endTrace:
	lw $ra, -4($fp)		# Restore $ra
	lw $s0, -8($fp)		# Restore $s0
	lw $s1, -12($fp)	# Restore $s1
	lw $fp, 0($fp)		# Restore $fp
	lw $sp, 0($sp)		# Restore $sp
	jr $ra

# Calculates the light intensity at a point
# Given:
# $a0 pointer to ray
# $a1 pointer to object
# Returns intensity in <$f0, $f2, $f4>
shadow:
	sw $ra, -4($sp)		# Put $ra on stack
	sw $s0, -8($sp)		# Put $s0 on stack
	sw $a0, -12($sp)	# put $a0 on stack
	# There's a spot on the stack for a normal vector (6 words) 56,64,72
	# There's a spot on the stack for the point of intersection (6 words) 32,40,48
	# There's a spot on the stack for the distance to the light (2 words) 24
	# There's a spot on the stack for the intensity (6 words) 0,8,16
	# 22 Words total on stack
	addi $sp, $sp, -92	# Adjust $sp
	
	jal normal	# Calculate normal to intersection
	# Put normal on stack
	s.d $f0, 56($sp)
	s.d $f2, 64($sp)
	s.d $f4, 72($sp)
	
	jal intersect	# Get intersection
	mov.d $f30, $f0	# Move $f0 to $f30
	# Load Ray Direction
	l.d $f0, 24($a0)
	l.d $f2, 32($a0)
	l.d $f4, 40($a0)
	# Multiply distance time direction vector
	mul.d $f0, $f0, $f30
	mul.d $f2, $f2, $f30
	mul.d $f4, $f4, $f30
	# Load Ray Source
	l.d $f6, 0($a0)
	l.d $f8, 8($a0)
	l.d $f10, 16($a0)
	jal add.v	# Add to find intersection point
	# Store intersection point to stack
	s.d $f24, 32($sp)
	s.d $f26, 40($sp)
	s.d $f28, 48($sp)
	
	lw $s0, lights($zero)	# Set $s0 to point to first light source
	# Initialize Intensity, put on stack
	mtc1 $zero, $f0
	cvt.d.w $f0, $f0
	s.d $f0, 0($sp)
	s.d $f0, 8($sp)
	s.d $f0, 16($sp)
nextLight:			# Loop through lights
	beq $s0, $zero, endLight	# Break loop when light pointer is NULL
	# Calculate Distance to Light Source (Put on Stack)
	# Load Light Source Position
	l.d $f0, 4($s0)
	l.d $f2, 12($s0)
	l.d $f4, 20($s0)
	# Load Intersection Point
	l.d $f6, 32($sp)
	l.d $f8, 40($sp)
	l.d $f10, 48($sp)
	jal sub.v	# Get vector from intersection to light
	# Move Result to f0-f4
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, $f28
	jal unit.v	# Get normal vector pointing to light, and magnitude in f30
	s.d $f30, 24($sp)	# Put Distance on Stack
	# Put a shadow ray on the Heap
	addi $a0, $gp, 4	# Set pointer to first word after $gp
	# Put Intersection point on heap
	s.d $f6, 4($gp)
	s.d $f8, 12($gp)
	s.d $f10, 20($gp)
	# Put normal vector on heap
	s.d $f24, 28($gp)
	s.d $f26, 36($gp)
	s.d $f28, 44($gp)
	addi $gp, $gp, 52	# Adjust $gp
	jal nearestHit		# Call Nearest Hit with shadow ray as argument
	beq $v0, $zero, isLight	# If No Hit goto isLight
	l.d $f2, 24($sp)	# Load distance to light
	c.lt.d $f2, $f0		# If light is closer than hit, goto isLight
	bc1t isLight
	j isShadow
isLight:
	# Calculate Dot of Normal and Shadow Ray Direction
	# Load Intersection Normal
	l.d $f0, 56($sp)
	l.d $f2, 64($sp)
	l.d $f4, 72($sp)
	# Load Shadow Ray Direction
	l.d $f6, -24($gp)
	l.d $f8, -16($gp)
	l.d $f10, -8($gp)
	jal dot.v		# Dot the normals
	# If less than zero, goto isShadow
	mtc1 $zero, $f28
	cvt.d.w $f28, $f28
	c.lt.d $f30, $f28
	bc1t isShadow
	# Raise Dot product to appropriate power?
	# Multiply value times light color
	l.d $f0, 28($s0)
	l.d $f2, 36($s0)
	l.d $f4, 44($s0)
	# Multiply Vector times value in $f30
	mul.d $f0, $f0, $f30
	mul.d $f2, $f2, $f30
	mul.d $f4, $f4, $f30
	# Add to current intensity Value on Stack
	l.d $f6, 0($sp)
	l.d $f8, 8($sp)
	l.d $f10, 16($sp)
	add.v		# Add intensities
	# Store intensity back to Stack
	s.d $f24, 0($sp)
	s.d $f26, 8($sp)
	s.d $f28, 16($sp)
isShadow:
	addi $gp, $gp, -52	# Delete Shadow Ray from Heap
	lw $s0, 0($s0)		# Set $s0 to Next Light
	j nextLight		# Loop through lights
endLight:
	# Load Diffuse Intensity
	l.d $f0, 0($sp)
	l.d $f2, 8($sp)
	l.d $f4, 16($sp)
	# Normalize Intensity so that the max value is 1
	li $t0, 1
	mtc1 $t0, $f28
	cvt.d.w $f28, $f28
	c.lt.d $f0, $f28
	movf.d $f0, $f28
	c.lt.d $f2, $f28
	movf.d $f2, $f28
	c.lt.d $f4, $f28
	movf.d $f4, $f28	
	la $s0, diffuse		# Memory Address of Diffuse Constants
	# Load Diffuse Constants
	l.d $f6, 0($s0)
	l.d $f8, 8($s0)
	l.d $f10, 16($s0)
	# Calculate Diffuse Intensity
	mul.d $f0, $f0, $f6
	mul.d $f2, $f2, $f8
	mul.d $f4, $f4, $f10
	la $s0, ambient		# Memory Address of Diffuse Constants
	# Load Ambient Constants
	l.d $f6, 0($s0)
	l.d $f8, 8($s0)
	l.d $f10, 16($s0)
	# Add ambient and diffuse contributions
	add.d $f0, $f0, $f6
	add.d $f2, $f2, $f8
	add.d $f4, $f4, $f10
	addi $sp, $sp, 92	# Restore $sp
	lw $a0, -12($sp)	# Restore $a0
	lw $s0, -8($sp)		# Restore $s0
	lw $ra, -4($sp)		# Restore $ra
	jal $ra			# Return
