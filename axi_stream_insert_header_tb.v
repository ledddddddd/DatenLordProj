`timescale 1ns / 1ps

module axi_stream_insert_header_tb;
	
	parameter DATA_WD 		= 32				  ;
	parameter DATA_BYTE_WD 	= DATA_WD / 8	  	  ;
	parameter BYTE_CNT_WD 	= $clog2(DATA_BYTE_WD);
	
	reg 						clk				= 0;
	reg 						rst_n			= 0;
	// AXI Stream input original data
	reg 						valid_in		= 0;
	reg [DATA_WD-1 : 0] 		data_in			= 0;
	reg [DATA_BYTE_WD-1 : 0] 	keep_in			= 0;
	reg 						last_in			= 0;
	wire 						ready_in		   ;
	// AXI Stream output with header inserted
	wire 						valid_out		   ;
	wire [DATA_WD-1 : 0] 		data_out		   ;
	wire [DATA_BYTE_WD-1 : 0] 	keep_out		   ;
	wire 						last_out		   ;
	reg 						ready_out		= 0;
	// The header to be inserted to AXI Stream input
	reg 						valid_insert	= 0;
	reg [DATA_WD-1 : 0] 		data_insert		= 0;
	reg [DATA_BYTE_WD-1 : 0] 	keep_insert		= 0;
	reg [BYTE_CNT_WD-1 : 0] 	byte_insert_cnt	= 0;
	wire 						ready_insert	   ;

	axi_stream_insert_header #(
		.DATA_WD 	 (DATA_WD	  ),
		.DATA_BYTE_WD(DATA_BYTE_WD),
		.BYTE_CNT_WD (BYTE_CNT_WD )
	) axi_stream_insert_header(
		.clk			(clk  )			 ,
		.rst_n			(rst_n)			 ,
		// AXI Stream input original data
		.valid_in		(valid_in)		 ,
		.data_in		(data_in )		 ,
		.keep_in		(keep_in )		 ,
		.last_in		(last_in )		 ,
		.ready_in		(ready_in)		 ,
		// AXI Stream output with header inserted
		.valid_out		(valid_out	)	 ,
		.data_out		(data_out	)	 ,
		.keep_out		(keep_out	)	 ,
		.last_out		(last_out	)	 ,
		.ready_out		(ready_out	)	 ,
		// The header to be inserted to AXI Stream input
		.valid_insert	(valid_insert	),
		.data_insert	(data_insert	),
		.keep_insert	(keep_insert	),
		.byte_insert_cnt(byte_insert_cnt),
		.ready_insert   (ready_insert   )
	);
	
	wire valid_insert_and_ready_insert = valid_insert && ready_insert;
	
	integer valid_in_fid;
	integer last_in_fid;
	integer ready_out_fid;
	integer valid_insert_fid;
	
	initial begin
		valid_in_fid = $fopen("E:/Practice/DatenLord/DatenLordProj/DatenLordProj.srcs/sim_1/data_sim/valid_in.txt", "r");
		last_in_fid = $fopen("E:/Practice/DatenLord/DatenLordProj/DatenLordProj.srcs/sim_1/data_sim/last_in.txt", "r");
		ready_out_fid = $fopen("E:/Practice/DatenLord/DatenLordProj/DatenLordProj.srcs/sim_1/data_sim/ready_out.txt", "r");
		valid_insert_fid = $fopen("E:/Practice/DatenLord/DatenLordProj/DatenLordProj.srcs/sim_1/data_sim/valid_insert.txt", "r");
	end
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			valid_in <= 0;
		else
			$fscanf(valid_in_fid, "%d", valid_in);
	end
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			data_in <= 0;
		else if(valid_in)
			data_in <= {$random} % 32'hffff_ffff;
		else
			data_in <= 0;
	end
	
	always @(*)
	begin
		if(!rst_n)
			keep_in <= 0;
		else if(last_in)
			keep_in <= 4'b1110;
		else if(valid_in)
			keep_in <= 4'b1111;
		else
			keep_in <= 0;
	end
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			last_in <= 0;
		else
			$fscanf(last_in_fid, "%d", last_in);
	end
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			ready_out <= 0;
		else
			$fscanf(ready_out_fid, "%d", ready_out);
	end
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			valid_insert <= 0;
		else
			$fscanf(valid_insert_fid, "%d", valid_insert);
	end
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			keep_insert <= 0;
		else if(valid_insert)
			keep_insert <= 4'b0011;
		else
			keep_insert <= 0;
	end
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			byte_insert_cnt <= 0;
		else if(valid_insert)
			case(keep_insert)
				4'b1111: begin byte_insert_cnt <= 2'd3; end
				4'b0111: begin byte_insert_cnt <= 2'd2; end
				4'b0011: begin byte_insert_cnt <= 2'd1; end
				4'b0001: begin byte_insert_cnt <= 2'd0; end
			endcase
	end
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			data_insert <= 0;
		else if(valid_insert_and_ready_insert)
			data_insert <= {$random} % 32'hffff_ffff;
	end
	
	initial begin
		clk   = 0;
		rst_n = 0;
		
		#100;
		rst_n = 1;
	end
	
	always #1 clk <= ~clk;
	

endmodule
