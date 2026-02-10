`ifndef CFS_ALGN_SEQ_REG_CONFIG_SV
	`define CFS_ALGN_SEQ_REG_CONFIG_SV
	class cfs_algn_seq_reg_config extends uvm_reg_sequence;

		uvm_status_e status;
		uvm_reg_data_t data;
		int unsigned algn_data_width;
		
		cfs_algn_reg_block reg_block;

		`uvm_object_utils(cfs_algn_seq_reg_config)
		
		function new(string name="");
			super.new(name);
		endfunction : new

		virtual task body();
			
			//env.model.reg_block.CTRL.write(status,32'h00000202);
			//reg_block.CTRL.SIZE.set(2);
	       //reg_block.CTRL.OFFSET.set(2);
	       //reg_block.CTRL.update(status);


	       void'(reg_block.CTRL.randomize());
	       reg_block.CTRL.update(status);
		
		   reg_block.CTRL.read(status,data);

		endtask : body

	endclass : cfs_algn_seq_reg_config
`endif