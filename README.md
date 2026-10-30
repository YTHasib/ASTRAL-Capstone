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


