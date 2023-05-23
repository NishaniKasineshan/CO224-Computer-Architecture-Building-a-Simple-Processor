/*
    Lab05-Building A Simple Processor Part 3
    Group-26 (E/18/245,E/18/017)
*/

/********CPU********/
module cpu(PC,INSTRUCTION,CLK,RESET);
    input [31:0] INSTRUCTION;//Fetched Instruction
    input CLK,RESET;
    output wire [31:0] PC;//Program Counter

    //registerRD-write reg
    //registerRS-read reg2
    //registerRT-read reg1
    wire [2:0] registerRD,registerRS,registerRT;
    wire [7:0] OPCODE,IMMEDIATE;
    wire ISIMMEDIATE,ISSUB,WRITEENABLE;//control signals
    wire [2:0] ALUOP;//ALU selection operation 
    //TWOSCOMOUT-output of two's complement
    //MUX_1OUT-Two's complement Selection MUX output
    //MUX_2OUT-IMMEDIATE Selection MUX output
    wire [7:0] TWOSCOMOUT,MUX1OUT,MUX2OUT,ALURESULT,OUT1,OUT2;

    //Decoding the INSTRUCTION
    assign OPCODE=INSTRUCTION[31:24];//(OPCODE:(bits 31-24))-identifies the instruction's operation
    assign registerRT=INSTRUCTION[15:8];//(RT:(bits 15-8))-register to be read from in the register file
    assign registerRS=INSTRUCTION[7:0];//(RS/IMM: (bits 7-0))-register to be read from in the register file
    assign registerRD=INSTRUCTION[23:16];//(RD/IMM:(bits 23-16))-register to be written into
    assign IMMEDIATE=INSTRUCTION[7:0];

    PC_ pc(PC,CLK,RESET);
    //initiating the control unit module
    CU cu(OPCODE,ALUOP,ISIMMEDIATE,ISSUB,WRITEENABLE);
    //initiating the reg_file module
    reg_file myregfile(ALURESULT,OUT1,OUT2,registerRD,registerRT,registerRS,WRITEENABLE,CLK,RESET);
    //initiating the two's complement module
    TWOS_COMPLEMENT tc(OUT2,TWOSCOMOUT);
    //initiating 2x1mux module for selection of two's complement value
    MUX mux_1(OUT2,TWOSCOMOUT,ISSUB,MUX1OUT);
    //initiating 2x1mux module for immediate value selection
    MUX mux_2(MUX1OUT,IMMEDIATE,ISIMMEDIATE,MUX2OUT);
    //initiating alu module
    alu myalu(OUT1,MUX2OUT,ALURESULT,ALUOP);
    
endmodule

/********Program Counter********/
module PC_(PC,CLK,RESET);
    input CLK,RESET;
    output reg[31:0] PC;
    wire [31:0] PCnext;
    //initiate Adder module to increment PC value
    Adder addr(PC,32'h0004,PCnext);
    
    always @(posedge CLK ) begin
        if(RESET)begin
            #1 PC<=0;//one time unit delay for PC update
        end
        else begin
            #1 PC<=PCnext;//one time unit delay for PC update
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
/********2x1 Mux********/
module MUX(IN1,IN2,SEL,OUT);
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

/********2's Complement********/
module TWOS_COMPLEMENT(IN,RESULT);
    input [7:0] IN;//input declaration
    output reg [7:0] RESULT;//output declaration
    //initiate Adder module to perform two's complement
    // Adder addr(IN,32'b,OUT)

    always @(IN) begin
        #1 RESULT= ~IN+1;//2s complement value
    end
endmodule

/********Control Unit********/
module CU(OPCODE,ALUOP,ISIMMEDIATE,ISSUB,WRITEENABLE);
//ISIMMEDIATE - selection pin for selecting immediate value
//ISSUB -selection pin for ADD and SUB option
//WRITEENABLE- WRITE enable pin
    input [7:0] OPCODE;
    output reg [2:0] ALUOP;
    output reg ISIMMEDIATE,ISSUB,WRITEENABLE;
    always @(*)
    begin
        #1//one time unit  for instruction decode
        case(OPCODE)//Generating control signals based on OPCODE
            8'b00000000://loadi
                begin
                    ALUOP=3'b000;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                end
            8'b00000001://mov
                begin
                    ALUOP=3'b000;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                end
            8'b00000010://add
                begin
                    ALUOP=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                end
            8'b00000011://sub
                begin
                    ALUOP=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b1;
                    WRITEENABLE=1'b1;
                end
            8'b00000100://and
                begin
                    ALUOP=3'b010;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                end
            8'b00000101://or
                begin
                    ALUOP=3'b011;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                end
        endcase
    end
endmodule;