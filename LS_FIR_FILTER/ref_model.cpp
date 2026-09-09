#include <iostream>
#include <vector>
#include <cmath>
#include <iomanip>
#include <fstream>
#include <cstdint> 

using namespace std;

// --- Parameters ---
const int NUM_TAPS = 73;
const int NUM_SAMPLES = 100; // As required by the deliverable

// Floating-point filter coefficients
const float coeff_float[NUM_TAPS] = {
    0.025804122, 0.020552684, 0.028396631, 0.037923047, 0.049296639, 0.062671826, 0.078188509,
    0.095967794, 0.116107786, 0.138679546, 0.163723333, 0.191245225, 0.221214225, 0.253559961,
    0.288171034, 0.324894126, 0.363533898, 0.403853725, 0.445577304, 0.488391123, 0.53194777,
    0.575870065, 0.61975593, 0.663183933, 0.705719403, 0.746921012, 0.786347677, 0.82356567,
    0.858155769, 0.889720317, 0.917890027, 0.942330394, 0.962747575, 0.978893597, 0.990570797,
    0.997635377, 1.0, 0.997635377, 0.990570797, 0.978893597, 0.962747575, 0.942330394, 0.917890027,
    0.889720317, 0.858155769, 0.82356567, 0.786347677, 0.746921012, 0.705719403, 0.663183933,
    0.61975593, 0.575870065, 0.53194777, 0.488391123, 0.445577304, 0.403853725, 0.363533898,
    0.324894126, 0.288171034, 0.253559961, 0.221214225, 0.191245225, 0.163723333, 0.138679546,
    0.116107786, 0.095967794, 0.078188509, 0.062671826, 0.049296639, 0.037923047, 0.028396631,
    0.020552684, 0.025804122
};

int main() {
    vector<int16_t> coeff_fixed(NUM_TAPS);
    vector<int16_t> input_fixed(NUM_SAMPLES);
    vector<int16_t> output_fixed(NUM_SAMPLES);

    // 1. Convert Coefficients to 16-bit Q2.14 Fixed-Point
    cout << "--- Fixed Point Coefficients (Q2.14) ---" << endl;
    for (int i = 0; i < NUM_TAPS; i++) {
        coeff_fixed[i] = round(coeff_float[i] * 16384.0f);
    }

    // 2. Generate 100 Input Samples in Q3.10 format
    // Simulating a mix of low and high frequencies to test the filter
    cout << "--- Generating 100 Input Samples (Q3.10) ---" << endl;
    for (int i = 0; i < NUM_SAMPLES; i++) {
        // Create a synthetic signal (e.g., sine wave sum) max amplitude ~1.5
        float sample = 1.0 * sin(2 * M_PI * 0.05 * i) + 0.5 * sin(2 * M_PI * 0.4 * i);
        
        // Convert to Q3.10 format (multiply by 2^10 = 1024)
        input_fixed[i] = round(sample * 1024.0f); 
    }

    // 3. FIR Filtering Operation (Convolution)
    for (int n = 0; n < NUM_SAMPLES; n++) {
        int64_t accumulator = 0; // Use a large accumulator to prevent overflow during sum
        
        for (int k = 0; k < NUM_TAPS; k++) {
            if (n - k >= 0) {
                accumulator += (int32_t)input_fixed[n - k] * (int32_t)coeff_fixed[k];
            }
        }

        // 4. Convert output to Q(3,13) format
        // Accumulator has 10 (input) + 14 (coeff) = 24 fractional bits.
        // We need 13 fractional bits, so shift right by 11 (24 - 13).
        output_fixed[n] = (int16_t)(accumulator >> 11);
    }

    // 5. Output Results for Verilog Test Bench Comparison
    cout << "\nSample\tInput(Q3.10)\tOutput(Q3.13)" << endl;
    cout << "----------------------------------------" << endl;
    for (int i = 0; i < 20; i++) { // Printing first 20 for brevity
        cout << i << "\t" 
             << input_fixed[i] << "\t\t" 
             << output_fixed[i] << endl;
    }
    
    // Optional: Write to file for easy Verilog $readmemh loading
    ofstream infile("input_samples.txt");
for (int i = 0; i < NUM_SAMPLES; i++) {
    infile << hex << setw(4) << setfill('0') << (input_fixed[i] & 0xFFFF) << endl;
}
infile.close();
    cout << "\n100 outputs written to 'golden_reference_out.txt' in hex format." << endl;

    return 0;
}