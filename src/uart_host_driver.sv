//----------------------------------------------------------------------------
//  File Name   : uart_host_driver.sv
//  Date        : 8/14/2020
//  Author(s)   : WeiChung Wu (exelion04 at gmail.com)
//  Description : 
//----------------------------------------------------------------------------

`ifndef UART_HOST_DRIVER_SV
`define UART_HOST_DRIVER_SV

class uart_host_driver extends uvm_driver;
    uart_host_config cfg;
    virtual uart_interface uart_vif;

    protected bit [7:0] received_data_fifo[$];

    // TX, RX operation can be performed simultaneously
    // In TX or RX operation, one transfer is following previous transfer ended
    protected semaphore tx_lock, rx_lock;

    `uvm_component_utils_begin(uart_host_driver)
        `uvm_field_object(cfg, UVM_DEFAULT|UVM_REFERENCE)
    `uvm_component_utils_end

    function new(string name = "uart_host_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        string val;
        uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();

        super.build_phase(phase);
        uart_vif = cfg.uart_vif;
        tx_lock = new(1);
        rx_lock = new(1);

        if(!clp.get_arg_value("+UART_DEBUG", val)) begin
            set_report_severity_id_action_hier(UVM_INFO, get_type_name(), UVM_NO_ACTION);
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        uart_vif.sout_data <= 1'b1;
        uart_vif.rts_n <= 1'b1;
        uart_vif.dtr_n <= 1'b1;
        fork
        main_loop();
        receive();
        auto_flow_ctrl();
        join
    endtask : run_phase

    extern virtual task main_loop();
    extern virtual task reset();
    extern virtual task send(ref uart_trans tr);
    extern virtual function bit get_parity(int n, ref uart_trans tr);
    extern virtual task auto_flow_ctrl();
    extern virtual task receive();
    extern virtual task read(ref uart_trans tr);
endclass

task uart_host_driver::main_loop();
    uvm_sequence_item item;
    uart_trans tr;

    forever begin
        seq_item_port.get(item);
        void'($cast(tr, item));
        if(tr==null) `uvm_fatal(get_name(), "casting failed or item returned null")
        if(tr.direction==UART_WRITE) tx_lock.get();
        else                        rx_lock.get();

        fork
        begin
            automatic uart_trans req, rsp;
            req = tr;
            if(req.direction==UART_WRITE) send(req);
            else                         read(req);
            $cast(rsp, req.clone());
            rsp.set_id_info(req);
            seq_item_port.put(rsp);
            if(req.direction==UART_WRITE) tx_lock.put();
            else                         rx_lock.put();
        end
        join_none
    end
endtask

task uart_host_driver::reset();
    forever begin
        @(posedge uart_vif.rst_);
        received_data_fifo.delete();
        uart_vif.sout_data <= 1'b1;
        uart_vif.rts_n <= 1'b1;
        uart_vif.dtr_n <= 1'b1;
    end
endtask

