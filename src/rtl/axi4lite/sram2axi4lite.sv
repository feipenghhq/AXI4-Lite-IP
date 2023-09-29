/* ------------------------------------------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Project: RVCoreF
 * Author: Heqing Huang
 * Date Created: 09/28/2023
 *
 * ------------------------------------------------------------------------------------------------
 * sram2axi4lite: SRAM bus IP to AXI4 lite
 * ------------------------------------------------------------------------------------------------
 */

module sram2axi4lite #(
    parameter DW = 32,
    parameter AW = 32
) (
    input                  clk,
    input                  rst_b,
    // SRAM Bus
    input  logic            sram_req,
    input  logic            sram_write,
    input  logic [DW/8-1:0] sram_wstrb,
    input  logic [AW-1:0]   sram_addr,
    input  logic [DW-1:0]   sram_wdata,
    output logic            sram_ready,
    output logic            sram_rvalid,
    output logic [DW-1:0]   sram_rdata,
    // AXI4 lite
    // Write address cahnnel
    output logic            axi_awvalid,
    output logic [AW-1:0]   axi_awaddr,
    output logic [2:0]      axi_awport,
    input  logic            axi_awready,
    // Write data channel
    output logic            axi_wvalid,
    output logic [DW-1:0]   axi_wdata,
    output logic [DW/8-1:0] axi_wstrb,
    input  logic            axi_wready,
    // Write response channel
    input  logic            axi_bvalid,
    input  logic [1:0]      axi_bresp,
    output logic            axi_bready,
    // Read addres channel
    output logic            axi_arvalid,
    output logic [AW-1:0]   axi_araddr,
    output logic [2:0]      axi_arport,
    input  logic            axi_arready,
    // Read data channel
    input  logic            axi_rvalid,
    input  logic [DW-1:0]   axi_rdata,
    input  logic [1:0]      axi_rresp,
    output logic            axi_rready
);

    // -----------------------------------------------
    // Map the AXI request channel to SRAM bus request
    // -----------------------------------------------

    // -----------------------------------------------
    // write addr channel
    assign axi_awvalid = sram_req & sram_write;
    assign axi_awaddr = sram_addr;
    assign axi_awport = 3'b0;

    // -----------------------------------------------
    // write data channel
    assign axi_wvalid = axi_awvalid;
    assign axi_wstrb = sram_wstrb;
    assign axi_wdata = sram_wdata;

    // -----------------------------------------------
    // write resp channel
    assign axi_bready = 1'b1;

    // -----------------------------------------------
    // read addr channel
    assign axi_arvalid = sram_req & ~sram_write;
    assign axi_araddr = sram_addr;
    assign axi_arport = 3'b0;

    // -----------------------------------------------
    // read resp channel
    assign sram_rvalid = axi_rvalid;
    assign sram_rdata = axi_rdata;
    assign axi_rready = 1'b1;

    // -----------------------------------------------
    // Map the ready signal
    assign sram_ready = (axi_awvalid & axi_awready & axi_wready) | (axi_arvalid & axi_arready);

endmodule