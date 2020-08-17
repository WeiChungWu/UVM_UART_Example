`ifndef TP__SV
`define TP__SV

`timescale 1ns/10ps

module tb;
    import uvm_pkg::*;
    import uart_host_pkg::*;

    dut_wrapper top();

    `include "uart_ip_test_lib.sv"

    initial begin
        uvm_config_db#(virtual uart_interface)::set(null, "*", "uart_interface", top.uart_if);
        uvm_config_db#(virtual cpu_intr_interface)::set(null, "*", "cpu_intr_interface", top.cpu_intr_if);
        run_test();
    end
endmodule : tb

`endif 
