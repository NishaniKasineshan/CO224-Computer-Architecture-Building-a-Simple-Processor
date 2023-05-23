// Computer Architecture (CO224) - Lab 05
// Design: Testbench of Integrated CPU of Simple Processor
// Author: Isuru Nawinne

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;
    
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
        //loadi 4 0x05  // r4 = 5
         {instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]} = 32'b00000000_00000100_00000000_00000101;
        // //loadi 2 0x09  // r2 = 9
        {instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]} = 32'b00000000_00000010_00000000_00001001;
         // //srl 3 2 0x02	// r1 = 1
        {instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]} = 32'b00001011_00000011_00000010_00000010;
        {instr_mem[10'd15], instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]} = 32'b00001010_00000000_00000100_00000010;
       
        // //mul 6 4 2  // r6 = r4<<2
        {instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]} = 32'b00001000_00000110_00000100_00000010;
        // //bne 0xFD 2 4		// r2 = r2 + r1 (r2++)
        {instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]} = 32'b00001001_11111101_00000010_00000100;
        
        // METHOD 2: loading instr_mem content from instr_mem.mem file
        //$readmemb("instr_mem.mem", instr_mem);
    end
    
    /* 
    -----
     CPU
    -----
    */
    cpu mycpu(PC, INSTRUCTION, CLK, RESET);

    initial begin
        //check the registers
        $monitor($time, " REG0: %d  REG1: %d  REG2: %d  REG3: %d  REG4: %d  REG5: %d  REG6: %d  REG7: %d ",mycpu.myregfile.registers[0], mycpu.myregfile.registers[1], mycpu.myregfile.registers[2],mycpu.myregfile.registers[3], mycpu.myregfile.registers[4], mycpu.myregfile.registers[5],mycpu.myregfile.registers[6], mycpu.myregfile.registers[7]);
    end
    initial
    begin
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
        
        CLK = 1'b0;
        RESET = 1'b0;
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        #2 RESET = 1'b1;

        #4 RESET=1'b0;
        // finish simulation after some time
        #500
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        

endmodule