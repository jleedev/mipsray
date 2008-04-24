	.data
zero:	.double 0.0
one:	.double 1.0
two:	.double 2.0
tiny:	.double 0.00000001
	.text
	.globl intersect
	.globl reflect
	.globl normal
	.globl nearestHit

# Return the object that is first hit by a ray
# Given:
# $a0 pointer to the ray
# Returns:
# $v0 1 if there is a hit, 0 if not
# $v1 memory address of first object hit (if there is one)
# $f0 The distance to the closest hit
nearestHit:
	add $v0, $zero, $zero	# Initialize $v0
	sw $ra, -4($sp)		# Put $ra on stack
	sw $s0, -8($sp)		# Put $s0 on stack
	sw $s1, -12($sp)	# Put $s1 on stack
	sw $s2, -16($sp)	# Put $s2 on stack
	# There is a spot (2 words) for temporarily storing the closest hit distance
	addi $sp, $sp, -24	# Adjust $sp
	lw $s0, objects($zero)	# load pointer to first object
	add $s1, $zero, $zero	# Initialize $s1 (for storing pointer to closest object)
	add $s2, $zero, $zero	# Initialize $s2 (has there been a hit yet?)
nextObj:
	beq $s0, $zero, exitObjs	# Loop while current object is not NULL
	add $a1, $s0, $zero		# Put object pointer into $a1
	jal intersect			# Calculate Intersection
	beq $v0, $zero, noHit		# Was there a hit?
	# Yes, there was a hit (update nearest if necessary)
	beq $s2, $zero, closeHit	# If there haven't yet been any hits, this is the closest
	# Otherwise, see if this hit is closer than before
	l.d $f2, 0($sp)			# Bring closest hit distance to $f2
	c.lt.d $f2, $f0			# Is old value smaller than current value?
	bc1t noHit			# If so, then this is not a hit
	# Otherwise, it was a hit
closeHit:
	addi $s2, $zero, 1		# There has been a hit
	add $s1, $s0, $zero		# Put object address in $s1
	s.d $f0, 0($sp)			# Put hit distance into spot on stack
noHit:
	lw $s0, 0($s0)		# Make $s0 point to the next object in the object list
	j nextObj			# Loop
exitObjs:
	add $v0, $s2, $zero	# Has there been a hit yet?
	add $v1, $s1, $zero	# Store pointer to closest object
	l.d $f0, 0($sp)		# Store closest hit distance
	addi $sp, $sp, 24	# Restore $sp
	lw $s2, -16($sp)	# Restore $s2
	lw $s1, -12($sp)	# Restore $s1
	lw $s0, -8($sp)		# Restore $s0
	lw $ra, -4($sp)		# Restore $ra
	jr $ra			# Return

# Main intersection code
# Given:
# $a0 pointer to the ray
# $a1 pointer to the shape
# Returns the first hit distance in $f0
#		$v0 1 if intersection, 0 if not
intersect:
	sw $ra, -4($sp)		# Put $ra on stack
	addi $sp, $sp, -4	# Adjust $sp
	lw $t0, 4($a1)		# Put shape type in $t0
	add $t1, $zero, $zero	# Initialize $t1 to 0
	bne $t0, $t1, nextInt1	# Is it a Sphere?
	jal sphere.intersect	# Call appropriate routine
	j endInt
nextInt1:
	addi $t1, $t1, 1	# Try next shape
	bne $t0, $t1, nextInt2	# Is it a Plane?
	jal plane.intersect	# Call appropriate routine
	j endInt
nextInt2:
	add $v0, $zero, $zero	# Invalid Shape
endInt:
	addi $sp, $sp, 4	# Restore $sp
	lw $ra, -4($sp)		# Restore $ra
	jr $ra			# Return

# Main reflection code
# Given:
# Inputs:	$a0 pointer to ray
#	 	$a1 pointer to shape
#		$a2 place to put reflected ray in memory
# Outputs:	$v0 memory address of reflected ray
reflect:
	sw $ra, -4($sp)		# Put $ra on stack
	addi $sp, $sp, -4	# Adjust $sp
	lw $t0, 4($a1)		# Put shape type in $t0
	add $t1, $zero, $zero	# Initialize $t1 to 0
	bne $t0, $t1, nextRef1	# Is it a Sphere?
	jal sphere.reflect	# Call appropriate routine
	j endRef
nextRef1:
	addi $t1, $t1, 1	# Try next shape
	bne $t0, $t1, nextRef2	# Is it a Plane?
	jal plane.reflect	# Call appropriate routine
	j endRef
nextRef2:
	add $v0, $zero, $zero	# Invalid Shape
