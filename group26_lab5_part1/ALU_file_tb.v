//testbench for alu module
module testbench;         

reg [7:0] DATA1,DATA2;    
reg [2:0] SELECT;         
wire [7:0] RESULT;        

//instantiate alu module
alu ALU1(DATA1,DATA2,RESULT,SELECT); 

//changing some values to the input data and checking the alu module
initial
begin
SELECT=3'b000; 
DATA1=8'b00000010; //2
DATA2=8'b00000011; //3
               
#10
SELECT=3'b001; 
DATA1=8'b00000100; //4
DATA2=8'b00000011; //3
            
#10
SELECT=3'b010;
DATA1=8'b00000010; //2
DATA2=8'b00000101; //5
             
#10
SELECT=3'b011;
DATA1=8'b00000100; //4
DATA2=8'b00000111; //7

end

initial
begin
$monitor($time,"  DATA1 = %b ,DATA2 = %b ,select = %b ,result = %b \n",DATA1,DATA2,SELECT,RESULT); //monitoring the inputs and outputs
$dumpfile("alu.vcd"); 
$dumpvars(0,ALU1);
end

endmodule