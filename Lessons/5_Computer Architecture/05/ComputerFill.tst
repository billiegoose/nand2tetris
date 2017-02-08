// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/05/ComputerFill.tst

load Computer.hdl,
output-file ComputerFill.out,
// compare-to ComputerFill.cmp,
output-list time%S1.4.1;


ROM32K load Fill.hack,
repeat 1000 {
    tick, tock, output;
}