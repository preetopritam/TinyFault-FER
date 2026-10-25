# TinyFault-FER

**Inference-Aware RTL Fault Injection of a Quantized INT8 Classifier MAC Datapath**

TinyFault-FER studies how transient single-bit faults in the signed 32-bit accumulator of a quantized INT8 classifier affect the final predicted class.

The experiment targets the final fully connected classifier of a compact FER CNN:

```text
32 INT8 input features
        ↓
signed INT8 × INT8 multiply
        ↓
signed 16-bit product
        ↓
signed 32-bit accumulator
        ↓
7 output-class scores
```

The RTL campaign evaluates one controlled architectural fault location: the **completed output-neuron accumulator**. It does not model arbitrary cycle-level faults, earlier CNN layers, or physical FPGA fault injection.

## Experimental Pipeline

```text
FER2013-Enhanced dataset
        ↓
Compact CNN
        ↓
Full-INT8 TensorFlow Lite model
        ↓
Final-layer quantized tensors
        ↓
Python integer reconstruction
        ↓
SystemVerilog MAC/accumulator
        ↓
Single-bit RTL fault campaign
        ↓
Reconstructed class-decision analysis
        ↓
Quartus synthesis and static timing
```

![Experimental pipeline](results/pipeline.png)

## Frozen Results

| Metric | Result |
|---|---:|
| FP32 accuracy on the provided test split | 62.45% |
| Full-INT8 accuracy on the provided test split | 62.54% |
| Fault-campaign input samples | 100 |
| Final-layer dimensions | 32 features × 7 outputs |
| RTL fault injections | 22,400 |
| Python ↔ RTL clean accumulator agreement | Bit-exact |
| Clean reconstructed decision ↔ TFLite agreement | 100% |
| Overall decision-flip rate | 12.43% |
| Decision-preserving faults | 87.57% |
| Most vulnerable accumulator bit | Bit 31 |
| Bit-31 decision-flip rate | 81.71% |

The campaign used 100 correctly classified INT8 samples drawn without replacement from the provided test split. For each selected input, faults were injected into all seven output neurons and all 32 accumulator bits:

```text
100 samples × 7 neurons × 32 bits = 22,400 fault scenarios
```

The reported decision-flip rates therefore describe this **fixed 100-sample campaign**. They are not a statistical estimate of hardware reliability over the full test split or the broader FER2013 population.

## Dataset and Model

The notebook uses the public Hugging Face dataset:

```text
abhilash88/fer2013-enhanced
```

Only the 48 × 48 grayscale images and seven emotion labels are used as CNN inputs/targets. Additional metadata from the dataset mirror is not used as a model feature.

The provided splits used in the frozen notebook are:

| Split | Samples |
|---|---:|
| Train | 25,117 |
| Validation | 5,380 |
| Test | 5,390 |

The accuracy values reported in this repository refer specifically to these provided splits. They should not be interpreted as benchmark results on the canonical FER2013 Training/PublicTest/PrivateTest partition.

The trained CNN was converted to a full-INT8 TensorFlow Lite model. The final classifier has:

```text
32 input features → 7 output neurons
```

Quantized activations, weights, biases, scales, and zero-points were extracted from the TFLite model. Activation zero-point correction was incorporated into the RTL bias term so that the reconstructed integer accumulator matched the deployed quantized arithmetic.

## RTL Datapath

The simulation RTL is in:

```text
rtl/int8_mac_accum.sv
rtl/tb_fault_campaign.sv
```

The MAC datapath implements:

```text
signed INT8 activation × signed INT8 weight
→ signed 16-bit product
→ sign extension
→ signed 32-bit accumulation
```

The testbench reconstructs each output-neuron accumulator over 32 input features, then flips one selected accumulator bit after accumulation is complete.

For each selected sample:

```text
7 output neurons × 32 bit positions = 224 faults
```

The raw RTL campaign writes:

```text
sample, neuron, bit, clean_acc, faulted_acc
```

to `reports/rtl_faults.csv`.

## Verification

Before fault analysis, clean RTL accumulator values were compared against a Python integer reconstruction of the final TFLite classifier.

The frozen campaign achieved:

- **bit-exact Python ↔ RTL accumulator agreement**
- **100% clean reconstructed argmax agreement with TFLite** for the 100 campaign samples

For faulty cases, the modified accumulator is mapped to the reconstructed **pre-output-requantization class score** using the corresponding accumulator scale. The faulty argmax is then compared with the clean reconstructed argmax.

