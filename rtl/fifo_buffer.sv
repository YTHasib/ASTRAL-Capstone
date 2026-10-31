module fifo_buffer (
    input logic clk,
    input logic rst,

    //Incoming data from Task 1 (input_handler)
    input logic [7:0] data_in, //an 8-bit input for one thermal pixel
    input logic [7:0] task_id_in, // an 8-bit input for the task ID associated with the incoming data
    input logic [1:0] priority_in, // a 2-bit input for the priority level of the incoming data

    //FIFO control signals
    input logic write_enable, // indicates that the FIFO should write the data_in, task_id_in, and priority_in to the FIFO (storing data for later processing)
    input logic read_enable, // indicates that the FIFO should read the next data_out, task_id_out, and priority_out from the FIFO (retrieving data for processing)

    //Output from FIFO to processing module 
    output logic [7:0]data_out, //an 8-bit output for one thermal pixel
    output logic [7:0] task_id_out, // an 8-bit output for the task ID associated with the outgoing data
    output logic [1:0] priority_out, // a 2-bit output for the priority level of the outgoing data
  
    //FIFO status signals
    output logic fifo_full, // indicates that the FIFO is full and cannot accept new data
    output logic fifo_empty, // indicates that the FIFO is empty and cannot provide new data
    output logic read_valid, // indicates that the data_out, task_id_out, and priority_out are valid and ready to be read from the FIFO




);

//FIFO configuration
localparam int FIFO_DEPTH = 4; //Depth of the FIFO buffer (number of entries it can hold)

//Memory arrays where the [0:FIFO_DEPTH-1] will create four storage locations, indexed 0,1,2,3,
logic [7:0] pixel_memory [0:FIFO_DEPTH-1]; //Memory array to hold the thermal pixel values
logic [7:0] task_id_memory [0:FIFO_DEPTH-1]; //Memory array to hold the task IDs
logic [1:0] priority_memory [0:FIFO_DEPTH-1]; //Memory array to hold the priority levels

// FIFO pointers and counter
logic [1:0] write_pointer; //Pointer to keep track of the current write location in the FIFO (2 bits to index 4 locations)
logic [1:0] read_pointer; //Pointers to keep track of the current write and read locations in the FIFO (2 bits to index 4 locations)
logic [2:0] count; //Counter to keep track of the number of entries in the FIFO (3 bits to count up to 4) 

//FIFO full and empty conditions
assign fifo_full = (count == FIFO_DEPTH); //FIFO is full when the count equals the FIFO depth
assign fifo_empty = (count == 0);//FIFO is empty when the count equals zero

//FIFO reset logic (starting to use sequential logic to reset the FIFO)
always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin //Reset the FIFO pointers and counter when reset signal is high
        write_pointer <= 0;//Reset the write pointer to 0
        read_pointer <= 0;
        count <= 0;
        read_valid <=0;

        data_out <=0;
        task_id_out <=0;
        priority_out <=0;
    
    end else begin
        //Default: no successful read this cycle
        read_valid <=0;

        //Write data if requested and FIFO has space
        if (write_enable && !fifo_full) begin // Check if write is enabled and FIFO is not full
            pixel memory[write_pointer]<=data_in; //Store the incoming data_in, task_id_in, and priority_in into the FIFO memory arrays at the current write_pointer location
            task_id_memory[write_pointer]<= task_id_in; // Store the incoming data_in, task_id_in, and priority_in into the FIFO memory arrays at the current write_pointer location
            priority_memory[write_pointer] <= priority_in; // Store the incoming data_in, task_id_in, and priority_in into the FIFO memory arrays at the current write_pointer location

            write_pointer <= write_pointer + 1'b1; //Increment the write pointer
            
        end
        
        //Read data if requested and FIFO is not empty
        if (read_enable && !fifo__empty) begin
            data_out <= pixel_memory[read_pointer];
            task_id_out <= task_id_memory[read_pointer];
            priority_out <= priority_memory[read_pointer];

            read_pointer <=read_pointer + 1'b1; //Increment the read pointer so we can read the next pixel
            read_valid <=1'b1; //Indicate that the data_out, task_id_out, and priority_out are valid and ready to be read from the FIFO
    
        end
        //Update the count of entries in the FIFO based on read and write operations
        if (write_enable && !fifo_full && !(read_enable && !fifo_empty)begin
            count <=count + 1'b1; //Increment the count if we wrote to the FIFO but did not read from it)
        end

        else if (read_enable && !fifo_empty && !(write_enable && !fifo_full))begin
            count <=count - 1'b1; //Decrement the count if we read from the FIFO but did not write to it)
        end

    end
end
endmodule