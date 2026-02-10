`ifndef CFS_ALGN_MODEL_SV
	`define CFS_ALGN_MODEL_SV

	`uvm_analysis_imp_decl(_in_rx)

	`uvm_analysis_imp_decl(_in_tx)

	class cfs_algn_model extends uvm_component implements uvm_ext_reset_handler;
		
		cfs_algn_reg_block reg_block;

		cfs_algn_env_config env_config;

		`uvm_component_utils(cfs_algn_model)

		uvm_analysis_imp_in_rx#(cfs_algn_data_item,cfs_algn_model) port_in_rx;

		uvm_analysis_imp_in_tx#(cfs_algn_data_item,cfs_algn_model) port_in_tx;

		uvm_analysis_port#(cfs_md_response) port_out_rx;

		uvm_analysis_port#(cfs_algn_data_item) port_out_tx;

		uvm_analysis_port#(bit) port_out_irq;

		uvm_analysis_port#(cfs_algn_split_info) port_out_split_info;

		protected uvm_tlm_fifo#(cfs_algn_data_item) rx_fifo;

		protected uvm_tlm_fifo#(cfs_algn_data_item) tx_fifo;

		local process process_push_to_rx_fifo;//the reasons for doing that are for controlling the task that run in the background in the function and to kill it in reseting.

		protected cfs_algn_data_item buffer[$];

		protected uvm_event tx_complete;

		protected process process_build_buffer;

		protected process process_align; 

		protected process process_tx_ctrl;

		protected bit exp_irq;

		local process process_send_exp_irq;

		local process process_set_rx_fifo_empty;

		local process process_set_rx_fifo_full;

		local process process_set_tx_fifo_empty;

		local process process_set_tx_fifo_full;		

		function new(string name="",uvm_component parent);
			super.new(name,parent);
			port_in_rx=new("port_in_rx",this);

			port_in_tx=new("port_in_tx",this);
			
			port_out_rx=new("port_out_rx",this);
			
			port_out_tx=new("port_out_tx",this);

			port_out_irq=new("port_out_irq",this);

			rx_fifo=new("rx_fifo",this,8);

			tx_fifo=new("tx_fifo",this,8);

			tx_complete=new("tx_complete");

			port_out_split_info=new("port_out_split_info",this);

		endfunction : new

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			if (reg_block==null) begin
				reg_block=cfs_algn_reg_block::type_id::create("reg_block",this);
				reg_block.build();
				reg_block.lock_model();
			end
		
		endfunction : build_phase

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);
			cfs_algn_clr_cnt_drop cbs=cfs_algn_clr_cnt_drop::type_id::create("cbs",this);
			cbs.cnt_drop=reg_block.STATUS.CNT_DROP;
			uvm_callbacks#(uvm_reg_field,cfs_algn_clr_cnt_drop)::add(reg_block.CTRL.CLR,cbs);
		endfunction : connect_phase

		virtual function void end_of_elaboration_phase(uvm_phase phase);
			super.end_of_elaboration_phase(phase);
			reg_block.CTRL.SET_ALGN_DATA_WIDTH(env_config.get_has_checks());
		endfunction : end_of_elaboration_phase

		virtual function void kill_process(ref process p);
			if (p != null) begin
				p.kill();
				p=null;
			end
		endfunction : kill_process
		
		virtual function void handle_reset(uvm_phase phase);
			reg_block.reset("HARD");
			kill_process(process_push_to_rx_fifo);
			kill_process(process_build_buffer);
			kill_process(process_align);
			kill_process(process_tx_ctrl);
			kill_process(process_send_exp_irq);
			kill_process(process_set_rx_fifo_empty);
			kill_process(process_set_rx_fifo_full);
			kill_process(process_set_tx_fifo_empty);
			kill_process(process_set_tx_fifo_full);
			tx_complete.reset();
			rx_fifo.flush();
			tx_fifo.flush();
			buffer={};
			exp_irq=0;
			build_buffer_nb();
			align_nb();
			tx_ctrl_nb();
			send_exp_irq_nb();
		endfunction : handle_reset

		virtual function bit is_empty();
			if (rx_fifo.used() != 0) begin
				return 0;
			end
			if (tx_fifo.used() != 0) begin
				return 0;
			end
			if (buffer.size() != 0) begin
				return 0;
			end
			return 1;
		endfunction : is_empty

		protected virtual function cfs_md_response get_exp_response(cfs_algn_data_item item);
			if (item.data.size()==0) begin
				return CFS_MD_ERR;
			end
			if ( item.offset + item.data.size() > (env_config.get_algn_data_width()/8)) begin
				return CFS_MD_ERR;
			end
			if (((env_config.get_algn_data_width()/8) + item.offset) % item.data.size()) begin
				return CFS_MD_ERR;
			end
			return CFS_MD_OKAY;
		endfunction : get_exp_response

		protected virtual function void set_max_drop();
			
			void'(reg_block.IRQ.MAX_DROP.predict(1));
			
			`uvm_info("CNT_DROP",$sformatf("drop counter has reached max value - %0s: %0d",reg_block.IRQEN.MAX_DROP.get_full_name(),reg_block.IRQEN.MAX_DROP.get_mirrored_value()),UVM_MEDIUM)
		
			if (reg_block.IRQEN.MAX_DROP.get_mirrored_value()=1) begin
				exp_irq=1;	
			end			
		endfunction : set_max_drop

		protected virtual function void set_rx_fifo_full();
			fork	
				begin
					process_set_rx_fifo_full=process::self();
					repeat(2)begin
						uvm_wait_for_nba_region();//we use it for the same clock system.
					end	
					end	void'(reg_block.IRQ.RX_FIFO_FULL.predict(1));
				
					`uvm_info("RX_FIFO",$sformatf("RX FIFO has became full - %0s : %0d ",reg_block.IRQEN.RX_FIFO_FULL.get_full_name(),reg_block.IRQEN.RX_FIFO_FULL.get_mirrored_value()),UVM_MEDIUM)
				
					if (reg_block.IRQEN.RX_FIFO_FULL.get_mirrored_value()==1) begin
						exp_irq=1;
					end
					process_set_rx_fifo_full=null;
				end
			join_none

		endfunction : set_rx_fifo_full

		protected virtual function void set_rx_fifo_empty();
			fork
				begin
					process_set_rx_fifo_empty=process::self();
					repeat(2)begin
						uvm_wait_for_nba_region();
					end
					void'(reg_block.IRQ.RX_FIFO_EMPTY.predict(1));
				
					`uvm_info("RX_FIFO",$sformatf("RX FIFO has became empty - %0s : %0d ",reg_block.IRQEN.RX_FIFO_EMPTY.get_full_name(),reg_block.IRQEN.RX_FIFO_EMPTY.get_mirrored_value()),UVM_MEDIUM)
				
					if (reg_block.IRQEN.RX_FIFO_EMPTY.get_mirrored_value()==1) begin
						exp_irq=1;
					end
					process_set_rx_fifo_empty=null;
				end
			join_none

		endfunction : set_rx_fifo_empty

		protected virtual function void set_tx_fifo_full();
			fork
				begin
					process_set_tx_fifo_full=process::self();
					repeat(2)begin
						uvm_wait_for_nba_region();
					end
					void'(reg_block.IRQ.TX_FIFO_FULL.predict(1));
				
					`uvm_info("TX_FIFO",$sformatf("tx FIFO has became full - %0s : %0d ",reg_block.IRQEN.TX_FIFO_FULL.get_full_name(),reg_block.IRQEN.TX_FIFO_FULL.get_mirrored_value()),UVM_MEDIUM)
				
					if (reg_block.IRQEN.TX_FIFO_FULL.get_mirrored_value()==1) begin
						exp_irq=1;
					end
					process_set_tx_fifo_full=null;
				end

			join_none
		endfunction : set_tx_fifo_full

		protected virtual function void set_tx_fifo_empty();
		    fork
		    	begin
		    		process_set_tx_fifo_empty=process::self();
		    		repeat(2)begin
		    			uvm_wait_for_nba_region();
		    		end
					void'(reg_block.IRQ.TX_FIFO_EMPTY.predict(1));
				
					`uvm_info("TX_FIFO",$sformatf("tx FIFO has became empty - %0s : %0d ",reg_block.IRQEN.TX_FIFO_EMPTY.get_full_name(),reg_block.IRQEN.TX_FIFO_EMPTY.get_mirrored_value()),UVM_MEDIUM)
				
					if (reg_block.IRQEN.TX_FIFO_EMPTY.get_mirrored_value()==1) begin
						exp_irq=1;
					end
					process_set_tx_fifo_empty=null;

				end
			join_none

		endfunction : set_tx_fifo_empty

		protected virtual function void kill_set_rx_fifo_empty();
			fork
				begin
					uvm_wait_for_nba_region();
					kill_process(process_set_rx_fifo_empty);
				end
			join_none
		endfunction : kill_set_rx_fifo_empty

		protected virtual function void kill_set_rx_fifo_full();
			fork
				begin
					uvm_wait_for_nba_region();
					kill_process(process_set_rx_fifo_full);
				end
			join_none
		endfunction : kill_set_rx_fifo_full

		protected virtual function void kill_set_tx_fifo_empty();
			fork
				begin
					uvm_wait_for_nba_region();
					kill_process(process_set_tx_fifo_empty);
				end
			join_none
		endfunction : kill_set_tx_fifo_empty

		protected virtual function void kill_set_tx_fifo_full();
			fork
				begin
					uvm_wait_for_nba_region();
					kill_process(process_set_tx_fifo_full);
				end
			join_none
		endfunction : kill_set_tx_fifo_full


		protected virtual function void inc_cnt_drop(cfs_md_response response);

			uvm_reg_data_t max_value = ('h1 << reg_block.STATUS.CNT_DROP.get_n_bits()) - 1;

			
			if (reg_block.STATUS.CNT_DROP.get_mirrored_value < max_value) begin
				void'(reg_block.STATUS.CNT_DROP.predict(reg_block.STATUS.CNT_DROP.get_mirrored_value()+1));
				`uvm_info("CNT_DROP",$sformatf("increment %s: %0d due to :%0s",reg_block.STATUS.CNT_DROP.get_full_name(),reg_block.STATUS.CNT_DROP.get_mirrored_value().response.name()),UVM_LOW)
			
				if (reg_block.STATUS.CNT_DROP.get_mirrored_value()==max_value) begin
					set_max_drop();
				end
			end

		endfunction : inc_cnt_drop

		protected virtual function void inc_rx_lvl();
			
			void'(reg_block.STATUS.RX_LVL.predict(reg_block.STATUS.RX_LVL.get_mirrored_value()+1));
			
			if (reg_block.STATUS.RX_LVL.get_mirrored_value()==rx_fifo.size()) begin
				set_rx_fifo_full();
			end
		
		endfunction : inc_rx_lvl

		protected virtual function void dec_rx_lvl();
			
			void'(reg_block.STATUS.RX_LVL.predict(reg_block.STATUS.RX_LVL.get_mirrored_value()-1));
			
			if (reg_block.STATUS.RX_LVL.get_mirrored_value()==0) begin
				set_rx_fifo_empty();
			end
		
		endfunction : dec_rx_lvl

		protected virtual function void inc_tx_lvl();
			
			void'(reg_block.STATUS.TX_LVL.predict(reg_block.STATUS.TX_LVL.get_mirrored_value()+1));
			
			if (reg_block.STATUS.TX_LVL.get_mirrored_value()==tx_fifo.size()) begin
				set_tx_fifo_full();
			end
		
		endfunction : inc_tx_lvl

		protected virtual function void dec_tx_lvl();
			
			void'(reg_block.STATUS.TX_LVL.predict(reg_block.STATUS.TX_LVL.get_mirrored_value()-1));
			
			if (reg_block.STATUS.TX_LVL.get_mirrored_value()==0 begin
				set_tx_fifo_empty();
			end
		
		endfunction : dec_tx_lvl

		protected virtual task sync_push_to_rx_fifo();
			fork
				begin
					fork
						begin
							@(posedge vif.clk iff(vif.rx_fifo_push));
						end
						begin
							repeat(10)begin
								@(posedge vif.clk iff(reg_block.STATUS.RX_LVL.get_mirrored_value() < rx_fifo.size()));
							end
							`uvm_warning("DUT_WARNING","RX FIFO PUSH didn't synchronize with RTL ")
						end
					join_any
					disable fork;
				end
			join
		endtask : sync_push_to_rx_fifo

		protected virtual task sync_pop_from_rx_fifo();
			fork
				begin
					fork
						begin
							@(posedge vif.clk iff(vif.rx_fifo_pop));
						end
						begin
							repeat(10)begin
								@(posedge vif.clk iff((reg_block.STATUS.RX_LVL.get_mirrored_value() > 0) && (reg_block.STATUS.TX_LVL.get_mirrored_value() < tx_fifo.size())));
							end
							`uvm_warning("DUT_WARNING","RX FIFO POP didn't synchronize with RTL ")
						end
					join_any
					disable fork;
				end
			join
		endtask : sync_pop_from_rx_fifo

		protected virtual task sync_push_to_tx_fifo();
			fork
				begin
					fork
						begin
							@(posedge vif.clk iff(vif.tx_fifo_push));
						end
						begin
							repeat(10)begin
								@(posedge vif.clk iff(reg_block.STATUS.TX_LVL.get_mirrored_value() < tx_fifo.size()));
							end
							`uvm_warning("DUT_WARNING","TX FIFO PUSH didn't synchronize with RTL ")
						end
					join_any
					disable fork;
				end
			join
		endtask : sync_push_to_tx_fifo

		protected virtual task sync_pop_from_tx_fifo();
			fork
				begin
					fork
						begin
							@(posedge vif.clk iff(vif.tx_fifo_pop));
						end
						begin
							repeat(200)begin
								@(posedge vif.clk iff(reg_block.STATUS.TX_LVL.get_mirrored_value() > 0));
							end
							`uvm_warning("DUT_WARNING","TX FIFO POP didn't synchronize with RTL ")
						end
					join_any
					disable fork;
				end
			join
		endtask : sync_pop_from_tx_fifo

		protected virtual task push_to_rx_fifo(cfs_algn_data_item item);
			
			sync_push_to_rx_fifo();

			rx_fifo.put(item);

			kill_set_rx_fifo_empty();

			inc_rx_lvl();

			`uvm_info("RX_FIFO",$sformatf(" RX FIFO BUSH - NEW LEVEL : %0d ,pushed entry : %0s",reg_block.STATUS.RX_LVL.get_mirrored_value(),item.convert2string()),UVM_LOW)

			port_out_rx.write(CFS_MD_OKAY);

		endtask : push_to_rx_fifo

		protected virtual task pop_from_rx_fifo(ref cfs_algn_data_item item);
			
			sync_pop_from_rx_fifo();

			rx_fifo.get(item);

			kill_set_rx_fifo_full();

			dec_rx_lvl();

			`uvm_info("RX_FIFO",$sformatf(" RX FIFO POP - NEW LEVEL : %0d ,popped entry : %0s",reg_block.STATUS.RX_LVL.get_mirrored_value(),item.convert2string()),UVM_LOW)

		endtask : pop_from_rx_fifo

		protected virtual task push_to_tx_fifo(cfs_algn_data_item item);
			
			sync_push_to_tx_fifo();

			tx_fifo.put(item);

			kill_set_tx_fifo_empty();

			inc_tx_lvl();

			`uvm_info("TX_FIFO",$sformatf(" TX FIFO BUSH - NEW LEVEL : %0d ,pushed entry : %0s",reg_block.STATUS.TX_LVL.get_mirrored_value(),item.convert2string()),UVM_LOW)

		endtask : push_to_tx_fifo

		protected virtual task pop_from_tx_fifo(ref cfs_algn_data_item item);
			
			sync_pop_from_tx_fifo();

			tx_fifo.get(item);

			kill_set_tx_fifo_full();

			dec_tx_lvl();

			`uvm_info("TX_FIFO",$sformatf(" TX FIFO POP - NEW LEVEL : %0d ,popped entry : %0s",reg_block.STATUS.TX_LVL.get_mirrored_value(),item.convert2string()),UVM_LOW)

		endtask : pop_from_tx_fifo

		protected virtual task build_buffer();
			cfs_algn_vif vif = env_config.get_vif();
			forever begin
				int unsigned ctrl_size = reg_block.CTRL.SIZE.get_mirrored_value();
				if ((buffer.sum()with(item.data.size()))<=ctrl_size) begin
					cfs_algn_data_item rx_item;
					pop_from_rx_fifo(rx_item);
					buffer.push_back(rx_item);
				end
				else begin
					@(posedge vif.clk);
				end
			end
		endtask : build_buffer

		protected virtual task tx_ctrl();
			cfs_algn_data_item item;
			forever begin
				pop_from_tx_fifo(item);
				port_out_tx(item);
				tx_complete.wait_trigger();
			end
		endtask : tx_ctrl

		protected virtual task send_exp_irq();
			cfs_algn_vif vif=env_config.get_vif();
			forever begin
				@(negedge vif.clk);//note that :this function without this delay is considered as the previous scenario. 
				if (exp_irq==1) begin
					port_out_irq(1);
					exp_irq=0
				end
			end
		endtask : send_exp_irq	

		protected virtual function void push_to_rx_fifo_nb(cfs_algn_data_item item);
			if (process_push_to_rx_fifo != null) begin
				`uvm_fatal("ALGORITHM_ISSUE","can not start two instances of push_to_rx_fifo () task")
			end
			fork
				begin
					process_push_to_rx_fifo=process::self();
					push_to_rx_fifo(item);
					process_push_to_rx_fifo=null;
				end
			join_none
		endfunction : push_to_rx_fifo_nb
		
		protected virtual task align();
			cfs_algn_vif vif=env_config.get_vif();
			forever begin
				int unsigned ctrl_size=reg_block.CTRL.SIZE.get_mirrored_value();
				int unsigned ctrl_offset=reg_block.CTRL.OFFSET.get_mirrored_value();
				uvm_wait_for_nba_region();
				if (ctrl_size <= ( buffer.sum() with (item.data.size())) ) begin
					while(ctrl_size <= ( buffer.sum() with (item.data.size())) )begin
						cfs_algn_data_item tx_item = cfs_algn_data_item::type_id::create("tx_item",this);
						tx_item.offset=ctrl_offset;
						void'(tx_item.begin_tr(buffer[0].get_begin_time()));
						
						while(tx_item.data.size() != ctrl_size)begin
							cfs_algn_data_item buffer_item=buffer.pop_front();
							if (tx_item.data.size() + buffer_item.data.size() <= ctrl_size) begin
								foreach (buffer_item.data[idx]) begin
									tx_item.data.push_back(buffer_item.data[idx]);
								end
									
									tx_item.sources.push_back(buffer_item);

								if (tx_item.data.size()==ctrl_size) begin
									tx_item.end_tr(buffer_item.get_end_time());
									push_to_tx_fifo(tx_item);
								end
							end
							else begin
								int unsigned num_bytes_needed =ctrl_size - tx_item.data.size();
								cfs_algn_data_item splitted_items[$];
								tx_item.sources.push_back(buffer_item);
								split(num_bytes_needed,buffer_item,splitted_items);
								buffer.push_front(splitted_items[1]);
								buffer.push_front(splitted_items[0]);

								tx_item.sources.push_back(splitted_items[0]);

								begin
									cfs_algn_split_info info =cfs_algn_split_info::type_id::create("info",this);
									info.ctrl_size=ctrl_size;
									info.ctrl_offset=ctrl_offset;
									info.md_size=buffer_item.data.size();
									info.md_offset=buffer_item.offset;
									info.num_byte_needed=num_bytes_needed;
									port_out_split_info(info);
								end
							end
						end

					end
				end
				else begin
					@(posedge vif.clk);
				end
			end
		endtask : align

		protected virtual function void split(int unsigned num_bytes, cfs_algn_data_item item, ref cfs_algn_data_item items[$]);
			if ((num_bytes==0)||(num_bytes>=item.data.size())) begin
				`uvm_fatal("ALGORITHM_ISSUE",$sformatf("Can't split an item as num_bytes has value of %0d.the size of the data queue in the item is %0d",num_bytes,item.data.size()))
			end
			for (int i = 0; i < 2; i++) begin
				cfs_algn_data_item splitted_item = cfs_algn_data_item::type_id::create("splitted_item",this);
				if (i==0) begin
					splitted_item.offset=item.offset;
					for (int j = 0; j < num_bytes; j++) begin
						splitted_item.data.push_back(item.data[j]);
					end
				end
				else begin
					splitted_item.offset=item.offset+num_bytes;
					for (int j = num_bytes; j < item.data.size(); j++) begin
						splitted_item.data.push_back(item.data[j]);
					end
				end
				splitted_item.prev_item_delay=item.prev_item_delay;
				splitted_item.length=item.length;
				splitted_item.response=item.response;
				splitted_item.sources=item.sources;
				void'(splitted_item.begin_tr(item.get_begin_time()));//“Start the split transaction at the SAME time the original transaction started.”Why do we do this?Because:The split item comes from the original item Logically, it started at the same time You want waveform viewers to line up correctly Otherwise, the split item would appear at a random time
				if(!item.is_active())begin
					splitted_item.end_tr(item.get_end_time());
				end
				items.push_back(splitted_item);
			end
		endfunction : split

		protected virtual function void build_buffer_nb();
			if (process_build_buffer != null) begin
				`uvm_fatal("ALGORITHM_ISSUE","can not start two instances of build_buffer () task")
			end
			fork
				begin
					process_build_buffer=process::self();
					build_buffer();
					process_build_buffer=null;
				end
			join_none
		endfunction : build_buffer_nb

		protected virtual function void align_nb();
			if (process_align != null) begin
				`uvm_fatal("ALGORITHM_ISSUE","can not start two instances of align () task")
			end
			fork
				begin
					process_align=process::self();
					align();
					process_align=null;
				end
			join_none
		endfunction : align_nb

		protected virtual function void tx_ctrl_nb();
			if (process_tx_ctrl != null) begin
				`uvm_fatal("ALGORITHM_ISSUE","can not start two instances of tx_ctrl () task")
			end
			fork
				begin
					process_tx_ctrl=process::self();
					tx_ctrl();
					process_tx_ctrl=null;
				end
			join_none
		endfunction : tx_ctrl_nb

		protected virtual function void send_exp_irq_nb();
			if (process_send_exp_irq != null) begin
				`uvm_fatal("ALGORITHM_ISSUE","can not start two instances of send_exp_irq () task")
			end
			fork
				begin
					process_send_exp_irq=process::self();
					send_exp_irq();
					process_send_exp_irq=null;
				end
			join_none
		endfunction : send_exp_irq_nb


		virtual function void write_in_rx(cfs_algn_data_item item);
			if (item.is_active()) begin
				cfs_md_response exp_response = get_exp_response(item);
				case (exp_response)
					CFS_MD_ERR : begin
						inc_cnt_drop(exp_response);
						port_out_rx.write(exp_response);
					end

					CFS_MD_OKAY : begin
						push_to_rx_fifo_nb(item);
					end
					default : begin
						`uvm_fatal("ALGORITHM_ISSUE",$sformatf("Un-supported value for response : %0s",exp_response.name()))
					end

				endcase
			end
		endfunction : write_in_rx

		virtual function void write_in_tx(cfs_algn_data_item item);
			if (!item.is_active()) begin
				tx_complete.trigger();
			end

		endfunction : write_in_tx

	endclass : cfs_algn_model
`endif

/*
the reasons for doing that:

if (process_push_to_rx_fifo != null) begin
	`uvm_fatal("ALGORITHM_ISSUE","can not start two instances of push_to_rx_fifo () task")
end

are:We prevent multiple task instances because the MD protocol allows only one RX transaction at a time,
so starting another task before the first finishes would be illegal.

What does “overlapping tasks” mean?

Overlapping means:

Task A starts
Task B starts BEFORE Task A finishes


Visually:

Time →
Task A: |---------|
Task B:     |---------|   ❌ overlap


This is illegal for your protocol.

How can overlapping happen in your design?

Remember this:

RX monitor can detect transactions very fast

Each detection calls write_in_rx() (a function)

Each function call can start a background task using fork

If you are not careful, you may accidentally do this:

RX transaction 1 → start push_to_rx_fifo()
RX transaction 2 → start push_to_rx_fifo() AGAIN ❌


Now you have:

Two tasks

Both pushing to RX FIFO

At the same time

❌ Protocol violation
❌ Wrong model behavior



*/