endRef:
	addi $sp, $sp, 4	# Restore $sp
	lw $ra, -4($sp)		# Restore $ra
	jr $ra			# Return

# Main normal code:
# Given:
# $a0 pointer to ray
# $a1 pointer to shape
# Returns normal in <$f0, $f2, $f4>
normal:
	sw $ra, -4($sp)		# Put $ra on stack
	addi $sp, $sp, -4	# Adjust $sp
	lw $t0, 4($a1)		# Put shape type in $t0
	add $t1, $zero, $zero	# Initialize $t1 to 0
	bne $t0, $t1, nextNor1	# Is it a Sphere?
	jal sphere.normal	# Call appropriate routine
	j endNor
nextNor1:
	addi $t1, $t1, 1	# Try next shape
	bne $t0, $t1, nextNor2	# Is it a Plane?
	jal plane.normal	# Call appropriate routine
	j endNor
nextNor2:
	# Invalid Shape
endNor:
	addi $sp, $sp, 4	# Restore $sp
	lw $ra, -4($sp)		# Restore $ra
	jr $ra			# Return

# Compute the intersections of a plane and a ray
# Inputs:	$a0 pointer to ray
#		$a1 pointer to shape
# Outputs:	first hit distance in $f0
#		$v0 1 if intersection, 0 if not
plane.intersect:
	add $t1, $ra, $zero	# Save return address
	# Put Ray Source (s) in $f{0,2,4}
	l.d $f0, 0($a0)
	l.d $f2, 8($a0)
	l.d $f4, 16($a0)
	# Put plane point (p) in $f{6,8,10}
	l.d $f6, 40($a1)
	l.d $f8, 48($a1)
	l.d $f10, 56($a1)
	jal sub.v	# Calculate v=s-p
	# Put s-p in $f{6,8,10}
	mov.d $f6, $f24
	mov.d $f8, $f26
	mov.d $f10, $f28
	# Put plane normal (n) in $f{0,2,4}
	l.d $f0, 64($a1)
	l.d $f2, 72($a1)
	l.d $f4, 80($a1)
	jal dot.v	# Calculate n.(s-p)
	mov.d $f18, $f30	# Move result temporarily
	# Put Ray Direction (d) in $f{6,8,10}
	l.d $f6, 24($a0)
	l.d $f8, 32($a0)
	l.d $f10, 40($a0)
	jal dot.v	# Calculate n.d
	mov.d $f0, $f30	# Put n.d in $f0
	mov.d $f2, $f18	# Put n.(s-p) in $f2
	jal linear	# Solve (n.d)t + (n.(s-p)) = 0
	mov.d $f0, $f28	# Put result in $f0
	# $v0 is already set appropriately by "linear" if n.d = 0
	# If $f0 is negative, it is not a hit
	mtc1 $zero, $f30
	cvt.d.w $f30, $f30
	c.lt.d $f0, $f30
	bc1f donePI
	add $v0, $zero, $zero	# If $f0 < 0, no intersection
donePI:
	add $ra, $t1, $zero	# Restore return address
	jr $ra			# Return

# Gives the reflected ray of a ray that hits a plane
# Inputs:	$a0 pointer to ray
#	 	$a1 pointer to shape
#		$a2 Memory Address of reflected ray
# Outputs:	Reflected ray in $a2 (Address also in $v0)
plane.reflect:
	add $t2, $ra, $zero	# Save Return Address
	jal plane.intersect	# Get Distance (t)
	mov.d $f30, $f0		# Put Distance in f30
	# Load Ray Direction (d)
	l.d $f0, 24($a0)
	l.d $f2, 32($a0)
	l.d $f4, 40($a0)
	jal scalar.v	# t*<d>
	# Save d for Later
	mov.d $f18, $f0
	mov.d $f20, $f2
	mov.d $f22, $f4
	# Load Ray Source (s)
	l.d $f0, 0($a0)
	l.d $f2, 8($a0)
	l.d $f4, 16($a0)
	# Put t*<d> in f6-f10
	mov.d $f6, $f24
	mov.d $f8, $f26
	mov.d $f10, $f28
	jal add.v	# Add to find point of intersection (y)
	# Save y to memory
	s.d $f24, 0($a2)
	s.d $f26, 8($a2)
	s.d $f28, 16($a2)
	# Load n to f0-f4
	l.d $f0, 64($a1)
	l.d $f2, 72($a1)
	l.d $f4, 80($a1)
	# Put d in f6-f10
	mov.d $f6, $f18
	mov.d $f8, $f20
	mov.d $f10, $f22
	jal dot.v	# n.d
	# Put constant 2 in $f28
	la $t0, two
	l.d $f28, 0($t0)
	mul.d $f30, $f28, $f30	# 2(n.d)
	jal scalar.v		# 2(n.d)n
	# Put d in f0-f4
	mov.d $f0, $f18
	mov.d $f2, $f20
	mov.d $f4, $f22
	# Put 2(n.d)n in f6-f10
	mov.d $f6, $f24
	mov.d $f8, $f26
	mov.d $f10, $f28
	jal sub.v		# d-2(n.d)n
	# Put Result in Memory
	s.d $f24, 24($a2)
	s.d $f26, 32($a2)
	s.d $f28, 40($a2)

	# Fix starting point
	la $t0, tiny
	l.d $f0, 0($t0)		# Get a tiny number
	l.d $f2, 0($a2)		# First Component
	mul.d $f24, $f24, $f0	# Tiny*DiretionX
	add.d $f2, $f2, $f24	# Add To X component
	s.d $f2, 0($a2)		# Store Back
	l.d $f2, 8($a2)		# Second Component
	mul.d $f26, $f26, $f0	# Tiny*DiretionY
	add.d $f2, $f2, $f26	# Add To X component
	s.d $f2, 8($a2)		# Store Back
	l.d $f2, 16($a2)		# First Component
	mul.d $f28, $f28, $f0	# Tiny*DiretionX
	add.d $f2, $f2, $f28	# Add To X component
	s.d $f2, 16($a2)		# Store Back
	
	add $v0, $a2, $zero	# Return memory address
	add $ra, $t2, $zero	# Restore $ra
	jr $ra			# Return

