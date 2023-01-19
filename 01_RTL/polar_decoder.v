// `include "reliability_ROM.v"
// `include "function_f.v"
// `include "function_g.v"


module polar_decoder (
    clk,
    rst_n,
    module_en,
    proc_done,
    raddr,
    rdata,
    waddr,
    wdata
);

// ---------------------------------------------------------------------------
// IO description
// ---------------------------------------------------------------------------

parameter IDLE      = 3'd0;
parameter LOAD      = 3'd1;
parameter COMPUTE   = 3'd2;
parameter FINISH    = 3'd3;

integer i, j;

input  wire         clk;
input  wire         rst_n;
input  wire         module_en;
input  wire [191:0] rdata;
output wire [ 10:0] raddr;
output wire [  5:0] waddr;
output wire [139:0] wdata;
output wire         proc_done;


reg         [ 10:0] raddr_r, raddr_w;
reg         [  5:0] waddr_r, waddr_w;
reg         [139:0] wdata_r, wdata_w;
reg                 proc_done_r, proc_done_w;
reg         [  2:0] state_r, state_w;
reg         [  9:0] n_r, n_w;
reg         [  7:0] k_r, k_w; 
reg         [  6:0] packets_num_r, packets_num_w;
reg         [  6:0] packets_idx_r, packets_idx_w;
reg         [ 10:0] compute_idx_r, compute_idx_w;
reg         [ 11:0] alpha_r[0:1022], alpha_w[0:1022];
reg         [  3:0] level_r, level_w;
reg         [  3:0] level_num_r, level_num_w;
reg         [  1:0] start_num_r, start_num_w;
reg         [ 10:0] level_idx_r[0:9], level_idx_w[0:9];
reg         [ 10:0] level_val_r[0:9], level_val_w[0:9];
reg         [ 10:0] alpha_idx_r, alpha_idx_w;
reg         [ 20:0] tmp_cal;
reg         [  7:0] out_idx_r, out_idx_w; 

reg         [ 11:0] alpha_0_r[0:511], alpha_0_w[0:511];
reg         [ 12:0] alpha_1_r[0:255], alpha_1_w[0:255];
reg         [ 13:0] alpha_2_r[0:127], alpha_2_w[0:127];
reg         [ 14:0] alpha_3_r[0:63] , alpha_3_w[0:63];
reg         [ 15:0] alpha_4_r[0:31] , alpha_4_w[0:31];
reg         [ 16:0] alpha_5_r[0:15] , alpha_5_w[0:15];
reg         [ 17:0] alpha_6_r[0:7]  , alpha_6_w[0:7];
reg         [ 18:0] alpha_7_r[0:3]  , alpha_7_w[0:3];
reg         [ 19:0] alpha_8_r[0:1]  , alpha_8_w[0:1];
reg         [ 20:0] alpha_9_r       , alpha_9_w;

reg         [255:0] beta_1_r, beta_1_w;
reg         [127:0] beta_2_r, beta_2_w;
reg         [ 63:0] beta_3_r, beta_3_w;
reg         [ 31:0] beta_4_r, beta_4_w;
reg         [ 15:0] beta_5_r, beta_5_w;
reg         [  7:0] beta_6_r, beta_6_w;
reg         [  3:0] beta_7_r, beta_7_w;
reg         [  1:0] beta_8_r, beta_8_w;
reg         [  1:0] beta_9_r, beta_9_w;
reg                 compute_fin_r, compute_fin_w;



reg         [ 20:0] a_r[0:255], b_r[0:255];
reg                 u_r[0:255];
wire        [ 20:0] result [0:255];
wire        [ 20:0] result2 [0:255];
wire                sign_bit [0:255];

reg         [  1:0] num_r;
wire        [  1:0] num;
reg         [  8:0] index1_r;
wire        [  8:0] index1;
wire        [  8:0] reliability1;

reg         [  9:0] node_idx;
wire        [  6:0] node_weight_128[0:5];
wire        [  7:0] node_weight_256[0:254];
wire        [  8:0] node_weight_512[0:510];
reg         [  3:0] weight_idx;
wire        [  11:0] tmp;

reliability_ROM2Out reliability(.N(num_r), .index1(index1_r), .reliability1(reliability1));
genvar k;

generate
    for(k=0; k<256; k=k+1)begin: BLOCK1
        function_f f(.a(a_r[k]), .b(b_r[k]), .sign_bit(sign_bit[k]), .result(result[k]));
        function_g g(.a(a_r[k]), .b(b_r[k]), .u(u_r[k]), .result(result2[k]));
    end
endgenerate  

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------

