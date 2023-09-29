/* ------------------------------------------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Project: RVCoreF
 * Author: Heqing Huang
 * Date Created: 09/25/2023
 *
 * ------------------------------------------------------------------------------------------------
 * axi4lite2sram: AXI4 lite to SRAM bus IP
 * ------------------------------------------------------------------------------------------------
 */

module axi4lite2sram #(
    parameter DW = 32,
    parameter AW = 32
) (
    input                   clk,
    input                   rst_b,
    // SRAM Bus
    output logic            sram_req,
    output logic            sram_write,
    output logic [DW/8-1:0] sram_wstrb,
    output logic [AW-1:0]   sram_addr,
    output logic [DW-1:0]   sram_wdata,
    input  logic            sram_ready,
    input  logic            sram_rvalid,
    input  logic [DW-1:0]   sram_rdata,
    // AXI4 lite
    // Write address cahnnel
    input  logic            axi_awvalid,
    input  logic [AW-1:0]   axi_awaddr,
    input  logic            axi_awport,
    output logic            axi_awready,
    // Write data channel
    input  logic            axi_wvalid,
    input  logic [DW-1:0]   axi_wdata,
    input  logic [DW/8-1:0] axi_wstrb,
    output logic            axi_wready,
    // Write response channel
    output logic            axi_bvalid,
    output logic [1:0]      axi_bresp,
    input  logic            axi_bready,
    // Read addres channel
    input  logic            axi_arvalid,
    input  logic [AW-1:0]   axi_araddr,
    input  logic            axi_arport,
    output logic            axi_arready,
    // Read data channel
    output logic            axi_rvalid,
    output logic [DW-1:0]   axi_rdata,
    output logic [1:0]      axi_rresp,
    input  logic            axi_rready
);

    // -----------------------------------------------
    // Signal Declaration
    // -----------------------------------------------

    logic           bvalid_pending;
    logic           rvalid_pending;
    logic [DW-1:0]  rdata;

    // -----------------------------------------------
    // Map the ready signal
    // -----------------------------------------------

    // Wait for both awvalid and awvalid before we assert the ready signal
    // so that we do not need to store the write address channel if write data
    // channel is not available.
    assign axi_awready = axi_awvalid & axi_wvalid & sram_ready;
    assign axi_wready  = axi_awready;
    assign axi_arready = axi_arvalid & sram_ready;

    // -----------------------------------------------
    // Map the AXI request channel to SRAM bus request
    // -----------------------------------------------
    assign sram_req = axi_awready | axi_arready;
    assign sram_write = axi_awready;
    assign sram_wstrb = axi_wstrb;
    assign sram_addr = axi_awready ? axi_awaddr : axi_araddr;
    assign sram_wdata = axi_wdata;

    // -----------------------------------------------
    // write response channel
    // -----------------------------------------------

    // buffering the write response if bready is not set
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) bvalid_pending <= 1'b0;
        else begin
            if (axi_awready && !axi_bready) bvalid_pending <= 1'b1;
            else if (axi_bvalid && axi_bready) bvalid_pending <= 1'b0;
        end
    end

    assign axi_bvalid = axi_awready | bvalid_pending;
    assign axi_bresp = 2'b0; // always OK.

    // -----------------------------------------------
    // Read response channel
    // -----------------------------------------------

    // buffering the read response if bready is not set
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            rvalid_pending <= 1'b0;
            rdata <= '0;
        end
        else begin
            if (sram_rvalid && !axi_rready) begin
                rvalid_pending <= 1'b1;
                rdata <= sram_rdata;
            end
            else if (axi_rvalid && axi_rready) begin
                rvalid_pending <= 1'b0;
                rdata <= '0;
            end
        end
    end

    assign axi_rvalid = sram_rvalid | rvalid_pending;
    assign axi_rresp = 2'b0; // always OK
    assign axi_rdata = sram_rvalid ? sram_rdata : rdata;

endmodule