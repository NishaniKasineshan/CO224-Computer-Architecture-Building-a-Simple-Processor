
`timescale  1ns/100ps
module dcache (clock,reset,C_WRITE,C_READ,C_Address,C_WRITEDATA,C_READDATA,busywait,mem_write,mem_read,mem_address,mem_writedata,mem_readdata,mem_busywait);

    input  clock, reset,C_WRITE,C_READ;
    input mem_busywait;
    input [7:0] C_WRITEDATA,C_Address;
    input [31:0] mem_readdata;

    output reg mem_write,mem_read,busywait;
    output reg [5:0] mem_address;
    output reg [7:0] C_READDATA;
    output reg [31:0] mem_writedata;
   
   reg readaccess,writeaccess,dirtybit,validbit;
   reg [1:0] offset;
   reg [2:0] index,tag;
   reg [36:0] Cache_MEM [7:0];
   reg [31:0] BLOCK;
   reg hit;
   reg [2:0] address_tag;
  
//Cache access signals are generated based on the read and write signals given to the cache
always @(C_WRITE,C_READ)
begin
        //if C_READ high or C_WRITE high make busywait high else make low
		busywait = ((C_READ || C_WRITE))? 1 : 0;
        //if C_READ high and C_WRITE low make readaccess high else make low
		readaccess = (C_READ && !C_WRITE)? 1 : 0;
        //if C_READ low and C_WRITE high make writeaccess high else make low
		writeaccess = (!C_READ && C_WRITE)? 1 : 0;
end

always @(*)begin
		//Cache memory array is seperated as block ,tag ,dirtybit ,validbit ,offset and index
		if(readaccess == 1'b1 || writeaccess == 1'b1)
        begin
		//one time unit delay for extracting the stored values values
		#1;
           //splitting the CPU given address in to tag,index and offset
            offset       =  C_Address[1:0];
			index        =  C_Address[4:2]; 
            address_tag  =  C_Address[7:5]; 
            //finding the correct cache entry and extracting the stored data block,
            //This extraction was done based on the index extracted from address      
			BLOCK    =  Cache_MEM[index][31:0];
			tag      =  Cache_MEM[index][34:32];
			dirtybit =  Cache_MEM[index][35];
			validbit =  Cache_MEM[index][36];   
		end	
end

//tag comparison and deciding whether its a hit or a miss 
always @(address_tag[0],address_tag[1],address_tag[2],tag[0],tag[1],tag[2],validbit)
begin

if(tag[0]==address_tag[0] && tag[1]==address_tag[1] && tag[2]==address_tag[2] && validbit)
    begin
        //if it is a successfull making hit high and giving a delay of 0.9 time unit
        #0.9 hit=1'b1;
    end  
else
    begin
         //if it is a unsuccessfull making hit low and giving a delay of 0.9 time unit
        #0.9 hit=1'b0;
    end 
end

//data word is selected based on the offset from the block 
always@(BLOCK[7:0],BLOCK[15:8],BLOCK[23:16],BLOCK[31:24],offset) 
begin
#1;
   case(offset)
         2'b00 :C_READDATA=BLOCK[7:0]; 
         2'b01 :C_READDATA=BLOCK[15:8];
         2'b10 :C_READDATA=BLOCK[23:16];
         2'b11 :C_READDATA=BLOCK[31:24];

   endcase 
end


  
always @(posedge clock)begin 
//READ-HIT
//Here, the hit is successful therefore we can give
//the CPU the answer without futher stalling of the CPU

if(readaccess == 1'b1 && hit == 1'b1)begin 			
   //to prevent accessing memory for reading 
   readaccess = 1'b0;
   //to prevent futher stalling of CPU
   busywait= 1'b0;

end

//WRITE-HIT
//Here, the hit is successful therefore we can write the cache
//the word  without futher stalling of the CPU
else if(writeaccess == 1'b1 && hit == 1'b1)begin 
    //Since, we have already found the hit, we can de-assert the busywait here
	busywait = 1'b0;		
	#1;
	case(offset)	
		//Dataword is written to the cache based on the offset
		2'b00	:	Cache_MEM[index][7:0]   = C_WRITEDATA;
		2'b01 	:	Cache_MEM[index][15:8]  = C_WRITEDATA;
		2'b10 	:	Cache_MEM[index][23:16] = C_WRITEDATA;
		2'b11   :	Cache_MEM[index][31:24] = C_WRITEDATA;	
	endcase

    //set dirtybit = 1
	Cache_MEM[index][35] = 1'b1;

    //set validbit = 1  
    Cache_MEM[index][36] = 1'b1; 

    //to prevent accessing memory for writing        	
	writeaccess = 1'b0;	 
	end
end


/* Cache Controller FSM Start */
    parameter IDLE = 3'b000, MEM_READ = 3'b001,MEM_WRITE=3'b010,C_MEM_WRITE=3'b011;
    reg [2:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                //if the existing block is not dirty ,the missing block should be fetched from memory
                if ((C_READ || C_WRITE) && !dirtybit && !hit)               
                    next_state = MEM_READ;        //memory read

                //if the existing block is dirty ,that block must be written back to the memory before fetching the missing block
                else if ((C_READ ||C_WRITE) && dirtybit && !hit)            
                    next_state = MEM_WRITE;       //write-back

                //if C_READ=0 and C_WRITE=0 remain same in IDLE condition
                else
                    next_state = IDLE;

            MEM_READ:
                if (!mem_busywait)
                    next_state = C_MEM_WRITE;
                else    
                    next_state = MEM_READ;

           MEM_WRITE:
             if (!mem_busywait)
                    next_state = MEM_READ;	//after memory writing,start the memory reading
                else    
                    next_state = MEM_WRITE;	//write back to the memory

            //next state after writing in cache from data received from memory is IDLE		
	        C_MEM_WRITE:
              
                next_state = IDLE;        
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
        //contol signals of cache control during read and write is 0
            IDLE:
            begin
                mem_read      = 0;
                mem_write     = 0;
                mem_address   = 6'dx;
                mem_writedata = 32'dx;           
            end
         //during a read miss we assert the mem_read to read from data memory
            MEM_READ: 
            begin
                mem_read      = 1;
                mem_write     = 0;
                mem_address   = {tag,index};
                mem_writedata = 32'dx;
            end

           	MEM_WRITE: 
            begin
                mem_read  = 1'd0;
                mem_write = 1'd1;
                mem_address ={tag,index};	//data block address from the cache
                mem_writedata =BLOCK; 
            end
			
			C_MEM_WRITE: 
            begin
                mem_read = 1'd0;
                mem_write = 1'd0;
                mem_address = 6'dx;
                mem_writedata = 32'dx;
                busywait=1;

               //this writing operation happens in the cache block after fetching the  memory
               //there is 1 time unit delay for this operation
				#1;
				Cache_MEM[index][31:0] = mem_readdata;	//write a data block to the cache
				Cache_MEM[index][34:32] = address_tag ;	//tag C_Address[7:5]
				Cache_MEM[index][35] = 1'd0;	//dirty bit=0 since we are writing a data in cache which is also in memory
				Cache_MEM[index][36] = 1'd1;	//valid bit
			
            end
        endcase
    end

    // sequential logic for state transitioning 
    always @(posedge clock, reset)
    begin
        if(reset)
        begin
            state = IDLE;
            busywait=1'b0;
            //reset the cache after 1 time unit delay
            #1;
            Cache_MEM[0] = 37'b0;
            Cache_MEM[1] = 37'b0;
            Cache_MEM[2] = 37'b0;
            Cache_MEM[3] = 37'b0;
            Cache_MEM[4] = 37'b0;
            Cache_MEM[5] = 37'b0;
            Cache_MEM[6] = 37'b0;
            Cache_MEM[7] = 37'b0;
        end
        
        else begin
            state = next_state;
         end
    end
    /* Cache Controller FSM End */

endmodule
