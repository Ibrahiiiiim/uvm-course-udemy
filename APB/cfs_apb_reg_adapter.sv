`ifndef CFS_APB_REG_ADAPTER_SV
	`define CFS_APB_REG_ADAPTER_SV
	class cfs_apb_reg_adapter extends uvm_reg_adapter;
		
		`uvm_object_utils(cfs_apb_reg_adapter)
		
		function new(string name="");
			super.new(name);
		endfunction : new
		
		virtual function void bus2reg(uvm_sequence_item bus_item ,ref uvm_reg_bus_op rw);
			
			cfs_apb_item_mon item_mon;
			
			cfs_apb_item_drv item_drv;
			
			if ($cast(item_mon,bus_item)) begin
				rw.kind = item_mon.dir==CFS_APB_WRITE ? UVM_WRITE : UVM_READ;
				rw.addr = item_mon.addr;
				rw.data = item_mon.data;
				rw.status = item_mon.response==CFS_APB_OKAY? UVM_IS_OK : UVM_NOT_OK;
			end
			else if ($cast(item_drv,bus_item)) begin
				rw.kind=(item_drv.dir==CFS_APB_WRITE)? UVM_WRITE : UVM_READ;
				rw.addr=item_drv.addr;
				rw.data=item_drv.data;
				rw.status=UVM_IS_OK;//We set rw.status = UVM_IS_OK for item_drv because the driver does not know the real bus response, so it can only report that the transaction was issued, not whether it actually succeeded.
			end
			else begin
				`uvm_fatal("ALGORITHM_ISSUE",$sformatf("class type not supported :%0s",bus_item.get_full_name()));
			end
		endfunction : bus2reg

		virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
			
			cfs_apb_item_drv item = cfs_apb_item_drv::type_id::create("item");
			
			//We use randomize() in reg2bus() not to randomize the register operation,
			// but to randomize the bus behavior while keeping the register semantics fixed.
			void'(item.randomize() with {
				item.dir  == (rw.kind == UVM_WRITE) ? CFS_APB_WRITE : CFS_APB_READ;
				item.data == rw.data;
				item.addr == rw.addr;
				} );

			return item;
		endfunction : reg2bus
	endclass : cfs_apb_reg_adapter
`endif