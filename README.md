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

<p><strong>22,400 RTL fault injections · Bit-exact RTL verification · 169.55 MHz synthesized datapath</strong></p>

</div>

---

**TinyFault-FER** studies how transient single-bit faults in the signed 32-bit accumulator of a deployed INT8 classifier propagate to **inference-level classification failures**.

The project connects a quantized neural-network workload to RTL fault injection and FPGA synthesis, allowing arithmetic corruption in the final classifier MAC/accumulator datapath to be evaluated by its effect on the final model decision.

<sub><strong>Keywords:</strong> RTL fault injection · INT8 CNN · quantized neural networks · AI accelerator reliability · FPGA · TinyML · transient bit flips · accumulator vulnerability · TensorFlow Lite · SystemVerilog</sub>

## Experimental Pipeline

<div align="center">

<strong>FER2013 → Compact CNN → Full-INT8 TFLite → Final-Layer MAC/Accumulator → RTL Fault Injection → Inference Vulnerability Analysis → FPGA Synthesis</strong>

<br><br>

<img src="results/pipeline.png" width="1000">

</div>

---

## Headline Results

<div align="center">

<table>
<tr>
<th align="left">Metric</th>
<th align="center">Result</th>
</tr>

<tr>
<td>FP32 test accuracy</td>
<td align="center"><b>62.45%</b></td>
</tr>

<tr>
<td>Full-INT8 test accuracy</td>
<td align="center"><b>62.54%</b></td>
</tr>

<tr>
<td>Validated inference samples</td>
<td align="center"><b>100</b></td>
</tr>

<tr>
<td>RTL fault injections</td>
<td align="center"><b>22,400</b></td>
</tr>

<tr>
<td>RTL ↔ Python accumulator verification</td>
<td align="center"><b>Bit-exact</b></td>
</tr>

<tr>
<td>Clean reconstruction ↔ TFLite agreement</td>
<td align="center"><b>100%</b></td>
</tr>

<tr>
<td>Overall decision-flip rate</td>
<td align="center"><b>12.43%</b></td>
</tr>

<tr>
<td>Most vulnerable accumulator bit</td>
<td align="center"><b>Bit 31</b></td>
</tr>

<tr>
<td>Bit-31 decision-flip rate</td>
<td align="center"><b>81.71%</b></td>
</tr>

<tr>
<td>Worst-case registered-datapath Fmax</td>
<td align="center"><b>169.55 MHz</b></td>
</tr>
</table>

</div>

---

## Methodology

### 1. Quantized CNN Workload

A compact convolutional neural network was trained for **7-class facial-expression recognition** and converted to a **full-integer TensorFlow Lite model**.

- FP32 test accuracy: **62.45%**
- Full-INT8 test accuracy: **62.54%**
- INT8–FP32 accuracy difference: **+0.09 percentage points**

The model was intentionally kept compact because the primary objective is **hardware fault analysis**, rather than maximizing facial-expression-recognition accuracy.

The experiment uses the **48 × 48 grayscale FER2013 images** and seven emotion labels exposed by the `abhilash88/fer2013-enhanced` Hugging Face dataset mirror. Additional quality metadata provided by the enhanced dataset was **not used as model input**.

<div align="center">

<table>
<tr>
<th>Split</th>
<th>Samples</th>
</tr>
<tr>
<td>Train</td>
<td align="center"><b>25,117</b></td>
</tr>
<tr>
<td>Validation</td>
<td align="center"><b>5,380</b></td>
</tr>
<tr>
<td>Test</td>
<td align="center"><b>5,390</b></td>
</tr>
</table>

</div>

### 2. RTL Datapath

The **final fully connected classifier** of the deployed INT8 model was selected as the RTL fault-analysis target.

I chose the final classifier because it gives a small, controllable RTL target while still allowing each injected fault to be traced to the final predicted class. Faults in the earlier convolution layers are outside the scope of this experiment.

The analyzed arithmetic path is:

```text
signed INT8 activation × signed INT8 weight
                    ↓
          signed 16-bit product
                    ↓
          signed 32-bit accumulator
```

The classifier contains:

```text
32 input features → 7 output neurons
```

Quantized activations, weights, biases, scales, and zero-points were extracted directly from the deployed TFLite model.

Activation zero-point correction was incorporated into the RTL bias term to preserve the intended signed integer arithmetic.

### 3. RTL Verification

The MAC/accumulator was implemented in **SystemVerilog** and simulated using **Icarus Verilog**.

Before fault injection, clean RTL accumulator outputs were compared against the Python integer reference reconstructed from the deployed TFLite tensors.

> **Bit-exact Python ↔ RTL accumulator agreement**

All **100 validated fault-campaign samples** also produced clean reconstructed classifier decisions identical to the corresponding TFLite decisions.

> **Clean reconstruction ↔ TFLite agreement: 100%**

