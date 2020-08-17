`ifndef CPU_INTR_INTERFACE_SV
`define CPU_INTR_INTERFACE_SV

interface cpu_intr_interface(input clk, input sclk);
    logic interrupt;

    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input interrupt;
    endclocking

    task idle_sclk(int count);
        repeat(count) @(posedge sclk);
    endtask

    task idle_ahb(int count);
        repeat(count) @mon_cb;
    endtask
endinterface

`endif
