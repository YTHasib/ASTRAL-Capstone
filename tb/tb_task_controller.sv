
`timescale 1ns/1ps

module tb_task_controller;

    // Clock and Reset
    logic clk = 0;
    logic rst = 0;

    // Incoming Task Information
    logic task_valid = 0;           // Indicates a new task
    logic [7:0] task_id_in = 0;      // Incoming task ID
    logic [1:0] task_priority_in = 0;// Incoming task priority
    logic [7:0] task_steps_in = 0;   // Number of processing steps

    // Task Acceptance and Processing
    logic task_ready;               // Controller can accept a task
    logic process_enable;           // Allows task processing

    // Active Task Information
    logic [7:0] active_task_id;      // Currently running task
    logic [1:0] active_priority;     // Priority of active task
    logic [7:0] steps_completed;     // Number of completed steps

    // Status Outputs
    logic busy;                     // Controller is busy
    logic task_paused;              // A task is paused
    logic task_done;                // Task has finished
    logic [7:0] completed_task_id;   // ID of finished task

    // Generate a 10 ns clock
    always #5 clk = ~clk;

    // Instantiate the Task Controller
    task_controller dut (
        .clk(clk),
        .rst(rst),

        // Task inputs
        .task_valid(task_valid),
        .task_id_in(task_id_in),
        .task_priority_in(task_priority_in),
        .task_steps_in(task_steps_in),

        // Control signals
        .task_ready(task_ready),
        .process_enable(process_enable),

        // Active task information
        .active_task_id(active_task_id),
        .active_priority(active_priority),
        .steps_completed(steps_completed),

        // Status outputs
        .busy(busy),
        .task_paused(task_paused),
        .task_done(task_done),
        .completed_task_id(completed_task_id)
    );

    
    initial begin

        // Test 1: Reset Verification
        #2 rst = 1'b1; // Activate reset
        #1;            // Allow signals to update

        // Display test name and results
        $display("\nTest 1: Reset Verification");
        $display("State = %0d, Busy = %b, Paused = %b, Steps = %0d, Done = %b, Ready = %b",
                 dut.state, busy, task_paused,
                 steps_completed, task_done, task_ready);

        // Automatically verify reset conditions
        if (dut.state !== 3'b000 ||
            active_task_id !== 8'd0 ||
            active_priority !== 2'd0 ||
            steps_completed !== 8'd0 ||
            busy !== 1'b0 ||
            task_paused !== 1'b0 ||
            task_done !== 1'b0 ||
            completed_task_id !== 8'd0 ||
            task_ready !== 1'b0 ||
            process_enable !== 1'b0)
            $fatal(1, "FAIL: Reset Verification");
        else
            $display("PASS: Reset Verification");

        // Release reset
        @(negedge clk);
        rst = 1'b0;

        #1;
        $finish; // End simulation after Test 1

    end



endmodule
