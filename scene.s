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
# - right
# - up

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
	.globl objects
	.globl lights
	.globl ambient
	.globl diffuse
	.globl background
objects:	.word 0		# Pointer to first element of objects list
lights:		.word 0		# Pointer to first element of lights list
# These Should Sum to 1
ambient:	.double .1, .1, .1	# Ambient Coefficient
diffuse:	.double .9, .9, .9	# Diffuse Coefficient
background:	.double 0, 0, 0		# Background Color
	.text
scene.init:
	
