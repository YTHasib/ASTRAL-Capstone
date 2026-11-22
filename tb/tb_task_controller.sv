
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


        // Test 2: Accept and Start a Normal Task

        @(negedge clk);
        task_valid = 1'b1;          // New task is available
        task_id_in = 8'd17;         // Task ID = 17
        task_priority_in = 2'd1;    // Low-priority task
        task_steps_in = 8'd4;       // Task requires 4 processing steps

        #1; // Allow combinational signals to update

        // Display test name and initial conditions
        $display("\nTest 2: Accept and Start a Normal Task");
        $display("Before Clock: State = %0d, Task Ready = %b, Task Valid = %b",
                dut.state, task_ready, task_valid);

        // Check that the controller is ready to accept the task
        if (dut.state !== 3'b000 ||
            task_ready !== 1'b1)
            $fatal(1, "FAIL: Task Acceptance");

        // Wait for rising clock edge to accept the task
        @(posedge clk);
        #1;

        // Display results after task acceptance
        $display("After Clock: State = %0d, Task ID = %0d, Priority = %0d, Steps = %0d, Busy = %b",
                dut.state, active_task_id, active_priority,
                steps_completed, busy);

        // Verify that the controller entered RUNNING
        if (dut.state !== 3'b001 ||
            active_task_id !== 8'd17 ||
            active_priority !== 2'd1 ||
            steps_completed !== 8'd0 ||
            busy !== 1'b1 ||
            process_enable !== 1'b1 ||
            task_paused !== 1'b0)
            $fatal(1, "FAIL: Task Start Verification");
        else
            $display("PASS: Accept and Start a Normal Task");

        // Stop requesting a new task
        @(negedge clk);
        task_valid = 1'b0;


    // Test 3: Normal Task Completion

    // Allow the task to complete its first 3 steps
    repeat (3) begin
        @(posedge clk);
        #1;
    end

    // Display progress before completion
    $display("\nTest 3: Normal Task Completion");
    $display("Before Completion: State = %0d, Task ID = %0d, Steps = %0d, Done = %b",
             dut.state, active_task_id,
             steps_completed, task_done);

    // Verify that the task is still running
    if (dut.state !== 3'b001 ||
        steps_completed !== 8'd3 ||
        task_done !== 1'b0)
        $fatal(1, "FAIL: Task Progress Verification");

    // Complete the fourth and final processing step
    @(posedge clk);
    #1;

    // Display results after task completion
    $display("After Completion: State = %0d, Completed Task ID = %0d, Steps = %0d, Busy = %b, Done = %b",
             dut.state, completed_task_id,
             steps_completed, busy, task_done);

    // Automatically verify successful task completion
    if (dut.state !== 3'b000 ||
        completed_task_id !== 8'd17 ||
        steps_completed !== 8'd4 ||
        busy !== 1'b0 ||
        task_done !== 1'b1 ||
        process_enable !== 1'b0)
        $fatal(1, "FAIL: Normal Task Completion");
    else
        $display("PASS: Normal Task Completion");



    // Test 4: High-Priority Task Interrupt

    // Step 1: Start a low-priority task
    @(negedge clk);
    task_valid = 1'b1;          // New task available
    task_id_in = 8'd21;         // Task A
    task_priority_in = 2'd1;    // Low priority
    task_steps_in = 8'd5;       // Requires 5 steps

    @(posedge clk);
    #1;

    // Verify Task A starts running
    if (dut.state !== 3'b001 ||
        active_task_id !== 8'd21 ||
        steps_completed !== 8'd0)
        $fatal(1, "FAIL: Task A Did Not Start");

    // Stop sending the initial task
    @(negedge clk);
    task_valid = 1'b0;

    // Step 2: Allow Task A to complete 2 steps
    repeat (2) begin
        @(posedge clk);
        #1;
    end

    $display("\nTest 4: High-Priority Task Interrupt");
    $display("Before Interrupt: State = %0d, Task ID = %0d, Priority = %0d, Steps = %0d",
             dut.state, active_task_id,
             active_priority, steps_completed);

    // Verify Task A has completed 2 steps
    if (steps_completed !== 8'd2 ||
        dut.state !== 3'b001)
        $fatal(1, "FAIL: Task A Progress");

    // Step 3: Introduce higher-priority Task B
    @(negedge clk);
    task_valid = 1'b1;
    task_id_in = 8'd22;         // Task B
    task_priority_in = 2'd3;    // Higher priority
    task_steps_in = 8'd2;       // Requires 2 steps

    #1; // Allow combinational signals to update

    // Verify controller accepts the urgent task
    // and stops advancing Task A
    if (task_ready !== 1'b1 ||
        process_enable !== 1'b0)
        $fatal(1, "FAIL: Interrupt Request");

    // Step 4: Accept interruption on rising edge
    @(posedge clk);
    #1;

    // Display controller status after interruption
    $display("After Interrupt: State = %0d, Paused = %b, Saved Task ID = %0d, Saved Steps = %0d",
             dut.state, task_paused,
             dut.saved_task_id, dut.saved_progress);

    // Verify Task A's information was saved
    if (dut.state !== 3'b010 ||
        task_paused !== 1'b1 ||
        dut.saved_task_id !== 8'd21 ||
        dut.saved_priority !== 2'd1 ||
        dut.saved_total_steps !== 8'd5 ||
        dut.saved_progress !== 8'd2 ||
        dut.urgent_task_id !== 8'd22 ||
        dut.urgent_priority !== 2'd3 ||
        dut.urgent_total_steps !== 8'd2 ||
        steps_completed !== 8'd2 ||
        process_enable !== 1'b0)
        $fatal(1, "FAIL: High-Priority Task Interrupt");
    else
        $display("PASS: High-Priority Task Interrupt");

    // Stop sending Task B
    @(negedge clk);
    task_valid = 1'b0;


    // Test 5: Verify Saved Task Progress

    // Move from PAUSE to HIGH_PRIORITY
    @(posedge clk);
    #1; // Allow registers to update

    // Display test name and results
    $display("\nTest 5: Verify Saved Task Progress");

    $display("Active Task: State = %0d, Task ID = %0d, Priority = %0d, Steps = %0d",
             dut.state, active_task_id,
             active_priority, steps_completed);

    $display("Saved Task: Task ID = %0d, Priority = %0d, Total Steps = %0d, Saved Progress = %0d",
             dut.saved_task_id, dut.saved_priority,
             dut.saved_total_steps, dut.saved_progress);

    // Verify Task B is now active
    if (dut.state !== 3'b011 ||
        active_task_id !== 8'd22 ||
        active_priority !== 2'd3 ||
        steps_completed !== 8'd0 ||
        dut.total_steps !== 8'd2)
        $fatal(1, "FAIL: Urgent Task Activation");

    // Verify Task A's information is still saved
    if (dut.saved_task_id !== 8'd21 ||
        dut.saved_priority !== 2'd1 ||
        dut.saved_total_steps !== 8'd5 ||
        dut.saved_progress !== 8'd2 ||
        dut.saved_valid !== 1'b1 ||
        task_paused !== 1'b1 ||
        process_enable !== 1'b1)
        $fatal(1, "FAIL: Saved Task Progress");
    else
        $display("PASS: Verify Saved Task Progress");


    // Test 6: High-Priority Task Completion

    // Step 1: Complete the first processing step of Task B
    @(posedge clk);
    #1; // Allow registers to update

    $display("\nTest 6: High-Priority Task Completion");
    $display("Before Completion: State = %0d, Task ID = %0d, Steps = %0d, Done = %b",
             dut.state, active_task_id,
             steps_completed, task_done);

    // Verify Task B is still running after one step
    if (dut.state !== 3'b011 ||
        active_task_id !== 8'd22 ||
        steps_completed !== 8'd1 ||
        task_done !== 1'b0)
        $fatal(1, "FAIL: High-Priority Task Progress");

    // Step 2: Complete the second and final step
    @(posedge clk);
    #1;

    // Display results after Task B completes
    $display("After Completion: State = %0d, Completed Task ID = %0d, Steps = %0d, Done = %b, Paused = %b",
             dut.state, completed_task_id,
             steps_completed, task_done, task_paused);

    // Verify Task B completed successfully
    if (dut.state !== 3'b100 ||
        completed_task_id !== 8'd22 ||
        steps_completed !== 8'd2 ||
        task_done !== 1'b1 ||
        process_enable !== 1'b0)
        $fatal(1, "FAIL: High-Priority Task Completion");

    // Verify Task A's progress is still saved
    if (dut.saved_task_id !== 8'd21 ||
        dut.saved_progress !== 8'd2 ||
        dut.saved_valid !== 1'b1 ||
        task_paused !== 1'b1)
        $fatal(1, "FAIL: Paused Task Information Lost");
    else
        $display("PASS: High-Priority Task Completion");




    end



endmodule
