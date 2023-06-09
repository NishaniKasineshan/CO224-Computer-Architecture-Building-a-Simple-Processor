
`timescale  1ns/100ps

module ins_cache (clock,PC,reset,c_instruction,c_busywait,mem_instruction,imem_read,imem_address,imem_busywait);

    input  clock, reset,imem_busywait;  //imem_busywait:busywait signal which comes from the ins memory to the ins cache
    input [31:0] PC;
    input [127:0] mem_instruction;      //data block which comes from ins_mem to the ins_cache
    
    output reg imem_read,c_busywait;   //imem_read:read signal which goes into the memory from the cache
    output reg [5:0] imem_address;     //address which goes from the ins cache into the ins memory
    output reg [31:0] c_instruction;   //instruction that goes into the cpu from the ins cache
    
    reg [31:0] instruction;            //temp reg to store the instruction           

   reg [1:0]  offset;
   reg [2:0]  index;
   reg [2:0]  PCaddress_tag,tag;
   reg [131:0] iCache [7:0];           //8 132 bits instruction cache to store instructions
   reg [127:0] BLOCK;                 //128 bit instruction block
   reg hit;
   reg validbit;

always @(*)begin
	#1;
    //splitting the CPU given address in to tag,index and offset
    offset         =  PC[3:2];
	index          =  PC[6:4];
    PCaddress_tag  =  PC[9:7]; 
    //This extraction was done based on the index extracted from address      
	BLOCK    =  iCache[index][127:0];      //instruction block
	tag      =  iCache[index][130:128];    //tag value
	validbit =  iCache[index][131];        //valid bit
end

//deciding whether its a hit or a miss 
always @(PCaddress_tag,tag,validbit)
begin

    if(tag==PCaddress_tag && validbit)begin
        //if it is a successfull hit
        #0.9 hit=1'b1;
    end  
else begin
        //if it is a unsuccessfull miss
        #0.9 hit=1'b0;
    end 
end

//instruction word is selected based on the offset from the block 
always@(BLOCK[31:0],BLOCK[63:32],BLOCK[95:64],BLOCK[127:96],offset)
   begin
    #1;
    case(offset)
         2'b00 :instruction=BLOCK[31:0]; 
         2'b01 :instruction=BLOCK[63:32];
         2'b10 :instruction=BLOCK[95:64];
         2'b11 :instruction=BLOCK[127:96];
    endcase
    end

always @(posedge clock)begin
    if(!hit) begin
    //In the event of a miss, the cpu must be stalled
    c_busywait = 1'b1;
    end
    else
    //if it is hit we dont want to stall the cpu
    c_busywait=1'b0;
    end

//Read hits are handeled Asynchronously
always @(instruction)
begin
    //if hit then,instruction is sent to the CPU
    if(hit)begin
        c_instruction = instruction;
    end
end

/* Cache Controller FSM Start */
    parameter IDLE = 2'b00, IMEM_READ = 2'b01,IC_WRITE=2'b10;
    reg [1:0] state, nextstate;
    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
            begin
            if(!hit)
              nextstate=IMEM_READ;
            else
              nextstate=IDLE; 
            end

           IMEM_READ:
           begin
            if(!imem_busywait)
               nextstate=IC_WRITE;
            else
                nextstate=IMEM_READ;
            end
           
           IC_WRITE:
               nextstate=IDLE; 
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
               imem_read = 0;
               imem_address = 6'dx;
            end
         
            IMEM_READ: 
            begin
                imem_read = 1;
                imem_address ={tag,index};   //a 6 bit address to read from instruction memory
                c_busywait=1;
            end

	        IC_WRITE:
            begin
                imem_read = 1'd0;
                imem_address = 6'dx;    
                //this happens in the instruction cache block after fetching the  memory
                 #1;
				iCache[index][127:0]   = mem_instruction;	//write a data block to the cache
				iCache[index][130:128] = PCaddress_tag;	    //tag received from CPU address
			    iCache[index][131]   = 1'd1;	            //valid bit
            end        
        endcase
    end 

always @(posedge clock, reset)
    begin
        if(reset)
        begin
            state = IDLE;
            c_busywait=1'b0;
             #1;
            iCache[0] = 131'b0;
            iCache[1] = 131'b0;
            iCache[2] = 131'b0;
            iCache[3] = 131'b0;
            iCache[4] = 131'b0;
            iCache[5] = 131'b0;
            iCache[6] = 131'b0;
            iCache[7] = 131'b0;
        end
        
        else begin
            state = nextstate;
         end
    end
    /* Cache Controller FSM End */

endmodule
