vlib work
vlog adder.v adder_tb.sv  +cover
vsim -voptargs=+acc work.adder_tb -cover
add wave *
coverage save adder_tb.ucdb -onexit
run -all