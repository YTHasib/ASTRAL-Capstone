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



      //Test 2: Read the thermal pixel from FIFO
      read_enable = 1;
      @(posedge clk);
      #1;

      $display("Pixel = %0d, Task ID = %0d, Priority = %0d", data_out, task_id_out, priority_out); // Display the read values from the FIFO
      $display("FIFO Count = %0d, Empty = %b, Read Valid = %b",dut.count, fifo_empty, read_valid);// Display the FIFO status after reading
      @(negedge clk);
      read_enable = 0;
       

       //Test 3: Reading when the FIFO is empty
       read_enable =1; //The FIFO is now empty after the previous read, so this read should not be valid
       @(posedge clk);
       #1;

       $display("Empty Read Test: Count = %0d, Empty = %b, Read Valid = %b", dut.count, fifo_empty, read_valid);

       @(negedge clk);
       read_enable = 0; //Stop reading
       
       
       //Test 4: Fill the FIFO
       @(negedge clk);
       write_enable = 1;
        data_in = 8'd35;

        @(negedge clk);
        data_in = 8'd42;

        @(negedge clk);
        data_in = 8'd85;

        @(negedge clk);
        data_in = 8'd47;

        @(posedge clk);
        #1;

        $display("FIFO Full Test: Count = %0d, Full = %b, Empty = %b", dut.count, fifo_full, fifo_empty);

        @(negedge clk);
        write_enable = 0;

        //Test 5: Attempt tp write when FIFO is full
        @(negedge clk);
        data_in = 8'd99; //This write should not be accepted since the FIFO is full
        write_enable = 1;

        @(posedge clk);
        #1;

        $display("Overflow Test: Count = %0d, Full = %b", dut.count, fifo_full); //Count should still be 4

        @(negedge clk);
        write_enable = 0;

        //Test 6: Read all the data from the FIFO
        read_enable = 1;

        repeat (4) begin //Read 4 times to empty the FIFO, its like a loop that will read until the FIFO is empty
            @(posedge clk);
            #1;
            $display("Read Test: Pixel = %0d, Task ID = %0d, Priority = %0d, Count = %0d, Empty = %b, Read Valid = %b", data_out, task_id_out, priority_out, dut.count, fifo_empty, read_valid);
        end

        @(negedge clk);
        read_enable = 0;//stops requesting reads from the FIFO

        //Test 7: Prepare for simultaneous read and write operations
       
        //Step 1: Prepare pixel 61 to be stored in FIFO
        data_in = 8'd61; //Set incoming thermal pixel to 61
        task_id_in = 8'd22; //Pixel belongs to task 22
        priority_in = 2'b10; //assign a priority level of 2 to this pixel
        write_enable = 1;  //Request a write (not stored yet, will be stored on the next posedge clk)

        @(posedge clk); //At this rising edge, FIFO stores pixel 61
        #1;

        $display("Test 7 Setup: Count = %0d", dut.count); // Display the FIFO count after writing one pixel
        //Count should now be 1 because pixel 61 was stored

        
        //Step 2: Prepare to read pixel 61 and write pixel 62 simultaneously
        @(negedge clk);//Wait for falling edge to change inputs safely
        data_in = 8'd62; //Set incoming thermal pixel to 62(not stored yet)
        task_id_in = 8'd23; //Pixel belongs to task 23
        priority_in = 2'b11; //assign a priority level of 3 to this pixel
        read_enable = 1; //request a read for the oldest pixel (61)
        //write_enable is already 1, so a write is also requested

        //Step 3: Perform both read and write operations on the next rising edge of the clock
        @(posedge clk); //FIFO reads pixel 61 and stores pixel 62
        #1; //Wait for output and counter to update

        $display("Simultaneous Test: Pixel Read = %0d, Count = %0d, Read Valid = %b",data_out, dut.count, read_valid);

        //Step 4: Stop requesting reads and writes  
        @(negedge clk);
        write_enable = 0;
        read_enable = 0;

        //***The negedge changes the input, but the posedge is when your FIFO actually reads and writes the data

        //Step 5: Verify that pixel 62 was stored

        @(negedge clk);
        read_enable = 1; //Request a read from the remaining pixel

        @(posedge clk); //FIFO reads pixel 62
        #1; //Wait for output and counter to update

         $display("Verify Pixel 62: Pixel = %0d, Task ID = %0d, Priority = %0d, Count = %0d, Empty = %b, Read Valid = %b", data_out, task_id_out, priority_out, dut.count, fifo_empty, read_valid);

         @(negedge clk);
         read_enable = 0; //Stop requesting reads


         //Test 8: Reset the FIFO, as we want to see if it clears the pointers and counters too 

         //Step 1: Store a pixel before resettng
        @(negedge clk);
        data_in = 8'd90;
        task_id_in = 8'd25;
        priority_in = 2'b11;
        write_enable = 1;

        @(posedge clk); //FIFO stores pixel 90
        #1;//Wait for registers to update

        $display("Before Reset: Count = %0d, Empty = %b", dut.count, fifo_empty);

        @(negedge clk);
        write_enable = 0; //Stop requesting writes


        //Test 8: Activate reset while FIFO contains data
        #2 rst = 1; //Activate reset 2 ns after falling edge
        #1; //Allow time for reset to propagate

        $display("After Reset: Count = %0d, Empty = %b, Full = %b", dut.count, fifo_empty, fifo_full);

        $display("Write Pointer = %0d, Read Pointer = %0d, Read Valid = %b", dut.write_pointer, dut.read_pointer, read_valid);
        #2 rst = 0;  // Release reset before next rising clock edge

        #10;
        $finish;
    
    end  



endmodule

