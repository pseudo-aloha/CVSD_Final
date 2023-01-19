module function_f(
    input   [20:0]   a,
    input   [20:0]   b,
    output           sign_bit,
    output  [20:0]   result
);

wire [20:0] sum;
wire [20:0] a_inv;
wire [20:0] b_inv;

assign a_inv = (~a+1);
assign b_inv = (~b+1);

assign sum = a+b;
assign result = (~(a[20]^b[20]))? (a<b)? ((~a[20])? a: b_inv): ((~a[20])? b: a_inv)
                              : ((a == 0) || (b == 0))? 0
                              : (sum[20])? ((~a[20])? a_inv: b_inv): ((~a[20])? b: a);
assign sign_bit = ((a == 0) || (b == 0))? 0: ((~(a[20]^b[20]))? 0: 1);

endmodule