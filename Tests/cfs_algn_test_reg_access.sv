`ifndef CFS_ALGN_TEST_REG_ACCESS_SV
	`define CFS_ALGN_TEST_REG_ACCESS_SV

	class cfs_algn_test_reg_access extends cfs_algn_test_base;

		protected int unsigned num_reg_accesses;

		protected int unsigned num_unmapped_accesses;

		`uvm_component_utils(cfs_algn_test_reg_access)

		function new(string name="",uvm_component parent);
			super.new(name,parent);
			num_reg_accesses=100;
			num_unmapped_accesses=100;
		endfunction : new

		virtual task run_phase(uvm_phase phase);

			uvm_status_e status;
			uvm_reg_data_t data;

			phase.raise_objection(this, "TEST_DONE");
	      
	      	#(100ns);

	      	/*fork
	      		begin
	      			cfs_apb_vif vif=env.apb_agent.agent_config.get_vif();

	      			repeat(3)begin
	      				@(posedge vif.pclk);
	      			end

	      			#11ns;

	      			vif.preset_n <=0;
	      			repeat(4)begin
	      				@(posedge vif.pclk);
	      			end

	      			vif.preset_n <=1;
	      		end

	        	begin
	        		cfs_apb_sequence_simple seq_simple;
	        		seq_simple=cfs_apb_sequence_simple::type_id::create("seq_simple");
	        		void'(seq_simple.randomize()with{
	        			item.addr =='h000c;
	        			item.dir ==CFS_APB_WRITE;
	        			item.data =='h11;
	        			});
	        		seq_simple.start(env.apb_agent.sequencer);
	        	end

	        	begin
	        		cfs_apb_sequence_rw seq_rw;
	        		seq_rw=cfs_apb_sequence_rw::type_id::create("seq_rw");
	        		void'(seq_rw.randomize()with{
	        			addr =='h0000;
	        			});
	        		seq_rw.start(env.apb_agent.sequencer);
	        	end

	        	begin
	          		cfs_apb_sequence_random seq_random ;
	          		seq_random= cfs_apb_sequence_random::type_id::create("seq_random");

	          		void'(seq_random.randomize() with {
	            		num_items == 3;
	          			});

	           		seq_random.start(env.apb_agent.sequencer);
	        	end

	        join
	        begin
	          		cfs_apb_sequence_random seq_random ;
	          		seq_random= cfs_apb_sequence_random::type_id::create("seq_random");

	          		void'(seq_random.randomize() with {
	            		num_items == 3;
	          			});

	           		seq_random.start(env.apb_agent.sequencer);
	        	
	        end*/
	        
	         
	        //begin
	        	//cfs_apb_sequence_simple seq_simple = cfs_apb_sequence_simple::type_id::create("seq_simple");
	        	//void'(seq_simple.randomize()with{
	        		//item.addr ==            'h0;
	        		//item.dir  ==  CFS_APB_WRITE;
	        		//item.data ==  32'h00000202;
	        		//});

	        	//seq_simple.start(env.apb_agent.sequencer);
	        //end
	        /*fork
		        begin
		          cfs_md_sequence_slave_response_forever seq = cfs_md_sequence_slave_response_forever::type_id::create("seq");
		          
		          seq.start(env.md_tx_agent.sequencer);
		        end
		    join_none
		    
		    begin
		        cfs_algn_seq_req_config seq =cfs_algn_seq_req_config::type_id::create("seq");
		        seq.reg_block = env.model.reg_block;
		        seq.start(env.model.reg_block.default_map.get_sequencer());
	    	end*/

	    	// repeat(2) begin
		    //     cfs_md_sequence_simple_master seq_simple = cfs_md_sequence_simple_master::type_id::create("seq_simple");
		    //     seq_simple.set_sequencer(env.md_rx_agent.sequencer);

		    //     void'(seq_simple.randomize() with {
		    //       item.data.size() == 4;
		    //       item.offset      == 0;
		    //     });

		    //     seq_simple.start(env.md_rx_agent.sequencer);
      		// end

      		//don't do this in a real project as
      		//calling the predict()function from the test is completely wrong as this the job of the model.

      		// void'(env.model.reg_block.STATUS.CNT_DROP.predict(2)); 

      		// env.model.reg_block.CTRL.read(status,data);

      		// env.model.reg_block.CTRL.CLR.set(1);

      		// env.model.reg_block.CTRL.update(status);

      		// env.model.reg_block.CTRL.read(status,data);

	        //begin
	        	//cfs_apb_sequence_simple seq_simple = cfs_apb_sequence_simple::type_id::create("seq_simple");
	        	//void'(seq_simple.randomize()with{
	        	//	item.addr ==            'h0;
	        	//	item.dir  ==   CFS_APB_READ;
	        	//	});

	        	//seq_simple.start(env.apb_agent.sequencer);
	        //end

	        fork
	        	begin
	        		cfs_algn_virtual_sequence_reg_access_random seq =cfs_algn_virtual_sequence_reg_access_random::type_id::create::("seq");
	        		void'(seq.randomize() with {
	        				num_accesses==num_reg_accesses;
	        			});
	        		seq.start(env.virtual_sequencer);
	        	end
	        	begin
	        		cfs_algn_virtual_sequence_reg_access_unmapped seq =cfs_algn_virtual_sequence_reg_access_unmapped::type_id::create::("seq");
	        		void'(seq.randomize() with {
	        				num_accesses==num_unmapped_accesses;
	        			});
	        		seq.start(env.virtual_sequencer);
	        	end
	        join
	        
	        #1000ns;
	      		phase.drop_objection(this, "TEST_DONE"); 
		endtask : run_phase
		
		
	endclass : cfs_algn_test_reg_access

`endif


