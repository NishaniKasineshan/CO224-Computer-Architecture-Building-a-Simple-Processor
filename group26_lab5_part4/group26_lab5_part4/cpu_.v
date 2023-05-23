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
    wire [7:0] OPCODE,IMMEDIATE,TARGET;
    wire ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH;//control signals
    wire [2:0] ALUOP;//ALU selection operation 
    //TWOSCOMOUT-output of two's complement
    //MUX_1OUT-Two's complement Selection MUX output
    //MUX_2OUT-IMMEDIATE Selection MUX output
    wire [7:0] TWOSCOMOUT,MUX1OUT,MUX2OUT,ALURESULT,OUT1,OUT2;
    wire [31:0] PCnext,Addr_Out,MUX3OUT;

    wire ISB,ALUZERO,ISJ;

    //Decoding the INSTRUCTION
    assign OPCODE=INSTRUCTION[31:24];//(OPCODE:(bits 31-24))-identifies the instruction's operation
    assign registerRT=INSTRUCTION[15:8];//(RT:(bits 15-8))-register to be read from in the register file
    assign registerRS=INSTRUCTION[7:0];//(RS/IMM: (bits 7-0))-register to be read from in the register file
    assign registerRD=INSTRUCTION[23:16];//(RD/IMM:(bits 23-16))-register to be written into
    assign IMMEDIATE=INSTRUCTION[7:0];
    assign TARGET=INSTRUCTION[23:16];

    
    //initiating the control unit module
    CU cu(OPCODE,ALUOP,ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH);
    //initiating the reg_file module
    reg_file myregfile(ALURESULT,OUT1,OUT2,registerRD,registerRT,registerRS,WRITEENABLE,CLK,RESET);
    //initiating the two's complement module
    TWOS_COMPLEMENT tc(OUT2,TWOSCOMOUT);
    //initiating 2x1mux 8 bits module for selection of two's complement value
    MUX_8 mux_1(OUT2,TWOSCOMOUT,ISSUB,MUX1OUT);
    //initiating 2x1mux bits module for immediate value selection
    MUX_8 mux_2(MUX1OUT,IMMEDIATE,ISIMMEDIATE,MUX2OUT);
    //initiate Adder module to increment PC value
    Adder addr(PC,32'h0004,PCnext);
    //initiating Branch/jump adder to compute the target address
    //sign extend the MSB to 32bits
    B_Adder baddr(PCnext,{{22{TARGET[7]}},TARGET,2'b00},Addr_Out);
    //initiating 2x1 mux 32 bits module for branch selection
    MUX_32 mux_3(PCnext,Addr_Out,ISJ,MUX3OUT);
    //initiating program counter module
    PC_ pc(PC,MUX3OUT,CLK,RESET);
    //initiating alu module
    alu myalu(OUT1,MUX2OUT,ALURESULT,ALUZERO,ALUOP);
    
    //for beq instruction 
    and and_1(ISB,ISBRANCH,ALUZERO);
    //for j instruction
    or or_1(ISJ,ISB,ISJUMP);
    

endmodule

/********Program Counter********/
module PC_(PC,PCnext,CLK,RESET);
    input CLK,RESET;
    output reg[31:0] PC;
    input [31:0] PCnext;

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
module CU(OPCODE,ALUOP,ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH);
//ISIMMEDIATE - selection pin for selecting immediate value
//ISSUB -selection pin for ADD and SUB option
//WRITEENABLE- WRITE enable pin
    input [7:0] OPCODE;
    output reg [2:0] ALUOP;
    output reg ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH;
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
                    ISJUMP=1'b0;
                    ISBRANCH=1'b0;
                end
            8'b00000001://mov
                begin
                    ALUOP=3'b000;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH=1'b0;
                end
            8'b00000010://add
                begin
                    ALUOP=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH=1'b0;
                end
            8'b00000011://sub
                begin
                    ALUOP=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b1;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH=1'b0;
                end
            8'b00000100://and
                begin
                    ALUOP=3'b010;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH=1'b0;
                end
            8'b00000101://or
                begin
                    ALUOP=3'b011;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH=1'b0;
                end
            8'b00000110://jump
                begin
                    ALUOP=3'b100;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b0;
                    ISJUMP=1'b1;
                    ISBRANCH=1'b0;
                end
            8'b00000111://beq
                begin
                    ALUOP=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b1;
                    WRITEENABLE=1'b0;
                    ISJUMP=1'b0;
                    ISBRANCH=1'b1;
                end
        endcase
    end
endmodule;

/********Branch Adder********/
//used to compute the branch/jump target address based on the next PC value and the offset provided by the branch/jump instruction
module B_Adder(INP1,INP2,OUT);
    input [31:0] INP1,INP2;
    output reg [31:0] OUT;
    always @(*) begin
       #2 OUT=INP1+INP2;
    end
endmodule