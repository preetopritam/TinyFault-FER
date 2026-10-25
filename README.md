<div align="center">

<h1>TinyFault-FER</h1>

<h3>Inference-Aware RTL Fault Injection of a Quantized INT8 Classifier MAC Datapath</h3>

<p>
  <img src="https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white">
  <img src="https://img.shields.io/badge/TensorFlow-TFLite-FF6F00?logo=tensorflow&logoColor=white">
  <img src="https://img.shields.io/badge/RTL-SystemVerilog-555555">
  <img src="https://img.shields.io/badge/Simulation-Icarus_Verilog-6A5ACD">
  <img src="https://img.shields.io/badge/Quartus_II-13.0_SP1-0071C5">
</p>

<p><strong>22,400 fault scenarios · Bit-exact clean RTL verification · 169.55 MHz registered MAC datapath</strong></p>

</div>

TinyFault-FER studies how transient single-bit faults in the signed 32-bit accumulator of a quantized INT8 classifier affect the final predicted class.

The experiment targets the final fully connected classifier of a compact facial-expression-recognition CNN. The RTL campaign evaluates one controlled architectural fault location: the completed output-neuron accumulator.
Scope: this repository does not claim arbitrary cycle-level fault injection, earlier-layer RTL faults, a complete CNN accelerator implementation, or physical FPGA fault injection.

Experimental Pipeline
<div align="center">

<strong>
FER2013-Enhanced → Compact CNN → Full-INT8 TFLite → Final-Layer Integer Reconstruction → SystemVerilog MAC/Accumulator → Single-Bit Fault Campaign → Reconstructed Decision Analysis → Quartus Synthesis
</strong>




<img src="results/pipeline.png" width="1000">

</div>

Frozen Results
<div align="center">

<table>
<tr>
<th align="left">Metric</th>
<th align="center">Result</th>
</tr>
<tr><td>FP32 accuracy on provided test split</td><td align="center"><b>62.45%</b></td></tr>
<tr><td>Full-INT8 accuracy on provided test split</td><td align="center"><b>62.54%</b></td></tr>
<tr><td>Fault-campaign input samples</td><td align="center"><b>100</b></td></tr>
<tr><td>Final-layer dimensions</td><td align="center"><b>32 features × 7 outputs</b></td></tr>
<tr><td>RTL fault scenarios</td><td align="center"><b>22,400</b></td></tr>
<tr><td>Python ↔ RTL clean accumulator agreement</td><td align="center"><b>Bit-exact</b></td></tr>
<tr><td>Clean reconstructed decision ↔ TFLite agreement</td><td align="center"><b>100%</b></td></tr>
<tr><td>Overall decision-flip rate</td><td align="center"><b>12.43%</b></td></tr>
<tr><td>Decision-preserving faults</td><td align="center"><b>87.57%</b></td></tr>
<tr><td>Most vulnerable accumulator bit</td><td align="center"><b>Bit 31</b></td></tr>
<tr><td>Bit-31 decision-flip rate</td><td align="center"><b>81.71%</b></td></tr>
</table>

</div>

The fault campaign used 100 correctly classified INT8 samples drawn without replacement from the provided test split. For each selected input, faults were injected into all seven output neurons and all 32 accumulator bits:
<div align="center">


<strong>100 samples × 7 neurons × 32 bits = 22,400 fault scenarios</strong>
</div>


The reported decision-flip rates therefore describe this fixed 100-sample campaign. They should not be interpreted as a statistical estimate of hardware reliability over the full test split or the broader FER2013 population.
Dataset and Model
The frozen notebook uses the public Hugging Face dataset:
abhilash88/fer2013-enhanced
Only the 48 × 48 grayscale images and seven emotion labels are used as CNN inputs/targets. Additional metadata from the dataset mirror is not used as a model feature.
<div align="center">

<table>
<tr>
<th>Provided split</th>
<th>Samples</th>
</tr>
<tr><td>Train</td><td align="center"><b>25,117</b></td></tr>
<tr><td>Validation</td><td align="center"><b>5,380</b></td></tr>
<tr><td>Test</td><td align="center"><b>5,390</b></td></tr>
</table>

</div>


The accuracy values reported here refer specifically to these provided mirror splits. They should not be interpreted as benchmark results on the canonical FER2013 Training/PublicTest/PrivateTest partition.

The trained CNN was converted to a full-INT8 TensorFlow Lite model. Its final classifier has:
<div align="center">


<strong>32 input features → 7 output neurons</strong>
</div>


