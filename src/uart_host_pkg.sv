`ifndef UART_HOST_PKG_SV
`define UART_HOST_PKG_SV

package uart_host_pkg;
    import uvm_pkg::*;

    `include "uart_host_config.sv"
    `include "uart_host_sequencer.sv"
    `include "uart_host_driver.sv"
    `include "uart_host_monitor.sv"
    `include "uart_host_agent.sv"
    `include "uart_host_sequence.sv"
    `include "uart_host_scoreboard.sv"
endpackage
`endif
