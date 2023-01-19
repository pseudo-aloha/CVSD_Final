module function_g(
    input   [20:0]   a,
    input   [20:0]   b,
    input            u,
    output  [20:0]   result
);
assign result = (u)? (~a+1)+b: a+b;

endmodule

// a_r[i] = {{9{alpha_0_r[i][11]}}, alpha_0_r[i]};
// b_r[i] = {{9{alpha_0_r[i+(512>>(level_r))][11]}}, alpha_0_r[i+(512>>(level_r))]};
// u_r[i] = beta_r[level_r][level_idx_r[level_r]+i-(512>>(level_r))];
// alpha_1_w[i] = result2[i]
