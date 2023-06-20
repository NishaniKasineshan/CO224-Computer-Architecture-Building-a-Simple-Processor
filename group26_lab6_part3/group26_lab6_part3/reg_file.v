/*
    Lab06-Building Memory Heirarchy - Part 1
    Group-26 (E/18/245,E/18/017)
*/

/********Register File********/
`timescale 1ns/100ps
module reg_file(IN,OUT1,OUT2,INADDRESS,OUT1ADDRESS,OUT2ADDRESS,WRITE,CLK,RESET,BUSYWAIT,INSBUSYWAIT);
    input [7:0] IN; //8 bit Data Input
    input [2:0] INADDRESS,OUT1ADDRESS,OUT2ADDRESS;// 3 bit WRITEREG
    input CLK,WRITE,RESET;
    output [7:0] OUT1,OUT2; //8 bit data out1, 8 bit data out2
    input BUSYWAIT,INSBUSYWAIT;
    reg[7:0] registers[0:7];// 8 Registers of 8 bits : 8x8 REGISTER FILE


    //Read operation should be done asynchronously
    //Data is sent out parallelly
    assign #2 OUT1=registers[OUT1ADDRESS];//Register Read Delay is 2 , Retrieve data from register numbers specified by OUT1ADDRESS
    assign #2 OUT2=registers[OUT2ADDRESS];//Register Read Delay is 2 , Retrieve data from register numbers specified by OUT2ADDRESS

    integer i;
    always @(posedge CLK) begin
        //Reset should happen synchronously at positive edge of clock if RESET is high
        if(RESET)begin
            #1//reset delay: 1 time unit
            for(i=0;i<8;i=i+1)begin
                registers[i]<=0;//reset all register values to 0
            end
        end
        else begin
            //writing to reg file is done synchronously
            #0.1
            if(WRITE && !BUSYWAIT && !INSBUSYWAIT)begin
                #0.9 registers[INADDRESS]<=IN;//Store the data input with INADDRESS providing the register number to store that data in.1 time unit delay for writing operation
            end
        end
    end
endmodule

