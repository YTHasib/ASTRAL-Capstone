`timescale 1ns/1ps

module tb_thermal_processor;

//Clock and Reset
logic clk = 0;
logic rst = 0;

//Inputs from Task 3
logic [7:0] pixel_in = 0;
logic [7:0] task_if_in = 0;
logic [1:0] priority_in = 0;
logic data_valid = 0;

// Processor Handshaking
logic processor_ready;

//Processing Results
logic [7:0] pixel_out;
logic [7:0] task_id_out;
logic [1:0] priority_out;
logic hotspot_flag;
logic result_valid;

//Clock Generation (10 ns period)
always #5 clk = ~clk;

endmodule