This analysis does **not** separately emulate TFLite's final output requantization and clipping for every faulty accumulator. The reported decision-flip rates therefore apply to the reconstructed final-layer score model used in the frozen campaign.

## Fault-Injection Results

Across all 22,400 fault scenarios:

- **2,785** changed the predicted class.
- **19,615** preserved the clean decision.
- Overall decision-flip rate: **12.43%**.
- Bits 0–9 caused no decision changes in this campaign.
- **Bit 31**, the signed accumulator MSB, was the most vulnerable position.
- Bit 31 changed the predicted class in **572 / 700 cases = 81.71%**.

![Accumulator-bit vulnerability](results/accumulator_bit_vulnerability.png)

![Fault outcome distribution](results/fault_outcome_distribution.png)

Vulnerability also varied across final-layer output neurons:

| Output class | Decision-flip rate |
|---|---:|
| Angry | 8.91% |
| Disgust | 4.09% |
| Fear | 20.91% |
| Happy | 6.44% |
| Sad | 18.06% |
| Surprise | 6.63% |
| Neutral | 22.00% |

![Output-neuron vulnerability](results/output_neuron_vulnerability.png)

These results show that numerical corruption and inference failure are not equivalent: many accumulator faults were masked at the final class decision, while high-significance bits were substantially more likely to alter the argmax.

## Quartus Synthesis

A registered wrapper around the same signed INT8 MAC datapath was synthesized using **Quartus II 13.0 SP1** for:

```text
Altera Cyclone IV E EP4CE22F17C6
```

The synthesis target is a **single registered MAC datapath**, not the complete CNN, seven-neuron classifier, or fault-injection testbench.

| Metric | Result |
|---|---:|
| Logic elements | 64 |
| Registers | 64 |
| Embedded multiplier resources | 1 |
| Memory bits | 0 |
| PLLs | 0 |
| Clock constraint | 100 MHz |
| Worst-case setup slack | +4.102 ns |
| Worst-case hold slack | +0.920 ns |
| Registered-datapath Fmax | 169.55 MHz |

The reported timing comes from static timing analysis. External board-level I/O timing was not modeled, and **no physical FPGA deployment or physical fault injection was performed**.

Quartus evidence is retained in:

```text
reports/quartus_resource_summary.txt
reports/tinyfault_mac.fit.summary
reports/tinyfault_mac.sta.rpt
```

## Repository Structure

```text
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
```

## Reproducibility

The notebook records the frozen end-to-end workflow used to:

1. load the dataset,
2. train the CNN,
3. convert it to full INT8 TFLite,
4. extract final-layer quantized tensors,
5. reconstruct clean integer accumulators,
6. generate RTL memory vectors,
7. run the Icarus Verilog fault campaign,
8. verify clean RTL arithmetic,
9. map faulty accumulators to reconstructed class decisions,
10. generate vulnerability summaries.

The RTL testbench expects:

```text
activations.mem
weights.mem
biases.mem
```

These files are generated by the notebook and are **not stored as frozen campaign inputs in the repository**. The exact frozen `.tflite`, seed `.npz`, and generated `.mem` files are also not committed.

Therefore:

- the repository preserves the frozen notebook, raw RTL fault output, result summaries, figures, RTL sources, and Quartus evidence;
- the experimental workflow can be inspected and rerun;
- but the exact frozen campaign cannot be replayed byte-for-byte from the committed files alone without regenerating the model-dependent artifacts.

Re-running the training/conversion pipeline may produce a different trained model and therefore should not be treated as reproduction of the exact frozen numerical campaign.

## Scope and Limitations

TinyFault-FER is intentionally limited to one final-layer classifier datapath.

It does not evaluate:

- faults in convolution layers;
- faults injected at arbitrary MAC cycles;
- register, control-path, memory, or interconnect faults;
- permanent or multi-bit faults;
- full accelerator RTL;
- physical FPGA fault injection;
- population-level hardware reliability;
- exact TFLite post-requantization behavior for every faulty accumulator.

A natural extension is to study fault propagation across earlier layers or processing elements and then compare protection strategies using inference impact, fault coverage, latency, and hardware overhead.

## Reference

I. J. Goodfellow et al., “Challenges in Representation Learning: A Report on Three Machine Learning Contests,” *Neural Networks*, vol. 64, pp. 59–63, 2015.

## Author

**Pritam Kumar Das**

Google Scholar: https://scholar.google.com/citations?hl=en&user=nZ0Ys7EAAAAJ