This verification gate ensures that fault propagation is evaluated from integer arithmetic consistent with the deployed quantized classifier.

### 4. Fault-Injection Protocol

A **transient single-bit fault** was injected independently into every position of the signed 32-bit accumulator.

```text
100 inference samples
× 7 output neurons
× 32 accumulator bits
= 22,400 RTL fault injections
```

The 100 fault-campaign samples were selected without replacement from correctly classified INT8 test cases. Each sample contributes **224 deterministic fault scenarios**.

Each injected fault modifies one **completed output-neuron accumulator** before the final classification decision is evaluated.

A fault is defined as **inference-critical** when:

```text
faulty predicted class ≠ clean predicted class
```

This distinguishes low-level numerical corruption from corruption that propagates into an application-level inference failure.

> **Scope note:** Statistical uncertainty over a larger independent input population was not evaluated in this exploratory RTL campaign.

---

## Fault-Injection Results

Across **22,400 RTL fault injections**:

- **12.43%** changed the final predicted class.
- **87.57%** preserved the clean decision.
- Vulnerability varied strongly with accumulator bit position.
- **Bit 31** was the most vulnerable accumulator position.
- Bit-31 corruption produced an **81.71% decision-flip rate**.

### Accumulator-Bit Vulnerability

<div align="center">
<img src="results/accumulator_bit_vulnerability.png" width="850">
</div>

The results show substantial **fault-significance asymmetry**: corruption of numerically significant accumulator positions is considerably more likely to propagate into a classification failure.

Bit 31 is the **sign bit** of the signed 32-bit two's-complement accumulator. Toggling this bit changes the represented accumulator value by \(2^{31}\) in magnitude, making it qualitatively different from lower-order bit perturbations.

Its high vulnerability is therefore partly expected from numerical significance. The empirical result of interest is that **81.71% of tested bit-31 corruptions propagated through the competing class scores strongly enough to change the final argmax decision**.

### Fault Outcome Distribution

<div align="center">
<img src="results/fault_outcome_distribution.png" width="650">
</div>

Most injected arithmetic faults were masked at the inference level: **87.57%** preserved the original predicted class despite corruption of an accumulator value.

### Output-Neuron Vulnerability

<div align="center">
<img src="results/output_neuron_vulnerability.png" width="850">
</div>

The campaign also evaluates how vulnerability varies across the seven final-layer output neurons.

> **Numerical corruption and inference failure are not equivalent.**

A reliability analysis limited to low-level arithmetic corruption can therefore overestimate the application-level impact of many faults while failing to distinguish the accumulator positions most likely to change the model decision.

---

## FPGA Synthesis

The registered MAC datapath was synthesized using **Quartus II 13.0 SP1 (64-bit)** targeting an **Altera Cyclone IV E EP4CE22F17C6**.

<div align="center">

<table>
<tr>
<th align="left">Resource / Timing Metric</th>
<th align="center">Result</th>
</tr>

<tr>
<td>Logic elements</td>
<td align="center"><b>64</b></td>
</tr>

<tr>
<td>Registers</td>
<td align="center"><b>64</b></td>
</tr>

<tr>
<td>Embedded multiplier resources</td>
<td align="center"><b>1</b></td>
</tr>

<tr>
<td>Memory bits</td>
<td align="center"><b>0</b></td>
</tr>

<tr>
<td>PLLs</td>
<td align="center"><b>0</b></td>
</tr>

<tr>
<td>Clock constraint</td>
<td align="center"><b>100 MHz</b></td>
</tr>

<tr>
<td>Worst-case setup slack</td>
<td align="center"><b>+4.102 ns</b></td>
</tr>

<tr>
<td>Worst-case hold slack</td>
<td align="center"><b>+0.920 ns</b></td>
</tr>

<tr>
<td>Worst-case registered-datapath Fmax</td>
<td align="center"><b>169.55 MHz</b></td>
</tr>
</table>

</div>

Quartus inferred the signed `INT8 × INT8` multiplication as an embedded multiplier resource.

The reported **169.55 MHz Fmax** corresponds to static timing analysis of the **registered MAC datapath**.

External board-level I/O timing was not modeled, and no physical FPGA deployment was performed.

---

## Experimental Scope

<div align="center">

<table>
<tr>
<th align="left">Component</th>
<th align="center">Scope</th>
</tr>

<tr>
<td>CNN execution</td>
<td align="center">TensorFlow / TensorFlow Lite</td>
</tr>

<tr>
<td>Quantization</td>
<td align="center">Full INT8</td>
</tr>

<tr>
<td>Classifier dimensions</td>
<td align="center">32 features → 7 outputs</td>
</tr>

<tr>
<td>RTL fault target</td>
<td align="center">Final-layer MAC / 32-bit accumulator</td>
</tr>

