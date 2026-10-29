module input_handler(
    input logic clk,
    input logic rst,

    //Incoming data from the assigned task
    input logic [7:0] data_in, //an 8-bit input for one thermal pixel
    input logic       data_valid, //indicates that the data_in is valid and ready to be processed
    input logic [7:0] task_id, // an 8-bit input for the task ID associated with the incoming data
    input logic [1:0] priority, // a 2-bit input for the priority level of the incoming data

    //FIFO status
    input logic       fifo_full, // indicates that the FIFO is full and cannot accept new data

    //Output to FIFO
    output logic [7:0]data_out, //an 8-bit output for one thermal pixel
    output logic [7:0] task_id_out, // an 8-bit output for the task ID associated with the outgoing data
    output logic [1:0] priority_out, // a 2-bit output for the priority level of the outgoing data
    output logic       fifo_write, // indicates that the FIFO should write the data_out, task_id_out, and priority_out to the FIFO (storing data for later processing)
    output logic       data_ready // indicates that the data_out, task_id_out, and priority_out are valid and ready to be written to the FIFO
);

   //We know it's combinational logic because its output depends only on the current inputs and not on the previous values or clock cycles
    assign data_ready = !rst && !fifo_full; // Data is ready to be written to the FIFO if the system is not in reset and the FIFO is not full, data_valid condition isnt important because even if data_valid = 0, the data_out, task_id_out, and priority_out will still be valid and ready to be written to the FIFO
    assign fifo_write = data_valid && data_ready; // Write to FIFO if the incoming data is valid and the FIFO is ready to accept new data
    assign data_out = data_in; // Pass the incoming data to the output, the value is being presented to FIFO and isn't actually stored in it (data on wire)
    assign task_id_out = task_id; // Pass the incoming task ID to the output, the value is being presented to FIFO and isn't actually stored in it (data on wire)
    assign priority_out = priority; // Pass the incoming priority level to the output, the value is being presented to FIFO and isn't actually stored in it (data on wire)
    

  
endmodule