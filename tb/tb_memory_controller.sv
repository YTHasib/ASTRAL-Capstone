`timescale 1ns/1ps

module tb_memory_controller;

    //Clock and reset
    logic clk = 0;
    logic rst = 0;

    //FIFO Inputs
    logic fifo_empty = 1;
    logic fifo_read_valid = 0;
    logic [7:0] fifo_data_in = 0;
    logic [7:0] fifo_task_id_in = 0;
    logic [1:0] fifo_priority_in = 0;

    //Processor Inputs
    logic processor_ready = 0;

    //Controller Outputs
    logic fifo_read_enable;
    logic [7:0] processor_data_out;
    logic [7:0] processor_task_id_out;
    logic [1:0] processor_priority_out;
    logic processor_data_valid;

    //Clock generation
    always #5 clk = ~clk; //Toggle clock every 5ns to create a 10ns period

    //Memory Controller instatiation
    memory_controller dut (
        .clk(clk),
        .rst(rst),

        .fifo_empty(fifo_empty),
        .fifo_read_valid(fifo_read_valid),
        .fifo_data_in(fifo_data_in),
        .fifo_task_id_in(fifo_task_id_in),
        .fifo_priority_in(fifo_priority_in),

        .processor_ready(processor_ready),

        .fifo_read_enable(fifo_read_enable),
        .processor_data_out(processor_data_out),
        .processor_task_id_out(processor_task_id_out),
        .processor_priority_out(processor_priority_out),
        .processor_data_valid(processor_data_valid)
    );

    //Test Cases

initial begin
    //Test 1: Reset Verification
    #2 rst = 1; //Activate reset
    #1;         //Allow signals to update

    //Display test name and results
    $display("Test 1: Reset Verification");
    $display("State = %0d, Data = %0d, Valid = %b, Read Enable = %b", dut.state, processor_data_out, processor_data_valid, fifo_read_enable);

    // Automatically check reset conditions
    if (dut.state !== 2'b00 || // Check if the state is not IDLE
        processor_data_out !== 8'd0 || // Check if the data output is not zero
        processor_task_id_out !== 8'd0 || // Check if the task ID output is not zero
        processor_priority_out !== 2'd0 || // Check if the priority output is not zero
        processor_data_valid !== 1'b0 || // Check if the data valid signal is not zero
        fifo_read_enable !== 1'b0) // Check if the FIFO read enable signal is not zero
        $fatal(1, "FAIL: Reset Verification"); // If any of the reset conditions are not met, terminate the simulation with a fatal error
    else
        $display("PASS: Reset Verification"); // If all reset conditions are met, print a pass message

    // Release reset
    @(negedge clk);
    rst = 0; //Release reset after one clock cycle

    #1;

    // Test 2: Empty FIFO verification
    @(negedge clk); //Wait for the next clock edge to allow the memory_controller to process the empty FIFO condition
    #1;

    $display("Test 2: Empty FIFO Verification"); //Display test name and results
    $display("State = %0d, Data = %0d, Valid = %b, Read Enable = %b", dut.state, processor_data_out, processor_data_valid, fifo_read_enable);//Display the current state, data output, data valid signal, and FIFO read enable signal for verification

    if(dut.state !==2'b00 || // Check if the state is not IDLE
       fifo_read_enable !== 1'b0 || // Check if the FIFO read enable signal is not zero
       processor_data_valid !== 1'b0) // Check if the data valid signal is not zero
        $fatal(1, "FAIL: Empty FIFO Verification"); // If any of the empty FIFO conditions are not met, terminate the simulation with a fatal error
    else
        $display("PASS: Empty FIFO Verification"); // If all empty FIFO conditions are met, print a pass message

    // Test 3: FIFO Read Request Verification
    @(negedge clk); //Wait for the next clock edge to allow the memory_controller to process the FIFO read request
    fifo_empty = 1'b0; //Simulate data becoming available in the FIFO
    #1;

    $display("Test 3: FIFO Read Request Verification"); //Display test name and results
    $display("Before Clock: State = %0d, FIFO Empty = %b, Read Enable = %b", dut.state, fifo_empty, fifo_read_enable);

    // Check that the controller requests a FIFO read
    if (dut.state !== 2'b00 || // Check if the state is not IDLE
        fifo_read_enable !== 1'b1) // Check if the FIFO read enable signal is not asserted
        $fatal(1, "FAIL: FIFO Read Request"); // If any of the FIFO read request conditions are not met, terminate the simulation with a fatal error

    // Wait for the rising clock edge
    @(posedge clk);
    #1;

    $display("After Clock: State = %0d, Read Enable = %b", 
             dut.state, fifo_read_enable); //Display the current state and FIFO read enable signal for verification

    // Check that FSM moves to WAIT_DATA
    if (dut.state !== 2'b01 ||
        fifo_read_enable !== 1'b0) // Check if the state is not WAIT_DATA or if the FIFO read enable signal is still asserted
        $fatal(1, "FAIL: FIFO State Transition"); // If any of the FIFO state transition conditions are not met, terminate the simulation with a fatal error
    else
        $display("PASS: FIFO Read Request"); // If all FIFO read request conditions are met, print a pass message
      
     // Test 4: Valid FIFO Data Reception
    @(negedge clk);

    fifo_read_valid = 1'b1;  // FIFO confirms valid data
    fifo_data_in = 8'd85;    // Thermal pixel value
    fifo_task_id_in = 8'd17; // Task ID
    fifo_priority_in = 2'd2; // Task priority

    @(posedge clk);
    #1;

    // Display test name and results
    $display("Test 4: Valid FIFO Data Reception");
    $display("State = %0d, Pixel = %0d, Task ID = %0d, Priority = %0d, Data Valid = %b",
             dut.state, processor_data_out,
             processor_task_id_out, processor_priority_out,
             processor_data_valid); // Display the current state, pixel value, task ID, priority, and data valid signal for verification

    // Automatically verify received data
    if (dut.state !== 2'b10 || // Check if the state is not HOLD_DATA
        processor_data_out !== 8'd85 || // Check if the pixel value is not 85
        processor_task_id_out !== 8'd17 || // Check if the task ID is not 17
        processor_priority_out !== 2'd2 || // Check if the priority is not 2
        processor_data_valid !== 1'b1) // Check if the data valid signal is not asserted
        $fatal(1, "FAIL: Valid FIFO Data Reception"); // If any of the valid FIFO data reception conditions are not met, terminate the simulation with a fatal error
    else
        $display("PASS: Valid FIFO Data Reception");

    // End FIFO valid pulse
    @(negedge clk);
    fifo_read_valid = 1'b0;

    //Test 5: Processor Busy - Hold Data
    @(negedge clk);
    processor_ready = 1'b0;  // Processor is busy

    //Wait for two clock cycles
    repeat (2) begin
        @(posedge clk);
        #1;
    end

    //Display test name and results
    $display("Test 5: Processor Busy - Hold Data");
    $display("State = %0d, Pixel = %0d, Task ID = %0d, Priority = %0d, Data Valid = %b",
             dut.state, processor_data_out,
             processor_task_id_out, processor_priority_out,
             processor_data_valid);

    //Automatically verify that the controller holds the data when the processor is busy
     if (dut.state !== 2'b10 ||
        processor_data_out !== 8'd85 ||
        processor_task_id_out !== 8'd17 ||
        processor_priority_out !== 2'd2 ||
        processor_data_valid !== 1'b1 ||
        fifo_read_enable !== 1'b0)
        $fatal(1, "FAIL: Processor Busy - Hold Data");
    else
        $display("PASS: Processor Busy - Hold Data");


//Test 6 Processor Ready  - Complete Transfer
    @(negedge clk);
    processor_ready = 1'b1;  // Processor is ready
    fifo_empty = 1'b1;      // FIFO is empty

    @(posedge clk);
    #1;

    //Display test name and results
    $display("Test 6: Processor Ready - Complete Transfer");
    $display("State = %0d, Processor Ready = %b, Data Valid = %b, Read Enable = %b",
             dut.state, processor_ready,
             processor_data_valid, fifo_read_enable);
    
    // Automatically verify the completed transfer
    if (dut.state !== 2'b00 ||
        processor_data_valid !== 1'b0 ||
        fifo_read_enable !== 1'b0 ||
        processor_data_out !== 8'd85 ||
        processor_task_id_out !== 8'd17 ||
        processor_priority_out !== 2'd2)
        $fatal(1, "FAIL: Processor Ready - Complete Transfer");
    else
        $display("PASS: Processor Ready - Complete Transfer");

//Test 7: Multiple Cosecutive Transfers
  $display("Test 7: Multiple Consecutive Transfers");

    for (int i = 0; i < 2; i++) begin

        // Step 1: Make new FIFO data available
        @(negedge clk);
        fifo_empty = 1'b0;
        fifo_read_valid = 1'b0;
        processor_ready = 1'b1;
        #1;

        // Verify the controller requests a read
        if (dut.state !== 2'b00 ||
            fifo_read_enable !== 1'b1)
            $fatal(1, "FAIL: FIFO Read Request");

        @(posedge clk);
        #1;

        // Verify transition to WAIT_DATA
        if (dut.state !== 2'b01)
            $fatal(1, "FAIL: WAIT_DATA Transition");

        // Step 2: Simulate FIFO returning data
        @(negedge clk);
        fifo_empty = 1'b1;
        fifo_read_valid = 1'b1;

        fifo_data_in = 8'd90 + i;
        fifo_task_id_in = 8'd21 + i;
        fifo_priority_in = (i == 0) ? 2'd1 : 2'd2;

        @(posedge clk);
        #1;

        // Display results
        $display("Transfer %0d: State = %0d, Pixel = %0d, Task ID = %0d, Priority = %0d, Valid = %b",
                 i + 1, dut.state, processor_data_out,
                 processor_task_id_out, processor_priority_out,
                 processor_data_valid);

        // Verify correct data reception
        if (dut.state !== 2'b10 ||
            processor_data_out !== fifo_data_in ||
            processor_task_id_out !== fifo_task_id_in ||
            processor_priority_out !== fifo_priority_in ||
            processor_data_valid !== 1'b1)
            $fatal(1, "FAIL: Transfer %0d Data Reception", i + 1);

        // Step 3: Processor accepts the data
        @(negedge clk);
        fifo_read_valid = 1'b0;

        @(posedge clk);
        #1;

        // Verify controller returns to IDLE
        if (dut.state !== 2'b00 ||
            processor_data_valid !== 1'b0)
            $fatal(1, "FAIL: Transfer %0d Completion", i + 1);

    end

    $display("PASS: Multiple Consecutive Transfers");


//Test 8: Reset During Actice Transfer
    $display("Test 8: Reset During Active Transfer");

    // Step 1: Simulate new data becoming available
    @(negedge clk);
    processor_ready = 1'b0; // Processor is busy
    fifo_empty = 1'b0;
    fifo_read_valid = 1'b0;

    @(posedge clk);
    #1;

    // Verify transition to WAIT_DATA
    if (dut.state !== 2'b01)
        $fatal(1, "FAIL: Controller did not enter WAIT_DATA");

    // Step 2: Simulate receiving valid FIFO data
    @(negedge clk);
    fifo_empty = 1'b1;
    fifo_read_valid = 1'b1;
    fifo_data_in = 8'd120;
    fifo_task_id_in = 8'd33;
    fifo_priority_in = 2'd3;

    @(posedge clk);
    #1;

    // Verify data is being held
    if (dut.state !== 2'b10 ||
        processor_data_valid !== 1'b1)
        $fatal(1, "FAIL: Controller did not enter HOLD_DATA");

    $display("Before Reset: State = %0d, Pixel = %0d, Task ID = %0d, Priority = %0d, Data Valid = %b",
             dut.state, processor_data_out,
             processor_task_id_out, processor_priority_out,
             processor_data_valid);

    // Step 3: Activate reset during HOLD_DATA
    @(negedge clk);
    fifo_read_valid = 1'b0;
    rst = 1'b1;
    #1;

    // Display results after reset
    $display("After Reset: State = %0d, Pixel = %0d, Task ID = %0d, Priority = %0d, Data Valid = %b, Read Enable = %b",
             dut.state, processor_data_out,
             processor_task_id_out, processor_priority_out,
             processor_data_valid, fifo_read_enable);

    // Step 4: Automatically verify reset conditions
    if (dut.state !== 2'b00 ||
        processor_data_out !== 8'd0 ||
        processor_task_id_out !== 8'd0 ||
        processor_priority_out !== 2'd0 ||
        processor_data_valid !== 1'b0 ||
        fifo_read_enable !== 1'b0)
        $fatal(1, "FAIL: Reset During Active Transfer");
    else
        $display("PASS: Reset During Active Transfer");

    // Release reset
    @(negedge clk);
    rst = 1'b0;

        $finish;


end

endmodule
