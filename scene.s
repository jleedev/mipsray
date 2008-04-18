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

# <objects>
# linked list. pointer in word 0; data follows
# - word 0 -> next <objects> node or 0
# - word 1 -> material
# - word 2 some code for the type
# - subsequent words type-specific

# <lights>
# - null-terminated list of pairs
# - each pair has 3-vectors for position and color

# Entities that are not exported

# the type of an object is
# - 0 = sphere
# - fields position, radius
# - 1 = plane
# - fields normal, distance (like in pov)

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
	
