
`timescale 1ns/1ps

module task_controller (
    input logic clk, // System clock
    input logic rst, // Resets the controller

    // Incoming task information
    input logic task_valid, // Indicates a new task is available
    input logic [7:0] task_id_in, // ID of the incoming task
    input logic [1:0] task_priority_in, // Incoming task priority
    input logic [7:0] task_steps_in, // Number of processing steps

    // Task acceptance and processing control
    output logic task_ready, // Controller can accept the incoming task
    output logic process_enable, // Allows the current task to progress

    // Current task information
    output logic [7:0] active_task_id, // Currently running task ID
    output logic [1:0] active_priority, // Current task priority
    output logic [7:0] steps_completed, // Completed processing steps

    // Status outputs
    output logic busy, // Controller is handling a task
    output logic task_paused, // A previous task is paused
    output logic task_done, // Pulses when a task finishes
    output logic [7:0] completed_task_id // ID of completed task
);

    // 1. FSM State Declaration


    typedef enum logic [2:0] {
        IDLE          = 3'b000,
        RUNNING       = 3'b001,
        PAUSE         = 3'b010,
        HIGH_PRIORITY = 3'b011,
        RESUME        = 3'b100
    } state_t;

    state_t state;

   
    // 2. Task Progress Registers

    // Total steps needed by the currently active task
    logic [7:0] total_steps;

    // Save the interrupted task's information
    logic [7:0] saved_task_id;
    logic [1:0] saved_priority;
    logic [7:0] saved_total_steps;
    logic [7:0] saved_progress;
    logic saved_valid;

    // Temporarily store the incoming urgent task
    logic [7:0] urgent_task_id;
    logic [1:0] urgent_priority;
    logic [7:0] urgent_total_steps;

    // Indicates that an incoming task is accepted
    logic accept_task;

    // 3. Task Acceptance and Status Logic

    // Accept a new task when idle, or allow one
    // higher-priority task to interrupt a running task.
    // Tasks must contain at least one processing step.
    assign task_ready = !rst &&
                        (task_steps_in != 8'd0) &&
                        ((state == IDLE) ||
                         ((state == RUNNING) &&
                          !saved_valid &&
                          (task_priority_in > active_priority)));

    // A task is accepted when both VALID and READY are high
    assign accept_task = task_valid && task_ready;

    // Enable one processing step per clock cycle.
    // Stop immediately when an urgent task is accepted.
    assign process_enable = !rst &&
                            ((state == HIGH_PRIORITY) ||
                             ((state == RUNNING) &&
                              !accept_task));

    // Indicate whether the controller is busy
    assign busy = (state != IDLE);

    // Indicate that a previous task has been saved
    assign task_paused = saved_valid;

    // 4. Clock and Reset Logic

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            // Return FSM to starting state
            state <= IDLE;

            // Clear active task information
            active_task_id <= 8'd0;
            active_priority <= 2'd0;
            total_steps <= 8'd0;
            steps_completed <= 8'd0;

            // Clear saved task information
            saved_task_id <= 8'd0;
            saved_priority <= 2'd0;
            saved_total_steps <= 8'd0;
            saved_progress <= 8'd0;
            saved_valid <= 1'b0;

            // Clear urgent task information
            urgent_task_id <= 8'd0;
            urgent_priority <= 2'd0;
            urgent_total_steps <= 8'd0;

            // Clear completion outputs
            task_done <= 1'b0;
            completed_task_id <= 8'd0;

        end

        else begin

            // Default: no task completed this cycle
            task_done <= 1'b0;

            case (state)

                // STATE 1: IDLE
                // Wait for a new task to arrive.

                IDLE: begin

                    if (accept_task) begin

                        // Store new task information
                        active_task_id <= task_id_in;
                        active_priority <= task_priority_in;
                        total_steps <= task_steps_in;

                        // Start processing from step zero
                        steps_completed <= 8'd0;

                        // Begin executing the task
                        state <= RUNNING;

                    end
                end

                // STATE 2: RUNNING
                // Execute the current task.
                // Pause if a more urgent task arrives.

                RUNNING: begin

                    if (accept_task) begin

                        // Save interrupted task information
                        saved_task_id <= active_task_id;
                        saved_priority <= active_priority;
                        saved_total_steps <= total_steps;
                        saved_progress <= steps_completed;
                        saved_valid <= 1'b1;

                        // Store incoming urgent task
                        urgent_task_id <= task_id_in;
                        urgent_priority <= task_priority_in;
                        urgent_total_steps <= task_steps_in;

                        // Move to PAUSE
                        state <= PAUSE;

                    end

                    else if (steps_completed ==
                             total_steps - 8'd1) begin

                        // Final processing step completed
                        steps_completed <= total_steps;

                        // Mark task as finished
                        task_done <= 1'b1;
                        completed_task_id <= active_task_id;

                        // Return to IDLE
                        state <= IDLE;

                    end

                    else begin

                        // Complete one processing step
                        steps_completed <= steps_completed + 8'd1;

                    end
                end

                
                // STATE 3: PAUSE
                // Switch from the interrupted task
                // to the higher-priority task.

                PAUSE: begin

                    // Load urgent task information
                    active_task_id <= urgent_task_id;
                    active_priority <= urgent_priority;
                    total_steps <= urgent_total_steps;

                    // Urgent task starts from step zero
                    steps_completed <= 8'd0;

                    // Begin urgent processing
                    state <= HIGH_PRIORITY;

                end

                // STATE 4: HIGH_PRIORITY
                // Execute the urgent task before
                // returning to the original task.

                HIGH_PRIORITY: begin

                    if (steps_completed ==
                        total_steps - 8'd1) begin

                        // Urgent task has finished
                        steps_completed <= total_steps;

                        task_done <= 1'b1;
                        completed_task_id <= active_task_id;

                        // Restore the interrupted task next
                        state <= RESUME;

                    end

                    else begin

                        // Continue urgent task processing
                        steps_completed <= steps_completed + 8'd1;

                    end
                end

                // STATE 5: RESUME
                // Restore the interrupted task
                // from its saved progress.

                RESUME: begin

                    // Restore previous task information
                    active_task_id <= saved_task_id;
                    active_priority <= saved_priority;
                    total_steps <= saved_total_steps;
                    steps_completed <= saved_progress;

                    // Clear saved-task indicator
                    saved_valid <= 1'b0;

                    // Continue the original task
                    state <= RUNNING;

                end

                // DEFAULT: Unexpected FSM State

                default: begin
                    state <= IDLE;
                    saved_valid <= 1'b0;
                    task_done <= 1'b0;
                end

            endcase
        end
    end

endmodule
