`ifndef CFS_APB_PKG_SV
	`define CFS_APB_PKG_SV 
	`include "uvm_macros.svh"
	`include "uvm_ext_pkg.sv"
	`include "cfs_apb_if.sv"
	package cfs_apb_pkg;
		import uvm_pkg::*;
		import uvm_ext_pkg::*;
		
		`include "cfs_apb_types.sv"
		`include "cfs_apb_item_base.sv"
		`include "cfs_apb_item_drv.sv"
		`include "cfs_apb_item_mon.sv"
		`include "cfs_apb_agent_config.sv"
		`include "cfs_apb_monitor.sv"
		`include "cfs_apb_coverage.sv"
		`include "cfs_apb_driver.sv"
		`include "cfs_apb_agent.sv"

		`include "cfs_apb_sequence_base.sv"
		`include "cfs_apb_sequence_simple.sv"
		`include "cfs_apb_sequence_rw.sv"
		`include "cfs_apb_sequence_random.sv"
		`include "cfs_apb_reg_adapter.sv"
	endpackage : cfs_apb_pkg
`endif