//----------------------------------------------------------------------------
//  File Name   : uart_host_agent.sv
//  Date        : 8/14/2020
//  Author(s)   : WeiChung Wu (exelion04 at gmail.com)
//  Description : 
//----------------------------------------------------------------------------

`ifndef UART_HOST_AGENT_SV
`define UART_HOST_AGENT_SV

class uart_host_agent extends uvm_agent;
    uart_host_sequencer sequencer;
    uart_host_driver    driver;
    uart_host_monitor   monitor;
    uart_host_config    cfg;

    `uvm_component_utils_begin(uart_host_agent)
        `uvm_field_object(cfg, UVM_DEFAULT|UVM_REFERENCE)
    `uvm_component_utils_end

    function new(string name = "uart_host_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(is_active == UVM_ACTIVE) begin
            sequencer = uart_host_sequencer::type_id::create("sequencer", this);
            driver = uart_host_driver::type_id::create("driver", this);
            cfg.set_sequencer(sequencer);
        end
        monitor = uart_host_monitor::type_id::create("monitor", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            driver.rsp_port.connect(sequencer.rsp_export);
        end
    endfunction : connect_phase
endclass : uart_host_agent
`endif
