`ifndef CFS_ALGN_SCOREBOARD_SV
	`define CFS_ALGN_SCOREBOARD_SV

	`uvm_analysis_imp_decl(in_model_rx)
	`uvm_analysis_imp_decl(in_model_tx)
	`uvm_analysis_imp_decl(in_model_irq)
	`uvm_analysis_imp_decl(in_adapter_rx)
	`uvm_analysis_imp_decl(in_adapter_tx)

	class cfs_algn_scoreboard extends uvm_component implements uvm_ext_reset_handler;

		cfs_algn_env_config env_config;

		uvm_analysis_imp_in_model_rx#(cfs_md_response,cfs_algn_scoreboard) port_in_model_rx;
		uvm_analysis_imp_in_model_tx#(cfs_algn_data_item,cfs_algn_scoreboard) port_in_model_tx;
		uvm_analysis_imp_in_model_irq#(bit,cfs_algn_scoreboard) port_in_model_irq;
		uvm_analysis_imp_in_adapter_rx#(cfs_algn_data_item,cfs_algn_scoreboard) port_in_adapter_rx;
		uvm_analysis_imp_in_adapter_tx#(cfs_algn_data_item,cfs_algn_scoreboard) port_in_adapter_tx;

		protected cfs_md_response exp_rx_responses[$];

		protected cfs_algn_data_item exp_tx_items[$];

		protected bit exp_irqs[$];

		local process process_exp_rx_response_watchdog[$];

		local process process_exp_tx_item_watchdog[$];

		local process process_exp_irq_watchdog[$];
		
		local process process_rcv_irq;

		`uvm_component_utils(cfs_algn_scoreboard)
	
		function new(string name="",uvm_component parent);
			super.new(name,parent);
			port_in_model_rx=new("port_in_model_rx",this);
			port_in_model_tx=new("port_in_model_tx",this);
			port_in_model_irq=new("port_in_model_irq",this);
			port_in_adapter_rx=new("port_in_adapter_rx",this);
			port_in_adapter_tx=new("port_in_adapter_tx",this);
		endfunction : new
	
		virtual function void handle_reset(uvm_phase phase);
			exp_rx_responses.delete();
			exp_tx_responses.delete();
			exp_irqs.delete();
			kill_processes_from_queue(process_exp_rx_response_watchdog[$]);
			kill_processes_from_queue(process_exp_tx_item_watchdog[$]);
			kill_processes_from_queue(process_exp_irq_watchdog[$]);
			if (process_rcv_irq!=null) begin
				process_rcv_irq.kill();
				process_rcv_irq=null;
			end
			rcv_irq_nb();
		endfunction : handle_reset

		virtual function void kill_processes_from_queue(ref process processes[$]);
			while(processes.size()>0)begin
				processes[0].kill();

				void'(processes.pop_front());
			end
		endfunction : kill_processes_from_queue

		protected virtual task exp_rx_response_watchdog(cfs_md_response response);
			cfs_algn_vif vif=env_config.get_vif();
			int unsigned threshold=env_config.get_exp_rx_response_threshold();
			time start_time =$time();
			repeat(threshold)begin
				@(posedge vif.clk)
			end

			if (env_config.get_has_checks()) begin
				`uvm_error("DUT_ERROR",$sformatf("the rx response,with the value %0s,expected in time %0t,was not received after %0d clock cycles ",response.name(),start_time,threshold)
			end

		endtask : exp_rx_response_watchdog

		protected virtual task exp_tx_item_watchdog(cfs_algn_data_item item);
			cfs_algn_vif vif=env_config.get_vif();
			int unsigned threshold=env_config.get_exp_tx_item_threshold();
			time start_time =$time();
			repeat(threshold)begin
				@(posedge vif.clk)
			end

			if (env_config.get_has_checks()) begin
				`uvm_error("DUT_ERROR",$sformatf("the tx item expected from time %0t,was not received after %0d clock cycles - %0s ",start_time,threshold.item.convert2string())
			end

		endtask : exp_tx_item_watchdog

		protected virtual task exp_irq_watchdog(bit irq);
			cfs_algn_vif vif=env_config.get_vif();
			int unsigned threshold=env_config.get_exp_irq_threshold();
			time start_time =$time();
			repeat(threshold)begin
				@(posedge vif.clk)
			end

			if (env_config.get_has_checks()) begin
				`uvm_error("DUT_ERROR",$sformatf("the irq expected from time %0t,was not received after %0d clock cycles ",start_time,threshold)
			end

		endtask : exp_irq_watchdog


		local function void exp_rx_response_watchdog_nb(cfs_md_response response);
			fork
				begin
					process p=process::self();
					process_exp_rx_response_watchdog.push_back(p);
					exp_rx_response_watchdog(response);
					if (process_exp_rx_response_watchdog.size()==0) begin
						`uvm_fatal("ALGORITHM_ISSUE","at the end of the task exp_rx_response_watchdog the queue of the processes process_exp_rx_response_watchdog is empty")
					end
					void'(process_exp_rx_response_watchdog.pop_front());
				end
			join_none
		endfunction : exp_rx_response_watchdog_nb

		local function void exp_tx_item_watchdog_nb(cfs_algn_data_item item);
			fork
				begin
					process p=process::self();
					process_exp_tx_item_watchdog.push_back(p);
					exp_tx_item_watchdog(item);
					if (process_exp_tx_item_watchdog.size()==0) begin
						`uvm_fatal("ALGORITHM_ISSUE","at the end of the task exp_tx_item_watchdog the queue of the processes process_exp_tx_item_watchdog is empty")
					end
					void'(process_exp_tx_item_watchdog.pop_front());
				end
			join_none
		endfunction : exp_tx_item_watchdog_nb

		local function void exp_irq_watchdog_nb(bit irq);
			fork
				begin
					process p=process::self();
					process_exp_irq_watchdog.push_back(p);
					exp_irq_watchdog(irq);
					if (process_exp_irq_watchdog.size()==0) begin
						`uvm_fatal("ALGORITHM_ISSUE","at the end of the task exp_irq_watchdog the queue of the processes process_exp_irq_watchdog is empty")
					end
					void'(process_exp_irq_watchdog.pop_front());
				end
			join_none
		endfunction : exp_irq_watchdog_nb

		virtual function void write_in_model_rx(cfs_md_response response);
			if (exp_rx_responses.size()>=1) begin
				`uvm_fatal("ALGORITHM_ISSUE",$sformatf("something went wrong as there are %0d entries in exp_rx_responses and we have just received one more",exp_rx_responses.size()))
			end
			exp_rx_responses.push_back(response);
			exp_rx_response_watchdog_nb(response);
		endfunction : write_in_model_rx

		virtual function void write_in_model_tx(cfs_algn_data_item item);
			if (exp_tx_items.size()>=1) begin
				`uvm_fatal("ALGORITHM_ISSUE",$sformatf("something went wrong as there are %0d entries in exp_tx_items and we have just received one more",exp_tx_items.size()))
			end
			exp_tx_items.push_back(item);
			exp_tx_item_watchdog_nb(item);
		endfunction : write_in_model_tx		

		virtual function void write_in_model_irq(bit irq);
			if (exp_irqs.size()>=5) begin
				`uvm_fatal("ALGORITHM_ISSUE",$sformatf("something went wrong as there are %0d entries in exp_irqs and we have just received one more",exp_irqs.size()))
			end
			exp_irqs.push_back(irq);
			exp_irq_watchdog_nb(irq);
		endfunction : write_in_model_irq

		virtual function void write_in_adapter_rx(cfs_algn_data_item item);
			if (!item.is_active()) begin
				cfs_md_response exp_response=exp_rx_responses.pop_front();
				process_exp_rx_response_watchdog[0].kill();
				void'(process_exp_rx_response_watchdog.pop_front());
				if (env_config.get_has_checks()) begin
					if (item.response!=exp_response) begin
						`uvm_error("DUT_ERROR",$sformatf("mismatch detected for the rx response -> the expected: %0s ,received: %0s ,item: %0s ",exp_response.name(),item.response.name(),item.convert2string()))
					end
				end
			end
		endfunction : write_in_adapter_rx

		virtual function void write_in_adapter_tx(cfs_algn_data_item item);
			if (!item.is_active()) begin
				cfs_algn_data_item exp_item=exp_tx_items.pop_front();
				process_exp_tx_item_watchdog[0].kill();
				void'(process_exp_tx_item_watchdog.pop_front());
				if (env_config.get_has_checks()) begin
					if (item.data!=exp_item.data) begin
						string src_str = "";

						foreach (exp_item.sources[i]) begin
  							src_str = {src_str,$sformatf("source[%0d]: %0s\n",i,exp_item.sources[i].convert2string())};
						end

						`uvm_error("DUT_ERROR",$sformatf("mismatch detected for the tx data -> \n the expected: %0s , \n received: %0s, \nsources :\n %0s",exp_item.data,item.data,src_str))
					end
					if (item.offset!=exp_item.offset) begin
						`uvm_error("DUT_ERROR",$sformatf("mismatch detected for the tx offset -> the expected: %0s ,received: %0s",exp_item.offset,item.offset)
					end
				end
			end
		endfunction : write_in_adapter_tx

		protected virtual task rcv_irq();
			cfs_algn_vif vif=env_config.get_vif();
			
			forever begin
				@(posedge vif.clk iff(vif.reset_n&&vif.irq));
				if (exp_irqs.size()==0) begin
					if (env_config.get_has_checks()) begin
						`uvm_error("DUT_ERROR","unexpected irq detected")
					end
				end
				else begin
					void'(exp_irqs.pop_front());
					process_exp_irq_watchdog[0].kill();
					void'(process_exp_irq_watchdog.pop_front());
				end
			end

		endtask : rcv_irq

		local virtual function void rcv_irq_nb();
			if (process_rcv_irq!=null) begin
				`uvm_fatal("ALGORITHM_ISSUE","can not start two instances of rcv_irq() task")
			end
			fork
				begin
					process_rcv_irq=process::self();
					rcv_irq();
					process_rcv_irq=null;
				end
			join_none
		endfunction : rcv_irq_nb

	endclass : cfs_algn_scoreboard
`endif