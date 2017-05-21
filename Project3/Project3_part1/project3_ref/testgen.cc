#include <iostream>
#include <fstream>
#include <vector>
#include <time.h>
#include <cstdlib>
#include <cstdio>
#include <bitset>

using namespace std;

void printUsage();
void genRandomVector(vector<long>& v, int size, int bits);
void computeOutputs(vector<long>& W, vector<long>& B, vector<long>& x, vector<long>& y, int M, int N, int bits);
long checkOverflow(long v, int bits);
string hexString(long v, int bits);

int main(int argc, char* argv[]) {

  int approxInputs = 10000;

  srand(time(NULL)); // initialize random number generator
   if (argc < 6) {
      printUsage();
      return 1;
   }

   int mode = atoi(argv[1]);
   int numInputs;
   string constFileName;
   ofstream os;
   string tb_name;
   int bits;
   vector<long> outputVals;
   string inFileName, outFileName, dut_name, out_file;



   // Mode 1: for parts 1/2: testbench for a single layer
   if ((mode == 1) && (argc == 6)) {
      int M = atoi(argv[2]);
      int N = atoi(argv[3]);
      int P = atoi(argv[4]);
      bits = atoi(argv[5]);

      numInputs = approxInputs - (approxInputs%N);
      if (numInputs < N) {
         cout << "ERROR: N > numInputs" << endl;
         return 1;
      }

      // step 1: generate M*N+M random inputs (W matrix and b vector)
      //         store them in vector here, and also output them to a file
      // We are going to generate all constants to have max value of bits/2 
      // in order to make overflows relatively rare
      vector<long> wMatrix, bVector;
      genRandomVector(wMatrix, M*N, bits/2);
      genRandomVector(bVector, M, bits/2);

      // Store the constants to a file named const_M_N_P_T.txt
      constFileName = "const_" + to_string(M) + "_" + to_string(N) + "_" + to_string(P) + "_" + to_string(bits) + ".txt";
      os.open(constFileName);
      if (!os.is_open()) {
         cout << "ERROR opening " << constFileName << " for writing." << endl;
         return 1;
      }
      for (int i=0; i<M*N; i++) {
         os << wMatrix[i] << endl;
      }
      for (int i=0; i<M; i++) {
         os << bVector[i] << endl;
      }
      os.close();

      // step 2: generate input values
      vector<long> inputVals;
      genRandomVector(inputVals, numInputs, bits/2);

      inFileName = "tb_layer_" + to_string(M) + "_" + to_string(N) + "_" + to_string(P) + "_" + to_string(bits) + ".in";
      os.open(inFileName);
      if (!os.is_open()) {
         cout << "ERROR opening " << inFileName << " for writing." << endl;
         return 1;
      }
      for (int i=0; i<numInputs; i++) {
         string s = bitset<32>(inputVals[i]).to_string();         
         os << s.substr(32-bits, 32) << endl;
      }
      os.close();

      // step 3: compute expected outputs. output them to a file
      computeOutputs(wMatrix, bVector, inputVals, outputVals, M, N, bits);

      outFileName = "tb_layer_" + to_string(M) + "_" + to_string(N) + "_" + to_string(P) + "_" + to_string(bits) + ".exp";
      os.open(outFileName);
      if (!os.is_open()) {
         cout << "ERROR opening " << outFileName << " for writing." << endl;
         return 1;
      }
      for (int i=0; i<outputVals.size(); i++) {
         string s = bitset<32>(outputVals[i]).to_string();         
         os << s.substr(32-bits, 32) << endl;
      }
      os.close();

      dut_name = "layer_" + to_string(M) + "_" + to_string(N) + "_" + to_string(P) + "_" + to_string(bits);
      tb_name = "tb_" + dut_name;
      out_file = tb_name + ".sv";

   }
   else if ((mode == 2) && (argc == 8)) {
      int N  = atoi(argv[2]);
      int M1 = atoi(argv[3]);
      int M2 = atoi(argv[4]);
      int M3 = atoi(argv[5]);
      int mult_budget = atoi(argv[6]);
      bits = atoi(argv[7]);

      numInputs = approxInputs - (approxInputs%N);
      if (numInputs < N) {
         cout << "ERROR: N > numInputs" << endl;
         return 1;
      }

      // step 1: generate three random matrices and biases for the three layers
      // store them in vectors and output them to the constant file
      vector<long> wMatrix1, wMatrix2, wMatrix3, bVector1, bVector2, bVector3;
      genRandomVector(wMatrix1, N*M1, bits/2);
      genRandomVector(bVector1, M1, bits/2);
      genRandomVector(wMatrix2, M1*M2, bits/2);
      genRandomVector(bVector2, M2, bits/2);
      genRandomVector(wMatrix3, M2*M3, bits/2);
      genRandomVector(bVector3, M3, bits/2);

      constFileName = "const_" + to_string(N) + "_" + to_string(M1) + "_" + to_string(M2) + "_" + to_string(M3) + "_" + to_string(mult_budget) + "_" + to_string(bits) + ".txt";

      os.open(constFileName);
      if (!os.is_open()) {
         cout << "ERROR opening " << constFileName << " for writing." << endl;
         return 1;
      }
      for (int i=0; i<M1*N; i++) 
         os << wMatrix1[i] << endl;
      for (int i=0; i<M1; i++) 
         os << bVector1[i] << endl;
      for (int i=0; i<M2*M1; i++) 
         os << wMatrix2[i] << endl;
      for (int i=0; i<M2; i++) 
         os << bVector2[i] << endl;
      for (int i=0; i<M3*M2; i++) 
         os << wMatrix3[i] << endl;
      for (int i=0; i<M3; i++) 
         os << bVector3[i] << endl;
      os.close();

      // step 2: generate input values
      vector<long> inputVals;
      genRandomVector(inputVals, numInputs, bits/2);

      inFileName = "tb_network_" + to_string(N) + "_" + to_string(M1) + "_" + to_string(M2) + "_" + to_string(M3) + "_" + to_string(mult_budget) + "_" + to_string(bits) + ".in";
      os.open(inFileName);
      if (!os.is_open()) {
         cout << "ERROR opening " << inFileName << " for writing." << endl;
         return 1;
      }
      for (int i=0; i<numInputs; i++) {
         string s = bitset<32>(inputVals[i]).to_string();         
         os << s.substr(32-bits, 32) << endl;
      }
      os.close();

      // step 3: compute expected outputs
      vector<long> intermediateVals1, intermediateVals2;
      computeOutputs(wMatrix1, bVector1, inputVals,         intermediateVals1, M1, N,  bits);
      computeOutputs(wMatrix2, bVector2, intermediateVals1, intermediateVals2, M2, M1, bits);
      computeOutputs(wMatrix3, bVector3, intermediateVals2, outputVals,        M3, M2, bits);

      outFileName = "tb_network_" + to_string(N) + "_" + to_string(M1) + "_" + to_string(M2) + "_" + to_string(M3) + "_" + to_string(mult_budget) + "_" + to_string(bits) + ".exp";
      os.open(outFileName);
      if (!os.is_open()) {
         cout << "ERROR opening " << outFileName << " for writing." << endl;
         return 1;
      }
      for (int i=0; i<outputVals.size(); i++) {
         string s = bitset<32>(outputVals[i]).to_string();         
         os << s.substr(32-bits, 32) << endl;
      }
      os.close();
      dut_name = "network_" + to_string(N) + "_" + to_string(M1) + "_" + to_string(M2) + "_" + to_string(M3) + "_" + to_string(mult_budget) + "_" + to_string(bits);
      tb_name = "tb_" + dut_name;
      out_file = tb_name + ".sv";

   }
   else {
      printUsage();
      return 1;
   }

   // step 4: generate the testbench .sv file
   // To do this, I wrote a template called tbtemplate.txt.
   // This is the .sv file we want but a number of things need to be filled in based on
   // this design. So, we will use the command line tool "sed" to do the substituions.
   // This code could run outside of our program in a shell script, but it's very convenient
   // to include it here.
   string myCmd = "cat tbtemplate.txt";
   myCmd += "| sed 's/<TBMODULENAME>/" + tb_name + "/g; ";
   myCmd += " s/<NUMBITS>/" + to_string(bits)  + "/g;";
   myCmd += " s/<NUMINPUTVALS>/" + to_string(numInputs)  + "/g;";
   myCmd += " s/<NUMOUTPUTVALS>/" + to_string(outputVals.size())  + "/g;";
   myCmd += " s/<INFILENAME>/" +  inFileName + "/g;";
   myCmd += " s/<EXPFILENAME>/" +  outFileName + "/g;";
   myCmd += " s/<DUTNAME>/" +  dut_name + "/g;";
   myCmd += "' > " + out_file;
   system(myCmd.c_str());
}


