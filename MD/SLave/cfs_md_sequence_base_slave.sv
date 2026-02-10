///////////////////////////////////////////////////////////////////////////////
// File:        cfs_md_sequence_base_slave.sv
// Author:      Cristian Florin Slav
// Date:        2024-01-08
// Description: MD slave base sequence class.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_MD_SEQUENCE_BASE_SLAVE_SV
  `define CFS_MD_SEQUENCE_BASE_SLAVE_SV

  	class cfs_md_sequence_base_slave extends cfs_md_sequence_base#(.ITEM_DRV(cfs_md_item_drv_slave));
    
	    `uvm_declare_p_sequencer(cfs_md_sequencer_base_slave)
	    
	    `uvm_object_utils(cfs_md_sequence_base_slave)
	    
	    function new(string name = "");
	      super.new(name);
	    endfunction

  	endclass

`endif