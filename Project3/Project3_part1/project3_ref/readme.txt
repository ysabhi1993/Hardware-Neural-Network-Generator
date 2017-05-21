ESE-507 Fall 2016
Project 3 
Handout Code with Testbench Generator

Please see comments in main.cc for information about how this code is structured.

To compile your code, run: 
      make

------------------------------------------------------

For Part 1 and Part 2, run the generator with:
      ./gen 1 M N P T const_file

As an example, you can try this with M=4, N=4, P=4, T=16, and const_file = const.txt:
      ./gen 1 4 4 4 16 const.txt

Then see the result in layer_4_4_1_16.sv.


------------------------------------------------------

For Part 3, run the generator with:
      ./gen 2 N M1 M2 M3 L T const_file

As an example, to make layer 1: 4x5, layer 2: 5x6, and layer 3: 6x7,
with a multiplier budget of 15 and T=16 bits, run:
      ./gen 2 4 5 6 7 15 16 const.txt

Then see the result in network_4_5_6_7_15_16.sv.

------------------------------------

Testing:

The testbench generator produces a .sv testbench file as well as three data files
that specify the input values to test, the expected output values, and the
constants for W and b.

The testbench produces names related to parameters you pick.

For mode 1: run the testbench generator with:
    ./testgen 1 M N P T
(where you replace M N P and T with your values for those parameters.
This will produce four files:
- tb_layer_M_N_P_T.sv  - the testbench file
- tb_layer_M_N_P_T.in  - the inputs to test
- tb_layer_M_N_P_T.exp - the expected results
- const_M_N_P_T.txt    - the constants to give your generator

Then, you would generate the accompanying code with:
   ./gen 1 M N P T const_M_N_P_T.txt
This will produce your layer_M_N_P_T.sv file.

Then, to simulate:
   vlog layer_M_N_P_T.sv tb_layer_M_N_P_T.sv
   vsim tb_layer_M_N_P_T

The simulation will report any errors.


For mode 2: everything works similarly, except you give your tester 
parameters N M1 M2 M3 MULTBUDGET T


-------------------------

Test scripts:

To test your designs, we have provided you with two testscripts. You will
give a test script your parameters, and it will generate the testbench,
generate the design, and simulate it for you. 

To test, run:

./testmode1 M N P T

or 

./testmode2 N M1 M2 M3 MULTS T
