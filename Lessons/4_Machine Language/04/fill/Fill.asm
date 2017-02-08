// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input. 
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel. When no key is pressed, the
// program clears the screen, i.e. writes "white" in every pixel.

// Put your code here.

// Initialize i
(START)
@SCREEN
D=A
@i
M=D

(LOOP)
@KBD        // switch(keyboard value) {
D=M
@KEYDOWN
D;JGT       // branch

(KEYUP)     // case 0:
@i          // follow pointer
A=M
M=0         // clear pixels
@DEFAULT    // break; 
0;JMP

(KEYDOWN)   // case 1:
D=0         // 16 pixels
D=!D        // 1111111111111111
@i          // follow pointer
A=M
M=D         // set pixels
@DEFAULT    // break;
0;JMP

(DEFAULT)   // };
// if i == 24576-1, goto START
@24575
D=A
@i
D=D-M
@START
D;JEQ

// increment i
@i
M=M+1

// loop
@LOOP
0;JMP