vlog -f file.txt +cover=f -covercells
vsim -sv_seed random -coverage -voptargs=+acc work.testbench +UVM_TESTNAME=cfs_algn_test_random_rx_err +UVM_MAX_QUIT_COUNT=1 -f messages.f +uvm_set_config_int=uvm_test_top.env.md_rx_agent.monitor,recording_detail,400
coverage save -onexit cov.ucdb
run -all
coverage report -details -output cov_report.txt 
#quit -sim
