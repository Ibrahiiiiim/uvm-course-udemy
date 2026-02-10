`ifndef CFS_ALGN_ENV_CONFIG_SV
	`define CFS_ALGN_ENV_CONFIG_SV
	class cfs_algn_env_config extends uvm_component;
		
		protected cfs_algn_vif vif;

		local bit has_checks;

		local bit has_coverage;

		local int unsigned algn_data_width;

		local int unsigned exp_rx_response_threshold;

		local int unsigned exp_tx_item_threshold;

		local int unsigned exp_irq_threshold;

		`uvm_component_utils(cfs_algn_env_config)

		function new(string name="",uvm_component parent);
			super.new(name,parent);
			has_checks=1;
			has_coverage=1;
			algn_data_width=8;
			exp_rx_response_threshold=10;
			exp_tx_item_threshold=10;
			exp_irq_threshold=10;
		endfunction : new


		virtual function bit get_has_checks();
			return has_checks;
		endfunction : get_has_checks

		virtual function void set_has_checks(bit value);
			has_checks=value;
		endfunction : set_has_checks

		virtual function bit get_has_coverage();
			return has_coverage;
		endfunction : get_has_coverage

		virtual function void set_has_coverage(bit value);
			has_coverage=value;
		endfunction : set_has_coverage

		virtual function int unsigned get_algn_data_width();
			return algn_data_width;
		endfunction : get_algn_data_width

		virtual function void set_algn_data_width(int unsigned value);
			if (value < 8) begin
				`uvm_fatal("ALGORITHM_ISSUE",$sformatf("the minimum value for algn_data_width is 8 but the user have tried to put %0d",value))
			end

			if ($countones(value) != 1) begin
				`uvm_fatal("ALGORITHM_ISSUE",$sformatf("the value for algn_data_width must be a power of 2 but the user have tried to put %0d",value))
			end
			algn_data_width=value;
		endfunction : set_algn_data_width

		virtual function cfs_algn_vif get_vif();
			return vif;
		endfunction : get_vif

		virtual function void set_vif(cfs_algn_vif value);
			if (vif==null) begin
				vif=value;
			end
			else begin
				`uvm_fatal("ALGORITHM_ISSUE","Tring to set virtual interface more than once")
			end
		endfunction : set_vif

		virtual function int unsigned get_exp_rx_response_threshold();
			return exp_rx_response_threshold;
		endfunction : get_exp_rx_response_threshold
		
		virtual function void set_exp_rx_response_threshold(int unsigned value);
			exp_rx_response_threshold=value;
		endfunction : set_exp_rx_response_threshold

		virtual function int unsigned get_exp_tx_item_threshold();
			return exp_tx_item_threshold;
		endfunction : get_exp_tx_item_threshold

		virtual function void set_exp_tx_item_threshold(int unsigned value);
			exp_tx_item_threshold=value;
		endfunction : set_exp_tx_item_threshold


		virtual function int unsigned get_exp_irq_threshold();
			return exp_irq_threshold;
		endfunction : get_exp_irq_threshold

		virtual function void set_exp_irq_threshold(int unsigned value);
			exp_irq_threshold=value;
		endfunction : set_exp_irq_threshold

		virtual function void start_of_simulation_phase(uvm_phase phase);
			super.start_of_simulation_phase(phase);
			if (get_vif()==null) begin
				`uvm_fatal("ALGORITHM_ISSUE","The aligner virtual interface is not configured at \"start of simulation\"phase")
			end
			else begin
				`uvm_info("CONFIG","the aligner virtual interface is configured at \"start of simulation\" phase",UVM_FULL)
			end
		endfunction : start_of_simulation_phase

	endclass : cfs_algn_env_config
`endif
