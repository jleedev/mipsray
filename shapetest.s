# Sphere Intersection Tester
	.data
prompt:
	.asciiz "Enter Ray Postion (x,y,z), Direction (x,y,z), Sphere Center (x,y,z) and Sphere Radius (r)\n"
ret:
	.asciiz "\n"
sphere:	.word 0,0,0,0,0,0,0,0,0
ray:	.word 0,0,0,0,0,0,0,0,0,0,0,0
	.text
	.globl main
main:
	la $a0, prompt
	li $v0, 4
	syscall
	la $s0, ray
	la $s1, sphere
	li $v0, 7
	syscall
	s.d $f0, 0($s0)
	syscall
	s.d $f0, 8($s0)
	syscall
	s.d $f0, 16($s0)
	syscall
	s.d $f0, 24($s0)
	syscall
	s.d $f0, 32($s0)
	syscall
	s.d $f0, 40($s0)
	syscall
	s.d $f0, 4($s1)
	syscall
	s.d $f0, 12($s1)
	syscall
	s.d $f0, 20($s1)
	syscall
	s.d $f0, 28($s1)
	# Test Intersect
	la $a0, ray
	la $a1, sphere
	jal sphere.intersect
	beq $v0, $zero, exit
	add $a0, $v0, $zero
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, ret
	syscall
	li $v0, 3
	mov.d $f12, $f0
	syscall
	li $v0, 4
	la $a0, ret
	syscall
	#Test Reflect
	la $a0, ray
	la $a1, sphere
	jal sphere.reflect
	add $s3, $v0, $zero
	li $v0, 3
	l.d $f12, 0($s3)
	syscall
	li $v0, 4
	la $a0, ret
	syscall
	li $v0, 3
	l.d $f12, 8($s3)
	syscall
	li $v0, 4
	la $a0, ret
	syscall
	li $v0, 3
	l.d $f12, 16($s3)
	syscall
	li $v0, 4
	la $a0, ret
	syscall
	li $v0, 3
	l.d $f12, 24($s3)
	syscall
	li $v0, 4
	la $a0, ret
	syscall
	li $v0, 3
	l.d $f12, 32($s3)
	syscall
	li $v0, 4
	la $a0, ret
	syscall
	li $v0, 3
	l.d $f12, 40($s3)
	syscall
	li $v0, 4
	la $a0, ret
	syscall
exit:
	li $v0, 10
	syscall
