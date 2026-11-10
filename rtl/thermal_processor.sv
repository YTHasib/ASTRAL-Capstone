`timescale 1ns / 1ps

module thermal_processor (
    input logic clk, //Clock signal hat controls when data is processed
    input logic rst, //Resets the module and clears its output

    //Inputs from Task 3
    input logic [7:0] pixel_in, //8-bit thermal pixel recieved from Task 3
    input logic [7:0] task_id_in, // 8-bit ID identifying the task
    input logic [1:0] priority_in, //2-bit priority level associated with the task
    input logic data_valid, //indicates the incoming pixel is data is valid

    //Handshaking output to Task 3
    output logic processor_ready, //indicates the Task 4 can accept new data

    //Processing results
    output logic [7:0] pixel_out, //Outputs the processed thermal pixel
    output logic [7:0] task_id_out, //Preserve the task ID associated with the pixel
    output logic [1:0] priority_out, //Preserves the priority level of the task
    output logic hotspot_flag, // Set to 1 when pixel exceeds the hotspot threshold
    output logic result_valid // Set to 1 when a valid processing result is available


);

// Thermal Pixel Threshold
localparam logic [7:0] HOTSPOT_THRESHOLD = 8'd100; //doesn't change when the circuit is running and sets the threshold to 100 in decimal

//Clock and Reset Logic
always_ff @(posedge clk or posedge rst) begin //Excute on rising clock edge or when reset is activated
    if (rst) begin
        pixel_out <= 8'b0;  //Clear pixel output
        task_id_out <= 8'b0;    //Clear task ID
        priority_out <= 2'b0;   //Clear task priority
        hotspot_flag <= 1'b0;   //Clear hotspot detection
        result_valid <= 1'b0;   //Indicate no valid result
    end
    else begin
        result_valid <= 1'b0; // Default: no new result this cycle

        if(data_valid && processor_ready) begin //Process data only when valid and processor is ready
            pixel_out <= pixel_in; //Store incoming pixel
            task_id_out <= task_id_in; //Preserve task ID
            priority_out <= priority_in; //Preserve priority

            if(pixel_in > HOTSPOT_THRESHOLD) begin //compare incoming pixel against threshold
                hotspot_flag <= 1'b1; //Hotspot detected 
            end
            else begin
                hotspot_flag <= 1'b0; //No hotspot detected
            end
            result_valid <= 1'b1; //Processing result is available
        end
    end
end

//Processor can accept data whenevr reset is inactivate
assign processor_ready = !rst;


endmodule


