`ifndef UART_INTERFACE_SV
`define UART_INTERFACE_SV

interface uart_interface(input clk, input rst_);
    logic sin_data;
    logic sout_data;
    logic rts_n;
    logic cts_n;
    logic dtr_n;
    logic dsr_n;

    clocking mst_cb @(posedge clk);
        default input #1step output #1;
        input sin_data, cts_n, dsr_n;
        output sout_data, rts_n, dtr_n;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input sin_data, cts_n, dsr_n;
        input sout_data, rts_n, dtr_n;
    endclocking
endinterface

`endif