# Compute the normal vector to a point of intersection
# Given:
# $a0 pointer to ray
# $a1 pointer to shape
# Returns normal in <$f0, $f2, $f4>
plane.normal:
	# Load n to f0-f4
	l.d $f0, 64($a1)
	l.d $f2, 72($a1)
	l.d $f4, 80($a1)
	jr $ra

# Compute the intersections of a sphere and a ray
# Inputs:	$a0 pointer to ray
#	 	$a1 pointer to shape
# Outputs:	first hit distance in $f0
#		$v0 1 if intersection, 0 if not	
sphere.intersect:
	add $t1, $ra, $zero	# Save return address
	# Put Ray Source (s) in $f{0,2,4}
	l.d $f0, 0($a0)
	l.d $f2, 8($a0)
	l.d $f4, 16($a0)
	# Put sphere center (c) in $f{6,8,10}
	l.d $f6, 40($a1)
	l.d $f8, 48($a1)
	l.d $f10, 56($a1)
	jal sub.v	# Calculate v=s-c
	# Put v in $f{0,2,4}
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, $f28
	# Put Ray Direction (d) in $f{6,8,10}
	l.d $f6, 24($a0)
	l.d $f8, 32($a0)
	l.d $f10, 40($a0)
	jal dot.v	# Calculate v.d
	# Put constant 2 in $f28
	la $t0, two
	l.d $f28, 0($t0)
	mul.d $f20, $f28, $f30	# Calculate 2(v.d), in $f20
	jal mag2.v	# Calculate ||v||^2
	l.d $f28, 64($a1)	# Radius (r)
	mul.d $f28, $f28, $f28	# r^2
	sub.d $f4, $f30, $f28	# Put ||v||^2-r^2 in $f4
	mov.d $f2, $f20		# Put 2(v.d) in $f2
	la $t0, one
	l.d $f0, 0($t0)		# Put constant 1 in $f0
	jal quadratic
	add $ra, $t1, $zero	# Restore return address
	# Put zero in $f0 for comparisons
	la $t0, zero
	l.d $f0, 0($t0)
	bne $v0, $zero, hasRoots
	# If no roots, return infinity
noIntersect:
	la $t0, zero
	l.d $f0, 0($t0)
	li $v0, 0
	jr $ra
hasRoots:
	li $t0, 1
	bne $v0, $t0, twoRoots
	# If has a root, check to see that it's positive
	c.lt.d $f28, $f0
	bc1t noIntersect
	j ret1			#If positive, return it
twoRoots:
	c.lt.d $f28, $f0
	bc1f firstPos		# If root1 is positive, continue check
	c.lt.d $f30, $f0
	bc1t noIntersect	# If both are neg., return infinity
	# Otherwise, root2 is the only positive root (return it)
ret2:
	mov.d $f0, $f30
	li $v0, 1
	jr $ra
firstPos:
	c.lt.d $f30, $f0
	bc1t ret1		# If root2 is neg., then root1 is the only pos. root
	# Otherwise, compare to return the smaller
	c.lt.d $f28, $f30
	bc1t ret1	# If root1 is smaller, return it
	j ret2		# Otherwise, return root2
ret1:
	mov.d $f0, $f28
	li $v0, 1
	jr $ra