Quantized activations, weights, biases, scales, and zero-points were extracted from the TFLite model. Activation zero-point correction was incorporated into the RTL bias term so that the reconstructed clean integer accumulator matched the deployed quantized arithmetic.
RTL Datapath
The simulation RTL is provided in:
rtl/int8_mac_accum.sv
rtl/tb_fault_campaign.sv
The analyzed arithmetic path is:
<div align="center">


<strong>signed INT8 activation × signed INT8 weight → signed 16-bit product → signed 32-bit accumulation</strong>
</div>


For each output neuron, the testbench reconstructs the complete accumulator over 32 input features and then flips one selected accumulator bit after accumulation is complete.

Each selected input contributes:
<div align="center">


<strong>7 output neurons × 32 accumulator bits = 224 fault scenarios</strong>
</div>


The raw RTL campaign records:
sample,neuron,bit,clean_acc,faulted_acc
in reports/rtl_faults.csv.
Verification
Before fault analysis, clean RTL accumulator values were compared against the Python integer reconstruction of the final TFLite classifier.
<div align="center">

<table>
<tr>
<th align="left">Verification</th>
<th align="center">Result</th>
</tr>
<tr><td>Python ↔ RTL accumulator arithmetic</td><td align="center"><b>Bit-exact</b></td></tr>
<tr><td>Clean reconstructed argmax ↔ TFLite</td><td align="center"><b>100% agreement</b></td></tr>
</table>

</div>


For faulty cases, the modified accumulator is mapped to the reconstructed pre-output-requantization class score using the corresponding accumulator scale. The faulty argmax is then compared with the clean reconstructed argmax.
Important methodological boundary: TFLite's final output requantization and clipping are not separately emulated for every faulty accumulator. The reported decision-flip rates therefore apply to the reconstructed final-layer score model used in the frozen campaign.

Fault-Injection Results
Across 22,400 fault scenarios:
- 2,785 changed the reconstructed predicted class.
- 19,615 preserved the clean decision.
- Overall decision-flip rate: 12.43%.
- Bits 0–9 produced no decision changes in this campaign.
- Bit 31 was the most vulnerable accumulator position.
- Bit 31 changed the class decision in 572 / 700 = 81.71% of its tested scenarios.
Accumulator-Bit Vulnerability
<div align="center">
<img src="results/accumulator_bit_vulnerability.png" width="850">
</div>

Bit 31 is the sign bit of the signed 32-bit two's-complement accumulator. Its corruption is therefore numerically much more significant than lower-order bit perturbations.
Fault Outcome Distribution
<div align="center">
<img src="results/fault_outcome_distribution.png" width="650">
</div>

Most injected faults were masked at the final reconstructed class decision: 87.57% preserved the clean argmax.
Output-Neuron Vulnerability
<div align="center">

<table>
<tr>
<th>Output class</th>
<th>Decision-flip rate</th>
</tr>
<tr><td>Angry</td><td align="center"><b>8.91%</b></td></tr>
<tr><td>Disgust</td><td align="center"><b>4.09%</b></td></tr>
<tr><td>Fear</td><td align="center"><b>20.91%</b></td></tr>
<tr><td>Happy</td><td align="center"><b>6.44%</b></td></tr>
<tr><td>Sad</td><td align="center"><b>18.06%</b></td></tr>
<tr><td>Surprise</td><td align="center"><b>6.63%</b></td></tr>
<tr><td>Neutral</td><td align="center"><b>22.00%</b></td></tr>
</table>


<img src="results/output_neuron_vulnerability.png" width="850">

</div>

The campaign shows that numerical corruption and inference failure are not equivalent: many accumulator faults are masked at the final decision, while high-significance bit positions are substantially more likely to alter the argmax.
Quartus Synthesis
A registered wrapper around the same signed INT8 MAC datapath was synthesized using Quartus II 13.0 SP1 for an Altera Cyclone IV E EP4CE22F17C6.
The synthesis target is a single registered MAC datapath, not the complete CNN, seven-neuron classifier, or fault-injection testbench.

<div align="center">

<table>
<tr>
<th align="left">Resource / Timing Metric</th>
<th align="center">Result</th>
</tr>
<tr><td>Logic elements</td><td align="center"><b>64</b></td></tr>
<tr><td>Registers</td><td align="center"><b>64</b></td></tr>
<tr><td>Embedded multiplier resources</td><td align="center"><b>1</b></td></tr>
<tr><td>Memory bits</td><td align="center"><b>0</b></td></tr>
<tr><td>PLLs</td><td align="center"><b>0</b></td></tr>
<tr><td>Clock constraint</td><td align="center"><b>100 MHz</b></td></tr>
<tr><td>Worst-case setup slack</td><td align="center"><b>+4.102 ns</b></td></tr>
<tr><td>Worst-case hold slack</td><td align="center"><b>+0.920 ns</b></td></tr>
<tr><td>Registered-datapath Fmax</td><td align="center"><b>169.55 MHz</b></td></tr>
</table>

