/*
    Lab06-Building Memory Heirarchy - Part 1
    Group-26 (E/18/245,E/18/017)
*/

/********CPU********/
`timescale 1ns/100ps
module cpu(PC, INSTRUCTION, CLK, RESET,BUSYWAIT,READ,WRITE,WRITEDATA,READDATA,ADDRESS,INSBUSYWAIT);
    input [31:0] INSTRUCTION;//Fetched Instruction
    input CLK,RESET,BUSYWAIT,INSBUSYWAIT;
    output wire [31:0] PC;//Program Counter
    output READ,WRITE;
    input [7:0] READDATA;
    output [7:0] WRITEDATA,ADDRESS;
    
    //registerRD-write reg
    //registerRS-read reg2
    //registerRT-read reg1
    wire [2:0] registerRD,registerRS,registerRT;
    wire [7:0] OUTCODE,IMMEDIATE,TARGET;
    wire ISIMMEDIATE,ISSUB,WRITEENABLE,A_WRITE,ISJUMP,ISBRANCH_EQUAL,ISBRANCH_NOTEQUAL,ISDATA_SELECT;//control signals
    wire [1:0] SHIFT;
    wire [2:0] ALUOUT;//ALU selection OUTeration 
    //TWOSCOMOUT-output of two's complement
    //MUX_1OUT-Two's complement Selection MUX output
    //MUX_2OUT-IMMEDIATE Selection MUX output
    wire [7:0] TWOSCOMOUT,MUX1OUT,MUX2OUT,MUX4OUT,OUT1,OUT2,ALURESULT;
    wire [31:0] PCnext,Addr_Out,MUX3OUT;

    wire ISB,ALUZERO,ISJ,ISBN;

    //Decoding the INSTRUCTION
    assign OUTCODE=INSTRUCTION[31:24];//(OUTCODE:(bits 31-24))-identifies the instruction's OUTeration
    assign registerRT=INSTRUCTION[15:8];//(RT:(bits 15-8))-register to be read from in the register file
    assign registerRS=INSTRUCTION[7:0];//(RS/IMM: (bits 7-0))-register to be read from in the register file
    assign registerRD=INSTRUCTION[23:16];//(RD/IMM:(bits 23-16))-register to be written into
    assign IMMEDIATE=INSTRUCTION[7:0];
    assign TARGET=INSTRUCTION[23:16];

    assign ADDRESS=ALURESULT;
    assign WRITEDATA=OUT1;

 
    //initiating the control unit module
    CU cu(OUTCODE,ALUOUT,ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH_EQUAL,ISBRANCH_NOTEQUAL,ISDATA_SELECT,SHIFT,READ,WRITE,BUSYWAIT);
    //for holding the write enable signal until busywait is de-asserted by memory
    assign A_WRITE=WRITEENABLE & !BUSYWAIT;
    //initiating 2x1mux 8 bitsmodule for selection for passing data from data memory or alu result
    MUX_8 mux_4 (ALURESULT,READDATA,ISDATA_SELECT,MUX4OUT); 
    //initiating the reg_file module
    reg_file myregfile(MUX4OUT,OUT1,OUT2,registerRD,registerRT,registerRS,A_WRITE,CLK,RESET,BUSYWAIT,INSBUSYWAIT);
    //initiating the two's complement module
    TWOS_COMPLEMENT tc(OUT2,TWOSCOMOUT);
    //initiating 2x1mux 8 bits module for selection of two's complement value
    MUX_8 mux_1(OUT2,TWOSCOMOUT,ISSUB,MUX1OUT);
    //initiating 2x1mux bits module for immediate value selection
    MUX_8 mux_2(MUX1OUT,IMMEDIATE,ISIMMEDIATE,MUX2OUT);
    //initiate Adder module to increment PC value
    Adder addr(PC,32'h0004,PCnext);
    //initiating Branch/jump adder to compute the target address
    //sign extend the MSB to 32bits and shift left two bits
    B_Adder baddr(PCnext,{{22{TARGET[7]}},TARGET,2'b00},Addr_Out);
    //initiating 2x1 mux 32 bits module for branch selection
    MUX_32 mux_3(PCnext,Addr_Out,ISJ,MUX3OUT);
    //initiating program counter module
    PC_ pc(PC,MUX3OUT,BUSYWAIT,CLK,RESET,INSBUSYWAIT);
    //initiating alu module
    alu myalu(OUT1,MUX2OUT,ALURESULT,ALUZERO,ALUOUT,SHIFT,IMMEDIATE);
    
    //for beq instruction 
    and and_1(ISB,ISBRANCH_EQUAL,ALUZERO);
    //for bne instruction 
    and and_2(ISBN,ISBRANCH_NOTEQUAL,~ALUZERO);
    //for j instruction
    or or_1(ISJ,ISB,ISBN,ISJUMP);
    

endmodule

/********Program Counter********/
module PC_(PC,PCnext,BUSYWAIT,CLK,RESET,INSBUSYWAIT);
    input CLK,RESET,BUSYWAIT,INSBUSYWAIT;
    output reg[31:0] PC;
    input [31:0] PCnext;

    always @(posedge CLK ) begin
    #0.1
        if(RESET)begin
            #0.9 PC<=0;//one time unit delay for PC update
        end
        else if(!BUSYWAIT && !INSBUSYWAIT)begin//holding fetching the next instruction until the BUSYWAIT signa is de-asserted in the memory
            #0.9 PC<=PCnext;//one time unit delay for PC update
        end
    end
endmodule

/********Adder********/
module Adder(INP1,INP2,OUT);
    input [31:0] INP1,INP2;
    output reg [31:0] OUT;
    always @(*) begin
       #1 OUT=INP1+INP2;
    end
endmodule

/********2x1 Mux_8 bit input********/
module MUX_8(IN1,IN2,SEL,OUT);
    input [7:0] IN1,IN2;// MUX inputs
    input SEL;//selection signal
    output reg [7:0] OUT;//MUX output

    //selection done based on the select signal 
    always @ (IN1,IN2,SEL)
    begin
        if(SEL == 1'b0)
        begin
            OUT = IN1;
        end
        else begin
            OUT = IN2;
        end
    end
endmodule

/********2x1 Mux_32 bit input********/
module MUX_32(IN1,IN2,SEL,OUT);
    input [31:0] IN1,IN2;// MUX inputs
    input SEL;//selection signal
    output reg [31:0] OUT;//MUX output

    //selection done based on the select signal 
    always @ (IN1,IN2,SEL)
    begin
        if(SEL == 1'b0)
        begin
            OUT = IN1;
        end
        else begin
            OUT = IN2;
        end
    end
endmodule

/********2's Complement********/
module TWOS_COMPLEMENT(IN,RESULT);
    input [7:0] IN;//input declaration
    output reg [7:0] RESULT;//output declaration

    always @(IN) begin
        #1 RESULT= ~IN+1;//2s complement value
    end
endmodule

/********Control Unit********/
module CU(OUTCODE,ALUOUT,ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH_EQUAL,ISBRANCH_NOTEQUAL,ISDATA_SELECT,SHIFT,READ,WRITE,BUSYWAIT);
//ISIMMEDIATE - selection pin for selecting immediate value
//ISSUB -selection pin for ADD and SUB OUTtion
//WRITEENABLE- WRITE enable pin
    input BUSYWAIT;
    input [7:0] OUTCODE;
    output reg [2:0] ALUOUT;
    output reg ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH_EQUAL,ISBRANCH_NOTEQUAL,ISDATA_SELECT,READ,WRITE;
    output reg [1:0] SHIFT;
    always @(*)
    begin
        #1//one time unit  for instruction decode
        case(OUTCODE)//Generating control signals based on OUTCODE
            8'b00000000://loadi
                begin
                    ALUOUT=3'b000;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00000001://mov
                begin
                    ALUOUT=3'b000;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00000010://add
                begin
                    ALUOUT=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00000011://sub
                begin
                    ALUOUT=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b1;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00000100://and
                begin
                    ALUOUT=3'b010;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00000101://or
                begin
                    ALUOUT=3'b011;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00000110://jump
                begin
                    ALUOUT=3'b100;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b0;
                    ISJUMP=1'b1;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00000111://beq
                begin
                    ALUOUT=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b1;
                    WRITEENABLE=1'b0;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b1;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00001100://mult
                begin
                    ALUOUT=3'b100;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00001101://bne
                begin
                    ALUOUT=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b1;
                    WRITEENABLE=1'b0;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b1;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00001110://sll
                begin
                    ALUOUT=3'b101;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    SHIFT=2'b01;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00001111://srl
                begin
                    ALUOUT=3'b101;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    SHIFT=2'b00;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00010000://sra
                begin
                    ALUOUT=3'b101;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    SHIFT=2'b10;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00010001://ror
                begin
                    ALUOUT=3'b101;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    SHIFT=2'b11;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b0;
                end
            8'b00001000://lwd
                begin
                    ALUOUT=3'b000;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    SHIFT=2'b00;
                    ISDATA_SELECT=1'b1;
                    READ=1'b1;
                    WRITE=1'b0;
                end
            8'b00001001://lwi
                begin
                    ALUOUT=3'b000;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b1;
                    READ=1'b1;
                    WRITE=1'b0;
                end
            8'b00001010://swd
                begin
                    ALUOUT=3'b000;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b0;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b1;
                end
            8'b00001011://swi
                begin
                    ALUOUT=3'b000;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b0;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    ISDATA_SELECT=1'b0;
                    READ=1'b0;
                    WRITE=1'b1;
                end
        endcase
    end
endmodule

/********Branch Adder********/
//used to compute the branch/jump target address based on the next PC value and the offset provided by the branch/jump instruction
module B_Adder(INP1,INP2,OUT);
    input [31:0] INP1,INP2;
    output reg [31:0] OUT;
    always @(*) begin
       #2 OUT=INP1+INP2;
    end
endmodule




