////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Header of multilayer perceptron
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                                       Youngin Park (young_in@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

void fully_connected(int[], int[], int [], int);
void load_bias_to_scratch_pad(int [], int [], int [], int []);
void load_input_to_scratch_pad(int [], int []);
void store_output_to_scratch_pad(int [], int);
void store_output(int [], int);
int max(int []);

#define INPUT_SIZE   784
#define HIDDEN1_SIZE 128
#define HIDDEN2_SIZE 64
#define OUTPUT_SIZE  10
#define NUM_OF_TEST  10000
#define ARRAY_SIZE   4

#define COL_NUM     ((OUTPUT_SIZE+ARRAY_SIZE-1)/ARRAY_SIZE)
#define ROW_NUM     ((NUM_OF_TEST+ARRAY_SIZE-1)/ARRAY_SIZE)

#define FC1_O_ADDR   0x00004000
#define FC2_O_ADDR   0x00004000
#define SCRATCH_ADDR 0x00004000
#define FC1_W_ADDR   SCRATCH_ADDR  + 0x00001000 
#define FC2_W_ADDR   (FC1_W_ADDR   + INPUT_SIZE   * HIDDEN1_SIZE * sizeof(int)) 
#define FC3_W_ADDR   (FC2_W_ADDR   + HIDDEN1_SIZE * HIDDEN2_SIZE * sizeof(int)) 
#define FC1_B_ADDR   (FC3_W_ADDR   + HIDDEN2_SIZE * OUTPUT_SIZE  * sizeof(int)) 
#define FC2_B_ADDR   (FC1_B_ADDR   + HIDDEN1_SIZE * sizeof(int))
#define FC3_B_ADDR   (FC2_B_ADDR   + HIDDEN2_SIZE * sizeof(int))
#define OUTPUT_ADDR  (FC3_B_ADDR   + OUTPUT_SIZE  * sizeof(int)) 
#define INPUT_ADDR   (OUTPUT_ADDR  + ARRAY_SIZE   * ARRAY_SIZE   * COL_NUM  * sizeof(int)) 
#define LABEL_ADDR   (INPUT_ADDR   + INPUT_SIZE   * NUM_OF_TEST  * sizeof(int)) 


