`timescale 1ns/1ps

module tb_input_handler;

//Clock and reset
    logic clk=0;
    logic rst=1;

    logic [7:0] data_in = 0;
    logic       data_valid = 0;
    logic [7:0] task_id = 0;
    logic [1:0] task_priority = 0;
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
        .task_priority(task_priority),
        .fifo_full(fifo_full),
        .data_out(data_out),
        .task_id_out(task_id_out),
        .priority_out(priority_out),
        .fifo_write(fifo_write),
        .data_ready(data_ready)
    );

    //We don't actually implement the clock yet so its still a conditional module
    always #5 clk = ~clk; //toggle the clock every 5 time units, creating a clock period of 10 time units


    //Starting simulation
    initial begin //This block runs once at the start of the simulation
        #12 rst = 0; //Release reset after 12 time units, allowing the input_handler to start processing data assuming FIFO still has space

        //Test 1: Send a valid thermal pixel
        @(negedge clk);
        data_valid = 1; //Indicate that the incoming data is valid and ready to be processed
        data_in = 8'd85;//Send a thermal pixel value of 85
        task_id = 8'd17;//Send a task ID of 17
        task_priority = 2'b01;//Send a priority level of 1
        fifo_full = 0; //Indicate that the FIFO is not full and can accept new data

        //Check if it's outputting the correct values to the FIFO
        @(posedge clk); //Wait for the next clock edge to allow the input_handler to process the incoming data
        #1;//Wait for 1 time unit to allow the output signals to stabilize

        $display("Pixel = %0d, Task ID = %0d, Priority = %0d", data_out, task_id_out, priority_out);//Print the output values to the console for verification in decimal format
        $display("Ready = %b, FIFO Write = %b", data_ready, fifo_write);//Print the status signals to the console for verification
       

        //Test 2: FIFO is full, so the input_handler should not write to the FIFO
        @(negedge clk);//Wait for the next clock edge to allow the input_handler to process the incoming data
        fifo_full = 1; //Indicate that the FIFO is full and cannot accept new data

        @(posedge clk); //Wait for the next clock edge to allow the input_handler to process the incoming data
        #1;//Wait for 1 time unit to allow the output signals to stabilize
        $display("FIFO Full Test: Ready = %b, Write = %b", data_ready, fifo_write);

        #10; //Wait for 10 time units before ending the simulation
        $finish;

    end

endmodule

