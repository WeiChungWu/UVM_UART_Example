//----------------------------------------------------------------------------
//  File Name   : uart_host_sequencer.sv
//  Date        : 8/14/2020
//  Author(s)   : WeiChung Wu (exelion04 at gmail.com)
//  Description : 
//----------------------------------------------------------------------------

`ifndef UART_HOST_SCORE_BOARD_SV
`define UART_HOST_SCORE_BOARD_SV

`uvm_analysis_imp_decl(_exp_tx_in)
`uvm_analysis_imp_decl(_act_tx_in)
`uvm_analysis_imp_decl(_exp_rx_in)
`uvm_analysis_imp_decl(_act_rx_in)

class uart_serial_data extends uvm_object;
    logic [7:0] data;
    bit         parity_err;
    bit         frame_err;
    `uvm_object_utils_begin(uart_serial_data)
        `uvm_field_int      (data,UVM_DEFAULT)
    `uvm_object_utils_end
    function new (string name="uart_serial_data");
        super.new(name);
    endfunction : new
    virtual function string convert2string();
        convert2string = $sformatf("data = %2h", data);
    endfunction : convert2string
endclass: uart_serial_data

class uart_sb_cmd extends uvm_object;
    uart_trans tx_data[$];
    uart_trans rx_data[$];
    `uvm_object_utils_begin(uart_sb_cmd)
    `uvm_object_utils_end

    function new (string name="UART_SB_OP");
        super.new(name);
    endfunction : new

    virtual function void insert_tx_data(bit [7:0] data_in[]);
        foreach(data_in[i]) begin
            tx_data.push_back(transform(data_in[i],0));
        end
        execute(get_name());
    endfunction : insert_tx_data

    virtual function void insert_rx_data(bit [7:0] data_in[]);
        foreach(data_in[i]) begin
            rx_data.push_back(transform(data_in[i],1));
        end
        execute(get_name());
    endfunction : insert_rx_data

    virtual function uart_trans transform(bit [7:0] data, bit dir=1);
        uart_trans pkt = uart_trans::type_id::create("uart_sb_cmd");
        pkt.addr = 64'h0;
        pkt.data_width = DATA_WIDTH_8BIT;
        pkt.burst_length = 1;
        pkt.direction = dir ? UART_READ : UART_WRITE;
        pkt.byte_array = new[1];
        pkt.byte_array[0] = data;
        pkt.data = pkt.unpack_bytestream();
        return pkt;
    endfunction

    virtual function string convert2string();
    endfunction : convert2string

    virtual function void execute(string ev_name);
        uvm_event_pool ep = uvm_event_pool::get_global_pool();
        uvm_event e;
        if(!ep.exists(ev_name)) `uvm_error(get_type_name(), $sformatf("uart_sb_cmd event:%s does not exist!", ev_name))
        else begin e = uvm_event_pool::get_global(ev_name); e.trigger(this); end
    endfunction : execute
endclass: uart_sb_cmd

