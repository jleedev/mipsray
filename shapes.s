	.text
	.globl intersect:

# Main intersection code
# Given:
# $a0 pointer to the shape
# $a1 pointer to the ray
# Returns the first hit distance in $f0
intersect:
	# We perform a dispatch on the type of the shape
	# and call the appropriate specific method
	# We need to transform the ray into object space

# Compute the intersections of a sphere and a ray
# Inputs: $a0 pointer to sphere
# Outputs: $a1 pointer to ray
sphere.intersect:
