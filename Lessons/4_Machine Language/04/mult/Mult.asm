// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[3], respectively.)

// Put your code here.

// NOTE: Because of the way this algorithm works, it will run faster
// if the smaller factor is placed in R0 and the larger in R1.
// I advice that compilers and JIT compilers take advantage of this
// fact where possible.

// Set R0 -> i
@R0
D=M
@i
M=D

// Set 0 -> result
@R2
M=0

// while i > 0
(WHILE)      
    // if i == 0, goto DONE
    @i
    D=M
    @DONE
    D;JEQ
    // R1 + R2 -> R2
    @R1
    D=M
    @R2
    M=D+M
    // i--
    @i
    M=M-1
@WHILE
0;JMP
(DONE)

// spin
(SPIN)
@SPIN
0;JMP