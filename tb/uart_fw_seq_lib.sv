`ifndef UART_FW_SEQ_LIB_SV
`define UART_FW_SEQ_LIB_SV

class uart_fw_base_sequence extends cpu_rw_sequence;
    ral_block_uart uart_reg;
    virtual cpu_intr_interface cpu_intr_vif;
    uvm_status_e status;
    uvm_reg_data_t data, rdata;

    bit [7:0] fcr_wdata = 8'hF7;
    bit [7:0] ier_wdata = 8'h0F;

    `uvm_object_utils(uart_fw_base_sequence)

    function new(string name = "uart_fw_base_sequence");
        super.new(name);
    endfunction : new

    virtual task pre_start();
        uvm_object obj;
        super.pre_start();
        if (!uvm_config_object::get(get_sequencer(), "", "ral_uart_reg", obj)) begin
            `uvm_fatal(get_name(), $sformatf("Can't get uart ral_model"))
        end
        void'($cast(uart_reg, obj));
    endtask

    virtual task write8(input logic [31:0] addr, input logic [7:0] data);
        this.writereg({32'h0,addr}, data, DATA_WIDTH_8BIT);
    endtask

    virtual task read8(input logic [31:0] addr, output logic [7:0] data);
        this.readreg({32'h0,addr}, data, DATA_WIDTH_8BIT);
    endtask

    virtual task read8_cmp(input logic [31:0] addr, input logic [7:0] data);
        logic [7:0] rdata;
        read8(addr, rdata);
        if(rdata!==data) begin
            `uvm_error(get_name(), $sformatf("Read Mismatch: exp=%0x rcv=%0x", data, rdata))
        end
    endtask

    virtual task write16(input logic [31:0] addr, input logic [15:0] data);
        this.writereg({32'h0,addr}, data, DATA_WIDTH_16BIT);
    endtask

    virtual task read16(input logic [31:0] addr, output logic [15:0] data);
        this.readreg({32'h0,addr}, data, DATA_WIDTH_16BIT);
    endtask

    virtual task write32(input logic [31:0] addr, input logic [31:0] data);
        this.writereg({32'h0,addr}, data, DATA_WIDTH_16BIT);
    endtask

    virtual task read32(input logic [31:0] addr, output logic [31:0] data);
        this.readreg({32'h0,addr}, data, DATA_WIDTH_16BIT);
    endtask

    virtual task isr();
        siu_isr();
    endtask

    virtual task siu_isr();
        `uvm_info(get_name(), $sformatf("UART interrupt asserted"), UVM_MEDIUM)
        uart_reg.iir_fcr.read(status, rdata, .parent(this));
        case(rdata[3:0])
            4'b0000 : begin
                `uvm_info(get_name(), $sformatf("Modem status"), UVM_MEDIUM)
                uart_reg.msr.read(status, rdata, .parent(this));
            end
            4'b0010 : begin
                `uvm_info(get_name(), $sformatf("Transmit holding register empty"), UVM_MEDIUM)
            end
            4'b0100 : begin
                `uvm_info(get_name(), $sformatf("Received data available"), UVM_MEDIUM)
            end
            4'b0110 : begin
                `uvm_info(get_name(), $sformatf("Received line status"), UVM_MEDIUM)
                uart_reg.lsr.read(status, rdata, .parent(this));
            end
            4'b0111 : begin
                `uvm_info(get_name(), $sformatf("Bust detect indication"), UVM_MEDIUM)
                uart_reg.usr.read(status, rdata, .parent(this));
            end
            4'b1100 : begin
                `uvm_info(get_name(), $sformatf("Character timeout indication"), UVM_MEDIUM)
            end
            default : begin
                `uvm_info(get_name(), $sformatf("No interrupt pending"), UVM_MEDIUM)
            end
        endcase
    endtask

    virtual task idle(int count);
        cpu_intr_vif.idle_sclk(count);
    endtask

    virtual task wait4Intr();
        wait(cpu_intr_vif.mon_cb.interrupt==1);
        isr();
        idle(16);
    endtask

    //UART subroutines
    virtual task siu_set_data_length(int bit_num=8);
        bit [1:0] dls;
        case(bit_num)
            5: dls = 2'b00;
            6: dls = 2'b01;
            7: dls = 2'b10;
            8: dls = 2'b11;
            default: dls = 2'b11;
        endcase
        reg8_rmw(uart_reg.lcr.wls, dls);
    endtask

    virtual task siu_set_parity_en(bit even_parity=0);
        reg8_rmw(uart_reg.lcr.par_sel, even_parity);
        reg8_rmw(uart_reg.lcr.par_en, 1'b1);
    endtask

    virtual task siu_set_divisor();
        reg8_rmw(uart_reg.lcr.div_latch_rd_wrt, 1'b1);
        uart_reg.dlh_ier.write(status, 8'h00, .parent(this));
        uart_reg.rbr_thr_dll.write(status, 8'h01, .parent(this));
        reg8_rmw(uart_reg.lcr.div_latch_rd_wrt, 1'b0);
    endtask

    virtual task siu_set_fifo_enable();
        uart_reg.iir_fcr.read(status, rdata, .parent(this));
        uart_reg.iir_fcr.write(status, {rdata[7:4],4'h7}, .parent(this));
    endtask

    virtual task siu_set_rcvr_trigger(bit [1:0] trig_lvl);
        fcr_wdata[7:6] = trig_lvl;
        uart_reg.iir_fcr.write(status, fcr_wdata, .parent(this));
    endtask

    virtual task siu_set_tx_empty_trigger(bit [1:0] trig_lvl);
        fcr_wdata[5:4] = trig_lvl;
        uart_reg.iir_fcr.write(status, fcr_wdata, .parent(this));
    endtask
endclass
`endif