assign  raddr = raddr_r;
assign  waddr = waddr_r;
assign  wdata = wdata_r;
assign  proc_done = proc_done_r;
// ===========================================
// 128 node weight ROM
// ===========================================

assign  node_weight_128[0] = 97;
assign  node_weight_128[1] = 72;
assign  node_weight_128[2] = 64;
assign  node_weight_128[3] = 32;
assign  node_weight_128[4] = 4;
assign  node_weight_128[5] = 1;

// ===========================================
// 256 node weight ROM
// ===========================================

assign  node_weight_256[0] = 200;
assign  node_weight_256[1] = 192;
assign  node_weight_256[2] = 130;
assign  node_weight_256[3] = 128;
assign  node_weight_256[4] = 32;
assign  node_weight_256[5] = 4;
assign  node_weight_256[6] = 1;

// ===========================================
// 512 node weight ROM
// ===========================================


assign  node_weight_512[0] = 416;
assign  node_weight_512[1] = 384;
assign  node_weight_512[2] = 288;
assign  node_weight_512[3] = 256;
assign  node_weight_512[4] = 128;
assign  node_weight_512[5] = 32;
assign  node_weight_512[6] = 4;
assign  node_weight_512[7] = 1;

assign tmp = ((packets_idx_r+1)<<5) + (packets_idx_r+1) + 1;
// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------

always @(*) begin
    case(state_r)
        IDLE: begin
            if (module_en == 1)         state_w = LOAD;
            else if (packets_idx_r > 0) state_w = LOAD;
            else                        state_w = state_r;
        end
        LOAD: begin
            if (raddr_r >= (tmp)) state_w = COMPUTE;
            else                                                             state_w = state_r;
        end
        COMPUTE: begin
            if ((packets_idx_r == packets_num_r - 1) && (node_idx == 2 * n_r - 2))         state_w = FINISH;
            else if (node_idx == 2 * n_r - 2)           state_w = IDLE;  
            else                                        state_w = state_r;
        end
        FINISH: begin
            state_w = IDLE;
        end
        default: state_w = state_r;
    endcase
end

