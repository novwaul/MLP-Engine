////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Code of multilayer perceptron
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                                       Youngin Park (young_in@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

#include "mlp.h"

int main(void){
    int* scratch     = (int*)(SCRATCH_ADDR);
    int* input       = (int*)(INPUT_ADDR);
    int* fc1_weight  = (int*)(FC1_W_ADDR);
    int* fc1_bias    = (int*)(FC1_B_ADDR);
    int* fc1_output  = (int*)(FC1_O_ADDR);
    int* fc2_weight  = (int*)(FC2_W_ADDR);
    int* fc2_bias    = (int*)(FC2_B_ADDR);
    int* fc2_output  = (int*)(FC2_O_ADDR);
    int* fc3_weight  = (int*)(FC3_W_ADDR);
    int* fc3_bias    = (int*)(FC3_B_ADDR);
    int* output      = (int*)(OUTPUT_ADDR);
    int* label       = (int*)(LABEL_ADDR);

////////////////////////////////////////////////////////////////////////////////
//  Inference
    register unsigned int image_idx asm("x26");
    register unsigned int correct_count asm("x27") = 0;


    unsigned int start_clow, start_chigh;
    unsigned int start_ilow, start_ihigh;
    unsigned int end_clow, end_chigh;
    unsigned int end_ilow, end_ihigh;

    asm volatile("csrrs %0, mcycle, x0" : "=r" (start_clow));
    asm volatile("csrrs %0, mcycleh, x0" : "=r" (start_chigh));
    asm volatile("csrrs %0, minstret, x0" : "=r" (start_ilow));
    asm volatile("csrrs %0, minstreth, x0" : "=r" (start_ihigh));
    
    int systolic_reg2=2; // dummy
    int *scratch_input;

    // load bias to scratch pad
    load_bias_to_scratch_pad(scratch, fc1_bias, fc2_bias, fc3_bias);
    
    //set pointers to point scratch pad
    fc1_bias = scratch;
    fc2_bias = fc1_bias + HIDDEN1_SIZE;
    fc3_bias = fc2_bias + HIDDEN2_SIZE;
    scratch_input = fc3_bias + OUTPUT_SIZE;
    fc1_output = scratch_input + INPUT_SIZE*ARRAY_SIZE;
    fc2_output = scratch_input;

    // execution
    for (int i = 0; i < ROW_NUM; i++) {
        // load input to scratch pad
        load_input_to_scratch_pad(scratch_input, &input[INPUT_SIZE * ARRAY_SIZE * i]);
        // layer 1
        for (int j = 0; j < HIDDEN1_SIZE/ARRAY_SIZE; j++) {
            fully_connected(scratch_input, &fc1_weight[INPUT_SIZE * ARRAY_SIZE * j], &fc1_bias[ARRAY_SIZE * j], INPUT_SIZE);
            store_output_to_scratch_pad(&fc1_output[ARRAY_SIZE * j], HIDDEN1_SIZE);
        }
        // layer 2
        for (int j = 0; j < HIDDEN2_SIZE/ARRAY_SIZE; j++) {
            fully_connected(fc1_output, &fc2_weight[HIDDEN1_SIZE * ARRAY_SIZE * j], &fc2_bias[ARRAY_SIZE * j], HIDDEN1_SIZE);
            store_output_to_scratch_pad(&fc2_output[ARRAY_SIZE * j], HIDDEN2_SIZE);
        }
        // layer 3
        for (int j = 0; j < COL_NUM; j++) {
            fully_connected(fc2_output, &fc3_weight[HIDDEN2_SIZE * ARRAY_SIZE * j], &fc3_bias[ARRAY_SIZE * j], HIDDEN2_SIZE);
            store_output(&output[ARRAY_SIZE * j], ARRAY_SIZE * COL_NUM);
        }

        for (int j = 0; j < ARRAY_SIZE; j++) {
            if (((ARRAY_SIZE * i + j) < NUM_OF_TEST) && (max(&output[ARRAY_SIZE * COL_NUM * j]) == label[ARRAY_SIZE * i + j])){
                ++correct_count;
            }
        }
    }


    asm volatile("csrrs %0, mcycle, x0" : "=r" (end_clow));
    asm volatile("csrrs %0, mcycleh, x0" : "=r" (end_chigh));
    asm volatile("csrrs %0, minstret, x0" : "=r" (end_ilow));
    asm volatile("csrrs %0, minstreth, x0" : "=r" (end_ihigh));
//
////////////////////////////////////////////////////////////////////////////////

    // Total clock
    register unsigned int cycle_low asm("x28") = end_clow - start_clow;
    if (cycle_low > end_clow){
        --end_chigh;
    }
    register unsigned int cycle_high asm("x29") = end_chigh - start_chigh;

    // Total instruction-retired count
    register unsigned int inst_low asm("x30") = end_ilow - start_ilow;
    if (inst_low > end_ilow){
        --end_ihigh;
    }
    register unsigned int inst_high asm("x31") = end_ihigh - start_ihigh;

    // Testbench uses this register to check the end of the simulation
    register unsigned int finish asm("x25") = 99999;

    return 0;
};

void store_output(int output[], int output_size) {
    int systolic_reg3=2; // dummy
    char *systolic_output = (char *) output;
    for (int i = 0; i < ARRAY_SIZE; i++) {
        for (int j = 0; j < ARRAY_SIZE; j++) {
            *(systolic_output + 4 * (output_size*i + j)) = systolic_reg3;
        }
    }
}

void store_output_to_scratch_pad(int output[], int output_size){
    int systolic_reg3=2; // dummy
    for (int i = 0; i < ARRAY_SIZE; i++) {
        for (int j = 0; j < ARRAY_SIZE; j++) {
            asm volatile("lbu x24, 0(%0)": "=r" (systolic_reg3) : "r" (&output[output_size*i+j]));
        }
    }
}

void load_input_to_scratch_pad(int scratch_input[], int input[]){
    for (int j = 0; j < INPUT_SIZE * ARRAY_SIZE; j++) {
        *(((short *)scratch_input) + 2*j) = input[j];
    }
}

void load_bias_to_scratch_pad(int scratch[], int fc1_bias[], int fc2_bias[], int fc3_bias[]){
    short *scratch_bias1 = (short *) scratch;
    for (int i = 0; i < HIDDEN1_SIZE; i++) {
        *(scratch_bias1 + 2*i) = fc1_bias[i];
    }
    fc1_bias = (int *) scratch_bias1;
    short *scratch_bias2 = (short *) (fc1_bias + HIDDEN1_SIZE);
    for (int i = 0; i < HIDDEN2_SIZE; i++) {
        *(scratch_bias2 + 2*i) = fc2_bias[i];
    }
    fc2_bias = (int *) scratch_bias2;
    short *scratch_bias3 = (short *) (fc2_bias + HIDDEN2_SIZE);
    for (int i = 0; i < OUTPUT_SIZE; i++) {
         *(scratch_bias3 + 2*i) = fc3_bias[i];
    }
}

void fully_connected(int input[], int weight[], int bias[], int input_size){
    // dummys
    unsigned int systolic_reg0=0;
    unsigned int systolic_reg1=1;
    unsigned int systolic_reg2=2;
    unsigned int systolic_reg3=3;

    // load bias
    for (int i = 0; i < ARRAY_SIZE; i++) {
        asm volatile("lb x24, 0(%0)": "=r" (systolic_reg1) : "r" (&bias[i]));
    }

    for (int k = 0; k < input_size; k++) {
        // load weight
        for (int j = 0; j < ARRAY_SIZE; j++) {
            asm volatile("lhu x24, 0(%0)": "=r" (systolic_reg1) : "r" (&weight[input_size*j + k]));
        }
        // load input or intermediate output
        for (int i = 0; i < ARRAY_SIZE; i++) {
            asm volatile("lh x24, 0(%0)": "=r" (systolic_reg1) : "r" (&input[input_size*i + k]));
        }
        // MAC
        asm volatile("mulh x24, x23, x22": "=r" (systolic_reg2) : "r" (systolic_reg0), "r" (systolic_reg1));
    }
    
    // ACT
    asm volatile("mulhu x24, x23, x22": "=r" (systolic_reg2) : "r" (systolic_reg0), "r" (systolic_reg1));
}

int max(int input[]) {
    int max_value = input[0];
    int max_index = 0;
    for (int i = 1; i < OUTPUT_SIZE; ++i) {
        if (input[i] > max_value) {
            max_value = input[i];
            max_index = i;
        }
    }
    return max_index;
}