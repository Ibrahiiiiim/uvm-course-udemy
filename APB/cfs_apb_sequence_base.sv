`ifndef CFS_APB_SEQUENCE_BASE
	`define CFS_APB_SEQUENCE_BASE
	class cfs_apb_sequence_base extends uvm_sequence #(.REQ(cfs_apb_item_drv));


		`uvm_declare_p_sequencer(uvm_ext_sequencer#(.ITEM_DRV(cfs_apb_item_drv)))

		`uvm_object_utils(cfs_apb_sequence_base)


		function new (string name="");
			super.new(name);
		endfunction : new
		
	endclass : cfs_apb_sequence_base
`endif