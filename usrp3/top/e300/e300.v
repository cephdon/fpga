//
// Copyright 2013-2014 Ettus Research
//

module e300
#(parameter STREAMS_WIDTH = 4,
  parameter CMDFIFO_DEPTH = 5,
  parameter CONFIG_BASE = 32'h4000_0000,
  parameter PAGE_WIDTH = 10)
(
  // ARM Connections
  inout [53:0]  MIO,
  input         PS_SRSTB,
  input         PS_CLK,
  input         PS_PORB,
  inout         DDR_Clk,
  inout         DDR_Clk_n,
  inout         DDR_CKE,
  inout         DDR_CS_n,
  inout         DDR_RAS_n,
  inout         DDR_CAS_n,
  inout         DDR_WEB,
  inout [2:0]   DDR_BankAddr,
  inout [14:0]  DDR_Addr,
  inout         DDR_ODT,
  inout         DDR_DRSTB,
  inout [31:0]  DDR_DQ,
  inout [3:0]   DDR_DM,
  inout [3:0]   DDR_DQS,
  inout [3:0]   DDR_DQS_n,
  inout         DDR_VRP,
  inout         DDR_VRN,

  // Control connections for FPGA
  //input wire SYSCLK_P;
  //input wire SYSCLK_N;
  //input wire PS_SRST_B;

  //AVR SPI IO
  output        AVR_CS_R,
  input         AVR_IRQ,
  input         AVR_MISO_R,
  output        AVR_MOSI_R,
  output        AVR_SCK_R,

  input         ONSWITCH_DB,

  // RF Board connections
  // Change to inout/output as
  // they are implemented/tested
  input [34:0]  DB_EXP_1_8V,

  //band selects
  output [2:0]  TX_BANDSEL,
  output [2:0]  RX1_BANDSEL,
  output [2:0]  RX2_BANDSEL,
  output [1:0]  RX2C_BANDSEL,
  output [1:0]  RX1B_BANDSEL,
  output [1:0]  RX1C_BANDSEL,
  output [1:0]  RX2B_BANDSEL,

  //enables
  output        TX_ENABLE1A,
  output        TX_ENABLE2A,
  output        TX_ENABLE1B,
  output        TX_ENABLE2B,

  //antenna selects
  output        VCTXRX1_V1,
  output        VCTXRX1_V2,
  output        VCTXRX2_V1,
  output        VCTXRX2_V2,
  output        VCRX1_V1,
  output        VCRX1_V2,
  output        VCRX2_V1,
  output        VCRX2_V2,

  // leds
  output        LED_TXRX1_TX,
  output        LED_TXRX1_RX,
  output        LED_RX1_RX,
  output        LED_TXRX2_TX,
  output        LED_TXRX2_RX,
  output        LED_RX2_RX,

  // ad9361 connections
  input [7:0]   CAT_CTRL_OUT,
  output [3:0]  CAT_CTRL_IN,
  output        CAT_RESET,  // Really CAT_RESET_B, active low
  output        CAT_CS,
  output        CAT_SCLK,
  output        CAT_MOSI,
  input         CAT_MISO,
  input         CAT_BBCLK_OUT, //unused
  output        CAT_SYNC,
  output        CAT_TXNRX,
  output        CAT_ENABLE,
  output        CAT_ENAGC,
  input         CAT_RX_FRAME,
  input         CAT_DATA_CLK,
  output        CAT_TX_FRAME,
  output        CAT_FB_CLK,
  input [11:0]  CAT_P0_D,
  output [11:0] CAT_P1_D,

  // pps connections
  input         GPS_PPS,
  input         PPS_EXT_IN,

  // VTCXO and the DAC that feeds it
  output        TCXO_DAC_SYNCn,
  output        TCXO_DAC_SCLK,
  output        TCXO_DAC_SDIN,
  input         TCXO_CLK,

  // gpios, change to inout somehow
  inout [5:0]   PL_GPIO
);

  // Internal connections to PS
  //   GP0 -- General Purpose port 0, FPGA is the slave
  wire [31:0] GP0_M_AXI_AWADDR;
  wire        GP0_M_AXI_AWVALID;
  wire        GP0_M_AXI_AWREADY;
  wire [31:0] GP0_M_AXI_WDATA;
  wire [3:0]  GP0_M_AXI_WSTRB;
  wire        GP0_M_AXI_WVALID;
  wire        GP0_M_AXI_WREADY;
  wire [1:0]  GP0_M_AXI_BRESP;
  wire        GP0_M_AXI_BVALID;
  wire        GP0_M_AXI_BREADY;
  wire [31:0] GP0_M_AXI_ARADDR;
  wire        GP0_M_AXI_ARVALID;
  wire        GP0_M_AXI_ARREADY;
  wire [31:0] GP0_M_AXI_RDATA;
  wire [1:0]  GP0_M_AXI_RRESP;
  wire        GP0_M_AXI_RVALID;
  wire        GP0_M_AXI_RREADY;
  //   HP0 -- High Performance port 0, FPGA is the master
  wire [5:0]  HP0_S_AXI_AWID;
  wire [31:0] HP0_S_AXI_AWADDR;
  wire [2:0]  HP0_S_AXI_AWPROT;
  wire        HP0_S_AXI_AWVALID;
  wire        HP0_S_AXI_AWREADY;
  wire [63:0] HP0_S_AXI_WDATA;
  wire [7:0]  HP0_S_AXI_WSTRB;
  wire        HP0_S_AXI_WVALID;
  wire        HP0_S_AXI_WREADY;
  wire [1:0]  HP0_S_AXI_BRESP;
  wire        HP0_S_AXI_BVALID;
  wire        HP0_S_AXI_BREADY;
  wire [5:0]  HP0_S_AXI_ARID;
  wire [31:0] HP0_S_AXI_ARADDR;
  wire [2:0]  HP0_S_AXI_ARPROT;
  wire        HP0_S_AXI_ARVALID;
  wire        HP0_S_AXI_ARREADY;
  wire [63:0] HP0_S_AXI_RDATA;
  wire [1:0]  HP0_S_AXI_RRESP;
  wire        HP0_S_AXI_RVALID;
  wire        HP0_S_AXI_RREADY;
  wire [3:0]  HP0_S_AXI_ARCACHE;
  wire [7:0]  HP0_S_AXI_AWLEN;
  wire [2:0]  HP0_S_AXI_AWSIZE;
  wire [1:0]  HP0_S_AXI_AWBURST;
  wire [3:0]  HP0_S_AXI_AWCACHE;
  wire        HP0_S_AXI_WLAST;
  wire [7:0]  HP0_S_AXI_ARLEN;
  wire [1:0]  HP0_S_AXI_ARBURST;
  wire [2:0]  HP0_S_AXI_ARSIZE;

  wire        fclk_clk0;
  wire        fclk_reset0;

  wire        bus_clk, radio_clk;
  wire        bus_rst, radio_rst;

  wire [31:0] ps_gpio_out;
  wire [31:0] ps_gpio_in;

  wire        stream_irq;

  wire [63:0] h2s_tdata;
  wire        h2s_tvalid;
  wire        h2s_tready;
  wire        h2s_tlast;

  wire [63:0] s2h_tdata;
  wire        s2h_tvalid;
  wire        s2h_tready;
  wire        s2h_tlast;

  // register the debounced onswitch signal to detect edges,
  // Note: ONSWITCH_DB is low active
  reg [1:0] onswitch_edge;
  always @ (posedge bus_clk)
    onswitch_edge <= bus_rst ? 2'b00 : {onswitch_edge[0], ONSWITCH_DB};

  wire button_press = ~ONSWITCH_DB & onswitch_edge[0] & onswitch_edge[1];
  wire button_release = ONSWITCH_DB & ~onswitch_edge[0] & ~onswitch_edge[1];

  // stretch the pulse so IRQs don't get lost
  reg [7:0] button_press_reg, button_release_reg;
  always @ (posedge bus_clk)
    if (bus_rst) begin
      button_press_reg <= 8'h00;
      button_release_reg <= 8'h00;
    end else begin
      button_press_reg <= {button_press_reg[6:0], button_press};
      button_release_reg <= {button_release_reg[6:0], button_release};
    end

  wire button_press_irq = |button_press_reg;
  wire button_release_irq = |button_release_reg;

  e300_processing_system inst_e300_processing_system
  (  // Outward connections to the pins
    .MIO(MIO),
    .PS_SRSTB(PS_SRSTB),
    .PS_CLK(PS_CLK),
    .PS_PORB(PS_PORB),
    .DDR_Clk(DDR_Clk),
    .DDR_Clk_n(DDR_Clk_n),
    .DDR_CKE(DDR_CKE),
    .DDR_CS_n(DDR_CS_n),
    .DDR_RAS_n(DDR_RAS_n),
    .DDR_CAS_n(DDR_CAS_n),
    .DDR_WEB(DDR_WEB),
    .DDR_BankAddr(DDR_BankAddr),
    .DDR_Addr(DDR_Addr),
    .DDR_ODT(DDR_ODT),
    .DDR_DRSTB(DDR_DRSTB),
    .DDR_DQ(DDR_DQ),
    .DDR_DM(DDR_DM),
    .DDR_DQS(DDR_DQS),
    .DDR_DQS_n(DDR_DQS_n),
    .DDR_VRN(DDR_VRN),
    .DDR_VRP(DDR_VRP),

    // Inward connections to our logic
    //    GP0  --  General Purpose Slave 0
    .M_AXI_GP0_AWADDR(GP0_M_AXI_AWADDR),
    .M_AXI_GP0_AWVALID(GP0_M_AXI_AWVALID),
    .M_AXI_GP0_AWREADY(GP0_M_AXI_AWREADY),
    .M_AXI_GP0_WDATA(GP0_M_AXI_WDATA),
    .M_AXI_GP0_WSTRB(GP0_M_AXI_WSTRB),
    .M_AXI_GP0_WVALID(GP0_M_AXI_WVALID),
    .M_AXI_GP0_WREADY(GP0_M_AXI_WREADY),
    .M_AXI_GP0_BRESP(GP0_M_AXI_BRESP),
    .M_AXI_GP0_BVALID(GP0_M_AXI_BVALID),
    .M_AXI_GP0_BREADY(GP0_M_AXI_BREADY),
    .M_AXI_GP0_ARADDR(GP0_M_AXI_ARADDR),
    .M_AXI_GP0_ARVALID(GP0_M_AXI_ARVALID),
    .M_AXI_GP0_ARREADY(GP0_M_AXI_ARREADY),
    .M_AXI_GP0_RDATA(GP0_M_AXI_RDATA),
    .M_AXI_GP0_RRESP(GP0_M_AXI_RRESP),
    .M_AXI_GP0_RVALID(GP0_M_AXI_RVALID),
    .M_AXI_GP0_RREADY(GP0_M_AXI_RREADY),

    //    Misc interrupts, GPIO, clk
    .IRQ_F2P({13'h0, button_release_irq, button_press_irq, stream_irq}),
    .GPIO_I(ps_gpio_in),
    .GPIO_O(ps_gpio_out),
    .FCLK_CLK0(fclk_clk0),
    .FCLK_RESET0(fclk_reset0),

    //    HP0  --  High Performance Master 0
    .S_AXI_HP0_AWID(HP0_S_AXI_AWID),
    .S_AXI_HP0_AWADDR(HP0_S_AXI_AWADDR),
    .S_AXI_HP0_AWPROT(HP0_S_AXI_AWPROT),
    .S_AXI_HP0_AWVALID(HP0_S_AXI_AWVALID),
    .S_AXI_HP0_AWREADY(HP0_S_AXI_AWREADY),
    .S_AXI_HP0_WDATA(HP0_S_AXI_WDATA),
    .S_AXI_HP0_WSTRB(HP0_S_AXI_WSTRB),
    .S_AXI_HP0_WVALID(HP0_S_AXI_WVALID),
    .S_AXI_HP0_WREADY(HP0_S_AXI_WREADY),
    .S_AXI_HP0_BRESP(HP0_S_AXI_BRESP),
    .S_AXI_HP0_BVALID(HP0_S_AXI_BVALID),
    .S_AXI_HP0_BREADY(HP0_S_AXI_BREADY),
    .S_AXI_HP0_ARID(HP0_S_AXI_ARID),
    .S_AXI_HP0_ARADDR(HP0_S_AXI_ARADDR),
    .S_AXI_HP0_ARPROT(HP0_S_AXI_ARPROT),
    .S_AXI_HP0_ARVALID(HP0_S_AXI_ARVALID),
    .S_AXI_HP0_ARREADY(HP0_S_AXI_ARREADY),
    .S_AXI_HP0_RDATA(HP0_S_AXI_RDATA),
    .S_AXI_HP0_RRESP(HP0_S_AXI_RRESP),
    .S_AXI_HP0_RVALID(HP0_S_AXI_RVALID),
    .S_AXI_HP0_RREADY(HP0_S_AXI_RREADY),
    .S_AXI_HP0_AWLEN(HP0_S_AXI_AWLEN),
    .S_AXI_HP0_RLAST(HP0_S_AXI_RLAST),
    .S_AXI_HP0_ARCACHE(HP0_S_AXI_ARCACHE),
    .S_AXI_HP0_AWSIZE(HP0_S_AXI_AWSIZE),
    .S_AXI_HP0_AWBURST(HP0_S_AXI_AWBURST),
    .S_AXI_HP0_AWCACHE(HP0_S_AXI_AWCACHE),
    .S_AXI_HP0_WLAST(HP0_S_AXI_WLAST),
    .S_AXI_HP0_ARLEN(HP0_S_AXI_ARLEN),
    .S_AXI_HP0_ARBURST(HP0_S_AXI_ARBURST),
    .S_AXI_HP0_ARSIZE(HP0_S_AXI_ARSIZE),

    //    SPI Core 0 - To AD9361
    .SPI0_SS(),
    .SPI0_SS1(CAT_CS),
    .SPI0_SS2(),
    .SPI0_SCLK(CAT_SCLK),
    .SPI0_MOSI(CAT_MOSI),
    .SPI0_MISO(CAT_MISO),

    //    SPI Core 1 - To AVR
    .SPI1_SS(),
    .SPI1_SS1(AVR_CS_R),
    .SPI1_SS2(),
    .SPI1_SCLK(AVR_SCK_R),
    .SPI1_MOSI(AVR_MOSI_R),
    .SPI1_MISO(AVR_MISO_R)
  );

  //------------------------------------------------------------------
  //-- generate clock and reset signals
  //------------------------------------------------------------------

  reset_sync radio_rst_sync
  (
    .clk(radio_clk),
    .reset_in(bus_rst | codec_arst),
    .reset_out(radio_rst)
  );

  assign bus_clk = fclk_clk0;
  assign bus_rst = fclk_reset0;

  //------------------------------------------------------------------
  // CODEC capture/gen
  //------------------------------------------------------------------
  wire mimo;
  wire codec_arst;
  wire [31:0] rx_data0, rx_data1, tx_data0, tx_data1;

  catcodec_ddr_cmos #(
    .DEVICE("7SERIES"))
  inst_catcodec_ddr_cmos (
    .radio_clk(radio_clk),
    .arst(codec_arst),
    .mimo(mimo),
    .rx1(rx_data0),
    .rx2(rx_data1),
    .tx1(tx_data0),
    .tx2(tx_data1),
    .rx_clk(CAT_DATA_CLK),
    .rx_frame(CAT_RX_FRAME),
    .rx_d(CAT_P0_D),
    .tx_clk(CAT_FB_CLK),
    .tx_frame(CAT_TX_FRAME),
    .tx_d(CAT_P1_D));

  assign CAT_CTRL_IN = 4'b1;
  assign CAT_ENAGC = 1'b1;
  assign CAT_TXNRX = 1'b1;
  assign CAT_ENABLE = 1'b1;

  assign CAT_RESET = ~(bus_rst || (CAT_CS & CAT_MOSI));   // Operates active-low, really CAT_RESET_B
  assign CAT_SYNC = 1'b0;

  //------------------------------------------------------------------
  //-- connect misc stuff to user GPIO
  //------------------------------------------------------------------
  assign ps_gpio_in[5] = AVR_IRQ;       //59
  assign ps_gpio_in[7] = ONSWITCH_DB;   //61

  //------------------------------------------------------------------
  //-- radio core from x300 for super fast bring up
  //------------------------------------------------------------------

  wire [31:0] gpio0, gpio1;

  assign { LED_TXRX1_TX, LED_TXRX1_RX, LED_RX1_RX, //3
           VCRX1_V2, VCRX1_V1, VCTXRX1_V2, VCTXRX1_V1, //4
           TX_ENABLE1B, TX_ENABLE1A //2
         } = gpio0[18:10];

  assign { LED_TXRX2_TX, LED_TXRX2_RX, LED_RX2_RX, //3
           VCRX2_V2, VCRX2_V1, VCTXRX2_V2, VCTXRX2_V1, //4
           TX_ENABLE2B, TX_ENABLE2A //2
         } = gpio1[18:10];

  //------------------------------------------------------------------
  //-- Zynq system interface, DMA, control channels, etc.
  //------------------------------------------------------------------

  wire [31:0] core_set_data, core_rb_data, xbar_set_data, xbar_rb_data;
  wire [31:0] core_set_addr, xbar_set_addr, xbar_rb_addr;
  wire        core_stb, xbar_set_stb, xbar_rb_stb;

  zynq_fifo_top
  #(
    .CONFIG_BASE(CONFIG_BASE),
    .PAGE_WIDTH(PAGE_WIDTH),
    .H2S_STREAMS_WIDTH(STREAMS_WIDTH),
    .H2S_CMDFIFO_DEPTH(CMDFIFO_DEPTH),
    .S2H_STREAMS_WIDTH(STREAMS_WIDTH),
    .S2H_CMDFIFO_DEPTH(CMDFIFO_DEPTH)
  )
  zynq_fifo_top0
  (
    .clk(bus_clk), .rst(bus_rst),
    .CTL_AXI_AWADDR(GP0_M_AXI_AWADDR),
    .CTL_AXI_AWVALID(GP0_M_AXI_AWVALID),
    .CTL_AXI_AWREADY(GP0_M_AXI_AWREADY),
    .CTL_AXI_WDATA(GP0_M_AXI_WDATA),
    .CTL_AXI_WSTRB(GP0_M_AXI_WSTRB),
    .CTL_AXI_WVALID(GP0_M_AXI_WVALID),
    .CTL_AXI_WREADY(GP0_M_AXI_WREADY),
    .CTL_AXI_BRESP(GP0_M_AXI_BRESP),
    .CTL_AXI_BVALID(GP0_M_AXI_BVALID),
    .CTL_AXI_BREADY(GP0_M_AXI_BREADY),
    .CTL_AXI_ARADDR(GP0_M_AXI_ARADDR),
    .CTL_AXI_ARVALID(GP0_M_AXI_ARVALID),
    .CTL_AXI_ARREADY(GP0_M_AXI_ARREADY),
    .CTL_AXI_RDATA(GP0_M_AXI_RDATA),
    .CTL_AXI_RRESP(GP0_M_AXI_RRESP),
    .CTL_AXI_RVALID(GP0_M_AXI_RVALID),
    .CTL_AXI_RREADY(GP0_M_AXI_RREADY),

    .DDR_AXI_AWID(HP0_S_AXI_AWID),
    .DDR_AXI_AWADDR(HP0_S_AXI_AWADDR),
    .DDR_AXI_AWPROT(HP0_S_AXI_AWPROT),
    .DDR_AXI_AWVALID(HP0_S_AXI_AWVALID),
    .DDR_AXI_AWREADY(HP0_S_AXI_AWREADY),
    .DDR_AXI_WDATA(HP0_S_AXI_WDATA),
    .DDR_AXI_WSTRB(HP0_S_AXI_WSTRB),
    .DDR_AXI_WVALID(HP0_S_AXI_WVALID),
    .DDR_AXI_WREADY(HP0_S_AXI_WREADY),
    .DDR_AXI_BRESP(HP0_S_AXI_BRESP),
    .DDR_AXI_BVALID(HP0_S_AXI_BVALID),
    .DDR_AXI_BREADY(HP0_S_AXI_BREADY),
    .DDR_AXI_ARID(HP0_S_AXI_ARID),
    .DDR_AXI_ARADDR(HP0_S_AXI_ARADDR),
    .DDR_AXI_ARPROT(HP0_S_AXI_ARPROT),
    .DDR_AXI_ARVALID(HP0_S_AXI_ARVALID),
    .DDR_AXI_ARREADY(HP0_S_AXI_ARREADY),
    .DDR_AXI_RDATA(HP0_S_AXI_RDATA),
    .DDR_AXI_RRESP(HP0_S_AXI_RRESP),
    .DDR_AXI_RVALID(HP0_S_AXI_RVALID),
    .DDR_AXI_RREADY(HP0_S_AXI_RREADY),
    .DDR_AXI_AWLEN(HP0_S_AXI_AWLEN),
    .DDR_AXI_RLAST(HP0_S_AXI_RLAST),
    .DDR_AXI_ARCACHE(HP0_S_AXI_ARCACHE),
    .DDR_AXI_AWSIZE(HP0_S_AXI_AWSIZE),
    .DDR_AXI_AWBURST(HP0_S_AXI_AWBURST),
    .DDR_AXI_AWCACHE(HP0_S_AXI_AWCACHE),
    .DDR_AXI_WLAST(HP0_S_AXI_WLAST),
    .DDR_AXI_ARLEN(HP0_S_AXI_ARLEN),
    .DDR_AXI_ARBURST(HP0_S_AXI_ARBURST),
    .DDR_AXI_ARSIZE(HP0_S_AXI_ARSIZE),

    .h2s_tdata(h2s_tdata),
    .h2s_tlast(h2s_tlast),
    .h2s_tvalid(h2s_tvalid),
    .h2s_tready(h2s_tready),

    .s2h_tdata(s2h_tdata),
    .s2h_tlast(s2h_tlast),
    .s2h_tvalid(s2h_tvalid),
    .s2h_tready(s2h_tready),

    .core_set_data(core_set_data),
    .core_set_addr(core_set_addr),
    .core_set_stb(core_set_stb),
    .core_rb_data(core_rb_data),

    .xbar_set_data(xbar_set_data),
    .xbar_set_addr(xbar_set_addr),
    .xbar_set_stb(xbar_set_stb),
    .xbar_rb_data(xbar_rb_data),
    .xbar_rb_addr(xbar_rb_addr),
    .xbar_rb_stb(xbar_rb_stb),

    .event_irq(stream_irq)
  );

  // resync pps to bus_clk >>> TODO: check this makes sense
  reg [1:0] ppsync;
  wire pps = ppsync[1];
  wire lpps;
  always @(posedge bus_clk)
    ppsync <= { ppsync[0], lpps };

  wire clk_tcxo = TCXO_CLK; // 40 MHz

  wire [1:0] pps_select;

  /* A local pps signal is derived from the tcxo clock. If a referenc
   * at an appropriate rate (1 pps or 10 MHz) is present and selected
   * a digital control loop will be invoked to tune the vcxo and lock t
   * the reference.
   */

  wire is_10meg, is_pps, reflck, plllck; // reference status bits
  ppsloop ppslp
  (
    .reset(1'b0),
    .xoclk(clk_tcxo), .ppsgps(GPS_PPS), .ppsext(PPS_EXT_IN),
    .refsel(pps_select),
    .lpps(lpps),
    .is10meg(is_10meg), .ispps(is_pps), .reflck(reflck), .plllck(plllck),
    .sclk(TCXO_DAC_SCLK), .mosi(TCXO_DAC_SDIN), .sync_n(TCXO_DAC_SYNCn),
    .dac_dflt(16'h7fff)
  );
  reg [3:0] tcxo_status, st_rsync;
  always @(posedge bus_clk) begin
    /* status signals originate from other than the bus_clk domain so re-sync
       before passing to e300_core
     */
    st_rsync <= {plllck, is_10meg, is_pps, reflck};
    tcxo_status <= st_rsync;
  end

  // E300 Core logic

  e300_core e300_core0
  (
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),

    .h2s_tdata(h2s_tdata),
    .h2s_tlast(h2s_tlast),
    .h2s_tvalid(h2s_tvalid),
    .h2s_tready(h2s_tready),

    .s2h_tdata(s2h_tdata),
    .s2h_tlast(s2h_tlast),
    .s2h_tvalid(s2h_tvalid),
    .s2h_tready(s2h_tready),

    .radio_clk(radio_clk),
    .radio_rst(radio_rst),
    // flip them to match case
    // this is a hack
    .rx_data0(rx_data1),
    .tx_data0(tx_data1),
    .rx_data1(rx_data0),
    .tx_data1(tx_data0),

    // flip them, to match
    // case ... this is a hack
    .ctrl_out0(gpio1),
    .ctrl_out1(gpio0),

    .fp_gpio(PL_GPIO),

    .set_data(core_set_data),
    .set_addr(core_set_addr),
    .set_stb(core_set_stb),
    .rb_data(core_rb_data),

    .xbar_set_data(xbar_set_data),
    .xbar_set_addr(xbar_set_addr),
    .xbar_set_stb(xbar_set_stb),
    .xbar_rb_data(xbar_rb_data),
    .xbar_rb_addr(xbar_rb_addr),
    .xbar_rb_stb(xbar_rb_stb),

    .pps_select(pps_select),
    .pps(pps),
    .tcxo_status(tcxo_status),

    .lock_signals(CAT_CTRL_OUT[7:6]),
    .mimo(mimo),
    .codec_arst(codec_arst),
    .tx_bandsel(TX_BANDSEL),
    .rx_bandsel_a({RX2_BANDSEL, RX1_BANDSEL}),
    .rx_bandsel_b({RX2B_BANDSEL, RX1B_BANDSEL}),
    .rx_bandsel_c({RX2C_BANDSEL, RX1C_BANDSEL}),
    .debug()
  );

endmodule // e300
