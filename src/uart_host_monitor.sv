//----------------------------------------------------------------------------
//  File Name   : uart_host_monitor.sv
//  Date        : 8/14/2020
//  Author(s)   : WeiChung Wu (exelion04 at gmail.com)
//  Description : 
//----------------------------------------------------------------------------

`ifndef UART_HOST_MONITOR_SV
`define UART_HOST_MONITOR_SV

class uart_host_monitor extends uvm_monitor;
    uart_host_config cfg;
    virtual uart_interface uart_vif;

    uvm_analysis_port#(uart_trans) tx_trans_ap;
    uvm_analysis_port#(uart_trans) rx_trans_ap;
    uvm_analysis_port#(uart_trans) trans_ap;

    typedef enum bit {TX=1'b0, RX=1'b1} uart_dir_e;

    protected string rpt_id;

    `uvm_component_utils_begin(uart_host_monitor)
        `uvm_field_object(cfg, UVM_DEFAULT|UVM_REFERENCE)
    `uvm_component_utils_end

    function new(string name = "uart_host_monitor", uvm_component parent = null);
        super.new(name, parent);
        tx_trans_ap = new("tx_trans_ap", this);
        rx_trans_ap = new("rx_trans_ap", this);
        trans_ap = new("trans_ap", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        string val;
        uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();

        super.build_phase(phase);
        uart_vif = cfg.uart_vif;

        if(!clp.get_arg_value("+UART_DEBUG", val)) begin
            set_report_severity_id_action_hier(UVM_INFO, get_type_name(), UVM_NO_ACTION);
        end
        rpt_id = $sformatf("uart_host_monitor%0d", cfg.id);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    virtual task run_phase(uvm_phase phase);
        fork
        main_loop(TX);
        main_loop(RX);
        join
    endtask : run_phase

    extern virtual task main_loop(uart_dir_e dir=RX);
    extern virtual function uart_trans transform(bit [7:0] data, uart_dir_e dir=RX);
endclass : uart_host_monitor

task uart_host_monitor::main_loop(uart_dir_e dir=RX);
    bit start_bit_found;
    bit stop_bit_found;
    bit [7:0] rdata;
    string id = {"[",dir.name(),"]"};

    forever begin
        if(cfg.auto_flow_ctrl) begin
            if(dir) wait(uart_vif.rts_n==0);
            else    wait(uart_vif.cts_n==0);
        end
        //wait start bit
        do begin
            start_bit_found = 1;
            if(dir) wait(uart_vif.sin_data==0);
            else    wait(uart_vif.sout_data==0);
            `uvm_info(get_type_name(), $sformatf("%s Start Bit begins...", id), UVM_MEDIUM)
            repeat (cfg.baud_cnt) begin
                @(uart_vif.mon_cb);
                if((uart_vif.mon_cb.sin_data==1&&dir) || (uart_vif.mon_cb.sout_data==1&&~dir)) begin
                    start_bit_found = 0;
                    `uvm_info(get_type_name(), $sformatf("%s Start Bit is aborted, mon_cb.sin_data=%1b", id, uart_vif.mon_cb.sin_data), UVM_MEDIUM)
                    break;
                end
            end
        end while(!start_bit_found);
        `uvm_info(get_type_name(), $sformatf("%s Start Bit is detected", id), UVM_MEDIUM)

        //receive data bit
        repeat (cfg.half_cnt) @(uart_vif.mon_cb);
        for (int i=0; i<cfg.data_len; i++) begin
            if(dir) rdata[i] = uart_vif.mon_cb.sin_data;
            else    rdata[i] = uart_vif.mon_cb.sout_data;
            `uvm_info(get_type_name(), $sformatf("%s Receive BIT%0d=%1b", id, i, rdata[i]), UVM_MEDIUM)
            if(i<7) repeat (cfg.baud_cnt) @(uart_vif.mon_cb);
            else    repeat (cfg.baud_cnt-cfg.half_cnt) @(uart_vif.mon_cb);
        end

        if(cfg.parity_en) begin
            `uvm_info(get_type_name(), $sformatf("%s Parity Bit begins", id), UVM_MEDIUM)
            repeat (cfg.baud_cnt) @(uart_vif.mon_cb);
            `uvm_info(get_type_name(), $sformatf("%s Parity Bit ends", id), UVM_MEDIUM)
        end

        //wait stop bit
        stop_bit_found = 1;
        `uvm_info(get_type_name(), $sformatf("%s Stop Bit begins", id), UVM_MEDIUM)
        repeat (cfg.baud_cnt) begin 
            @(uart_vif.mon_cb);
            if((uart_vif.mon_cb.sin_data==0&&dir) || (uart_vif.mon_cb.sout_data==0&&~dir)) begin
                stop_bit_found = 0;
                break;
            end
        end
        if(stop_bit_found) begin
            `uvm_info(get_type_name(), $sformatf("%s Stop Bit is detected", id), UVM_MEDIUM)
            if(dir) `uvm_info(rpt_id, $sformatf("[H <- D] SIN_DATA = %2h", rdata), UVM_MEDIUM)
            else    `uvm_info(rpt_id, $sformatf("[H -> D] SOUT_DATA = %2h", rdata), UVM_MEDIUM)
            if(dir) rx_trans_ap.write(transform(rdata, dir));
            else    tx_trans_ap.write(transform(rdata, dir));
            trans_ap.write(transform(rdata, dir));
        end
    end
endtask

function uart_trans uart_host_monitor::transform(bit [7:0] data, uart_dir_e dir=RX);
    uart_trans pkt = uart_trans::type_id::create("uart_mon");
    pkt.addr = 64'h0;
    pkt.data_width = DATA_WIDTH_8BIT;
    pkt.burst_length = 1;
    pkt.direction = dir ? UART_READ : UART_WRITE;
    pkt.byte_array = new[1];
    pkt.byte_array[0] = data;
    pkt.data = pkt.unpack_bytestream();
    return pkt;
endfunction
`endif
