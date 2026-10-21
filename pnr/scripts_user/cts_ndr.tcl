################################################################################
## AS501
## Final Project
## CTS Non-Default-Routing(NDR) Rule
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Jihwan Cho (jihwancho@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch

set CTS_NDR_MIN_ROUTING_LAYER       M4
set CTS_NDR_MAX_ROUTING_LAYER       M6
set CTS_LEAF_NDR_MIN_ROUTING_LAYER  M1
set CTS_LEAF_NDR_MAX_ROUTING_LAYER  M6
set CTS_NDR_RULE_NAME               cts_w2_s2_vlg
set CTS_LEAF_NDR_RULE_NAME          cts_w1_s2

# Clock routing rule for Clock tree
if {$CTS_NDR_RULE_NAME != ""} {
    remove_routing_rules $CTS_NDR_RULE_NAME > /dev/null

    create_routing_rule $CTS_NDR_RULE_NAME \
        -default_reference_rule \
        -widths { M1 0.1 M2 0.11 M3 0.11 M4 0.11 M5 0.11 M6 0.11 } \
        -spacings { M2 0.16 M3 0.45 M4 0.45 M5 1.1 M6 1.1 }

    set_clock_routing_rules -rules $CTS_NDR_RULE_NAME \
    -min_routing_layer $CTS_NDR_MIN_ROUTING_LAYER \
    -max_routing_layer $CTS_NDR_MAX_ROUTING_LAYER

}

# Clock routing rule for Leaf
if {$CTS_LEAF_NDR_RULE_NAME != ""} {
    remove_routing_rules $CTS_LEAF_NDR_RULE_NAME > /dev/null

    create_routing_rule $CTS_LEAF_NDR_RULE_NAME \
        -default_reference_rule \
        -spacings { M2 0.16 M3 0.45 M4 0.45 M5 1.1 M6 1.1}

    set_clock_routing_rules -net_type sink -rules $CTS_LEAF_NDR_RULE_NAME \
        -min_routing_layer $CTS_LEAF_NDR_MIN_ROUTING_LAYER \
        -max_routing_layer $CTS_LEAF_NDR_MAX_ROUTING_LAYER
}