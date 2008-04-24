# A scene must export the following symbols

# <filename>
# - asciiz string, not including the ".bmp" extension
# <image.width>
# - unsigned word
# <image.height>
# - unsigned word

# <camera>
# four 3-vectors of doubles
# - location
# - direction
# - right (Length of vector = width of frame)
# - up (Length of vector = height of frame)
# - word 0,1,2,3,4,5 -> Camera X,Y,Z
# - word 6,7,8,9,10,11 -> Corner X,Y,Z
# - word 12,13,14,15,16,17 -> Right X,Y,Z
# - word 18,19,20,21,22,23 -> Up X,Y,Z

# <objects> (Allocate 22 Words for each object)
# linked list. pointer in word 0; data follows
# - word 0 -> next <objects> node or 0
# - word 1 -> type
# - word 2,3 -> ColorR
# - word 4,5 -> ColorG
# - word 6,7 -> ColorB
# - word 8 -> Reflectivity
# - word 9 -> Shininess
# - subsequent words type-specific

# <lights>
# - null-terminated list of pairs
# - each pair has 3-vectors for position and color
# - word 0 -> next light (or 0)
# - word 2,3 -> X Position
# - word 4,5 -> Y Position
# - word 6,7 -> Z Position
# - word 8,9 -> R
# - word 10,11 -> G
# - word 12,13 -> B

# Entities that are not exported

# Rays
# - words 0,1,2,3,4,5 -> Point from which the ray starts
# - words 6,7,8,9,10,11 -> Unit Vector in Direction of Ray

# the type of an object is
# - 0 = sphere
# - fields position, radius (8 Words total)
# - 1 = plane
# - fields point on plane, normal (12 Words total)

# a material is
# - 3-vector for color
# XXX will be expanded later

	.data
	.globl camera
# The Camera/Frame
camera:	.double 0.0,-5.0,5.0	# Camera
	.double -5.0,0.0,0.0	# Corner
	.double 10.0,0.0,0.0	# Right
	.double 0.0,0.0,10.0	# Up

	.globl objects
	.globl lights
	.globl ambient
	.globl diffuse
	.globl background
objects:	.word 0		# Pointer to first element of objects list
lights:		.word 0		# Pointer to first element of lights list
# These Should Sum to 1
ambient:	.double 0.2, 0.2, 0.2	# Ambient Coefficient
diffuse:	.double 0.8, 0.8, 0.8	# Diffuse Coefficient
background:	.double 0.0, 0.0, 0.0		# Background Color

# Object Variables
sphere2:	.word 0,0	# Pointer, Type
		.double 0.5,0.0,0.5	# Color
		.double 0.4		# Reflectivity
		.double -4.0,7.0,4.0	# Center
		.double 4.0,0.0,0.0	# Radius
plane2:		.word 0,1	# Pointer, Type
		.double 0.3,0.3,0.3	# Color
		.double 0.2		# Reflectivity
		.double 0.0,0.0,0.0	# Point
		.double 0.0,0.0,1.0	# Normal
sphere1:	.word 0,0	# Pointer, Type
		.double 0.0,1.0,1.0	# Color
		.double 0.6		# Reflectivity
		.double 4.0,13.0,10.0	# Center
		.double 5.5,0.0,0.0	# Radius
light1:		.word 0,0
		.double 10.0,10.0,15.0	# Position
		.double 1.0,1.0,1.0	# Color
light2:		.word 0,0
		.double -10.0,5.0,15.0	# Position
		.double 1.0,1.0,1.0	# Color
	.text
	.globl scene.init
scene.init:
	# Initialize objects linked list
	la $t0, objects
	la $t1, sphere1
	sw $t1, 0($t0)	# Make "objects" point to "sphere1"
	la $t0, sphere2
	sw $t0, 0($t1)	# Make "shere1" point to "plane2"
	la $t1, plane2
	sw $t1, 0($t0)	# Make plane2 point to sphere2

	# Initialize lights linked list
	la $t0, lights
	la $t1, light1
	sw $t1, 0($t0)	# Make "lights" point to "light1"
	la $t0, light2
	sw $t0, 0($t1)	# Make "light1" point to "light2"
	jr $ra
