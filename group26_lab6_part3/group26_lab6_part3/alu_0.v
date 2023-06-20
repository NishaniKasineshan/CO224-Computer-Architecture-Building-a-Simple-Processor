/*
   Lab06-Building Memory Heirarchy - Part 1
    Group-26 (E/18/245,E/18/017)
*/

/***********ALU******************/
`timescale 1ns/100ps
module alu(DATA1,DATA2,RESULT,ZERO,SELECT,SHIFT_SELECT,SHIFT_VALUE);
    input [7:0] DATA1;//OPERAND1
    input [7:0] DATA2;//OPERAND2
    input [7:0] SHIFT_VALUE;//shift amount
    input [2:0] SELECT;//ALUOP 
    output reg [7:0] RESULT;//ALURESULT 
    output reg ZERO;//ZERO output port to indicate whether the result of a subtract operation is zero or not in order to implement the beq instruction
    wire [7:0] FORWARD_WIRE, ADD_WIRE, AND_WIRE, OR_WIRE,MULT_WIRE,SHIFT_WIRE;
    input [1:0] SHIFT_SELECT;

    FORWARD forward1(DATA2,FORWARD_WIRE);
    ADD add1(DATA1,DATA2,ADD_WIRE);
    AND and1(DATA1,DATA2,AND_WIRE);
    OR or1(DATA1,DATA2,OR_WIRE);
    MULT mult1(DATA1,DATA2,MULT_WIRE);
    SHIFTER shifter1(SHIFT_WIRE,DATA1,SHIFT_SELECT,SHIFT_VALUE);

    always@(FORWARD_WIRE, ADD_WIRE, AND_WIRE, OR_WIRE,MULT_WIRE,SELECT,SHIFT_WIRE)
    begin
        case(SELECT)
            3'b000:
                RESULT=FORWARD_WIRE;//FORWARD func
            3'b001:
                begin
                    RESULT=ADD_WIRE;//ADD func
                    ZERO=(RESULT==8'b0)? 1'b1 : 1'b0;//(ZERO=~(RESULT))
                end
            3'b010:
                RESULT=AND_WIRE;//AND func
            3'b011:
                RESULT=OR_WIRE;//OR func
            3'b100:
                RESULT=MULT_WIRE;//MULT func
            3'b101:
                RESULT=SHIFT_WIRE;//SHIFT func
            default:
                RESULT=0;//Reserved
        endcase
    end
    
endmodule


module FORWARD(DATA2,RESULT);

    input [7:0] DATA2;
    output reg [7:0] RESULT;

    always@(DATA2)
    begin
    #1 RESULT=DATA2;
end

endmodule

module ADD(DATA1,DATA2,RESULT);

    input [7:0] DATA1,DATA2;
    output reg [7:0] RESULT;

    always@(DATA1,DATA2)
    begin
    #2 RESULT= DATA1 + DATA2;
end

endmodule

module AND(DATA1,DATA2,RESULT);

    input [7:0] DATA1,DATA2;
    output reg [7:0] RESULT;

    always@(DATA1,DATA2)
    begin
    #1 RESULT= DATA1 & DATA2;
end

endmodule

module OR(DATA1,DATA2,RESULT);

    input [7:0] DATA1,DATA2;
    output reg [7:0] RESULT;

    always@(DATA1,DATA2)
    begin
    #1 RESULT= DATA1 | DATA2;
end

endmodule

module MULT(DATA1,DATA2,RESULT);
    input [7:0] DATA1,DATA2;
    output [7:0] RESULT;
    
    wire [7:0] RES0,RES1,RES2,RES3,RES4,RES5,RES6,RES7;//Result parts to add them up together to get the result

    assign RES0=(DATA2[0]==1'b1)?{DATA1}:8'd0;
    assign RES1=(DATA2[1]==1'b1)?{DATA1,1'b0}:8'd0;
    assign RES2=(DATA2[2]==1'b1)?{DATA1,2'b00}:8'd0;
    assign RES3=(DATA2[3]==1'b1)?{DATA1,3'b000}:8'd0;
    assign RES4=(DATA2[4]==1'b1)?{DATA1,4'b0000}:8'd0;
    assign RES5=(DATA2[5]==1'b1)?{DATA1,5'b00000}:8'd0;
    assign RES6=(DATA2[6]==1'b1)?{DATA1,6'b000000}:8'd0;
    assign RES7=(DATA2[7]==1'b1)?{DATA1,7'b0000000}:8'd0;

    assign #1 RESULT=RES0+RES1+RES2+RES3+RES4+RES5+RES6+RES7;
endmodule

//shifting modules
//shfit=1-> left shift by one bit
//shfit=0 -> right shift by one bit
module ONE_BIT_SHIFTER(RESULT,INPUT,SHIFT_S,SELECT);

input [7:0] INPUT;
input [1:0] SHIFT_S;
input SELECT;
reg SHIFT,out_res;
output [7:0] RESULT;
wire [7:0] OUT;
wire and1_out,and2_out,and3_out,and4_out,and5_out,and6_out,and7_out,and8_out,and9_out,and10_out,and11_out,and12_out,and13_out,and14_out;

initial begin
    #1;
end
always @(*)begin
    case(SHIFT_S)
    2'b00://right shift
        begin
            SHIFT=1'b0;
            out_res=and13_out;
        end
    2'b01://left shift
        begin
            SHIFT=1'b1;
            out_res=and13_out;
        end
    2'b10://arithmetic right shift
        begin
            SHIFT=1'b0;
            out_res=INPUT[7];
        end
    2'b11://rotate right
        begin
            SHIFT=1'b0;
            out_res=INPUT[0];
        end
endcase
end

and and1(and1_out,INPUT[0],SHIFT);
and and2(and2_out,~SHIFT,INPUT[1]);
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
and and13(and13_out,INPUT[6],SHIFT);
and and14(and14_out,~SHIFT,INPUT[7]);
or s1(OUT[1],and1_out,and4_out);
or s2(OUT[2],and3_out,and6_out);
or s3(OUT[3],and5_out,and8_out);
or s4(OUT[4],and7_out,and10_out);
or s5(OUT[5],and9_out,and12_out);
or s6(OUT[6],and11_out,and14_out);

assign OUT[0]=and2_out;
assign OUT[7]=out_res;

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
module TWO_BIT_SHIFTER(OUT,INPUT,SHIFT_S,SELECT);

output [7:0] OUT;
input [7:0] INPUT;
wire [7:0] OUT_WIRE;
input SELECT;
input [1:0] SHIFT_S;


ONE_BIT_SHIFTER obs1(OUT_WIRE,INPUT,SHIFT_S,SELECT);
ONE_BIT_SHIFTER obs2(OUT,OUT_WIRE,SHIFT_S,SELECT);

endmodule

//a four bit shifter
module FOUR_BIT_SHIFTER(OUT,INPUT,SHIFT_S,SELECT);

output [7:0]OUT;
input [7:0] INPUT;
wire [7:0] OUT_WIRE;
input SELECT;
input [1:0] SHIFT_S;

TWO_BIT_SHIFTER tbs1(OUT_WIRE,INPUT,SHIFT_S,SELECT);
TWO_BIT_SHIFTER tbs2(OUT,OUT_WIRE,SHIFT_S,SELECT);

endmodule


module SHIFTER(RESULT,INPUT,SHIFT_SELECT,SHIFT_VALUE);

output [7:0] RESULT;
input [7:0] INPUT;
input [1:0] SHIFT_SELECT;
input [7:0] SHIFT_VALUE;
wire [7:0] OUT1,OUT2,OUT3,OUT;


ONE_BIT_SHIFTER obs3(OUT1,INPUT,SHIFT_SELECT,SHIFT_VALUE[0]);
TWO_BIT_SHIFTER tbs3(OUT2,OUT1,SHIFT_SELECT,SHIFT_VALUE[1]);
FOUR_BIT_SHIFTER fbs1(OUT,OUT2,SHIFT_SELECT,SHIFT_VALUE[2]);

assign #1 RESULT=OUT;

endmodule


// module testbench;//testbench for alu
//     //alu inputs
//     reg [7:0] data1,data2;
//     reg [2:0] select;
//     //alu output
//     wire [7:0] out;

//     alu al(data1,data2,out,select);

//     integer i;

//     initial begin
//         $dumpfile("alu.vcd");
//         $dumpvars(0,testbench);

//         select=3'b000; 
//         data1=8'b00011010; //26
//         data2=8'b00010111; //23
                    
//         #10 select=3'b001; 
//         data1=8'b00010100; //20
//         data2=8'b00001111; //15
                    
//         #10 select=3'b010;
//         data1=8'b00110010; //50
//         data2=8'b00100101; //37
                    
//         #10 select=3'b011;
//         data1=8'b01100100; //100
//         data2=8'b11111010; //250
    

//     end

//     initial begin
//         $monitor("time=%3d data1=%d data2=%d select=%3b out=%d",$time,data1,data2,select,out);
//     end
// endmodule