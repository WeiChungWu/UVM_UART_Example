`ifndef UART_IP_TB_SV
`define UART_IP_TB_SV

`include "uart_fw_seq_lib.sv"

class uart_ip_tb extends uvm_env;

    `uvm_component_utils(uart_ip_tb)

    uart_host_config       uart_host_cfg;
    uart_host_agent        uart_host;
    uart_host_scoreboard   uart_sb;

    uvm_table_printer printer;

    function new (string name = "uart_ip_tb", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //UART Host
        uart_host_cfg = uart_host_config::type_id::create("uart_host_cfg");
        if(!uart_host_cfg.randomize())
            `uvm_fatal(get_name(), "uart_host_cfg randomize failed!")
        if (!uvm_config_db#(virtual uart_interface)::get(this, "", "uart_interface", uart_host_cfg.uart_vif)) begin
            `uvm_fatal(get_name(), $sformatf("No virtual uart_interface specified"))
        end
        uvm_config_object::set(this, "uart_host*", "cfg", uart_host_cfg);
        uart_host = uart_host_agent::type_id::create("uart_host", this);
        uart_sb = uart_host_scoreboard::type_id::create("uart_sb", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        uart_host.monitor.tx_trans_ap.connect(uart_sb.exp_tx_in);
        uart_host.monitor.rx_trans_ap.connect(uart_sb.act_rx_in);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        printer = new();
        printer.knobs.depth = 3;

        begin
            uvm_report_server rs =uvm_report_server::get_server();
            rs.set_max_quit_count(1);
        end

        uvm_report_info(get_type_name(), $psprintf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW);

        `uvm_info(get_name(), "Print timescale:", UVM_MEDIUM)
        $printtimescale(tb.top);
    endfunction : end_of_elaboration_phase

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
    endfunction : start_of_simulation_phase

    virtual task run_phase(uvm_phase phase);
    endtask : run_phase

    virtual task reset_phase(uvm_phase phase);
        phase.raise_objection(this);
        @(posedge tb.top.rstn);
        `uvm_info(get_type_name(), "Reset is done", UVM_MEDIUM)
        phase.drop_objection(this);
    endtask : reset_phase

endclass : uart_ip_tb
`endif
