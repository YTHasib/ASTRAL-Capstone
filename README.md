# ASTRAL FPGA
SystemVerilog simulations for the ASTRAL satellite project.

Mini Project Description:
ASTRAL is a satellite cooperative computing project that enables multiple FPGA based satellites to share processing task. This repository focuses on developing and simulating SystemVerilog modules for data processing, memory management, and task interruption, supporting a Python-based cooperation algorithim. 
Unlike traditional satellites that mainly rely on their own processing power, ASTRAL allows satellites to help each other complete tasks. This can reduce delays, make better use of available resources and help older satellites handle more demading tasks without needing expensive upgrades.
For example, during a forest fire, satellites can use thermal imaging to detect areas of extreme heat. If one satellite is overwhelmed with data, ASTRAL allows it to share the work with another satellite, helping identify potential fires faster and deliver important information to emergency responders sooner. 

## Task 1:Input Data Handling 
- Purpose: thermal image pixels or sensor measurements that were assigned to this FPGA by the cooperation algorithim. It only makes sure that it does not detect forest fires yet but ensures that the thermal data gets into the FPGA correctly.
- Pseudo Code: 
```text
        When reset:
        Clear output status

        Otherwise:
        Check if FIFO has space:

       IF FIFO is not full:
        Tell sender "READY"
    
        IF incoming data is valid:
            Accept the pixel
            Forward it to FIFO
            Request FIFO to write
    
        ELSE:
        Tell sender "NOT READY"
        Do not accept new data
```

****FPGA should only accept a pixel when both data_valid and data_ready are 1 at clock edge. So that it prevents data from being accepted when there's no room.



## Task 2: Memory Buffer (FIFO)
- Purpose: It is a small memory buffer that stores incoming data in the order it arrives and retrieves the oldest data first. ASTRAL uses FIFO (First in First Out) because it allows for temporarily storage of pixels until the processing module is ready 
- Connection to previous task: Task 2 builds on Task 1 by storing the incoming data, task id, and task priorities that the input handler forwards. While Task 1 checks whether data can be accepted, Task 2 temporarily stores it in a FIFO buffer until the FPGA is ready to process it. 
- Pseudo Code:
```text
        INITIALIZE:
            FIFO capacity = 4;
            write_pointer = 0;
            read_pointer = 0;
            count = 0

        WHEN reset occurs:
            Clear read and write pointers
            Set count to 0
            Clear read status

        ON each rising clock edge:
        IF write_enable AND FIFO is not full:
        Store incoming pixel
        Store task ID
        Store priority

        Move write_pointer to next location

        IF read_enable AND FIFO is not empty
        Retrieve oldest pixel
        Retrieve its task ID
        Retrieve its priority 

        Mark output as valid
        Move read_ponter to next location

        IF only a write succeeds:
            Increase count by 1
        ELSE IF only a read succeeds:
            Decrease count by 1
        ELSE:
            Keep count unchanged
        IF count equals FIFO capacity:
            FIFO is full
        IF count equals 0:
            FIFO is empty
```


## Task 3: Memory Read/Write Control (using a simple FSM)
- Purpose: Now we want to control when stored data should be retrieved from FIFO and delivered to the processing module. It builds on Task 2 by making sure data is only retrieved when available and is safely passed to the processor when it's ready, preventing data loss.  
- Connection to previous task: Task 3 builds on Task 2 by controlling when stored data is read from the FIFO buffer and sent to the processing module. While Task 2 focuses on storing and retrieving data, Task 3 ensures that data is transferred at the right time without losing any information. For example, in Task 2, the testbench manually controlled the write_enable and read_enable signals. However, in the actual system, these operations must be controlled automatically by the hardware rather than relying on a testbench. 
- Pseudo Code:
```text
        START
        1. Initialize/Reset
            - Set state to IDLE
            - Set fifo_read_enable = 0
            - Set processor_data_valid = 0
            - Clear output data, task ID, and priority
        2. Check current state <-- FSM starts here
        IF state == IDLE:
            - Check if FIFO is not empty
            - IF data is available:
            - Set fifo_read_enable = 1
            - Request the next FIFO entry
            - Move to WAIT_DATA
        ELSE IF state == WAIT_DATA:
            - Set fifo_read_enable = 0
            - Wait for fifo_read_valid = 1
            - IF data is valid:
                - store the pixel data
                - store the task ID
                - store the task priority
                - set processor_data_valid = 1
                - Move to HOLD_DATA
        ELSE IF state == HOLD_DATA:
            - Keep the stored data unchanged
            - IF processor_ready = 1:
                - Complete the data transfer
                - Set processor_data_valid = 0
                - Return to IDLE
            - ELSE: 
                - Continue holding the data
        3. Repeat until reset

        END
```

## Task 4
- Purpose: The purpose of this task is to recieve thermal pixel data from the memory controller which was designed in task 3, to analyze the pixel values and determine whether they exceed a specified threshold. For instance if the pixel value exceeds 100, the module will flag it as potential hotspot. This threshold represents a digital pixel value, not necessarily a temperature in degrees.
- Connection to previous task: Task 4 builds on Task 3 by processing the thermal pixel data transferred from Memory Controller. While Task3 controls when data is sent to the processor, Task 4 performs the actual analysis. It also uses handshaking signals to inform Task 3 when it is ready to recieve new data.
- Pseudo: 
```
START

1. Initialize/Reset:
    - Clear output data, task Id, and priority
    - Set hotspot_flag = 0
    - Set result_valid = 0

2. Check if data can be processed:
    - Set processor_ready based on whether the module can accept new data
    - Wait for data_valid = 1 and processor_ready = 1

3. Processing incoming data:
    - Recieve thermal pixel value
    - Store task ID and priority

    IF pixel value > 100:
        - Set hotspot_flag = 1
    ELSE: 
        - Set hotspot_flag = 0

4. Output results:
    - Store processed pixel value
    - Output task ID and priority
    - Set result_valid = 1

5. Repeat:
    - Clear result_valid wen no new result is produced
    - Wait for the next valid pixel

END

```