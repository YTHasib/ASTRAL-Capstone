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