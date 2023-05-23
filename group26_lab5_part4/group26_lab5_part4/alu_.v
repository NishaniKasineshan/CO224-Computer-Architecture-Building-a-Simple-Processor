/*
    Lab05-Building A Simple Processor Part 1
    Group-26 (E/18/245,E/18/017)
*/

/***********ALU******************/
module alu(DATA1,DATA2,RESULT,ZERO,SELECT);
    input [7:0] DATA1;//OPERAND1
    input [7:0] DATA2;//OPERAND2
    input [2:0] SELECT;//ALUOP 
    output reg [7:0] RESULT;//ALURESULT 
    output ZERO;//ZERO output port to indicate whether the result of a subtract operation is zero or not in order to implement the beq instruction
    wire [7:0] FORWARD_WIRE, ADD_WIRE, AND_WIRE, OR_WIRE;

    FORWARD forward1(DATA2,FORWARD_WIRE);
    ADD add1(DATA1,DATA2,ADD_WIRE);
    AND and1(DATA1,DATA2,AND_WIRE);
    OR or1(DATA1,DATA2,OR_WIRE);

    always@(FORWARD_WIRE, ADD_WIRE, AND_WIRE, OR_WIRE,SELECT)
    begin
        case(SELECT)
            3'b000:
                RESULT=FORWARD_WIRE;//FORWARD func
            3'b001:
                RESULT=ADD_WIRE;//ADD func
            3'b010:
                RESULT=AND_WIRE;//AND func
            3'b011:
                RESULT=OR_WIRE;//OR func
            default:
                RESULT=0;//Reserved
        endcase
    end
    assign ZERO=(RESULT==8'b0)? 1'b1 : 1'b0;//(ZERO=~(RESULT))
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