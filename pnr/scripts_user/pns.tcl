################################################################################
## AS501
## Final Project
## Power Network Synthesis
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Jihwan Cho (jihwancho@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch

# Remove all pre-existing PG-related objects
remove_pg_strategies -all
remove_pg_patterns -all
remove_pg_regions -all
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} -ring -stripe -macro_pin_connect -lib_cell_pin_connect > /dev/null

connect_pg_net

# Via master rules
set_pg_via_master_rule PGVIA_10X10 -via_array_dimension {10 10}
set_pg_via_master_rule PGVIA_2X4 -via_array_dimension {2 4}

####################################
## TOP RING
####################################

# Build Power Rings
create_pg_ring_pattern PG_RING_PATTERN_TOP \
    -horizontal_layer {M9} -horizontal_width {5} -horizontal_spacing {2} \
    -vertical_layer {M8} -vertical_width {5} -vertical_spacing {2} \
    -via_rule {{intersection: adjacent }{via_master: default}} \
    -corner_bridge false

set_pg_strategy S_RING_TOP \
	-design_boundary \
	-pattern { {name: PG_RING_PATTERN_TOP} {nets:{VDD VSS}} {offset: {-12 -12}} }

compile_pg -strategies {S_RING_TOP}

####################################
## SRAM Macro RING
####################################

# Build Power Rings
create_pg_ring_pattern PG_RING_PATTERN_MACRO \
    -horizontal_layer {M5} -horizontal_width {1} -horizontal_spacing {0.5} \
    -vertical_layer {M6} -vertical_width {1} -vertical_spacing {0.5} \
    -via_rule {{intersection: adjacent }{via_master: default}} \
    -corner_bridge false

set_pg_strategy S_RING_MACRO \
	-macros  {ICACHE/ICACHE_SRAM/SRAM48 ICACHE/ICACHE_SRAM/SRAM8} \
	-pattern { {name: PG_RING_PATTERN_MACRO} {nets:{VDD VSS}} {offset: {0.5 0.5}} }

compile_pg -strategies {S_RING_MACRO}

####################################
## SRAM Macro Ring Connection
####################################

#create_macro_Ring_conn_pattern(vias)
create_pg_macro_conn_pattern PG_MACRO_CONN_PATTERN \
    -pin_conn_type scattered_pin \
    -layers {M5 M6}

set_pg_strategy S_MACRO_CONN \
    -macros  {ICACHE/ICACHE_SRAM/SRAM48 ICACHE/ICACHE_SRAM/SRAM8} \
	-pattern { {pattern: PG_MACRO_CONN_PATTERN} {nets: {VDD VSS}} }

compile_pg -strategies {S_MACRO_CONN}

####################################
## TOP Mesh
####################################

create_pg_mesh_pattern PG_MESH_PATTERN_TOP \
	-layers { \
		{ {horizontal_layer: M7} {width: 4} {spacing: interleaving} {pitch: 13.376} {offset: 0.856} {trim : true} } \
		{ {vertical_layer: M8}   {width: 4} {spacing: interleaving} {pitch: 19.456} {offset: 0}  {trim : true} } \
		} \
	-via_rule { {intersection: adjacent} {via_master : PGVIA_10X10} }

set_pg_strategy S_MESH_TOP \
	-core \
	-pattern   { {name: PG_MESH_PATTERN_TOP} {nets:{VDD VSS}} {offset_start: {20 20}} } \
	-extension { {stop: outermost_ring} }

compile_pg -strategies {S_MESH_TOP}

####################################
## Low Mesh
####################################

create_pg_mesh_pattern PG_MESH_PATTERN_LOW \
	-layers { \
		{ {vertical_layer: M2} {width: 0.44 0.192 0.192} {spacing: 2.724 3.456} {pitch: 9.728} {offset: 0} {trim : false} } \
		}

set_pg_strategy S_MESH_LOW \
	-core  \
	-pattern   { {name: PG_MESH_PATTERN_LOW} {nets: {VDD VSS VSS}} {offset_start: {20 0}} } \
	-blockage  { {macros_with_keepout: {ICACHE/ICACHE_SRAM/SRAM48 ICACHE/ICACHE_SRAM/SRAM8}} }

set_pg_strategy_via_rule S_VIA_M2_M7 \
	-via_rule { \
		{  {{strategies: {S_MESH_LOW}} {layers: { M2 }} {nets: {VDD}} } \
		   {{strategies: {S_MESH_TOP}} {layers: { M7 }} }  \
			{via_master: {PGVIA_2X4}} } \
		{  {{strategies: {S_MESH_LOW}} {layers: { M2 }} {nets: {VSS}} } \
		   {{strategies: {S_MESH_TOP}} {layers: { M7 }} } \
			{via_master: {PGVIA_2X4}} } \
	}

compile_pg -strategies {S_MESH_TOP S_MESH_LOW} -via_rule {S_VIA_M2_M7}

####################################
## Standard Cell Rail
####################################

# Build STD cell Rails
create_pg_std_cell_conn_pattern STD_RAIL_PATTERN

set_pg_strategy S_STD_RAIL \
	-core \
	-pattern   { {name: STD_RAIL_PATTERN} {nets: {VDD VSS}} } \
	-blockage  { {{nets: {VDD VSS}} {macros_with_keepout: {ICACHE/ICACHE_SRAM/SRAM48 ICACHE/ICACHE_SRAM/SRAM8}}} } \
	-extension { {stop: core_boundary} }

set_pg_strategy_via_rule S_VIA_STD_RAIL \
        -via_rule {{intersection: adjacent}{via_master: default}}

compile_pg -strategies {S_STD_RAIL} -via_rule {S_VIA_STD_RAIL}
