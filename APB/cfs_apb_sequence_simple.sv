`ifndef CFS_APB_SEQUENCE_SIMPLE_SV
	`define CFS_APB_SEQUENCE_SIMPLE_SV
	class cfs_apb_sequence_simple extends cfs_apb_sequence_base;

		rand cfs_apb_item_drv item;

		`uvm_object_utils(cfs_apb_sequence_simple)

		function new(string name="");
			super.new(name);
			item=cfs_apb_item_drv::type_id::create("item");
		endfunction : new

		virtual task body();
			start_item(item);
			finish_item(item);
			 //An alternative with macros is to use `uvm_send().
      		//Macro `uvm_do() will not work because any constraints from sequence call will have no effect
      		//`uvm_send(item)
		endtask : body

	endclass : cfs_apb_sequence_simple
`endif