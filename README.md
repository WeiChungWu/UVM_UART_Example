UVM UART Host Agent Bench Example
============
Author: WeiChung Wu

This is an UVM test bench example to demonstrate that an UART host agent performs TX/RX data transfer between UART device design.
It is an example of how to build a basic UVM environment bench. So if you are a beginner in the field of constraint random verification, it might help you well to go through the UVM methodology.

## Features in this example
1. It demonstrates how to implement pipeline mechanism in the uvm_driver and also perform UART TX/RX transfer simultaneously.
2. It demonstrates a use case of uvm_event_callback exmaple that providing a loose coupling mechanism to interact between uvm_sequence and uvm_component.
3. It demonstrates how to perform better practice of read()/write() tasks in uvm_sequence.

## Note
This is an example for UVM learning only. 
If you are trying to run this example, there will be some missing files and runtime errors which are left intentionally.
Users should be able to implement the rest of part by themselves.

## Test Bench Diagram
![uart_tb_diagram](https://github.com/WeiChungWu/UVM_UART_Example/tree/master/tb/uart_tb_diagram.png)