always @(*) begin

    for (i=0; i<10; i=i+1) begin
        level_idx_w[i]   =  level_idx_r[i];
        level_val_w[i]   =  level_val_r[i];
    end
    
    level_w = level_r;
    wdata_w = wdata_r;

    num_r = 0;
    index1_r = 0;
    
    node_idx = 0;
    out_idx_w = out_idx_r;

    packets_idx_w = packets_idx_r;
    level_num_w = level_num_r;
    packets_num_w = packets_num_r;
    waddr_w = waddr_r;
    raddr_w = raddr_r;
    n_w = n_r;
    k_w = k_r;
    beta_1_w  =  beta_1_r;
    beta_2_w  =  beta_2_r;
    beta_3_w  =  beta_3_r;
    beta_4_w  =  beta_4_r;
    beta_5_w  =  beta_5_r;
    beta_6_w  =  beta_6_r;
    beta_7_w  =  beta_7_r;
    beta_8_w  =  beta_8_r;
    beta_9_w  =  beta_9_r;
    compute_fin_w = compute_fin_r;

    weight_idx = 15;

    for (i=0; i<256; i=i+1) begin
        a_r[i] = 0;
        b_r[i] = 0;
        u_r[i] = 0;
    end
    for (i=0; i<512; i=i+1) begin
        alpha_0_w[i]     =  alpha_0_r[i];
        alpha_0_w[i]     =  alpha_0_r[i];
    end
    for (i=0; i<256; i=i+1) begin
        alpha_1_w[i]     =  alpha_1_r[i];
        alpha_0_w[i]     =  alpha_0_r[i];

    end
    for (i=0; i<128; i=i+1) begin
        alpha_2_w[i]     =  alpha_2_r[i];
    end
    for (i=0; i<64; i=i+1) begin
        alpha_3_w[i]     =  alpha_3_r[i];
    end
    for (i=0; i<32; i=i+1) begin
        alpha_4_w[i]     =  alpha_4_r[i];
    end
    for (i=0; i<16; i=i+1) begin
        alpha_5_w[i]     =  alpha_5_r[i];
    end
    for (i=0; i<8; i=i+1) begin
        alpha_6_w[i]     =  alpha_6_r[i];
    end
    for (i=0; i<4; i=i+1) begin
        alpha_7_w[i]     =  alpha_7_r[i];
    end
    for (i=0; i<2; i=i+1) begin
        alpha_8_w[i]     =  alpha_8_r[i];
    end
    alpha_9_w     =  alpha_9_r;

    if (state_r == LOAD) begin
        raddr_w = raddr_r + 1;
        if(raddr_r == 1) begin
            packets_num_w = rdata;
        end
        else if (raddr_r == ((packets_idx_r<<5) + packets_idx_r + 2)) begin
            n_w = rdata[9:0];
            k_w = rdata[17:10];
            if      (rdata[9:0] == 128) level_num_w = 2;
            else if (rdata[9:0] == 256) level_num_w = 1;
            else                        level_num_w = 0;
            $display("n_w: %d, k_w: %d", n_w, k_w);
        end
        else if (raddr_r > ((packets_idx_r<<5) + packets_idx_r + 2) )begin
            for (i=0; i<16; i=i+1) begin
                for (j=0; j<12; j=j+1) begin
                    if (level_num_r == 0) begin
                        alpha_0_w[(raddr_r - ((packets_idx_r<<5) + packets_idx_r + 3))*16+i][j] = rdata[i*12+j];
                        level_w = 1;
                    end
                    else if (level_num_r == 1) begin
                        alpha_1_w[(raddr_r - ((packets_idx_r<<5) + packets_idx_r + 3))*16+i][j] = rdata[i*12+j];
                        level_w = 2;
                    end
                    else begin
                        alpha_2_w[(raddr_r - ((packets_idx_r<<5) + packets_idx_r + 3))*16+i][j] = rdata[i*12+j];
                        level_w = 3;
                    end
                end
                if (level_num_r == 1) begin 
                    alpha_1_w[(raddr_r - ((packets_idx_r<<5) + packets_idx_r + 3))*16+i][12] = rdata[i*12+11];
                end
                else if (level_num_r == 2) begin
                    alpha_2_w[(raddr_r - ((packets_idx_r<<5) + packets_idx_r + 3))*16+i][12] = rdata[i*12+11];
                    alpha_2_w[(raddr_r - ((packets_idx_r<<5) + packets_idx_r + 3))*16+i][13] = rdata[i*12+11];
                end
                else begin
                    alpha_0_w[(raddr_r - ((packets_idx_r<<5) + packets_idx_r + 3))*16+i][11] = rdata[i*12+11];
                end
            end
            
            if (((raddr_r - ((packets_idx_r<<5) + packets_idx_r + 3))*16+15) == n_r-1) begin
                raddr_w = (tmp);
                // $display(raddr_w);
            end
            else begin
                raddr_w = raddr_r + 1;
            end
        end
    end
    else if (state_r == COMPUTE) begin
        node_idx = (level_idx_r[level_r] >> (9 - level_r)) + (1 << (level_r - level_num_r)) - 1;
        case(node_idx)
            1:
                weight_idx = 0;
            3:
                weight_idx = 1;
            7:
                weight_idx = 2;
            15:
                weight_idx = 3;
            31:
                weight_idx = 4;
            63:
                weight_idx = 5;
            127:
                weight_idx = 6;
            255:
                weight_idx = 7;
            default
                weight_idx = 15;
        endcase
        if(level_r < 9 && weight_idx != 15 && ((n_r == 128 && node_weight_128[weight_idx] < n_r - k_r) || (n_r == 256 && node_weight_256[weight_idx] < n_r - k_r) || (n_r == 512 && node_weight_512[weight_idx] < n_r - k_r))) begin
            for(i=1; i<10; i=i+1) begin
                level_idx_w[i] = (level_r <= i) ? level_idx_r[level_r] + (n_r>>(level_r - level_num_r)) : level_idx_r[i];
            end

        end
        else begin
            raddr_w = tmp;
            if(level_idx_r[level_r][(9-level_r)] == 0) begin // left node
                case(level_r)
                    1: begin
                        for (i=0; i<256; i=i+1) begin 
                            a_r[i] = {{9{alpha_0_r[i][11]}}, alpha_0_r[i]};
                            b_r[i] = {{9{alpha_0_r[i+256][11]}}, alpha_0_r[i+256]};
                            alpha_1_w[i] = {sign_bit[i], result[i][11:0]};

                        end
                    end
                    2: begin
                        for (i=0; i<128; i=i+1) begin
                            a_r[i] = {{8{alpha_1_r[i][12]}}, alpha_1_r[i]};
                            b_r[i] = {{8{alpha_1_r[i+128][12]}}, alpha_1_r[i+128]};
                            alpha_2_w[i] = {sign_bit[i], result[i][12:0]};
                        end
                    end
                    3: begin
                        for (i=0; i<64; i=i+1) begin
                            a_r[i] = {{7{alpha_2_r[i][13]}}, alpha_2_r[i]};
                            b_r[i] = {{7{alpha_2_r[i+(64)][13]}}, alpha_2_r[i+(64)]};
                            alpha_3_w[i] = {sign_bit[i], result[i][13:0]};
                        end
                    end
                    4: begin
                        for (i=0; i<32; i=i+1) begin
                            a_r[i] = {{6{alpha_3_r[i][14]}}, alpha_3_r[i]};
                            b_r[i] = {{6{alpha_3_r[i+(32)][14]}}, alpha_3_r[i+32]};
                            alpha_4_w[i] = {sign_bit[i], result[i][14:0]};
                        end
                    end
                    5: begin
                        for (i=0; i<16; i=i+1) begin
                            a_r[i] = {{5{alpha_4_r[i][15]}}, alpha_4_r[i]};
                            b_r[i] = {{5{alpha_4_r[i+16][15]}}, alpha_4_r[i+16]};
                            alpha_5_w[i] = {sign_bit[i], result[i][15:0]};
                        end 
                    end
                    6: begin
                        for (i=0; i<8; i=i+1) begin
                            a_r[i] = {{4{alpha_5_r[i][16]}}, alpha_5_r[i]};
                            b_r[i] = {{4{alpha_5_r[i+8][16]}}, alpha_5_r[i+8]};
                            alpha_6_w[i] = {sign_bit[i], result[i][16:0]};
                        end
                    end
                    7: begin
                        for (i=0; i<4; i=i+1) begin
                            a_r[i] = {{3{alpha_6_r[i][17]}}, alpha_6_r[i]};
                            b_r[i] = {{3{alpha_6_r[i+4][17]}}, alpha_6_r[i+4]};
                            alpha_7_w[i] = {sign_bit[i], result[i][17:0]};
                        end
                    end
                    8: begin
                        for (i=0; i<2; i=i+1) begin
                            a_r[i] = {{2{alpha_7_r[i][18]}}, alpha_7_r[i]};
                            b_r[i] = {{2{alpha_7_r[i+2][18]}}, alpha_7_r[i+2]};
                            alpha_8_w[i] = {sign_bit[i], result[i][18:0]}; 
                        end
                    end
                    default: begin
                        for (i=0; i<1; i=i+1) begin
                            a_r[0] = {alpha_8_r[i][19], alpha_8_r[i]};
                            b_r[0] = {alpha_8_r[i+1][19], alpha_8_r[i+1]};
                            alpha_9_w = {sign_bit[i], result[i][19:0]}; 
                        end
                    end
                endcase

            end
            else begin // right node
                case(level_r)
                    1: begin
                        for (i=0; i<256; i=i+1) begin
                            a_r[i] = {{9{alpha_0_r[i][11]}}, alpha_0_r[i]};
                            b_r[i] = {{9{alpha_0_r[i+256][11]}}, alpha_0_r[i+256]};
                            alpha_1_w[i] = result2[i];
                        end
                        for (i=0; i<256; i=i+1) begin
                            u_r[i] = beta_1_r[i];
                        end
                    end
                    2: begin
                        for (i=0; i<128; i=i+1) begin
                            a_r[i] = {{8{alpha_1_r[i][12]}}, alpha_1_r[i]};
                            b_r[i] = {{8{alpha_1_r[i+128][12]}}, alpha_1_r[i+128]};
                            alpha_2_w[i] = result2[i];
                        end
                        for (i=0; i<128; i=i+1) begin
                            u_r[i] = beta_2_r[i];
                        end
                    end
                    3: begin
                        for (i=0; i<64; i=i+1) begin
                            a_r[i] = {{7{alpha_2_r[i][13]}}, alpha_2_r[i]};
                            b_r[i] = {{7{alpha_2_r[i+64][13]}}, alpha_2_r[i+64]};
                            alpha_3_w[i] = result2[i];
                        end
                        for (i=0; i<64; i=i+1) begin
                            u_r[i] = beta_3_r[i];
                        end
                    end
                    4: begin
                        for (i=0; i<32; i=i+1) begin
                            a_r[i] = {{6{alpha_3_r[i][14]}}, alpha_3_r[i]};
                            b_r[i] = {{6{alpha_3_r[i+32][14]}}, alpha_3_r[i+32]};
                            alpha_4_w[i] = result2[i];
                        end
                        for (i=0; i<32; i=i+1) begin
                            u_r[i] = beta_4_r[i];
                        end
                    end
                    5: begin
                        for (i=0; i<16; i=i+1) begin
                            a_r[i] = {{5{alpha_4_r[i][15]}}, alpha_4_r[i]};
                            b_r[i] = {{5{alpha_4_r[i+16][15]}}, alpha_4_r[i+16]};
                            alpha_5_w[i] = result2[i];
                        end
                        for (i=0; i<16; i=i+1) begin
                            u_r[i] = beta_5_r[i];
                        end
                    end
                    6: begin
                        for (i=0; i<8; i=i+1) begin
                            a_r[i] = {{4{alpha_5_r[i][16]}}, alpha_5_r[i]};
                            b_r[i] = {{4{alpha_5_r[i+8][16]}}, alpha_5_r[i+8]};
                            alpha_6_w[i] = result2[i];
                        end
                        for (i=0; i<8; i=i+1) begin
                            u_r[i] = beta_6_r[i];
                        end
                    end
                    7: begin
                        for (i=0; i<4; i=i+1) begin
                            a_r[i] = {{3{alpha_6_r[i][17]}}, alpha_6_r[i]};
                            b_r[i] = {{3{alpha_6_r[i+4][17]}}, alpha_6_r[i+4]};
                            alpha_7_w[i] = result2[i];
                        end
                        for (i=0; i<4; i=i+1) begin
                            u_r[i] = beta_7_r[i];
                        end
                    end
                    8: begin
                        for (i=0; i<2; i=i+1) begin
                            a_r[i] = {{2{alpha_7_r[i][18]}}, alpha_7_r[i]};
                            b_r[i] = {{2{alpha_7_r[i+2][18]}}, alpha_7_r[i+2]};
                            alpha_8_w[i] = result2[i];
                        end
                        for (i=0; i<2; i=i+1) begin
                            u_r[i] = beta_8_r[i];
                        end
                    end
                    default: begin
                        for (i=0; i<1; i=i+1) begin
                            a_r[i] = {{1{alpha_8_r[i][19]}}, alpha_8_r[i]};
                            b_r[i] = {{1{alpha_8_r[i+1][19]}}, alpha_8_r[i+1]};
                            alpha_9_w = result2[i];
                        end
                        u_r[0] = beta_9_r[0];
                    end 
                endcase
            end
            if (level_r == 9) begin
                index1_r = level_idx_r[9];
                num_r = (n_r == 128)? 2: (n_r == 256)? 1: 0;
                if (reliability1 >= (n_r-k_r)) begin
                    beta_9_w[0] = (~level_idx_r[9][0])? ((alpha_9_w[20])? 1: 0): beta_9_r[0];
                    beta_9_w[1] = (~level_idx_r[9][0])? beta_9_r[1]: ((alpha_9_w[20])? 1: 0);
                    wdata_w[out_idx_r] = ((alpha_9_w[20])? 1: 0);
                    out_idx_w = out_idx_r + 1;
                    waddr_w = packets_idx_r;
                end
                else begin
                    beta_9_w[0] = (~level_idx_r[level_r][0])? 0: beta_9_r[0];
                    beta_9_w[1] = (~level_idx_r[level_r][0])? beta_9_r[1]: 0;
                    out_idx_w = out_idx_r;
                end
                if (level_idx_r[level_r] == n_r-1) compute_fin_w = 1;
                else                               compute_fin_w = compute_fin_r;

                if(level_idx_r[9][7:0] == 255) begin
                    beta_8_w[0] = beta_9_r[0]^beta_9_w[1];
                    beta_8_w[1] = beta_9_w[1];
                    for (i=0; i<2; i=i+1) begin
                        beta_7_w[i] = beta_8_r[i]^beta_8_w[i];
                        beta_7_w[i+2] = beta_8_w[i];
                    end
                    for (i=0; i<4; i=i+1) begin
                        beta_6_w[i] = beta_7_r[i]^beta_7_w[i];
                        beta_6_w[i+4] = beta_7_w[i];
                    end
                    for (i=0; i<8; i=i+1) begin
                        beta_5_w[i] = beta_6_r[i]^beta_6_w[i];
                        beta_5_w[i+8] = beta_6_w[i];
                    end
                    for (i=0; i<16; i=i+1) begin
                        beta_4_w[i] = beta_5_r[i]^beta_5_w[i];
                        beta_4_w[i+16] = beta_5_w[i];
                    end
                    for (i=0; i<32; i=i+1) begin
                        beta_3_w[i] = beta_4_r[i]^beta_4_w[i];
                        beta_3_w[i+32] = beta_4_w[i];
                    end
                    for (i=0; i<64; i=i+1) begin
                        beta_2_w[i] = beta_3_r[i]^beta_3_w[i];
                        beta_2_w[i+64] = beta_3_w[i];
                    end
                    for (i=0; i<128; i=i+1) begin
                        beta_1_w[i] = beta_2_r[i]^beta_2_w[i];
                        beta_1_w[i+128] = beta_2_w[i];
                    end
                end
                else if(level_idx_r[9][6:0] == 127) begin
                    beta_8_w[0] = beta_9_r[0]^beta_9_w[1];
                    beta_8_w[1] = beta_9_w[1];
                    for (i=0; i<2; i=i+1) begin
                        beta_7_w[i] = beta_8_r[i]^beta_8_w[i];
                        beta_7_w[i+2] = beta_8_w[i];
                    end
                    for (i=0; i<4; i=i+1) begin
                        beta_6_w[i] = beta_7_r[i]^beta_7_w[i];
                        beta_6_w[i+4] = beta_7_w[i];
                    end
                    for (i=0; i<8; i=i+1) begin
                        beta_5_w[i] = beta_6_r[i]^beta_6_w[i];
                        beta_5_w[i+8] = beta_6_w[i];
                    end
                    for (i=0; i<16; i=i+1) begin
                        beta_4_w[i] = beta_5_r[i]^beta_5_w[i];
                        beta_4_w[i+16] = beta_5_w[i];
                    end
                    for (i=0; i<32; i=i+1) begin
                        beta_3_w[i] = beta_4_r[i]^beta_4_w[i];
                        beta_3_w[i+32] = beta_4_w[i];
                    end
                    for (i=0; i<64; i=i+1) begin
                        beta_2_w[i] = beta_3_r[i]^beta_3_w[i];
                        beta_2_w[i+64] = beta_3_w[i];
                    end
                end
                else if(level_idx_r[9][5:0] == 63) begin
                    beta_8_w[0] = beta_9_r[0]^beta_9_w[1];
                    beta_8_w[1] = beta_9_w[1];
                    for (i=0; i<2; i=i+1) begin
                        beta_7_w[i] = beta_8_r[i]^beta_8_w[i];
                        beta_7_w[i+2] = beta_8_w[i];
                    end
                    for (i=0; i<4; i=i+1) begin
                        beta_6_w[i] = beta_7_r[i]^beta_7_w[i];
                        beta_6_w[i+4] = beta_7_w[i];
                    end
                    for (i=0; i<8; i=i+1) begin
                        beta_5_w[i] = beta_6_r[i]^beta_6_w[i];
                        beta_5_w[i+8] = beta_6_w[i];
                    end
                    for (i=0; i<16; i=i+1) begin
                        beta_4_w[i] = beta_5_r[i]^beta_5_w[i];
                        beta_4_w[i+16] = beta_5_w[i];
                    end
                    for (i=0; i<32; i=i+1) begin
                        beta_3_w[i] = beta_4_r[i]^beta_4_w[i];
                        beta_3_w[i+32] = beta_4_w[i];
                    end
                end
                else if(level_idx_r[9][4:0] == 31)begin
                    beta_8_w[0] = beta_9_r[0]^beta_9_w[1];
                    beta_8_w[1] = beta_9_w[1];
                    for (i=0; i<2; i=i+1) begin
                        beta_7_w[i] = beta_8_r[i]^beta_8_w[i];
                        beta_7_w[i+2] = beta_8_w[i];
                    end
                    for (i=0; i<4; i=i+1) begin
                        beta_6_w[i] = beta_7_r[i]^beta_7_w[i];
                        beta_6_w[i+4] = beta_7_w[i];
                    end
                    for (i=0; i<8; i=i+1) begin
                        beta_5_w[i] = beta_6_r[i]^beta_6_w[i];
                        beta_5_w[i+8] = beta_6_w[i];
                    end
                    for (i=0; i<16; i=i+1) begin
                        beta_4_w[i] = beta_5_r[i]^beta_5_w[i];
                        beta_4_w[i+16] = beta_5_w[i];
                    end
                end
                else if(level_idx_r[9][3:0] == 15)begin
                    beta_8_w[0] = beta_9_r[0]^beta_9_w[1];
                    beta_8_w[1] = beta_9_w[1];
                    for (i=0; i<2; i=i+1) begin
                        beta_7_w[i] = beta_8_r[i]^beta_8_w[i];
                        beta_7_w[i+2] = beta_8_w[i];
                    end
                    for (i=0; i<4; i=i+1) begin
                        beta_6_w[i] = beta_7_r[i]^beta_7_w[i];
                        beta_6_w[i+4] = beta_7_w[i];
                    end
                    for (i=0; i<8; i=i+1) begin
                        beta_5_w[i] = beta_6_r[i]^beta_6_w[i];
                        beta_5_w[i+8] = beta_6_w[i];
                    end
                end
                else if(level_idx_r[9][2:0] == 7) begin
                    beta_8_w[0] = beta_9_r[0]^beta_9_w[1];
                    beta_8_w[1] = beta_9_w[1];
                    for (i=0; i<2; i=i+1) begin
                        beta_7_w[i] = beta_8_r[i]^beta_8_w[i];
                        beta_7_w[i+2] = beta_8_w[i];
                    end
                    for (i=0; i<4; i=i+1) begin
                        beta_6_w[i] = beta_7_r[i]^beta_7_w[i];
                        beta_6_w[i+4] = beta_7_w[i];
                    end
                end
                else if(level_idx_r[9][1:0] == 3) begin
                    beta_8_w[0] = beta_9_r[0]^beta_9_w[1];
                    beta_8_w[1] = beta_9_w[1];
                    for (i=0; i<2; i=i+1) begin
                        beta_7_w[i] = beta_8_r[i]^beta_8_w[i];
                        beta_7_w[i+2] = beta_8_w[i];
                    end
                end
                else if(level_idx_r[9][0] == 1) begin
                    beta_8_w[0] = beta_9_r[0]^beta_9_w[1];
                    beta_8_w[1] = beta_9_w[1];
                end
                else begin
                    // if (packets_idx_r == 29) $display(level_idx_r[level_r]);
                    beta_8_w[0] = beta_8_r[0];
                end
            end
            level_idx_w[level_r] = level_idx_r[level_r] + (512>>(level_r));
            compute_idx_w = compute_idx_r + 1;
            if (node_idx == 2 * n_r - 2) begin
                packets_idx_w = packets_idx_r + 1;
            end
            else begin
                packets_idx_w = packets_idx_r;
            end
        end
        if (level_num_r == 0) begin
            level_w = level_idx_w[9] < level_idx_w[8] ? 9 :
                level_idx_w[8] < level_idx_w[7] ? 8 :
                level_idx_w[7] < level_idx_w[6] ? 7 :
                level_idx_w[6] < level_idx_w[5] ? 6 :
                level_idx_w[5] < level_idx_w[4] ? 5 :
                level_idx_w[4] < level_idx_w[3] ? 4 :
                level_idx_w[3] < level_idx_w[2] ? 3 :
                level_idx_w[2] < level_idx_w[1] ? 2 :
                                                    1 ;
        end
        else if (level_num_r == 1) begin
            level_w = level_idx_w[9] < level_idx_w[8] ? 9 :
                level_idx_w[8] < level_idx_w[7] ? 8 :
                level_idx_w[7] < level_idx_w[6] ? 7 :
                level_idx_w[6] < level_idx_w[5] ? 6 :
                level_idx_w[5] < level_idx_w[4] ? 5 :
                level_idx_w[4] < level_idx_w[3] ? 4 :
                level_idx_w[3] < level_idx_w[2] ? 3 :
                                                    2 ;
        end
        else begin
            level_w = level_idx_w[9] < level_idx_w[8] ? 9 :
                level_idx_w[8] < level_idx_w[7] ? 8 :
                level_idx_w[7] < level_idx_w[6] ? 7 :
                level_idx_w[6] < level_idx_w[5] ? 6 :
                level_idx_w[5] < level_idx_w[4] ? 5 :
                level_idx_w[4] < level_idx_w[3] ? 4 :
                                                    3 ;
        end
        // if (packets_idx_r == 0) $display("%d, %d, %d, %d, %d,  %d, %d, %d, %d, %d, %d", level_r, level_idx_r[0], level_idx_r[1], level_idx_r[2], level_idx_r[3] , level_idx_r[4], level_idx_r[5], level_idx_r[6], level_idx_r[7],  level_idx_r[8],  level_idx_r[9]);

    end
    else if (state_r == FINISH) begin
        raddr_w = 0;
        packets_idx_w = 0;
        waddr_w = 0;
        node_idx = 0;
    end
    else begin
        compute_idx_w = 1;
        packets_idx_w = packets_idx_r;
        level_w = level_r;
        for (i=0; i<10; i=i+1) begin
            level_idx_w[i]   =  0;
            level_val_w[i]   =  0;
        end
        if(packets_idx_r < packets_num_r - 1) begin
            waddr_w = packets_idx_r + 1;
        end
        else begin
            waddr_w = packets_idx_r;
        end
        wdata_w = 0;
        num_r = 0;
        index1_r = 0;
        out_idx_w = 0;
        raddr_w = raddr_r;
        compute_fin_w = 0;
        beta_1_w             =  256'd0;
        beta_2_w             =  128'd0;
        beta_3_w             =   64'd0;
        beta_4_w             =   32'd0;
        beta_5_w             =   16'd0;
        beta_6_w             =    8'd0;
        beta_7_w             =    4'd0;
        beta_8_w             =    2'd0;
        beta_9_w             =    2'd0;
    end
