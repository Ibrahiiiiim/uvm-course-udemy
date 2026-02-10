`ifndef CFS_ALGN_DATA_ADAPTER_SV
	`define CFS_ALGN_DATA_ADAPTER_SV

	`uvm_analysis_imp_decl(_in_agent_rx)
	`uvm_analysis_imp_decl(_in_agent_tx)

	class cfs_algn_data_adapter extends uvm_component ;
		
		uvm_analysis_imp_in_agent_rx#(cfs_md_item_mon,cfs_algn_data_adapter) port_in_agent_rx;
		uvm_analysis_imp_in_agent_tx#(cfs_md_item_mon,cfs_algn_data_adapter) port_in_agent_tx;

		uvm_analysis_port#(cfs_algn_data_item) port_out_rx;
		uvm_analysis_port#(cfs_algn_data_item) port_out_tx;

		`uvm_component_utils(cfs_algn_data_adapter)
		
		function new(string name="",uvm_component parent);
			super.new(name,parent);
			port_in_agent_rx=new("port_in_agent_rx",this);
			port_in_agent_tx=new("port_in_agent_tx",this);
			port_out_rx=new("port_out_rx",this);
			port_out_tx=new("port_out_tx",this);
		endfunction : new

		virtual function cfs_algn_data_item mon2env(cfs_md_item_mon item);
			
			cfs_algn_data_item result = cfs_algn_data_item::type_id::create("result",this);

			result.data=item.data;
			result.response=item.response;
			result.offset=item.offset;
			result.length=item.length;
			result.prev_item_delay=item.prev_item_delay;

			result.sources.push_back(item);

			return result;

		endfunction : mon2env

		virtual function void write_in_agent_rx(cfs_md_item_mon item_mon);
			if (item_mon.is_active()) begin
				port_out_rx.write(mon2env(item_mon));
			end
		endfunction : write_in_agent_rx

		virtual function void write_in_agent_tx(cfs_md_item_mon item_mon);
			if (item_mon.is_active()) begin
				port_out_tx.write(mon2env(item_mon));
			end
		endfunction : write_in_agent_tx

	endclass : cfs_algn_data_adapter
`endif