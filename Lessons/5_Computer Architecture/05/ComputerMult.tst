// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/05/ComputerMult.tst

load Computer.hdl,
output-file ComputerMult.out,
// compare-to ComputerMult.cmp,
output-list time%S1.4.1 RAM16K[0]%D1.7.1 RAM16K[1]%D1.7.1 RAM16K[2]%D1.7.1;

ROM32K load Mult.hack,

set RAM16K[0] 3,
set RAM16K[1] 8,
output;

repeat 100 {
    tick, tock, output;
}