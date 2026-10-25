# Design Decisions

## Why I used the final classifier layer

I used the final fully connected classifier as the RTL fault target because it is small enough to study clearly, while each corrupted accumulator value can still be traced directly to the final predicted class. The earlier convolution layers are outside the scope of this project.

## Why I used INT8 arithmetic

The trained CNN was converted to a full-INT8 TensorFlow Lite model. I therefore extracted the deployed quantized activations, weights, biases, scales, and zero-points and used those values for the RTL experiment.

## Why the accumulator is 32-bit

The RTL datapath uses signed INT8 activations and weights, producing a signed 16-bit product. The products are accumulated in a signed 32-bit accumulator, matching the integer arithmetic reconstructed from the deployed TFLite classifier.

## Why I used 100 samples

The fault campaign used 100 correctly classified INT8 test samples selected without replacement. This kept the RTL campaign manageable while still allowing every output neuron and every accumulator bit to be tested for each selected input.

This is an exploratory campaign, not a statistical estimate of hardware reliability over the complete FER2013 test set.

## Where the fault is injected

For each output neuron, the clean accumulator is first computed over all 32 input features. A transient single-bit fault is then injected into the completed 32-bit accumulator before the final class decision is evaluated.

This means the experiment studies faults at one controlled accumulator location. It does not model faults occurring at arbitrary MAC cycles or inside earlier CNN layers.

## Why all 32 bits are tested

Each accumulator bit is flipped independently so that the inference effect can be compared across bit positions. This is important because numerical corruption does not always change the final predicted class.

## FPGA scope

The registered MAC datapath was synthesized in Quartus II for an Altera Cyclone IV E device. The reported FPGA results come from synthesis and static timing analysis.

No physical FPGA fault-injection experiment was performed.

## Main limitation and next step

TinyFault-FER studies one representative final-layer classifier datapath rather than a complete CNN accelerator. A natural next step is to extend the same inference-aware fault analysis to earlier layers and larger accelerator structures.