void computeOutputs(vector<long>& W, vector<long>& B, vector<long>& x, vector<long>& y, int M, int N, int bits) {
   int iterations = x.size()/N;
   for (int i=0; i<iterations; i++) {
      for (int m=0; m<M; m++) {
         y.push_back(B[m]);
         for (int n=0; n<N; n++) {
            long prod = checkOverflow(W[m*N+n]*x[n+i*N], bits);
            y[m+i*M] = checkOverflow(y[m+i*M] + prod, bits);
         }
	 y[m+i*M] = (y[m+i*M] < 0) ? 0 : y[m+i*M];
      }
   }
}

long checkOverflow(long v, int bits) {
  long maxVal = ((long)1<<(bits-1))-1;
  long minVal = -1*((long)1<<(bits-1));
  long ovVal = ((long)1 << bits);
  
  while (v > maxVal)
    v -= ovVal;
  while (v < minVal)
    v += ovVal;
  return v;
}

void genRandomVector(vector<long>& v, int size, int bits) {
   for (int i=0; i<size; i++)
     v.push_back(rand()%(1<<bits)-(1<<(bits-1)));     
}

void printUsage() {
   cout << "usage: ./testgen mode ARGS" << endl;
   cout << "   Mode 1: Testbench for Mode 1 designs (Part 1 and Part 2)" << endl;
   cout << "      ./testgen 1 M N P bits" << endl;
   cout << "      Example: produce a testbench for given parameters" << endl;
   cout << "      Note that P does not affect the testbench, but we need it so the" << endl;
   cout << "      testbench's instantiation of your system matches the specification" << endl; 

   cout << "   Mode 2: Produce a system with three interconnected layers with four testbenches (Part 3)" << endl;
   cout << "      Arguments: N, M1, M2, M3, mult_budget, bits, const_file" << endl;
   cout << "         Layer 1: M1 x N matrix" << endl;
   cout << "         Layer 2: M2 x M1 matrix" << endl;
   cout << "         Layer 3: M3 x M2 matrix" << endl;
   cout << "              e.g.: ./testgen 2 4 5 6 7 15 16" << endl << endl;
}
