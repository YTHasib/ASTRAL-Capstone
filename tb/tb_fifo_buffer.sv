`timescale 1ns/1ps

module tb_fifo_buffer;

    //Clock and reset
    logic clk = 0;
    logic rst = 0; //cleats the FIFO buffer and resets the pointers and counter
    /*We want Satellite A 
        At 0 ns: rst = 0 //simulation begins
        At 12 ns: rst = 1 //reset activates and clears FIFO control state
        At 15 ns: The FPGA can begin storing thermal pixels at the next rising clock edge
    */

    //Simulated incoming data from Task 1
    logic [7:0] data_in = 0;
    logic [7:0] task_id_in = 0;
    logic [1:0] priority_in = 0;

    //FIFO control signals
    logic write_enable = 0; // indicates that the FIFO should write the data_in, task_id_in, and priority_in to the FIFO (storing data for later processing)
    logic read_enable = 0; // indicates that the FIFO should read the next data_out, task_id_out, and priority_out from the FIFO (retrieving data for processing)


    //Outputs from the FIFO
    logic [7:0] data_out;
    logic [7:0] task_id_out;
    logic [1:0] priority_out;

    //FIFO status signals
    logic fifo_full;
    logic fifo_empty;
    logic read_valid; 

    //Connect the testbench to the FIFO buffer module
    fifo_buffer dut( //Device Under Test
        .clk(clk),
        .rst(rst),

        .data_in(data_in),
        .task_id_in(task_id_in),
        .priority_in(priority_in),

        .write_enable(write_enable),
        .read_enable(read_enable),

        .data_out(data_out),
        .task_id_out(task_id_out),
        .priority_out(priority_out),

        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .read_valid(read_valid)
    );

    // Generate clock with a 10ns period
    always #5 clk = ~clk; //Toggle clock every 5ns to create a 10ns period

    //Initialize the FIFO before testing
    initial begin
      #2 rst = 1; //Activate reset at 2ns
      #10 rst = 0; //Release reset at 12 ns


      //Test 1: Write a thermal pixel into FIFO
      @(negedge clk);
      data_in = 8'd85;
      task_id_in = 8'd17;
      priority_in = 2'b01;
      write_enable = 1;

      //Wait for FIFO to store the data
      @(posedge clk);
      #1;

      $display("FIFO Count = %0d, Empty = %b, Full = %b", dut.count, fifo_empty, fifo_full);

      //Stop writing after one pixel
      @(negedge clk);
      write_enable = 0;

        #10;
        $finish;
    
    end  



endmodule