# Gives the reflected ray of a ray that hits a sphere
# Inputs:	$a0 pointer to ray
#	 	$a1 pointer to shape
#		$a2 Memory address of relfected ray
# Outputs:	$v0 memory address of reflected ray
sphere.reflect:
	add $t2, $ra, $zero	# Save Return Address
	jal sphere.intersect	# Get Distance (t)
	mov.d $f30, $f0		# Put Distance in f30
	# Load Ray Direction (d)
	l.d $f0, 24($a0)
	l.d $f2, 32($a0)
	l.d $f4, 40($a0)
	jal scalar.v	# t*<d>
	# Save d for Later
	mov.d $f18, $f0
	mov.d $f20, $f2
	mov.d $f22, $f4
	# Load Ray Source (s)
	l.d $f0, 0($a0)
	l.d $f2, 8($a0)
	l.d $f4, 16($a0)
	# Put t*<d> in f6-f10
	mov.d $f6, $f24
	mov.d $f8, $f26
	mov.d $f10, $f28
	jal add.v	# Add to find point of intersection (y)
	# Save y to memory
	s.d $f24, 0($a2)
	s.d $f26, 8($a2)
	s.d $f28, 16($a2)
	# Put y in f0-f4
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, $f28
	# Load Circle Center (c)
	l.d $f6, 40($a1)
	l.d $f8, 48($a1)
	l.d $f10, 56($a1)
	jal sub.v	# y-c
	# Put y-c in f0-f4
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, $f28
	jal unit.v	# Unit normal of intersection (n)
	# Put n in f0-f4
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, ,$f28
	# Put d in f6-f10
	mov.d $f6, $f18
	mov.d $f8, $f20
	mov.d $f10, $f22
	jal dot.v # Calculate n.d
	# Put constant 2 in $f16
	la $t0, two
	l.d $f16, 0($t0)
	mul.d $f30, $f30, $f16	# 2(n.d)
	jal scalar.v		# 2(n.d)<n>
	# Put Result in f6-f10
	mov.d $f6, $f24
	mov.d $f8, $f26
	mov.d $f10, $f28
	# Put d in f0-f4
	mov.d $f0, $f18
	mov.d $f2, $f20
	mov.d $f4, $f22
	jal sub.v	# d-2(n.d)<n>
	# Put Result in Memory
	s.d $f24, 24($a2)
	s.d $f26, 32($a2)
	s.d $f28, 40($a2)

	# Fix starting point
	la $t0, tiny
	l.d $f0, 0($t0)		# Get a tiny number
	l.d $f2, 0($a2)		# First Component
	mul.d $f24, $f24, $f0	# Tiny*DiretionX
	add.d $f2, $f2, $f24	# Add To X component
	s.d $f2, 0($a2)		# Store Back
	l.d $f2, 8($a2)		# Second Component
	mul.d $f26, $f26, $f0	# Tiny*DiretionY
	add.d $f2, $f2, $f26	# Add To X component
	s.d $f2, 8($a2)		# Store Back
	l.d $f2, 16($a2)		# First Component
	mul.d $f28, $f28, $f0	# Tiny*DiretionX
	add.d $f2, $f2, $f28	# Add To X component
	s.d $f2, 16($a2)		# Store Back
	
	add $v0, $a2, $zero	# Return memory address
	add $ra, $t2, $zero	# Restore $ra
	jr $ra			# Return
	
# Finds normal vector to point of intersection
# Given:
# $a0 pointer to ray
# $a1 pointer to sphere
# Returns normal in <$f0, $f2, $f4>
sphere.normal:
	add $t2, $ra, $zero	# Save Return Address
	jal sphere.intersect	# Get Distance (t)
	mov.d $f30, $f0		# Put Distance in f30
	# Load Ray Direction (d)
	l.d $f0, 24($a0)
	l.d $f2, 32($a0)
	l.d $f4, 40($a0)
	jal scalar.v	# t*<d>
	# Load Ray Source (s)
	l.d $f0, 0($a0)
	l.d $f2, 8($a0)
	l.d $f4, 16($a0)
	# Put t*<d> in f6-f10
	mov.d $f6, $f24
	mov.d $f8, $f26
	mov.d $f10, $f28
	jal add.v	# Add to find point of intersection (y)
	# Put y in f0-f4
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, $f28
	# Load Circle Center (c)
	l.d $f6, 40($a1)
	l.d $f8, 48($a1)
	l.d $f10, 56($a1)
	jal sub.v	# y-c
	# Put y-c in f0-f4
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, $f28
	jal unit.v	# Unit normal of intersection (n)
	# Put n in f0-f4
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, ,$f28
	add $ra, $t2, $zero	# Restore $ra
	jr $ra			# Return
