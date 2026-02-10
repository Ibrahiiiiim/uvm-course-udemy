`ifndef CFS_MD_IF_SV
	`define CFS_MD_IF_SV
	interface cfs_md_if #(int unsigned DATA_WIDTH=32)(input clk);

		localparam OFFSET_WIDTH = $clog2(DATA_WIDTH/8) < 1 ? 1 : $clog2(DATA_WIDTH/8);

		localparam SIZE_WIDTH = $clog2(DATA_WIDTH/8) + 1;

		logic reset_n;
		logic valid;
		logic[DATA_WIDTH-1:0] data;
		logic [OFFSET_WIDTH-1:0] offset;
		logic[SIZE_WIDTH-1:0] size;
		logic ready;
		logic err;
		bit has_checks;
		initial begin
			has_checks=1;
		end

		//initial begin
			//if ($countones(DATA_WIDTH)!=1) begin
				//$error($sformatf("DATA_WIDTH is not a power of two - value in binary:'b%0b, in hex:'h%0h, in decimal: %0d",DATA_WIDTH,DATA_WIDTH,DATA_WIDTH));//for questasim simulator and synopsys tools.
			//end

    	if($log10(DATA_WIDTH)/$log10(2) - $clog2(DATA_WIDTH) != 0) begin
      		$error("DATA_WIDTH is not a power of two - value in binary: 'b%0b, in hex is 'h%0h, in dec is %0d", DATA_WIDTH, DATA_WIDTH, DATA_WIDTH);
		
      	end
		//end
		/*What is elaboration?

Before simulation starts, the tool does:

Build the design hierarchy

Instantiate modules and interfaces

Set parameters

Allocate signals

Prepare everything for simulation

This stage is called elaboration.

If you put code outside an initial block, it runs during elaboration, not during simulation.


Why is that better?

Because:

If the data width is invalid,

They want to fail before simulation starts,

Not after time 0.

This stops the user from running a whole simulation with a broken configuration.

In one sentence:

Moving the data-width check outside the initial block makes the simulator run the check during elaboration (when the interface is instantiated), which stops the simulation immediately if the width is invalid.*/

		if (DATA_WIDTH<8) begin
			$error("DATA_WIDTH must be bigger than or equal to 8 but the detected value is %0d ",DATA_WIDTH);
		end

		property valid_high_until_ready_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			$fell(valid) |-> $past(ready)==1;
		endproperty

		VALID_HIGH_UNTIL_READY_A :assert property(valid_high_until_ready_p) else
			$error("valid signal didn't stay high until ready becomes high ");

		property unknown_value_data_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid |-> $isunknown(data)==0;
		endproperty
		
		UNKNOWN_VALUE_DATA_A :assert property(unknown_value_data_p)else
			$error("Detected unknown value for MD signal data");

		property stable_data_untile_ready_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid & $past(valid) & !$past(ready) |-> $stable(data)==1;
		endproperty

		STABLE_DATA_UNTILE_READY_A :assert property(stable_data_untile_ready_p)else
			$error("data signal didn't remain stable untile the end of the transfer");

		property unknown_value_offset_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid |-> $isunknown(offset)==0;
		endproperty
		
		UNKNOWN_VALUE_OFFSET_A :assert property(unknown_value_offset_p)else
			$error("Detected unknown value for MD signal offset");

		property stable_offset_untile_ready_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid & $past(valid) & !$past(ready) |-> $stable(offset)==1;
		endproperty

		STABLE_OFFSET_UNTILE_READY_A :assert property(stable_offset_untile_ready_p)else
			$error("offset signal didn't remain stable untile the end of the transfer");



		property unknown_value_size_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid |-> $isunknown(size)==0;
		endproperty
		
		UNKNOWN_VALUE_SIZE_A :assert property(unknown_value_size_p)else
			$error("Detected unknown value for MD signal size");


		property stable_size_untile_ready_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid & $past(valid) & !$past(ready) |-> $stable(size)==1;
		endproperty

		STABLE_SIZE_UNTILE_READY_A :assert property(stable_size_untile_ready_p)else
			$error("size signal didn't remain stable untile the end of the transfer");


		property size_eq_0_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid |-> size !=0;
		endproperty

		SIZE_EQ_0_A :assert property(size_eq_0_p)else
			$error("Detected value 0 for MD signal size");


		property unknown_value_err_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid & ready|-> $isunknown(err)==0;
		endproperty
		
		UNKNOWN_VALUE_ERR_A :assert property(unknown_value_err_p)else
			$error("Detected unknown value for MD signal err");

		property err_high_at_valid_and_ready_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			err |-> valid & ready;//when err high check valid and ready and this is logical as valid is high before err is high 
		endproperty
		
		ERR_HIGH_AT_VALID_AND_READY_A :assert property(err_high_at_valid_and_ready_p)else
			$error("Detected err signal when ready & valid !=1");


		property unknown_value_valid_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			$isunknown(valid)==0;
		endproperty
		
		UNKNOWN_VALUE_VALID_A :assert property(unknown_value_valid_p)else
			$error("Detected unknown value for MD signal valid");



		property unknown_value_ready_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid |-> $isunknown(ready)==0;
		endproperty
		
		UNKNOWN_VALUE_READY_A :assert property(unknown_value_ready_p)else
			$error("Detected unknown value for MD signal ready");

		property size_plus_offset_gt_data_width_p;
			@(posedge clk) disable iff(!reset_n || !has_checks)
			valid |-> offset + size <= (DATA_WIDTH/8);
		endproperty
		
		SIZE_PLUS_OFFSET_GT_DATA_WIDTH_A :assert property(size_plus_offset_gt_data_width_p)else
			$error("Detected that size + offset is greater than the data width ,in bytes");


	endinterface : cfs_md_if
`endif