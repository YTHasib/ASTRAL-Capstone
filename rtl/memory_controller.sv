module memory_controller (
    input logic clk,
    input logic rst,

    //FIFO inputs
    input logic fifo_empty, // indicates that the FIFO is empty and cannot provide new data
    input logic fifo_read_valid, // indicates that the data_out, task_id_out, and priority_out are valid and ready to be read from the FIFO
    input logic [7:0] fifo_data_in, //an 8-bit input for one thermal pixel from the FIFO
    input logic [7:0] fifo_task_id_in, // an 8-bit input for the task ID associated with the incoming data from the FIFO
    input logic [1:0] fifo_priority_in, // a 2-bit input for the priority level of the incoming data from the FIFO

    //Processor Inputs
    input logic processor_ready, // indicates that the processor is ready to accept new data

    //FIFO control outputs
    output logic fifo_read_enable, // indicates that the FIFO should read the next data_out, task_id_out, and priority_out from the FIFO (retrieving data for processing)

    //Processor control outputs
    output logic [7:0] processor_data_out, //an 8-bit output for one thermal pixel to the processor
    output logic [7:0] processor_task_id_out, // an 8-bit output for the task ID associated with the outgoing data to the processor
    output logic [1:0] processor_priority_out, // a 2-bit output for the priority level of the outgoing data to the processor
    output logic       processor_data_valid // indicates that the processor_data_out, processor_task_id_out, and processor_priority_out are valid and ready to be read by the processor

);

// FSM States
typedef enum logic [1:0] { //creates a custom data type that can represent different FSM states
    IDLE = 2'b00, // Waiting for data in FIFO
    WAIT_DATA = 2'b01, // Waiting for the FIFO to return valid data (waits for the FIFO)
    HOLD_DATA = 2'b10 // Holding data until the processor is ready (waits for the processor)
} state_t;//gives the name "state_t" to the custom data type, which can be used to declare variables of this type

state_t state;//stores which state the FSM is currently in, and can take on one of the values defined in the state_t enum
assign fifo_read_enable = (state == IDLE) && !fifo_empty && !rst; // Request a FIFO read when the FSM is in the IDLE state, the FIFO is not empty, and the system is not in reset

//FSM Clock and Reset Logic
always_ff @(posedge clk or posedge rst) begin //Tells the hardware to execute the sequential logic whenever the clock rises from 0 to 1 or when the reset signal is high (1). The sequential logic will be executed on the rising edge of the clock or when the reset signal is high.
    if(rst) begin // If the reset signal is high, reset the FSM to the IDLE state and reset the processor outputs

        state <= IDLE; // Reset the FSM to the IDLE state

        processor_data_out <=8'b0; // Reset the processor data output to 0
        processor_task_id_out <=8'b0; // Reset the processor task ID output to 0
        processor_priority_out <=2'b0; // Reset the processor priority output to 0
        processor_data_valid <=1'b0; // Reset the processor data valid output to 0
    end
    else begin
        case (state) //checks the current state of the FSM and executes the corresponding logic for that state
            IDLE: begin
                if (!fifo_empty) begin // If the FIFO is not empty, transition to the WAIT_DATA state
                    state <= WAIT_DATA; 
                end
            end
            WAIT_DATA: begin
                if(fifo_read_valid) begin // If the FIFO has valid data, pass it to the processor and transition to the HOLD_DATA state
                    processor_data_out <= fifo_data_in; // Pass the data from the FIFO to the processor
                    processor_task_id_out <= fifo_task_id_in; // Pass the task ID from the FIFO to the processor
                    processor_priority_out <= fifo_priority_in; // Pass the priority level from the FIFO to the processor
                    processor_data_valid <= 1'b1; // Indicate that the data is valid and ready to be read by the processor
                    state <= HOLD_DATA; // Transition to the HOLD_DATA state
                end
            end
            HOLD_DATA: begin
                if (processor_ready) begin // If the processor is ready to accept new data, transition back to the IDLE state
                    processor_data_valid <= 1'b0; // Indicate that the data is no longer valid and has been read by the processor
                    state <= IDLE; // Transition back to the IDLE state
                end
            end

            default: begin
                state <= IDLE; // If the FSM is in an unknown state, transition back to the IDLE state
                processor_data_valid <=1'b0; // Clear valid flag if FSM enters an unknown state
            end
            
        endcase
    end
end

endmodule