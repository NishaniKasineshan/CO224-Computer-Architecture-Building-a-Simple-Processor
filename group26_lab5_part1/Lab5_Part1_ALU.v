//alu module
module alu(DATA1, DATA2, RESULT, SELECT);

input [7:0] DATA1, DATA2;
input [2:0] SELECT;
output reg [7:0] RESULT;
wire [7:0] FORWARD_WIRE, ADD_WIRE, AND_WIRE, OR_WIRE;

//instantiate all four modules
FORWARD forward1(DATA2,FORWARD_WIRE);
ADD add1(DATA1,DATA2,ADD_WIRE);
AND and1(DATA1,DATA2,AND_WIRE);
OR or1(DATA1,DATA2,OR_WIRE);


always @ (FORWARD_WIRE, ADD_WIRE, AND_WIRE, OR_WIRE, SELECT)
begin
//selecting the corresponding operation using switch
case(SELECT)

3'b000:
RESULT = FORWARD_WIRE; 
3'b001:
RESULT = ADD_WIRE; 
3'b010:
RESULT = AND_WIRE; 
3'b011:
RESULT = OR_WIRE;
default:
RESULT = 8'b00000000; //handling other selecter bits which are not used here

endcase
end
endmodule

//module for FORWARD operation
module FORWARD(DATA2,RESULT);

input [7:0] DATA2; //declaring a 8 bit input port 
output reg [7:0] RESULT; //declaring a 1 8 bit output port

always@(DATA2)
begin
#1
RESULT=DATA2; //after time delay of 1 assign the data2 value to result
end

endmodule

//module for ADD operation
module ADD(DATA1,DATA2,RESULT);

input [7:0] DATA1,DATA2; //declaring 2 8 bit input port 
output reg [7:0] RESULT; //declaring a 1 8 bit output port

always@(DATA1,DATA2)
begin
#2
RESULT= DATA1 + DATA2; //after time delay of 2 assign the Result of add operation
end

endmodule

//module for AND operation
module AND(DATA1,DATA2,RESULT);

input [7:0] DATA1,DATA2; //declaring 2 8 bit input port 
output reg [7:0] RESULT; //declaring a 1 8 bit output port

always@(DATA1,DATA2)
begin
#1
RESULT= DATA1 & DATA2;//after time delay of 1 assign the Result of and operation
end

endmodule

//module for OR operation
module OR(DATA1,DATA2,RESULT);

input [7:0] DATA1,DATA2; //declaring 2 8 bit input port 
output reg [7:0] RESULT; //declaring a 1 8 bit output port

always@(DATA1,DATA2)
begin
#1
RESULT= DATA1 | DATA2; //after time delay of 1 assign the Result of or operation
end

endmodule