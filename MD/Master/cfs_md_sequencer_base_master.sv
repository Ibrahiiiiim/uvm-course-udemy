///////////////////////////////////////////////////////////////////////////////
// File:        cfs_md_sequencer_base_master.sv
// Author:      Cristian Florin Slav
// Date:        2024-01-07
// Description: MD base master sequencer
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_MD_SEQUENCER_BASE_MASTER_SV
  `define CFS_MD_SEQUENCER_BASE_MASTER_SV

  	class cfs_md_sequencer_base_master extends cfs_md_sequencer_base#(.ITEM_DRV(cfs_md_item_drv_master));

	    `uvm_component_utils(cfs_md_sequencer_base_master)

	    function new(string name = "", uvm_component parent);
	      super.new(name, parent);
	    endfunction
  	endclass

`endif