end

always @(*) begin
    if (state_r == FINISH) begin
        proc_done_w = 1;
    end
    else begin
        proc_done_w = 0;
    end
end



// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        raddr_r              <=   11'd0;
        waddr_r              <=    6'd0;
        wdata_r              <=  140'd0;
        proc_done_r          <=    1'd0;
        state_r              <=    3'd0;
        n_r                  <=   10'd0;
        k_r                  <=    8'd0;
        packets_num_r        <=    7'd0;
        packets_idx_r        <=    7'd0;
        compute_idx_r        <=   11'd0;
        level_r              <=    4'd0;
        level_num_r          <=    4'd0;
        start_num_r          <=    2'd0;
        out_idx_r            <=    8'd0;
        beta_1_r             <=  256'd0;
        beta_2_r             <=  128'd0;
        beta_3_r             <=   64'd0;
        beta_4_r             <=   32'd0;
        beta_5_r             <=   16'd0;
        beta_6_r             <=    8'd0;
        beta_7_r             <=    4'd0;
        beta_8_r             <=    2'd0;
        beta_9_r             <=    2'd0;
        compute_fin_r        <=    1'd0;

        for (i=0; i<10; i=i+1) begin
            level_idx_r[i]   <=   11'd0;
            level_val_r[i]   <=  512>>i;
        end
        for (i=0; i<512; i=i+1) begin
            alpha_0_r[i]     <=   12'd0;
        end
        for (i=0; i<256; i=i+1) begin
            alpha_1_r[i]     <=   13'd0;
        end
        for (i=0; i<128; i=i+1) begin
            alpha_2_r[i]     <=   14'd0;
        end
        for (i=0; i<64; i=i+1) begin
            alpha_3_r[i]     <=   15'd0;
        end
        for (i=0; i<32; i=i+1) begin
            alpha_4_r[i]     <=   16'd0;
        end
        for (i=0; i<16; i=i+1) begin
            alpha_5_r[i]     <=   17'd0;
        end
        for (i=0; i<8; i=i+1) begin
            alpha_6_r[i]     <=   18'd0;
        end
        for (i=0; i<4; i=i+1) begin
            alpha_7_r[i]     <=   19'd0;
        end
        for (i=0; i<2; i=i+1) begin
            alpha_8_r[i]     <=   20'd0;
        end
        alpha_9_r            <=   21'd0;
    end
    else begin
        raddr_r              <=  raddr_w;
        waddr_r              <=  waddr_w;
        wdata_r              <=  wdata_w;
        proc_done_r          <=  proc_done_w;
        state_r              <=  state_w;
        n_r                  <=  n_w;
        k_r                  <=  k_w;
        packets_num_r        <=  packets_num_w;
        packets_idx_r        <=  packets_idx_w;
        compute_idx_r        <=  compute_idx_w;
        level_r              <=  level_w;
        level_num_r          <=  level_num_w;
        start_num_r          <=  start_num_w;
        out_idx_r            <=  out_idx_w;
        beta_1_r             <=  beta_1_w;
        beta_2_r             <=  beta_2_w;
        beta_3_r             <=  beta_3_w;
        beta_4_r             <=  beta_4_w;
        beta_5_r             <=  beta_5_w;
        beta_6_r             <=  beta_6_w;
        beta_7_r             <=  beta_7_w;
        beta_8_r             <=  beta_8_w;
        beta_9_r             <=  beta_9_w;
        compute_fin_r        <=  compute_fin_w;

        for (i=0; i<10; i=i+1) begin
            level_idx_r[i]   <=  level_idx_w[i];
            level_val_r[i]   <=  level_val_w[i];
        end
        for (i=0; i<512; i=i+1) begin
            alpha_0_r[i]     <=  alpha_0_w[i];
        end
        for (i=0; i<256; i=i+1) begin
            alpha_1_r[i]     <=  alpha_1_w[i];
        end
        for (i=0; i<128; i=i+1) begin
            alpha_2_r[i]     <=  alpha_2_w[i];
        end
        for (i=0; i<64; i=i+1) begin
            alpha_3_r[i]     <=  alpha_3_w[i];
        end
        for (i=0; i<32; i=i+1) begin
            alpha_4_r[i]     <=  alpha_4_w[i];
        end
        for (i=0; i<16; i=i+1) begin
            alpha_5_r[i]     <=  alpha_5_w[i];
        end
        for (i=0; i<8; i=i+1) begin
            alpha_6_r[i]     <=  alpha_6_w[i];
        end
        for (i=0; i<4; i=i+1) begin
            alpha_7_r[i]     <=  alpha_7_w[i];
        end
        for (i=0; i<2; i=i+1) begin
            alpha_8_r[i]     <=  alpha_8_w[i];
        end
        alpha_9_r            <=  alpha_9_w;
    end
end


    
endmodule