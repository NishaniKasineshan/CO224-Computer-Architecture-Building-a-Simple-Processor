// Computer Architecture (CO224) - Lab 06
// Design: Testbench of Integrated CPU of Simple Processor
// Author: Isuru Nawinne
//Group 26 E/18/017 E/18/245

`include "alu_0.v"
`include "reg_file.v"
`include "cpu_0.v"
`include "dmem.v"
`include "dcache.v"

`timescale 1ns/1ps
module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
    wire C_READ,C_WRITE,busywait;
    wire [7:0] C_Address,C_READDATA,C_WRITEDATA;
    wire mem_write,mem_read,mem_busywait;
    wire [5:0] mem_address;
    wire [31:0] mem_writedata,mem_readdata;
    /* 
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
    
    // TODO: Initialize an array of registers (8x1024) named 'instr_mem' to be used as instruction memory
    reg[7:0] instr_mem[0:1023];
    // TODO: Create combinational logic to support CPU instruction fetching, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
    //CPU's onstruction fetching mechanism to read the hardcoded instructions asynchronously based on the address provided by PC
    assign #2 INSTRUCTION={instr_mem[PC+3], instr_mem[PC+2], instr_mem[PC+1], instr_mem[PC]};//two time units delay for instruction memory read
    
    initial
    begin
        // Initialize instruction memory with the set of instructions you need execute on CPU
        
        // METHOD 1: manually loading instructions to instr_mem
        //loadi 0 0x09  // r4 = 5
        // {instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]} = 32'b00000000_00000000_00000000_00001001;
        // // //loadi 1 0x01  // r2 = 9
        // {instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]} = 32'b00000000_00000001_00000000_00000001;
        // //swd 0 1 
        // {instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]} = 32'b00010000_00000000_00000000_00000001;
        // //swi 1 0x00  
        // {instr_mem[10'd15], instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]} = 32'b00010001_00000000_00000001_00000000;
        // //lwd 2 1
        // {instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]} = 32'b00001110_00000010_00000000_00000001;
        // //lwd 3 1
        // {instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]} = 32'b00001110_00000011_00000000_00000001;
        // //sub 4 0 1
        // {instr_mem[10'd27], instr_mem[10'd26], instr_mem[10'd25], instr_mem[10'd24]}= 32'b00000011_00000100_00000000_00000001;
        // //swi 4 0x02 
        // {instr_mem[10'd31], instr_mem[10'd30], instr_mem[10'd29], instr_mem[10'd28]}= 32'b00010001_00000000_00000100_00000010;
        // //lwi 5 0x02  
        // {instr_mem[10'd35], instr_mem[10'd34], instr_mem[10'd33], instr_mem[10'd32]}= 32'b00001111_00000101_00000000_00000010;
        // //swi 4 0x20 
        // {instr_mem[10'd39], instr_mem[10'd38], instr_mem[10'd37], instr_mem[10'd36]}= 32'b00010001_00000000_00000100_00010100;
        // //lwi 6 0x20
        // {instr_mem[10'd43], instr_mem[10'd42], instr_mem[10'd41], instr_mem[10'd40]}= 32'b00001111_00000110_00000000_00010100;

        // METHOD 2: loading instr_mem content from instr_mem.mem file
        $readmemb("instr_mem.mem", instr_mem);
    end
    
    /* 
    -----
     CPU
    -----
    */
    //module cpu(PC,INSTRUCTION,CLK,RESET,READ,WRITE,ADDRESS,WRITEDATA,READDATA,BUSYWAIT);
    cpu mycpu(PC,INSTRUCTION, CLK,RESET,C_READ,C_WRITE,C_Address,C_WRITEDATA,C_READDATA,busywait);
    dcache my_dcache(CLK,RESET,C_WRITE,C_READ,C_Address,C_WRITEDATA,C_READDATA,busywait,mem_write,mem_read,mem_address,mem_writedata,mem_readdata,mem_busywait);          
    data_memory my_data_memory(CLK,RESET,mem_read,mem_write,mem_address,mem_writedata,mem_readdata,mem_busywait);

    //(clock,reset,C_WRITE,C_READ,C_Address,C_WRITEDATA,C_READDATA,busywait,mem_write,mem_read,mem_address,mem_writedata,mem_readdata,mem_busywait);
    initial begin
        //check the registers
        $monitor($time, " REG0: %d  REG1: %d  REG2: %d  REG3: %d  REG4: %d  REG5: %d  REG6: %d  REG7: %d ",mycpu.myregfile.registers[0], mycpu.myregfile.registers[1], mycpu.myregfile.registers[2],mycpu.myregfile.registers[3], mycpu.myregfile.registers[4], mycpu.myregfile.registers[5],mycpu.myregfile.registers[6], mycpu.myregfile.registers[7]);
    end
    integer i;
    initial
    begin
        // generate files needed to plot the waveform using GTKWave
         // generate files needed to plot the waveform using GTKWave
       $dumpfile("cpu_wavedata.vcd");
	$dumpvars(0, cpu_tb);
	
        CLK = 1'b0;
        RESET = 1'b1;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        #5 RESET=1'b0;
       
        // finish simulation after some time
        #1000
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        

endmodule