task uart_host_driver::send(ref uart_trans tr);
    `uvm_info(get_type_name(), $sformatf("In send() :\n%s", tr.convert2string()), UVM_MEDIUM)

    repeat (cfg.half_cnt) @(uart_vif.mst_cb);
    for(int n=0; n<tr.byte_array.size(); n++) begin
        if(cfg.auto_flow_ctrl) begin
            wait(uart_vif.cts_n==0);
            @(uart_vif.mst_cb) uart_vif.mst_cb.sout_data <= 1'b0;
        end
        // Send start bit
        uart_vif.mst_cb.sout_data <= 1'b0;
        repeat (cfg.baud_cnt) @(uart_vif.mst_cb);

        for(int i=0; i<cfg.data_len; i++) begin
            uart_vif.mst_cb.sout_data <= tr.byte_array[n][i];
            repeat (cfg.baud_cnt) @(uart_vif.mst_cb);
        end

        // Send parity bit
        if(cfg.parity_en) begin
            uart_vif.mst_cb.sout_data <= get_parity(n, tr);
            repeat (cfg.baud_cnt) @(uart_vif.mst_cb);
        end

        // Send stop bit
        uart_vif.mst_cb.sout_data <= 1'b1;
        repeat (cfg.baud_cnt*cfg.stop_len) @(uart_vif.mst_cb);
        //`uvm_info(tr.get_name(), $sformatf("[H -> D] SOUT_DATA = %2h", tr.byte_array[n]), UVM_MEDIUM)
    end

    `uvm_info(get_type_name(), $sformatf("In send() : end"), UVM_MEDIUM)
endtask

function bit uart_host_driver::get_parity(int n, ref uart_trans tr);
    bit [7:0] data = tr.byte_array[n];
    get_parity = ^{data, ~cfg.even_parity};
    if(tr.strb_array[n]==0) begin //insert parity error, using strb_array to indicate it
        get_parity = ~get_parity;
    end
endfunction

task uart_host_driver::read(ref uart_trans tr);
    `uvm_info(get_type_name(), $sformatf("In read() :\n%s", tr.convert2string()), UVM_MEDIUM)
    for(int n=0; n<tr.byte_array.size(); n++) begin
        wait(received_data_fifo.size()!=0);
        tr.byte_array[n] = received_data_fifo.pop_front();
        //`uvm_info(tr.get_name(), $sformatf("[H <- D] SIN_DATA = %2h", tr.byte_array[n]), UVM_MEDIUM)
    end
    `uvm_info(get_type_name(), $sformatf("In read() : end"), UVM_MEDIUM)
endtask

task uart_host_driver::auto_flow_ctrl();
    forever begin
        if(cfg.auto_flow_ctrl) begin
            if(received_data_fifo.size()==0) begin
                uart_vif.mst_cb.rts_n <= 1'b0;
            end
            else if(received_data_fifo.size()>=(cfg.rcv_threshold-1)) begin
                uart_vif.mst_cb.rts_n <= 1'b1;
            end
        end
        @(uart_vif.mst_cb);
    end
endtask

task uart_host_driver::receive();
    uart_trans  tr;
    bit start_bit_found;
    bit stop_bit_found;
    bit [7:0] rdata;

    forever begin
        //wait start bit
        do begin
            start_bit_found = 1;
            wait(uart_vif.sin_data==0);
            `uvm_info(get_type_name(), $sformatf("Start Bit begins..."), UVM_MEDIUM)
            repeat (cfg.baud_cnt) begin
                @(uart_vif.mst_cb);
                if(uart_vif.mst_cb.sin_data==1) begin
                    start_bit_found = 0;
                    `uvm_info(get_type_name(), $sformatf("Start Bit is aborted, mst_cb.sin_data=%1b", uart_vif.mst_cb.sin_data), UVM_MEDIUM)
                    break;
                end
            end
        end while(!start_bit_found);
        `uvm_info(get_type_name(), $sformatf("Start Bit is detected"), UVM_MEDIUM)

        //receive data bit
        repeat (cfg.half_cnt) @(uart_vif.mst_cb);
        for (int i=0; i<cfg.data_len; i++) begin
            rdata[i] = uart_vif.sin_data;
            `uvm_info(get_type_name(), $sformatf("Receive BIT%0d=%1b", i, rdata[i]), UVM_MEDIUM)
            if(i<cfg.data_len-1) repeat (cfg.baud_cnt) @(uart_vif.mst_cb);
            else    repeat (cfg.baud_cnt-cfg.half_cnt) @(uart_vif.mst_cb);
        end

        if(cfg.parity_en) begin
            repeat (cfg.baud_cnt) @(uart_vif.mst_cb);
        end

        //wait stop bit
        stop_bit_found = 1;
        `uvm_info(get_type_name(), $sformatf("Stop Bit begins"), UVM_MEDIUM)
        repeat (cfg.baud_cnt*cfg.stop_len) begin
            @(uart_vif.mst_cb);
            if(uart_vif.mst_cb.sin_data==0) begin
                stop_bit_found = 0;
                //`uvm_error(get_name(), "Stop bit not received properly")
                break;
            end
        end
        if(stop_bit_found) begin
            received_data_fifo.push_back(rdata);
            `uvm_info(get_type_name(), $sformatf("Stop Bit is detected"), UVM_MEDIUM)
            `uvm_info(get_type_name(), $sformatf("Host received data = %2h", rdata), UVM_MEDIUM)
        end
    end
endtask
`endif

