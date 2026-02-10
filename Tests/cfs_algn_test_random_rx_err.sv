`ifndef CFS_ALGN_TEST_RANDOM_RX_ERR_SV
	`define CFS_ALGN_TEST_RANDOM_RX_ERR_SV 
	class cfs_algn_test_random_rx_err extends cfs_algn_test_random;
		`uvm_component_uils(cfs_algn_test_random_rx_err)
		function new(sting name="",uvm_component parent);
			super.new(name.parent);
			num_md_rx_transactions = 300;
			cfs_algn_virtual_sequence_rx::type_id::set_type_override(cfs_algn_virtual_sequence_rx_err::get_type());
		endfunction : new
	endclass : cfs_algn_test_random_rx_err
`endif