///////////////////////////////////////////////////////////////////////////////
// File:        cfs_algn_test_random.sv
// Author:      Cristian Florin Slav
// Date:        2023-12-17
// Description: Random test
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_ALGN_TEST_RANDOM_SV
  `define CFS_ALGN_TEST_RANDOM_SV

    class cfs_algn_test_random extends cfs_algn_test_base;

      int unsigned num_md_rx_transactions;

      `uvm_component_utils(cfs_algn_test_random)
      
      function new(string name = "", uvm_component parent);
        super.new(name, parent);
        num_md_rx_transactions=300;
      endfunction
      
      virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "TEST_DONE");
        
        #(100ns);
        uvm_status_e status;
        fork
          begin

            cfs_md_sequence_slave_response_forever seq = cfs_md_sequence_slave_response_forever::type_id::create("seq");
            seq.start(env.md_tx_agent.sequencer);
            
          end
        join_none
        // env.model.reg_block.IRQEN.write(status,5'h11111);
        // void'(env.model.reg_block.CTRL.randomize());
        // //env.model.reg_block.CTRL.SIZE.set(1);
        // env.model.reg_block.CTRL.update(status);


        // repeat(2) begin

        //   cfs_md_sequence_simple_master seq_simple = cfs_md_sequence_simple_master::type_id::create("seq_simple");
          
        //   seq_simple.set_sequencer(env.md_rx_agent.sequencer);

        //   void'(seq_simple.randomize()with{
        //       item.data.size()==3;
        //       item.offset==0;
        //     });
          
        //   seq_simple.start(env.md_rx_agent.sequencer);
        // end
        // begin

        //   cfs_md_sequence_simple_master seq_simple = cfs_md_sequence_simple_master::type_id::create("seq_simple");
          
        //   seq_simple.set_sequencer(env.md_rx_agent.sequencer);

        //   void'(seq_simple.randomize()with{
        //       item.data.size()==4;
        //       item.offset==0;
        //     });
          
        //   seq_simple.start(env.md_rx_agent.sequencer);
        // // end
        // repeat(100) begin

        //   // cfs_md_sequence_simple_master seq_simple = cfs_md_sequence_simple_master::type_id::create("seq_simple");
          
        //   // seq_simple.set_sequencer(env.md_rx_agent.sequencer);

        //   // void'(seq_simple.randomize()with{
        //   //     /*seq_simple.item.data.size()==env.md_rx_agent.sequencer.get_data_width/8;
        //   //     seq_simple.item.offset==0;
        //   //     seq_simple.item.pre_drive_delay==0;   to fill the fifo
        //   //     seq_simple.item.post_drive_delay==0;*/
        //   //   });
          
        //   // seq_simple.start(env.md_rx_agent.sequencer);
          // cfs_algn_virtual_slow_pace seq_slow_pace=cfs_algn_virtual_slow_pace::type_id::create("seq_slow_pace",this);
          // seq_slow_pace.set_sequencer(env.virtual_sequencer);//we can't write this line.
          // void'(seq_slow_pace.randomize());
          // seq_slow_pace.start(env.virtual_sequencer);
        // end
        repeat(2)begin
          if(env.model.is_empty() == 1)begin
            cfs_algn_virtual_sequence_reg_config seq = cfs_algn_virtual_sequence_reg_config::type_id::create("seq");

            void'(seq.randomize());
            seq.start(env.virtual_sequencer);
          end

          repeat(num_md_rx_transactions) begin
            cfs_algn_virtual_sequence_rx seq = cfs_algn_virtual_sequence_rx::type_id::create("seq");
            seq.set_sequencer(env.virtual_sequencer);

            void'(seq.randomize());
            seq.start(env.virtual_sequencer);
          end

          begin
            cfs_algn_vif vif = env.env_config.get_vif();
            repeat(100)begin
              @(posedge vif.clk);
            end
          end

          begin
            cfs_algn_virtual_sequence_reg_status seq = cfs_algn_virtual_sequence_reg_status::type_id::create("seq");

            void'(seq.randomize());
            seq.start(env.virtual_sequencer);
          end
        end

        #(500ns);
                
        phase.drop_objection(this, "TEST_DONE"); 
      endtask
    
    endclass

`endif