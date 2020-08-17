`ifndef UART_BASE_TEST__SV
`define UART_BASE_TEST__SV

class uart_base_test extends uvm_test;

    `uvm_component_utils(uart_base_test)

    uart_ip_tb uarttb;

    function new (string name = "uart_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uarttb = uart_ip_tb::type_id::create("uart_tb", this);
    endfunction : build_phase

    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(),"[UART Test] Main Phase", UVM_LOW)
        phase.drop_objection(this);
    endtask : main_phase

endclass : uart_base_test
`endif
