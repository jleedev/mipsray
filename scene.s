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
# - word 2 -> matrix
# - word 3 some code for the type
# - subsequent words type-specific

# <lights>
# - null-terminated list of pairs
# - each pair has 3-vectors for position and color

# Entities that are not exported

# a matrix is four 3-vectors; that is, twelve doubles
# [Ax Ay Az 0]
# [Bx By Bz 0]
# [Cx Cy Cz 0]
# [Dx Dy Dz 1]

# the type of an object is
# - 1 = sphere
# - fields position, radius
# - 2 = plane
# - fields normal, distance (like in pov)

# a material is
# - 3-vector for color
# XXX will be expanded later

	.data
	.globl objects
objects:
