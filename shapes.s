	.data
zero:
	.double 0.0
one:
	.double 1.0
two:
	.double 2.0
	.text
	.globl intersect
	.globl scalar.v

# Main intersection code
# Given:
# $a0 pointer to the ray
# $a1 pointer to the shape
# Returns the first hit distance in $f0
intersect:
	# We perform a dispatch on the type of the shape
	# and call the appropriate specific method
	# We need to transform the ray into object space

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
	l.d $f6, 4($a1)
	l.d $f8, 12($a1)
	l.d $f10, 20($a1)
	jal sub.v	# Calculate v=s-p
	# Put s-p in $f{6,8,10}
	mov.d $f6, $f24
	mov.d $f8, $f26
	mov.d $f10, $f28
	# Put plane normal (n) in $f{0,2,4}
	l.d $f0, 28($a1)
	l.d $f2, 36($a1)
	l.d $f4, 44($a1)
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
	# $v0 is already set appropriately by "linear"
	add $ra, $t1, $zero	# Restore return address
	jr $ra			# Return

# Gives the reflected ray of a ray that hits a plane
# Inputs:	$a0 pointer to ray
#	 	$a1 pointer to shape
# Outputs:	$v0 memory address of reflected ray
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
	s.d $f24, 0($gp)
	s.d $f26, 8($gp)
	s.d $f28, 16($gp)
	# Load n to f0-f4
	l.d $f0, 28($a1)
	l.d $f2, 36($a1)
	l.d $f4, 44($a1)
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
	s.d $f24, 24($gp)
	s.d $f26, 32($gp)
	s.d $f28, 40($gp)
	add $v0, $gp, $zero	# Return memory address
	addi $gp, $gp, 48	# Adjust gp
	add $ra, $t2, $zero	# Restore $ra
	jr $ra			# Return	

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
	l.d $f6, 4($a1)
	l.d $f8, 12($a1)
	l.d $f10, 20($a1)
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
	l.d $f28, 28($a1)	# Radius (r)
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
	s.d $f24, 0($gp)
	s.d $f26, 8($gp)
	s.d $f28, 16($gp)
	# Put y in f0-f4
	mov.d $f0, $f24
	mov.d $f2, $f26
	mov.d $f4, $f28
	# Load Circle Center (c)
	l.d $f6, 4($a1)
	l.d $f8, 12($a1)
	l.d $f10, 20($a1)
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
	s.d $f24, 24($gp)
	s.d $f26, 32($gp)
	s.d $f28, 40($gp)
	add $v0, $gp, $zero	# Return memory address
	addi $gp, $gp, 48	# Adjust gp
	add $ra, $t2, $zero	# Restore $ra
	jr $ra			# Return
	
