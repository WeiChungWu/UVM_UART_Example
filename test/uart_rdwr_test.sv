`ifndef UART_RDWR_TEST_SV
`define UART_RDWR_TEST_SV

class uart_rdwr_sequence extends uart_host_base_sequence;
    bit [7:0] tx_data[];
    bit [7:0] rx_data[];
    `uvm_object_utils(uart_rdwr_sequence)
    function new(string name = "uart_rdwr_sequence");
        super.new(name);
    endfunction : new

    virtual task body();
        bit [7:0] rdata;
        for(int i=0; i<tx_data.size(); i++) begin
            write8(32'h0, tx_data[i]);
        end
        for(int i=0; i<rx_data.size(); i++) begin
            read8(32'h0, rdata);
            `uvm_info(get_name(), $sformatf("[Host] received data = %2h", rdata), UVM_MEDIUM)
            if(rdata!==rx_data[i]) begin
                `uvm_error(get_name(), $sformatf("Host Read Mismatch: exp=%0x rcv=%0x", rx_data[i], rdata))
            end
        end
    endtask
endclass

class uart_fw_rdwr_init_sequence extends uart_fw_base_sequence;
    `uvm_object_utils(uart_fw_rdwr_init_sequence)
    function new(string name = "uart_fw_rdwr_init_sequence");
        super.new(name);
    endfunction : new

    virtual task body();
        siu_set_divisor();
        siu_set_data_length();
        siu_set_parity_en();
        siu_set_fifo_enable();
        uart_reg.dlh_ier.write(status, 8'h01, .parent(this));  // Enable Rx data available interrupt
    endtask
endclass

class uart_fw_rdwr_ctrl_sequence extends uart_fw_base_sequence;
    bit [7:0] tx_data[];
    bit [7:0] rx_data[];
    `uvm_object_utils(uart_fw_rdwr_ctrl_sequence)
    function new(string name = "uart_fw_rdwr_ctrl_sequence");
        super.new(name);
    endfunction : new

    virtual task body();
        uart_reg.lsr.read(status, rdata, .parent(this));
        //Fill TX FIFO
        for(int i=0; i<tx_data.size(); i++) begin
            uart_reg.rbr_thr_dll.write(status, tx_data[i], .parent(this));
        end

        uart_reg.lcr.read(status, rdata, .parent(this));

        `uvm_delay(500ns)
        //Read RX FIFO by polling status bit
        for(int i=0; i<rx_data.size(); i++) begin
            do begin
                uart_reg.lsr.read(status, rdata, .parent(this));
                idle(16);
            end while(rdata[0]==0);
            uart_reg.rbr_thr_dll.read(status, rdata, .parent(this));
            `uvm_info(get_name(), $sformatf("[UART] received data = %2h", rdata), UVM_MEDIUM)

            if(rdata!==rx_data[i]) begin
                `uvm_error(get_name(), $sformatf("UART Read Mismatch: exp=%0x rcv=%0x", rx_data[i], rdata))
            end
        end

        uart_reg.lsr.read(status, rdata, .parent(this));
    endtask
endclass

class uart_rdwr_test extends uart_base_test;
    uart_rdwr_sequence uart_rdwr_seq;
    uart_fw_rdwr_init_sequence uart_fw_init_seq;
    uart_fw_rdwr_ctrl_sequence uart_fw_ctrl_seq;
    bit [7:0] tx_data[];
    bit [7:0] rx_data[];

    `uvm_component_utils(uart_rdwr_test)

    function new (string name = "uart_rdwr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        uart_rdwr_seq = uart_rdwr_sequence::type_id::create("uart_rdwr_seq");
        uart_fw_init_seq = uart_fw_rdwr_init_sequence::type_id::create("uart_fw_init_seq");
        uart_fw_ctrl_seq = uart_fw_rdwr_ctrl_sequence::type_id::create("uart_fw_ctrl_seq");

        tx_data = new[17];
        rx_data = new[17];
        std::randomize(tx_data);
        std::randomize(rx_data);
        uart_rdwr_seq.tx_data = tx_data;
        uart_rdwr_seq.rx_data = rx_data;
        uart_fw_ctrl_seq.tx_data = rx_data;
        uart_fw_ctrl_seq.rx_data = tx_data;

        `uvm_info(get_name(), $sformatf("Print config:\n%s", uarttb.uart_host_cfg.convert2string()), UVM_MEDIUM)
        uart_fw_init_seq.start(uarttb.ahb_mst[0].sequencer);
        fork
        uart_rdwr_seq.start(uarttb.uart_host.sequencer);
        uart_fw_ctrl_seq.start(uarttb.ahb_mst[0].sequencer);
        join

        phase.drop_objection(this);
    endtask : main_phase
endclass : uart_rdwr_test
`endif
