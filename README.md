# ASTRAL FPGA
SystemVerilog simulations for the ASTRAL satellite project.

Mini Project Description:
ASTRAL is a satellite cooperative computing project that enables multiple FPGA based satellites to share processing task. This repository focuses on developing and simulating SystemVerilog modules for data processing, memory management, and task interruption, supporting a Python-based cooperation algorithim. 
Unlike traditional satellites that mainly rely on their own processing power, ASTRAL allows satellites to help each other complete tasks. This can reduce delays, make better use of available resources and help older satellites handle more demading tasks without needing expensive upgrades.
For example, during a forest fire, satellites can use thermal imaging to detect areas of extreme heat. If one satellite is overwhelmed with data, ASTRAL allows it to share the work with another satellite, helping identify potential fires faster and deliver important information to emergency responders sooner. 

Task 1:Input Data Handling 
- Purpose: thermal image pixels or sensor measurements that were assigned to this FPGA by the cooperation algorithim. It only makes sure that it does not detect forest fires yet but ensures that the thermal data gets into the FPGA correctly.
- Pseudo Code 

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

****FPGA should only accept a pixel when both data_valid and data_ready are 1 at clock edge. So that it prevents data from being accepted when there's no room.

Completion of Task 1: <img width="542" height="195" alt="image" src="https://github.com/user-attachments/assets/cb0ea5dc-5d4d-4c91-bac8-7ff932d00f8e" />




Task 2: Memory Buffer (FIFO)
- Purpose: It is a small memory buffer that stores incoming data in the order it arrives and retrieves the oldest data first. ASTRAL uses FIFO (First in First Out) because it allows for temporarily storage of pixels until the processing module is ready 
- Connection to previous task: Task 2 builds on Task 1 by storing the incoming data, task id, and task priorities that the input handler forwards. While Task 1 checks whether data can be accepted, Task 2 temporarily stores it in a FIFO buffer until the FPGA is ready to process it. 
- Pseudo Code:
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