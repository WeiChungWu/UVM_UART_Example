module dut_wrapper();

    reg clk;
    reg rstn;

    reg siu_clkg;

    wire        uart_intr;
    wire [13:0] uart_debug_mon;

    // -------------------------------
    // Clocks and Resets
    // -------------------------------
    initial begin
        // init
        clk  = 0;
        rstn = 0;
        siu_clkg = 0;
        #100ns;
        rstn = 1;
    end

    always #(clk_period/2) clk <= ~clk;
    always #(sclk_period/2) siu_clkg <= ~siu_clkg;

    uart_interface uart_if(.clk(siu_clkg), .rst_(rstn));
    cpu_intr_interface cpu_intr_if(.clk(clk), .sclk(siu_clkg));

    assign cpu_intr_if.interrupt = uart_intr;

    // ----------------------------------------------------------------
    // UART DUT
    // ----------------------------------------------------------------

    uart_top uart_top (
        .HCLK                   (),
        .HRESETn                (),
        .HTRANS                 (),
        .HADDR                  (),
        .HWRITE                 (),
        .HSIZE                  (),
        .HBURST                 (),
        .HWDATA                 (),
        .HSEL                   (),
        .AHB_HREADY             (),
        .HREADY                 (),
        .HRESP                  (),
        .HRDATA                 (),
        .apbclk                 (),
        .clk                    (),
        .rst_                   (),
        .sclk                   (siu_clkg),
        .siu_rst_               (rstn),
        .siu_cfg_rst_           (rstn),
        .inst_sin               (uart_if.sout_data),
        .inst_cts_n             (uart_if.rts_n),
        .inst_dsr_n             (uart_if.dtr_n),
        .inst_dcd_n             (1'b1),
        .inst_ri_n              (1'b1),
        .intr_inst              (uart_intr),
        .sout_inst              (uart_if.sin_data),
        .dtr_n_inst             (uart_if.dsr_n),
        .rts_n_inst             (uart_if.cts_n)
    );

endmodule
