///////////////////////////////////////////////////////////////////////////////
// File:        cfs_md_item_base.sv
// Author:      Cristian Florin Slav
// Date:        2023-12-17
// Description: Base class for the MD item.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_MD_ITEM_BASE_SV
  `define CFS_MD_ITEM_BASE_SV

  	class cfs_md_item_base extends uvm_sequence_item;

	    `uvm_object_utils(cfs_md_item_base)

	    function new(string name = "");
	      super.new(name);
	    endfunction

  	endclass

`endif