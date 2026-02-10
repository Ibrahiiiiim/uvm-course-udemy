`ifndef CFS_APB_REG_PREDICTOR_SV
	`define CFS_APB_REG_PREDICTOR_SV
	class cfs_algn_reg_predictor#( type BUSTYPE = uvm_sequence_item ) extends uvm_reg_predictor#(.BUSTYPE(BUSTYPE));
		
		cfs_algn_env_config env_config;

		`uvm_component_param_utils(cfs_algn_reg_predictor#(BUSTYPE))
		
		function new(string name="",uvm_component parent);
			super.new(name,parent);
		endfunction : new

		protected virtual function uvm_reg_data_t get_reg_field_value(uvm_reg_field reg_field,uvm_reg_data_t reg_data);
			uvm_reg_data_t mask =(('h1 << reg_field.get_n_bits())-1) << reg_field.get_lsb_pos();
			return ( mask & reg_data ) >> reg_field.get_lsb_pos;
		endfunction : get_reg_field_value

		protected function cfs_algn_reg_access_status_info get_expected_response(uvm_reg_bus_op operation);
			
			uvm_reg register;

			register = map.get_reg_by_offset(operation.addr,(operation.kind==UVM_READ));

			if (register==null) begin
				return cfs_algn_reg_access_status_info::new_instance(UVM_NOT_OK,"access to a location on which no register is mapped");
			end

			if (operation.kind==UVM_WRITE) begin
				uvm_reg_map_info info = map.get_reg_map_info(register);
				if (info.rights=="RO") begin
				 	return cfs_algn_reg_access_status_info::new_instance(UVM_NOT_OK,"write access to a fully read_only register");
				 end 
			end

			if (operation.kind==UVM_READ) begin
				uvm_reg_map_info info = map.get_reg_map_info(register);
				if (info.rights=="WO") begin
				 	return cfs_algn_reg_access_status_info::new_instance(UVM_NOT_OK,"read access to a fully write_only register");
				 end 
			end

			if (operation.kind==UVM_WRITE) begin
				cfs_algn_reg_ctrl ctrl;
				if ($cast(ctrl,register)) begin
					uvm_reg_data_t size_value=get_reg_field_value(ctrl.SIZE,operation.data);
					uvm_reg_data_t offset_value=get_reg_field_value(ctrl.OFFSET,operation.data);

					if (size_value==0) begin
						return cfs_algn_reg_access_status_info::new_instance(UVM_NOT_OK,"write value 0 to ctrl.size");
					end

					if(((env_config.get_algn_data_width() / 8) + offset_value) % size_value != 0) begin
              			return cfs_algn_reg_access_status_info::new_instance(UVM_NOT_OK, $sformatf("Illegal access to CTRL - OFFSET: %0d, SIZE: %0d, aligner data width: %0d",offset_value, size_value, env_config.get_algn_data_width()));
          			end

          			if( offset_value + size_value > (env_config.get_algn_data_width() / 8)) begin
              			return cfs_algn_reg_access_status_info::new_instance(UVM_NOT_OK, $sformatf("Illegal access to CTRL -> OFFSET (%0d) + SIZE (%0d) > aligner data width: %0d",offset_value, size_value, env_config.get_algn_data_width()));
          			end
				end
			end
			return cfs_algn_reg_access_status_info::new_instance(UVM_NOT_OK,"All is ok");
		endfunction : get_expected_response
      
		virtual function void write(BUSTYPE tr);
			uvm_reg_bus_op operation;
			
			adapter.bus2reg(tr,operation);

			if (env_config.get_has_checks()) begin
				cfs_algn_reg_access_status_info exp_response=get_expected_response(operation);

				if (exp_response.status != operation.status) begin
					`uvm_error("DUT_ERROR",$sformatf("mismatched detected for the bus operation status - expected : %0s, received :%0s on access: %0s - reason:%0s",exp_response.status.name(),operation.status.name(),tr.convert2string(),exp_response.info))
				end
			end

			if(operation.status==UVM_IS_OK)begin
				super.write(tr);//basically this write is responible for receiving the transaction for the DUT.
			end
		endfunction : write
	
	endclass : cfs_algn_reg_predictor
`endif
        



		