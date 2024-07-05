`timescale 1ns / 1ps

module axi_stream_insert_header #(
	parameter DATA_WD 		= 32,
	parameter DATA_BYTE_WD 	= DATA_WD / 8,
	parameter BYTE_CNT_WD 	= $clog2(DATA_BYTE_WD)
) (
	input 						clk				,
	input 						rst_n			,
	// AXI Stream input original data
	input 						valid_in		,
	input [DATA_WD-1 : 0] 		data_in			,
	input [DATA_BYTE_WD-1 : 0] 	keep_in			,
	input 						last_in			,
	output 						ready_in		,
	// AXI Stream output with header inserted
	output 						valid_out		,
	output [DATA_WD-1 : 0] 		data_out		,
	output [DATA_BYTE_WD-1 : 0] keep_out		,
	output 						last_out		,
	input 						ready_out		,
	// The header to be inserted to AXI Stream input
	input 						valid_insert	,
	input [DATA_WD-1 : 0] 		data_insert		,
	input [DATA_BYTE_WD-1 : 0] 	keep_insert		,
	input [BYTE_CNT_WD-1 : 0] 	byte_insert_cnt	,
	output 						ready_insert
);
	
	// Your code here
	/******************assign***********************************/
	assign ready_in 	  = r_ready_in				  ;
	assign ready_insert   = r_ready_insert			  ;
	assign valid_out 	  = r_valid_out				  ;
	assign data_out  	  = r_data_out 				  ;
	assign keep_out  	  = r_keep_out 				  ;
	assign last_out  	  = r_last_out 				  ;
	
	/******************parameter***********************************/	
	wire w_valid_in_pos 	  			  		 =  valid_in 	 		  && ~r_valid_in_d1 ;
	wire w_valid_in_neg 	  			  		 = ~valid_in 	 		  &&  r_valid_in_d1 ;
	wire w_ready_in_pos 	  			  		 =  ready_in 	 		  && ~r_ready_in_d  ;
	wire valid_insert_and_r_ready_insert  		 =  valid_insert 		  &&  r_ready_insert;
	wire valid_in_and_last_in 			  		 =  valid_in 	 		  &&  last_in	    ;
	wire valid_in_and_ready_in 			  		 =  valid_in 	 		  &&  ready_in	    ;
	wire w_valid_in_pos_or_w_ready_in_pos 		 =  w_valid_in_pos  	  ||  w_ready_in_pos;
	wire valid_in_and_ready_in_or_w_valid_in_neg =  valid_in_and_ready_in ||  w_valid_in_neg;
	wire [7:0] keep_insert_a_keep_in			 =  {keep_insert, keep_in}					;
	wire [7:0] keep_insert_a_r_keep_in_d		 =  {keep_insert, r_keep_in_d}				;
	
	reg 					 r_ready_in 	= 0;
	reg 					 r_ready_insert = 0;
	reg 					 r_valid_out 	= 0;
	reg [DATA_WD-1 : 0] 	 r_data_out  	= 0;
	reg [DATA_BYTE_WD-1 : 0] r_keep_out  	= 0;
	reg 					 r_last_out  	= 0;
	reg [DATA_WD-1 : 0] 	 r_data_in_d 	= 0;
	reg 					 r_valid_in_d 	= 0;
	reg 					 r_valid_in_d1 	= 0;
	reg 					 r_ready_in_d 	= 0;
	reg [DATA_BYTE_WD-1 : 0] r_keep_in_d	= 0;
	reg 					 r_last_in_d	= 0;
	
	/******************always***********************************/	
	// r_ready_insert
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_ready_insert <= 0;
		else if(ready_out)
			r_ready_insert <= 1'b1;
		else if(valid_insert_and_r_ready_insert)
			r_ready_insert <= 0;
	end
	
	// r_ready_in
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_ready_in <= 0;
		else if(valid_insert_and_r_ready_insert)
			r_ready_in <= 1'b1;
		else if(valid_in_and_last_in)
			r_ready_in <= 0;
	end
	
	// r_data_in_d
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_data_in_d <= 0;
		else
			r_data_in_d <= data_in;
	end
	
	// r_valid_in_d
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_valid_in_d <= 0;
		else
			r_valid_in_d <= valid_in;
	end
	
	// r_valid_in_d1
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_valid_in_d1 <= 0;
		else
			r_valid_in_d1 <= r_valid_in_d;
	end
	
	// r_ready_in_d
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_ready_in_d <= 0;
		else
			r_ready_in_d <= ready_in;
	end
	
	// r_data_out
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_data_out <= 0;
		else if(valid_in_and_ready_in_or_w_valid_in_neg)
			case(keep_insert)
			4'b1111:begin
				if(w_valid_in_pos_or_w_ready_in_pos)
					r_data_out <= data_insert;
				else
					r_data_out <= r_data_in_d;
			end
			4'b0111:begin
				if(w_valid_in_pos_or_w_ready_in_pos)
					r_data_out <= {data_insert[DATA_WD-9 : 0], data_in[DATA_WD-1 : 24]};
				else
					r_data_out <= {r_data_in_d[DATA_WD-9 : 0], data_in[DATA_WD-1 : 24]};
			end
			4'b0011:begin
				if(w_valid_in_pos_or_w_ready_in_pos)
					r_data_out <= {data_insert[DATA_WD-17 : 0], data_in[DATA_WD-1 : 16]};
				else
					r_data_out <= {r_data_in_d[DATA_WD-17 : 0], data_in[DATA_WD-1 : 16]};
			end
			4'b0001:begin
				if(w_valid_in_pos_or_w_ready_in_pos)
					r_data_out <= {data_insert[DATA_WD-25 : 0], data_in[DATA_WD-1 : 8]};
				else
					r_data_out <= {r_data_in_d[DATA_WD-25 : 0], data_in[DATA_WD-1 : 8]};
			end
			endcase
		else
			r_data_out <= 0;
	end
	
	// r_keep_in_d
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_keep_in_d <= 0;
		else
			r_keep_in_d <= keep_in;
	end
	
	// r_valid_out
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_valid_out <= 0;
		else if(w_valid_in_neg)
		begin
			case({keep_insert, r_keep_in_d})
				8'b1111_1111: r_valid_out <= 1'b1;
				8'b1111_1110: r_valid_out <= 1'b1;
				8'b1111_1100: r_valid_out <= 1'b1;
				8'b1111_1000: r_valid_out <= 1'b1;
				8'b0111_1111: r_valid_out <= 1'b1;
				8'b0111_1110: r_valid_out <= 1'b1;
				8'b0111_1100: r_valid_out <= 1'b1;
				8'b0111_1000: r_valid_out <= 1'b0;
				8'b0011_1111: r_valid_out <= 1'b1;
				8'b0011_1110: r_valid_out <= 1'b1;
				8'b0011_1100: r_valid_out <= 1'b0;
				8'b0011_1000: r_valid_out <= 1'b0;
				8'b0001_1111: r_valid_out <= 1'b1;
				8'b0001_1110: r_valid_out <= 1'b0;
				8'b0001_1100: r_valid_out <= 1'b0;
				8'b0001_1000: r_valid_out <= 1'b0;
			endcase
		end
		else if(valid_in_and_ready_in)
			 r_valid_out <= 1'b1;
		else
			 r_valid_out <= 1'b0;
	end
	
	// r_last_in_d
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_last_in_d <= 0;
		else
			r_last_in_d <= last_in;
	end
	
	// r_keep_out
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_keep_out <= 0;
		else if(r_last_in_d)
			case({keep_insert, keep_in})
				8'b0111_1000: r_keep_out <= 4'b1111;
				8'b0011_1100: r_keep_out <= 4'b1111;
				8'b0011_1000: r_keep_out <= 4'b1110;
				8'b0001_1110: r_keep_out <= 4'b1111;
				8'b0001_1100: r_keep_out <= 4'b1110;
				8'b0001_1000: r_keep_out <= 4'b1100;
			endcase
		else if(w_valid_in_neg)
			case({keep_insert, r_keep_in_d})
				8'b1111_1111: r_keep_out <= 4'b1111;
				8'b1111_1110: r_keep_out <= 4'b1110;
				8'b1111_1100: r_keep_out <= 4'b1100;
				8'b1111_1000: r_keep_out <= 4'b1000;
				8'b0111_1111: r_keep_out <= 4'b1110;
				8'b0111_1110: r_keep_out <= 4'b1100;
				8'b0111_1100: r_keep_out <= 4'b1000;
				8'b0011_1111: r_keep_out <= 4'b1100;
				8'b0011_1110: r_keep_out <= 4'b1000;
				8'b0001_1111: r_keep_out <= 4'b1000;
			endcase
		else if(valid_in_and_ready_in)
			 r_keep_out <= 4'b1111;
		else
			r_keep_out <= 0;
	end
	
	// r_last_out
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_last_out <= 0;
		else if(r_last_in_d)
			case({keep_insert, keep_in})
				8'b0111_1000: begin r_last_out <= 1'b1; end
				8'b0011_1100: begin r_last_out <= 1'b1; end
				8'b0011_1000: begin r_last_out <= 1'b1; end
				8'b0001_1110: begin r_last_out <= 1'b1; end
				8'b0001_1100: begin r_last_out <= 1'b1; end
				8'b0001_1000: begin r_last_out <= 1'b1; end
			endcase
		else if(w_valid_in_neg)
			case({keep_insert, r_keep_in_d})
				8'b1111_1111: begin r_last_out <= 1'b1; end
				8'b1111_1110: begin r_last_out <= 1'b1; end
				8'b1111_1100: begin r_last_out <= 1'b1; end
				8'b1111_1000: begin r_last_out <= 1'b1; end
				8'b0111_1111: begin r_last_out <= 1'b1; end
				8'b0111_1110: begin r_last_out <= 1'b1; end
				8'b0111_1100: begin r_last_out <= 1'b1; end
				8'b0011_1111: begin r_last_out <= 1'b1; end
				8'b0011_1110: begin r_last_out <= 1'b1; end
				8'b0001_1111: begin r_last_out <= 1'b1; end
			endcase
		else
			r_last_out <= 0;
	end


	
	
	
endmodule