</div>

The reported timing comes from static timing analysis. External board-level I/O timing was not modeled, and no physical FPGA deployment or physical fault injection was performed.

Quartus evidence is retained in:
reports/quartus_resource_summary.txt
reports/tinyfault_mac.fit.summary
reports/tinyfault_mac.sta.rpt
Repository Structure
TinyFault-FER/
├── README.md
├── LICENSE
├── CITATION.cff
├── .gitignore
│
├── notebooks/
│   └── TinyFault_FER_Colab.ipynb
│
├── rtl/
│   ├── int8_mac_accum.sv
│   └── tb_fault_campaign.sv
│
├── quartus/
│   ├── int8_mac_accum.v
│   ├── quartus_top.v
│   ├── tinyfault_mac.qpf
│   ├── tinyfault_mac.qsf
│   ├── tinyfault_mac.sdc
│   └── compile.bat
│
├── reports/
│   ├── rtl_faults.csv
│   ├── rtl_summary.json
│   ├── bit_vulnerability_summary.csv
│   ├── fault_outcome_summary.csv
│   ├── output_neuron_vulnerability_summary.csv
│   ├── quartus_resource_summary.txt
│   ├── tinyfault_mac.fit.summary
│   └── tinyfault_mac.sta.rpt
│
├── results/
│   ├── pipeline.png
│   ├── accumulator_bit_vulnerability.png
│   ├── fault_outcome_distribution.png
│   └── output_neuron_vulnerability.png
│
└── docs/
    └── DESIGN_DECISIONS.md
Reproducibility
The frozen notebook records the workflow used to:
1. load the dataset;
2. train the CNN;
3. convert it to full-INT8 TFLite;
4. extract final-layer quantized tensors;
5. reconstruct clean integer accumulators;
6. generate RTL memory vectors;
7. run the Icarus Verilog fault campaign;
8. verify clean Python ↔ RTL arithmetic;
9. map faulty accumulators to reconstructed class decisions;
10. generate vulnerability summaries and figures.
The RTL testbench expects:
activations.mem
weights.mem
biases.mem
These files are generated by the notebook and are not stored as frozen campaign inputs in the repository. The exact frozen .tflite, seed .npz, and generated .mem files are also not committed.

Therefore, the repository preserves the frozen notebook, raw RTL output, summaries, figures, RTL sources, and Quartus evidence, and the workflow can be inspected and rerun. However, the exact frozen numerical campaign cannot be replayed byte-for-byte from the committed files alone without regenerating the model-dependent artifacts.

Re-running training/conversion may produce a different trained model and should not be treated as reproduction of the exact frozen campaign.
Scope and Limitations
<div align="center">

<table>
<tr>
<th align="left">Component</th>
<th align="center">Scope</th>
</tr>
<tr><td>CNN execution</td><td align="center">TensorFlow / TensorFlow Lite</td></tr>
<tr><td>Quantization</td><td align="center">Full INT8</td></tr>
<tr><td>Classifier dimensions</td><td align="center">32 features → 7 outputs</td></tr>
<tr><td>RTL fault target</td><td align="center">Completed final-layer 32-bit accumulator</td></tr>
<tr><td>Fault model</td><td align="center">Transient single-bit flip</td></tr>
<tr><td>Fault positions</td><td align="center">Bits 0–31</td></tr>
<tr><td>Campaign inputs</td><td align="center">100 correctly classified INT8 samples</td></tr>
<tr><td>Total fault scenarios</td><td align="center">22,400</td></tr>
<tr><td>FPGA analysis</td><td align="center">Quartus synthesis + static timing</td></tr>
<tr><td>Physical FPGA deployment</td><td align="center">Not performed</td></tr>
</table>

</div>

TinyFault-FER does not evaluate:
- faults in convolution layers;
- faults at arbitrary MAC cycles;
- register, control-path, memory, or interconnect faults;
- permanent or multi-bit faults;
- a complete accelerator RTL implementation;
- physical FPGA fault injection;
- population-level hardware reliability;
- exact TFLite post-requantization behavior for every faulty accumulator.
A natural extension is to study earlier layers or processing elements and then compare protection strategies using inference impact, fault coverage, latency, and hardware overhead.
Reference
I. J. Goodfellow et al.,
“Challenges in Representation Learning: A Report on Three Machine Learning Contests,”
Neural Networks, vol. 64, pp. 59–63, 2015.
<div align="center">

Author
Pritam Kumar Das

Google Scholar
</div>
