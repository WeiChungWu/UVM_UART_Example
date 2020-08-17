//----------------------------------------------------------------------------
//  File Name   : uart_host_sequence.sv
//  Date        : 8/14/2020
//  Author(s)   : WeiChung Wu (exelion04 at gmail.com)
//  Description : 
//----------------------------------------------------------------------------

`ifndef UART_HOST_SEQUENCE_SV
`define UART_HOST_SEQUENCE_SV

class uart_host_base_sequence extends uvm_sequence#(uart_trans);
    `uvm_object_utils(uart_host_base_sequence)

    local uart_trans tr;     //reuse the constraint solver

    function new(string name = "uart_host_base_sequence");
        super.new(name);
        tr = uart_trans::type_id::create(get_name(),,get_full_name());
    endfunction : new

    virtual function void set_name (string name);
        super.set_name(name);
        tr.set_name(name);
    endfunction

    virtual task body();
    endtask : body

    virtual task pre_start();
        `uvm_info(get_name(), $sformatf("Entering : %0s", get_sequence_path()), UVM_MEDIUM)
    endtask

    virtual task post_start();
        `uvm_info(get_name(), $sformatf("Exiting : %0s", get_sequence_path()), UVM_MEDIUM)
    endtask

    virtual task writeburst(input bit [63:0] addr, input uvm_bitstream_t data,
                            input int length,      input int data_width);
        bit success;
        uart_trans req, rsp;
        // randomize item
        success = tr.randomize() with {addr         == local::addr;
                                       data         == 0;
                                       data_width   == local::data_width;
                                       direction    == UART_WRITE;
                                       burst_length == local::length;
                                       id           == 0;};
        if(!success) `uvm_error(get_name(), {tr.get_type_name()," Randomized failed!"})
        $cast(req, tr.clone());
        req.pack_bytestream(data);
        start_item(req);
        finish_item(req);
        get_response(rsp, req.get_transaction_id());
    endtask

    virtual task readburst(input logic [63:0] addr, output uvm_bitstream_t data,
                           input int length,        input int data_width);
        bit success;
        uart_trans req, rsp;
        // randomize item
        success = tr.randomize() with {addr         == local::addr;
                                       data         == 0;
                                       data_width   == local::data_width;
                                       direction    == UART_READ;
                                       burst_length == local::length;
                                       id           == 0;};
        if(!success) `uvm_error(get_name(), {tr.get_type_name()," Randomized failed!"})
        $cast(req, tr.clone());
        start_item(req);
        finish_item(req);
        get_response(rsp, req.get_transaction_id());
        data = rsp.unpack_bytestream();
    endtask

    virtual task writereg(input logic [63:0] addr, input logic [127:0] data, input int data_width);
        this.writeburst(addr, data, 1, data_width);
    endtask

    virtual task readreg(input logic [63:0] addr, output logic [127:0] data, input int data_width);
        this.readburst(addr, data, 1, data_width);
    endtask

    virtual task write8(input logic [31:0] addr, input logic [7:0] data);
        this.writereg({32'h0,addr}, data, DATA_WIDTH_8BIT);
    endtask

    virtual task read8(input logic [31:0] addr, output logic [7:0] data);
        this.readreg({32'h0,addr}, data, DATA_WIDTH_8BIT);
    endtask

    virtual task write16(input logic [31:0] addr, input logic [15:0] data);
        this.writereg({32'h0,addr}, data, DATA_WIDTH_16BIT);
    endtask

    virtual task read16(input logic [31:0] addr, output logic [15:0] data);
        this.readreg({32'h0,addr}, data, DATA_WIDTH_16BIT);
    endtask

    virtual task write32(input logic [31:0] addr, input logic [31:0] data);
        this.writereg({32'h0,addr}, data, DATA_WIDTH_32BIT);
    endtask

    virtual task read32(input logic [31:0] addr, output logic [31:0] data);
        this.readreg({32'h0,addr}, data, DATA_WIDTH_32BIT);
    endtask
endclass
`endif
