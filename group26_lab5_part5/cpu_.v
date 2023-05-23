/*
    Lab05-Building A Simple Processor Part 5
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
    wire [7:0] OUTCODE,IMMEDIATE,TARGET;
    wire ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH_EQUAL,ISBRANCH_NOTEQUAL;//control signals
    wire SHIFT;
    wire [2:0] ALUOUT;//ALU selection OUTeration 
    //TWOSCOMOUT-output of two's complement
    //MUX_1OUT-Two's complement Selection MUX output
    //MUX_2OUT-IMMEDIATE Selection MUX output
    wire [7:0] TWOSCOMOUT,MUX1OUT,MUX2OUT,ALURESULT,OUT1,OUT2;
    wire [31:0] PCnext,Addr_Out,MUX3OUT;

    wire ISB,ALUZERO,ISJ,ISBN;

    //Decoding the INSTRUCTION
    assign OUTCODE=INSTRUCTION[31:24];//(OUTCODE:(bits 31-24))-identifies the instruction's OUTeration
    assign registerRT=INSTRUCTION[15:8];//(RT:(bits 15-8))-register to be read from in the register file
    assign registerRS=INSTRUCTION[7:0];//(RS/IMM: (bits 7-0))-register to be read from in the register file
    assign registerRD=INSTRUCTION[23:16];//(RD/IMM:(bits 23-16))-register to be written into
    assign IMMEDIATE=INSTRUCTION[7:0];
    assign TARGET=INSTRUCTION[23:16];

    
    //initiating the control unit module
    CU cu(OUTCODE,ALUOUT,ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH_EQUAL,ISBRANCH_NOTEQUAL,SHIFT);
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
    //sign extend the MSB to 32bits and shift left two bits
    B_Adder baddr(PCnext,{{22{TARGET[7]}},TARGET,2'b00},Addr_Out);
    //initiating 2x1 mux 32 bits module for branch selection
    MUX_32 mux_3(PCnext,Addr_Out,ISJ,MUX3OUT);
    //initiating program counter module
    PC_ pc(PC,MUX3OUT,CLK,RESET);
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
module CU(OUTCODE,ALUOUT,ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH_EQUAL,ISBRANCH_NOTEQUAL,SHIFT);
//ISIMMEDIATE - selection pin for selecting immediate value
//ISSUB -selection pin for ADD and SUB OUTtion
//WRITEENABLE- WRITE enable pin
    input [7:0] OUTCODE;
    output reg [2:0] ALUOUT;
    output reg ISIMMEDIATE,ISSUB,WRITEENABLE,ISJUMP,ISBRANCH_EQUAL,ISBRANCH_NOTEQUAL,SHIFT;
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
                end
            8'b00001000://mult
                begin
                    ALUOUT=3'b100;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                end
            8'b00001001://bne
                begin
                    ALUOUT=3'b001;
                    ISIMMEDIATE=1'b0;
                    ISSUB=1'b1;
                    WRITEENABLE=1'b0;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b1;
                end
            8'b00001010://sll
                begin
                    ALUOUT=3'b101;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    SHIFT=1'b1;
                end
            8'b00001011://srl
                begin
                    ALUOUT=3'b101;
                    ISIMMEDIATE=1'b1;
                    ISSUB=1'b0;
                    WRITEENABLE=1'b1;
                    ISJUMP=1'b0;
                    ISBRANCH_EQUAL=1'b0;
                    ISBRANCH_NOTEQUAL=1'b0;
                    SHIFT=1'b0;
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

//shifting modules
//shfit=1-> left shift by one bit
//shfit=0 -> right shift by one bit
module ONE_BIT_SHIFTER(RESULT,INPUT,SHIFT,SELECT);

input [7:0] INPUT;
input SHIFT,SELECT;
output [7:0] RESULT;
wire [7:0] OUT;
wire and1_out,and2_out,and3_out,and4_out,and5_out,and6_out,and7_out,and8_out,and9_out,and10_out,and11_out,and12_out,and13_out,and14_out;

initial begin
    #1;
end

and and1(and1_out,INPUT[0],SHIFT);
and and2(OUT[0],~SHIFT,INPUT[1]);
and and3(and3_out,INPUT[1],SHIFT);
and and4(and4_out,~SHIFT,INPUT[2]);
and and5(and5_out,INPUT[2],SHIFT);
and and6(and6_out,~SHIFT,INPUT[3]);
and and7(and7_out,INPUT[3],SHIFT);
and and8(and8_out,~SHIFT,INPUT[4]);
and and9(and9_out,INPUT[4],SHIFT);
and and10(and10_out,~SHIFT,INPUT[5]);
and and11(and11_out,INPUT[5],SHIFT);
and and12(and12_out,~SHIFT,INPUT[6]);
and and13(OUT[7],INPUT[6],SHIFT);
and and14(and14_out,~SHIFT,INPUT[7]);
or s1(OUT[1],and1_out,and4_out);
or s2(OUT[2],and3_out,and6_out);
or s3(OUT[3],and5_out,and8_out);
or s4(OUT[4],and7_out,and10_out);
or s5(OUT[5],and9_out,and12_out);
or s6(OUT[6],and11_out,and14_out);

assign OUT[0]=and2_out;
assign OUT[7]=and13_out;

//if select is 0 then the input is forwarded to output else if select is 1 then shifted data is forwarded to ouput
MUX_2 mux1(RESULT[0], INPUT[0], OUT[0], SELECT);
MUX_2 mux2(RESULT[1], INPUT[1], OUT[1], SELECT);
MUX_2 mux3(RESULT[2], INPUT[2], OUT[2], SELECT);
MUX_2 mux4(RESULT[3], INPUT[3], OUT[3], SELECT);
MUX_2 mux5(RESULT[4], INPUT[4], OUT[4], SELECT);
MUX_2 mux6(RESULT[5], INPUT[5], OUT[5], SELECT);
MUX_2 mux7(RESULT[6], INPUT[6], OUT[6], SELECT);
MUX_2 mux8(RESULT[7], INPUT[7], OUT[7], SELECT);


endmodule

//2x1 mux 
module MUX_2(RESULT,INPUT1,INPUT2,SELECT);

output RESULT;
input INPUT1, INPUT2, SELECT;
wire WIRE1,WIRE2,SELECT_BAR;

and (WIRE1,INPUT2,SELECT);
and (WIRE2, INPUT1,SELECT_BAR);
not (SELECT_BAR, SELECT);
or (RESULT, WIRE1,WIRE2);

endmodule


//a two bit shifter
module TWO_BIT_SHIFTER(OUT,INPUT,SHIFT,SELECT);

output [7:0] OUT;
input [7:0] INPUT;
wire [7:0] OUT_WIRE;
input SHIFT,SELECT;


ONE_BIT_SHIFTER obs1(OUT_WIRE,INPUT,SHIFT,SELECT);
ONE_BIT_SHIFTER obs2(OUT,OUT_WIRE,SHIFT,SELECT);

endmodule

//a four bit shifter
module FOUR_BIT_SHIFTER(OUT,INPUT,SHIFT,SELECT);

output [7:0]OUT;
input [7:0] INPUT;
wire [7:0] OUT_WIRE;
input SHIFT,SELECT;

TWO_BIT_SHIFTER tbs1(OUT_WIRE,INPUT,SHIFT,SELECT);
TWO_BIT_SHIFTER tbs2(OUT,OUT_WIRE,SHIFT,SELECT);

endmodule


module SHIFTER(RESULT,INPUT,SHIFT_SELECT,SHIFT_VALUE);

output [7:0] RESULT;
input [7:0] INPUT;
input SHIFT_SELECT;
input [7:0] SHIFT_VALUE;
wire [7:0] OUT1,OUT2,OUT3,OUT;


ONE_BIT_SHIFTER obs3(OUT1,INPUT,SHIFT_SELECT,SHIFT_VALUE[0]);
TWO_BIT_SHIFTER tbs3(OUT2,OUT1,SHIFT_SELECT,SHIFT_VALUE[1]);
FOUR_BIT_SHIFTER fbs1(OUT,OUT2,SHIFT_SELECT,SHIFT_VALUE[2]);

assign #1 RESULT=OUT;

endmodule




