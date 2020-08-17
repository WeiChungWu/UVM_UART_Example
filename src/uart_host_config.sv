//----------------------------------------------------------------------------
//  File Name   : uart_host_config.sv
//  Date        : 8/14/2020
//  Author(s)   : WeiChung Wu (exelion04 at gmail.com)
//  Description : 
//----------------------------------------------------------------------------

`ifndef UART_HOST_CONFIG_SV
`define UART_HOST_CONFIG_SV

class uart_host_config extends uvm_object;
    int id;
    uvm_sequencer_base m_sequencer;     //sequencer in current agent
    virtual uart_interface uart_vif;
    int baud_cnt = 16;
    int half_cnt = 8;
    rand int data_len;           //refer LCR[1:0]
    rand int stop_len;           //refer LCR[2]
    rand bit parity_en;          //refer LCR[3]
    rand bit even_parity;        //refer LCR[4]
    rand bit auto_flow_ctrl;     //refer MCR[5]
    rand int rcv_threshold;      //refer FCR[7:6]

    `uvm_object_utils_begin(uart_host_config)
        `uvm_field_int(id, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(baud_cnt, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(data_len, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(stop_len, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(parity_en, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(even_parity, UVM_ALL_ON|UVM_NOPACK)
        `uvm_field_int(auto_flow_ctrl, UVM_ALL_ON|UVM_NOPACK)
    `uvm_object_utils_end

    function new(string name = "uart_host_config");
        super.new(name);
        half_cnt = baud_cnt/2;
    endfunction : new

    constraint con_data_len {
        data_len inside {[5:8]};
        soft data_len == 8;
    }
    constraint con_stop_len {
        stop_len inside {1,2};
        soft stop_len == 1;
    }
    constraint con_parity_en {
        soft parity_en == 1;
    }
    constraint con_even_parity {
        soft even_parity == 0;
    }
    constraint con_auto_flow_ctrl {
        soft auto_flow_ctrl == 0;
    }
    constraint con_rcv_threshold {
        soft rcv_threshold == 256;
    }

    virtual function void set_sequencer(uvm_sequencer_base seqr);
        m_sequencer = seqr;
    endfunction : set_sequencer

    virtual function uvm_sequencer_base get_sequencer();
        return m_sequencer;
    endfunction : get_sequencer

    virtual function string convert2string();
        string qs[$];
        qs.push_back($sformatf("UART_HOST_CONFIG (type: %0s)\n", get_type_name()));
        qs.push_back($sformatf("  data_len       = %0d\n", data_len));
        qs.push_back($sformatf("  stop_len       = %0d\n", stop_len));
        qs.push_back($sformatf("  parity_en      = %0d\n", parity_en));
        qs.push_back($sformatf("  even_parity    = %0d\n", even_parity));
        qs.push_back($sformatf("  auto_flow_ctrl = %0d\n", auto_flow_ctrl));
        qs.push_back($sformatf("  rcv_threshold  = %0d\n", rcv_threshold));
        return `UVM_STRING_QUEUE_STREAMING_PACK(qs);
    endfunction
endclass : uart_host_config
`endif
