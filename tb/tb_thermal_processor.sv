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

//Instantiate the thermal processor
thermal_processor dut(
    .clk(clk),
    .rst(rst),

    //Inputs from Task 3
     .pixel_in(pixel_in),
    .task_id_in(task_id_in),
    .priority_in(priority_in),
    .data_valid(data_valid),

    //Processor Handshaking
    .processor_ready(processor_ready),

     // Processing Results
     .pixel_out(pixel_out),
     .task_id_out(task_id_out),
     .priority_out(priority_out),
     .hotspot_flag(hotspot_flag),
     .result_valid(result_valid)

);


    initial begin

        // Test 1: Reset Verification ( Verify that reset clears all outputs and prevents the processor from accepting data. )

        #2 rst = 1'b1; // Activate reset
        #1;            // Allow outputs to update

        $display("\nTest 1: Reset Verification");
        $display("Pixel = %0d, Task ID = %0d, Priority = %0d, Hotspot = %b, Valid = %b, Ready = %b",
                 pixel_out, task_id_out, priority_out,
                 hotspot_flag, result_valid, processor_ready);

        // Check that all outputs have been reset
        if (pixel_out !== 8'd0 ||
            task_id_out !== 8'd0 ||
            priority_out !== 2'd0 ||
            hotspot_flag !== 1'b0 ||
            result_valid !== 1'b0 ||
            processor_ready !== 1'b0)
            $fatal(1, "FAIL: Reset Verification");
        else
            $display("PASS: Reset Verification");

        // Release reset before continuing
        @(negedge clk);
        rst = 1'b0;

        // Test 2: Pixel Below Threshold( Verify that pixel 85 does not trigger a hotspot because it is below 100.)

        @(negedge clk);
        pixel_in = 8'd85;    // Thermal pixel value
        task_id_in = 8'd17; // Task identifier
        priority_in = 2'd1; // Task priority
        data_valid = 1'b1;  // Incoming data is valid

        @(posedge clk);
        #1; // Wait for registered outputs to update

        $display("\nTest 2: Pixel Below Threshold");
        $display("Pixel = %0d, Task ID = %0d, Priority = %0d, Hotspot = %b, Valid = %b",
                 pixel_out, task_id_out, priority_out,
                 hotspot_flag, result_valid);

        // Verify the pixel and metadata were received
        // and hotspot detection remains disabled
        if (pixel_out !== 8'd85 ||
            task_id_out !== 8'd17 ||
            priority_out !== 2'd1 ||
            hotspot_flag !== 1'b0 ||
            result_valid !== 1'b1 ||
            processor_ready !== 1'b1)
            $fatal(1, "FAIL: Pixel Below Threshold");
        else
            $display("PASS: Pixel Below Threshold");


        // Test 3: Pixel Equal to Threshold ( Verify that pixel 100 is not flagged because detection requires pixel > 100.)

        @(negedge clk);
        pixel_in = 8'd100;
        task_id_in = 8'd18;
        priority_in = 2'd2;
        data_valid = 1'b1;

        @(posedge clk);
        #1;

        $display("\nTest 3: Pixel Equal to Threshold");
        $display("Pixel = %0d, Task ID = %0d, Priority = %0d, Hotspot = %b, Valid = %b",
                 pixel_out, task_id_out, priority_out,
                 hotspot_flag, result_valid);

        // Check correct threshold boundary behavior
        if (pixel_out !== 8'd100 ||
            task_id_out !== 8'd18 ||
            priority_out !== 2'd2 ||
            hotspot_flag !== 1'b0 ||
            result_valid !== 1'b1)
            $fatal(1, "FAIL: Pixel Equal to Threshold");
        else
            $display("PASS: Pixel Equal to Threshold");


        // Test 4: Pixel Above Threshold ( Verify that a pixel greater than 10 triggers the hotspot detection flag.)

        @(negedge clk);
        pixel_in = 8'd120;
        task_id_in = 8'd19;
        priority_in = 2'd3;
        data_valid = 1'b1;

        @(posedge clk);
        #1;

        $display("\nTest 4: Pixel Above Threshold");
        $display("Pixel = %0d, Task ID = %0d, Priority = %0d, Hotspot = %b, Valid = %b",
                 pixel_out, task_id_out, priority_out,
                 hotspot_flag, result_valid);

        // Check hotspot detection is activated
        if (pixel_out !== 8'd120 ||
            task_id_out !== 8'd19 ||
            priority_out !== 2'd3 ||
            hotspot_flag !== 1'b1 ||
            result_valid !== 1'b1)
            $fatal(1, "FAIL: Pixel Above Threshold");
        else
            $display("PASS: Pixel Above Threshold");

        // Test 5: Invalid Input Data ( Verify that the processor ignores incoming data when data_valid = 0.)

        @(negedge clk);
        data_valid = 1'b0; // Incoming data is invalid
        pixel_in = 8'd200;
        task_id_in = 8'd20;
        priority_in = 2'd0;

        @(posedge clk);
        #1;

        $display("\nTest 5: Invalid Input Data");
        $display("Pixel = %0d, Task ID = %0d, Priority = %0d, Hotspot = %b, Valid = %b",
                 pixel_out, task_id_out, priority_out,
                 hotspot_flag, result_valid);

        // The previous outputs should remain unchanged and no new result should be marked valid.
        if (pixel_out !== 8'd120 ||
            task_id_out !== 8'd19 ||
            priority_out !== 2'd3 ||
            hotspot_flag !== 1'b1 ||
            result_valid !== 1'b0)
            $fatal(1, "FAIL: Invalid Input Data");
        else
            $display("PASS: Invalid Input Data");

        // Test 6: Multiple Consecutive Pixels(Verify that the processor can handle different pixels on consecutive clock cycles.)

        $display("\nTest 6: Multiple Consecutive Pixels");

        // Repeat processing for three pixels
        for (int i = 0; i < 3; i++) begin

            @(negedge clk);
            data_valid = 1'b1;

            // Assign a different pixel each iteration
            case (i)
                0: pixel_in = 8'd85;
                1: pixel_in = 8'd120;
                2: pixel_in = 8'd200;
            endcase

            // Assign unique task IDs and priorities
            task_id_in = 8'd21 + i;
            priority_in = i[1:0];

            @(posedge clk);
            #1;

            // Display the result of each pixel
            $display("Pixel %0d: Value = %0d, Task ID = %0d, Priority = %0d, Hotspot = %b, Valid = %b",
                     i + 1, pixel_out, task_id_out,
                     priority_out, hotspot_flag, result_valid);

            // Verify that each pixel is processed
            // correctly without losing its metadata
            if (pixel_out !== pixel_in ||
                task_id_out !== task_id_in ||
                priority_out !== priority_in ||
                hotspot_flag !== (pixel_in > 8'd100) ||
                result_valid !== 1'b1)
                $fatal(1, "FAIL: Consecutive Pixel %0d", i + 1);
        end

        $display("PASS: Multiple Consecutive Pixels");

        $display("\nAll 6 Thermal Processor Tests Passed!");

        #10;
        $finish; // End the simulation

    end

endmodule