typedef class uart_host_scoreboard;
class uart_sb_subscriber#(type T=uvm_object) extends uvm_event_callback;
    protected T obs;
    function new(string name="");
        super.new(name);
    endfunction

    virtual function bit pre_trigger(uvm_event e, uvm_object data=null);
        this.obs.observe(e,data);
        return 0;
    endfunction

    virtual function void append_cb(T obs, uvm_event e);
        this.obs = obs;
        `ifdef UVM_VERSION
        uvm_event#()::cbs_type::add(e, this, UVM_APPEND);
        `elsif UVM_MAJOR_REV_1
        e.add_callback(this);
        `endif
    endfunction
endclass

class uart_host_scoreboard extends uvm_scoreboard;
    uvm_queue#(uart_serial_data) m_tx_queue;
    uvm_queue#(uart_serial_data) m_rx_queue;

    uvm_analysis_imp_exp_tx_in#(uart_trans, uart_host_scoreboard) exp_tx_in;
    uvm_analysis_imp_act_tx_in#(uart_trans, uart_host_scoreboard) act_tx_in;
    uvm_analysis_imp_exp_rx_in#(uart_trans, uart_host_scoreboard) exp_rx_in;
    uvm_analysis_imp_act_rx_in#(uart_trans, uart_host_scoreboard) act_rx_in;

    `uvm_component_utils_begin(uart_host_scoreboard)
    `uvm_component_utils_end

    function new (string name = "uart_host_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        exp_tx_in = new("exp_tx_in", this);
        act_tx_in = new("act_tx_in", this);
        exp_rx_in = new("exp_rx_in", this);
        act_rx_in = new("act_rx_in", this);
        m_tx_queue = new();
        m_rx_queue = new();
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        event_cb_configure("UART_SB_OP");
    endfunction : build_phase

    virtual task post_main_phase(uvm_phase phase);
        super.post_main_phase(phase);
        check_orphan();
    endtask : post_main_phase

    virtual function void write_exp_tx_in(uvm_object exp_in);
        process_exp_in(exp_in, 0);
    endfunction : write_exp_tx_in

    virtual function void write_exp_rx_in(uvm_object exp_in);
        process_exp_in(exp_in, 1);
    endfunction : write_exp_rx_in

    virtual function void process_exp_in(uvm_object exp_in, bit dir=0);
        uart_trans exp_tmp;
        uart_serial_data exp_pkt;
        string msg = dir ? "RX" : "TX";
        uvm_queue#(uart_serial_data) m_queue = dir ? m_rx_queue : m_tx_queue;
        if ($cast(exp_tmp,exp_in)) begin
            exp_pkt = transform(exp_tmp);
            `uvm_info(get_type_name(), $sformatf("Insert %s Expected : [%0s]", msg, exp_pkt.convert2string()), UVM_MEDIUM)
            m_queue.push_back(exp_pkt);       
        end
    endfunction : process_exp_in

    virtual function void write_act_tx_in(uvm_object act_in);
        process_act_in(act_in, 0);
    endfunction : write_act_tx_in

    virtual function void write_act_rx_in(uvm_object act_in);
        process_act_in(act_in, 1);
    endfunction : write_act_rx_in

    virtual function void process_act_in(uvm_object act_in, bit dir=0);
        uart_trans act_tmp;
        uart_serial_data act_pkt, exp_pkt;
        string msg = dir ? "RX" : "TX";
        uvm_queue#(uart_serial_data) m_queue = dir ? m_rx_queue : m_tx_queue;
        if ($cast(act_tmp,act_in)) begin
            act_pkt = transform(act_tmp);
            if (m_queue.size()) begin
                // In order checking
                `uvm_info(get_type_name(), $sformatf("Compare %s Actual  : [%0s]", msg, act_pkt.convert2string()), UVM_MEDIUM)
                exp_pkt = m_queue.pop_front();
                if (!exp_pkt.compare(act_pkt)) begin
                    `uvm_error(get_type_name(), $sformatf("UART Scoreboard %s expected FAIL => Expected : [%0s], Actual : [%0s]", msg, exp_pkt.convert2string(), act_pkt.convert2string()))
                end
            end
            else begin
                `uvm_error(get_type_name(), $sformatf("FAIL: UART Scoreboard %s is Empty => Actual : [%0s]", msg, act_pkt.convert2string()))
            end
        end
    endfunction : process_act_in

    virtual function void check_orphan();
        if (m_tx_queue.size()) begin
            `uvm_error(get_type_name(), $sformatf("%0s HAS ORPHAN, number = %0d", get_name(), m_tx_queue.size()))
        end
        if (m_rx_queue.size()) begin
            `uvm_error(get_type_name(), $sformatf("%0s HAS ORPHAN, number = %0d", get_name(), m_rx_queue.size()))
        end
    endfunction

    virtual function uart_serial_data transform(uart_trans tr);
        uart_serial_data pkt = uart_serial_data::type_id::create("uart_sb");
        pkt.data = tr.byte_array[0];
        pkt.parity_err = 0;
        pkt.frame_err = 0;
        return pkt;
    endfunction

    virtual function void observe(uvm_event e, uvm_object data=null);
        uart_sb_cmd sb_cmd;
        void'($cast(sb_cmd, data));
        if(sb_cmd.tx_data.size()>0) begin
            foreach(sb_cmd.tx_data[i]) write_act_tx_in(sb_cmd.tx_data[i]);
        end
        if(sb_cmd.rx_data.size()>0) begin
            foreach(sb_cmd.rx_data[i]) write_exp_rx_in(sb_cmd.rx_data[i]);
        end
        sb_cmd.tx_data.delete();
        sb_cmd.rx_data.delete();
    endfunction: observe

    virtual function void event_cb_configure(string ev_name);
        uart_sb_subscriber#(uart_host_scoreboard) cb;
        uvm_event e = uvm_event_pool::get_global(ev_name);
        cb=new(ev_name);
        cb.append_cb(this, e);
    endfunction: event_cb_configure
endclass
`endif
