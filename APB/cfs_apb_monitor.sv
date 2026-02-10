`ifndef CFS_APB_MONITOR_SV
	`define CFS_APB_MONITOR_SV
	class cfs_apb_monitor extends uvm_ext_monitor#(.VIRTUAL_INTF(cfs_apb_vif),.ITEM_MON(cfs_apb_item_mon));

		cfs_apb_agent_config agent_config;
		

		`uvm_component_utils(cfs_apb_monitor)
		
		function new(string name="",uvm_component parent);
			super.new(name,parent);
			
		endfunction : new

		virtual function void end_of_elaboration_phase(uvm_phase phase);
			super.end_of_elaboration_phase(phase);
			if ($cast(agent_config,super.agent_config)==0) begin
				`uvm_fatal("ALGORITHM_ISSUE",$sformatf("Could not cast %0s to %0s ",super.agent_config.get_full_name(),agent_config.get_full_name()))
			end
		endfunction : end_of_elaboration_phase

		protected virtual task collect_transaction();

			cfs_apb_vif vif=agent_config.get_vif();
			cfs_apb_item_mon item;
			item=cfs_apb_item_mon::type_id::create("item");
			
			while (vif.psel !==1) begin
				@(posedge vif.pclk);
				item.prev_item_delay++;
			end

			item.addr=vif.paddr;
			item.dir=cfs_apb_dir'(vif.pwrite);
			if (item.dir==CFS_APB_WRITE) begin
				item.data=vif.pwdata;
			end

			item.length=1;

			@(posedge vif.pclk);
			item.length++;

			while(vif.pready!==1)begin
				@(posedge vif.pclk);
				item.length++;
				if(agent_config.get_stuck_threshold())begin
					if(item.length>=agent_config.get_stuck_threshold())
            			`uvm_error("PROTOCOL_ERROR", $sformatf("The APB transfer reached the stuck threshold value of %0d", item.length))
				end
				
			end
            
            item.response=cfs_apb_response'(vif.pslverr);

            if (item.dir==CFS_APB_READ) begin
            	item.data=vif.prdata;
            end

            output_port.write(item);

            `uvm_info("DEBUG",$sformatf("Monitored item : %0s",item.convert2string()),UVM_NONE)
            
            @(posedge vif.pclk);

		endtask : collect_transaction

		
	endclass : cfs_apb_monitor
`endif