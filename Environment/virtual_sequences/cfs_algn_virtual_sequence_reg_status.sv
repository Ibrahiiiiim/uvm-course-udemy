`ifndef CFS_ALGN_VIRTUAL_SEQUENCE_REG_STATUS_SV
	`define CFS_ALGN_VIRTUAL_SEQUENCE_REG_STATUS_SV
	class cfs_algn_virtual_sequence_reg_status extends cfs_algn_virtual_sequence_base;
		
		`uvm_object_utils(cfs_algn_virtual_sequence_reg_status)
		
		function new(string name="");
			super.new(name);
		endfunction : new

		virtual task body();
			uvm_reg registers[$];
			uvm_status_e status;
			uvm_reg_data_t data;

			p_sequencer.model.reg_block.get_registers(registers);

			for (int reg_idx = registers.size() - 1; reg_idx >= 0; reg_idx--) begin
				if (!(registers[reg_idx].get_rights() inside {"RO"})) begin
					registers[reg_idx].delete();
				end
			end

			registers.shuffle();

			foreach (registers[reg_idx]) begin
				void'(registers[reg_idx].randomize());
				registers[reg_idx].read(status,data);
			end
		endtask : body
	endclass : cfs_algn_virtual_sequence_reg_status
`endif