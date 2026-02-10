///////////////////////////////////////////////////////////////////////////////
// File:        cfs_md_item_drv.sv
// Author:      Cristian Florin Slav
// Date:        2023-12-17
// Description: Base class for the MD driving item.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_MD_ITEM_DRV_SV
  `define CFS_MD_ITEM_DRV_SV

  	class cfs_md_item_drv extends cfs_md_item_base;

	    `uvm_object_utils(cfs_md_item_drv)

	    function new(string name = "");
	      super.new(name);
	    endfunction

 	endclass

`endif