code for CORDIC Algorithm from  https://zipcpu.com/dsp/2017/08/30/cordic.html

wire	signed [(WW-1):0]	e_xval, e_yval;
assign	e_xval = { {i_xval[(IW-1)]}, i_xval, {(WW-IW-1){1'b0}} };
assign	e_yval = { {i_yval[(IW-1)]}, i_yval, {(WW-IW-1){1'b0}} };

// Declare variables for all of the separate stages
reg	signed	[(WW-1):0]	xv	[0:(NSTAGES)];
reg	signed	[(WW-1):0]	yv	[0:(NSTAGES)];
reg		[(PW-1):0]	ph	[0:(NSTAGES)];


always @(posedge i_clk)
if (i_ce)

case(i_phase[(PW-1):(PW-3)])
3'b000: begin	// 0 .. 45, No change
		xv[0] <= e_xval;
		yv[0] <= e_yval;
		ph[0] <= i_phase;
		end
	3'b001: begin	// 45 .. 90
		xv[0] <= -e_yval;
		yv[0] <= e_xval;
		ph[0] <= i_phase - 18'h10000;
		end
	3'b010: begin	// 90 .. 135
		xv[0] <= -e_yval;
		yv[0] <= e_xval;
		ph[0] <= i_phase - 18'h10000;
		end
	3'b011: begin	// 135 .. 180
		xv[0] <= -e_xval;
		yv[0] <= -e_yval;
		ph[0] <= i_phase - 18'h20000;
		end
	3'b100: begin	// 180 .. 225
		xv[0] <= -e_xval;
		yv[0] <= -e_yval;
		ph[0] <= i_phase - 18'h20000;
		end
	3'b101: begin	// 225 .. 270
		xv[0] <= e_yval;
		yv[0] <= -e_xval;
		ph[0] <= i_phase - 18'h30000;
		end
	3'b110: begin	// 270 .. 315
		xv[0] <= e_yval;
		yv[0] <= -e_xval;
		ph[0] <= i_phase - 18'h30000;
		end
	3'b111: begin	// 315 .. 360, No change
		xv[0] <= e_xval;
		yv[0] <= e_yval;
		ph[0] <= i_phase;
		end
	endcase
  
  genvar	i;
generate for(i=0; i<NSTAGES; i=i+1) begin : CORDICops

always @(posedge i_clk)
	// Reset logic can be placed here, but it isnt required
	if (i_ce)
	begin
  
  // You can check for cord[i] == 0 here if you would like
		if (ph[i][(PW-1)]) // Negative phase
		begin
			// If the phase is negative, rotate by the
			// CORDIC angle in a clockwise direction.
			xv[i+1] <= xv[i] + (yv[i]>>>(i+1));
			yv[i+1] <= yv[i] - (xv[i]>>>(i+1));
			ph[i+1] <= ph[i] + cordic_angle[i];

		end else begin
			// On the other hand, if the phase is
			// positive ... rotate in the
			// counter-clockwise direction
			xv[i+1] <= xv[i] - (yv[i]>>>(i+1));
			yv[i+1] <= yv[i] + (xv[i]>>>(i+1));
			ph[i+1] <= ph[i] - cordic_angle[i];

		end
	end
endgenerate

for(unsigned k=0; k<(unsigned)nstages; k++) {
	double		x, deg;
	unsigned	phase_value;
  
  x = atan2(1., pow(2,k));
  
  deg = x * 180.0 / M_PI;
  
  x *= (4.0 * (1ul<<(phase_bits-2))) / (M_PI * 2.0);
	phase_value = (unsigned)x;
  
  fprintf(fp, "\tassign\tcordic_angle[%2d] = %2d\'h%0*x; //%11.6f deg\n",
		k, phase_bits, (phase_bits+3)/4, phase_value,
		deg);
}

assign	cordic_angle[ 0] = 18'h0_4b90; //  26.565051 deg
assign	cordic_angle[ 1] = 18'h0_27ec; //  14.036243 deg
assign	cordic_angle[ 2] = 18'h0_1444; //   7.125016 deg
assign	cordic_angle[ 3] = 18'h0_0a2c; //   3.576334 deg
assign	cordic_angle[ 4] = 18'h0_0517; //   1.789911 deg
assign	cordic_angle[ 5] = 18'h0_028b; //   0.895174 deg
assign	cordic_angle[ 6] = 18'h0_0145; //   0.447614 deg
assign	cordic_angle[ 7] = 18'h0_00a2; //   0.223811 deg
assign	cordic_angle[ 8] = 18'h0_0051; //   0.111906 deg
assign	cordic_angle[ 9] = 18'h0_0028; //   0.055953 deg
assign	cordic_angle[10] = 18'h0_0014; //   0.027976 deg
assign	cordic_angle[11] = 18'h0_000a; //   0.013988 deg
assign	cordic_angle[12] = 18'h0_0005; //   0.006994 deg
assign	cordic_angle[13] = 18'h0_0002; //   0.003497 deg

always @(posedge i_clk)
	if (i_reset)
		ax <= {(NSTAGES+1){1'b0}};
	else if (i_ce)
		ax <= { ax[(NSTAGES-1):0], i_aux };

always @(posedge i_clk)
	o_aux <= ax[NSTAGES];
  
  // Round our result towards even
	wire	[(WW-1):0]	pre_xval, pre_yval;

	assign	pre_xval = xv[NSTAGES] + {{(OW){1'b0}},
				xv[NSTAGES][(WW-OW)],
				{(WW-OW-1){!xv[NSTAGES][WW-OW]}}};
	assign	pre_yval = yv[NSTAGES] + {{(OW){1'b0}},
				yv[NSTAGES][(WW-OW)],
				{(WW-OW-1){!yv[NSTAGES][WW-OW]}}};

	always @(posedge i_clk)
	begin
		o_xval <= pre_xval[(WW-1):(WW-OW)];
		o_yval <= pre_yval[(WW-1):(WW-OW)];
	end
  
  double	cordic_gain(int nstages, int phase_bits) {
	double	gain = 1.0;

	for(int k=0; k<nstages; k++) {
		double		dgain;

		dgain = 1.0 + pow(2.0,-2.*(k));
		dgain = sqrt(dgain);
		gain = gain * dgain;
	}

	return gain;
}
// Gain is 1.646760
// You can annihilate this gain by multiplying by 32'h9b74edae
// and right shifting by 32 bits.
