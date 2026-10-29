`timescale 1ns/1ps

module tb_input_handler;

//Clock and reset
    logic clk=0;
    logic rst=1;

    logic [7:0] data_in = 0;
    logic       data_valid = 0;
    logic [7:0] task_id = 0;
    logic [1:0] priority = 0;
    logic       fifo_full = 0;

    //Outputs from the input_handler
    logic [7:0] data_out;
    logic [7:0] task_id_out;
    logic [1:0] priority_out;
    logic       fifo_write;
    logic       data_ready;

    //Connect the testbench to the input handler module
    //This doesn't create a second copy of your source code. It tells the simulator to instantiate your existing input handler so the testbench can control and observe it.
    input_handler dut ( //name of the hardware module and dut stands for device under test
        .clk(clk), //the first clk is the name of the port in the input_handler module, the second clk is the name of the signal in the testbench
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .task_id(task_id),
        .priority(priority),
        .fifo_full(fifo_full),
        .data_out(data_out),
        .task_id_out(task_id_out),
        .priority_out(priority_out),
        .fifo_write(fifo_write),
        .data_ready(data_ready)
    );

    //We don't actually implement the clock yet so its still a conditional module
    always #5 clk = ~clk; //toggle the clock every 5 time units, creating a clock period of 10 time units