<tr>
<td>RTL simulator</td>
<td align="center">Icarus Verilog</td>
</tr>

<tr>
<td>Fault model</td>
<td align="center">Transient single-bit accumulator flip</td>
</tr>

<tr>
<td>Injection point</td>
<td align="center">Completed output-neuron accumulator</td>
</tr>

<tr>
<td>Fault positions</td>
<td align="center">Bits 0–31</td>
</tr>

<tr>
<td>Validated inference samples</td>
<td align="center">100</td>
</tr>

<tr>
<td>Total fault injections</td>
<td align="center">22,400</td>
</tr>

<tr>
<td>FPGA analysis</td>
<td align="center">Quartus II synthesis + static timing</td>
</tr>

<tr>
<td>Physical FPGA deployment</td>
<td align="center">Not performed</td>
</tr>
</table>

</div>

TinyFault-FER evaluates a **representative quantized classifier arithmetic datapath**, rather than claiming a complete CNN RTL implementation.

RTL simulation provides deterministic and repeatable control over fault location while allowing all 32 accumulator positions to be evaluated across thousands of inference scenarios.

---

## Reproducibility

### Repository Structure

```text
TinyFault-FER/
├── README.md
├── LICENSE
├── .gitignore
├── CITATION.cff
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
├── results/
│   ├── pipeline.png
│   ├── accumulator_bit_vulnerability.png
│   ├── fault_outcome_distribution.png
│   └── output_neuron_vulnerability.png
│
└── reports/
    ├── rtl_summary.json
    ├── rtl_faults.csv
    └── quartus_resource_summary.txt
```

### Notebook Workflow

The Colab notebook implements the experimental pipeline:

1. load the FER2013 workload,
2. train the compact CNN,
3. convert the model to full INT8 TFLite,
4. evaluate FP32 and INT8 accuracy,
5. extract deployed final-layer quantized tensors,
6. reconstruct clean integer accumulators,
7. generate RTL test vectors,
8. execute the Icarus Verilog fault campaign,
9. verify Python ↔ RTL arithmetic,
10. propagate faulty accumulators to inference decisions,
11. generate vulnerability summaries and figures.

### RTL Simulation

The notebook generates the RTL memory vectors required by the testbench:

```text
activations.mem
weights.mem
biases.mem
```

With those generated files present alongside the RTL sources, the campaign is compiled and executed with:

```bash
iverilog -g2012 -Wall \
    -o fault_campaign.vvp \
    int8_mac_accum.sv \
    tb_fault_campaign.sv

vvp fault_campaign.vvp
```

Raw injection-level RTL output from the frozen campaign is provided in:

```text
reports/rtl_faults.csv
```

Frozen campaign summary:

```text
reports/rtl_summary.json
```

### Quartus Synthesis

**Tool:** Quartus II 13.0 SP1 (64-bit)  
**Target:** Altera Cyclone IV E EP4CE22F17C6

```bash
quartus_sh --flow compile tinyfault_mac
```

Synthesis and timing summary:

```text
reports/quartus_resource_summary.txt
```

---

## Dataset and References

### Dataset

[FER2013 Enhanced — Hugging Face](https://huggingface.co/datasets/abhilash88/fer2013-enhanced)

Dataset identifier:

```text
abhilash88/fer2013-enhanced
```

Only the FER2013 **48 × 48 grayscale images** and **seven expression labels** were used for the CNN workload. Additional metadata supplied by the enhanced mirror was not used as a model feature.

```text
Train        25,117
Validation    5,380
Test          5,390
```

### Original FER2013 Reference

I. J. Goodfellow et al.,  
**“Challenges in Representation Learning: A Report on Three Machine Learning Contests,”**  
*Neural Networks*, vol. 64, pp. 59–63, 2015.  
[DOI: 10.1016/j.neunet.2014.09.005](https://doi.org/10.1016/j.neunet.2014.09.005)

The publication describes the ICML 2013 representation-learning contests, including the facial-expression-recognition challenge associated with FER2013.

---

## Key Takeaway

<div align="center">

<h3>Hardware faults are not equally important at the inference level.</h3>

<p><strong>22,400 faults → 12.43% decision changes</strong></p>

<p><strong>Bit 31 → 81.71% decision-flip rate</strong></p>

</div>

Most accumulator corruptions in the evaluated campaign did **not** change the CNN decision, whereas faults in high-significance positions—particularly the signed most-significant bit—frequently propagated to classification failures.

TinyFault-FER therefore demonstrates the value of **inference-aware vulnerability analysis** alongside conventional low-level fault characterization for reliable quantized AI accelerator datapaths.

---

## Researcher

**Pritam K Das**  
Email: [preeto.pritam@gmail.com](mailto:preeto.pritam@gmail.com)  
Google Scholar: [Pritam K Das](https://scholar.google.com/citations?hl=en&user=nZ0Ys7EAAAAJ)
