module tb_fault_campaign;

    localparam integer N_SAMPLES  = 100;
    localparam integer N_CLASSES  = 7;
    localparam integer N_FEATURES = 32;

    logic signed [7:0]  activations [0:N_SAMPLES*N_FEATURES-1];
    logic signed [7:0]  weights     [0:N_CLASSES*N_FEATURES-1];
    logic signed [31:0] biases      [0:N_CLASSES-1];

    logic signed [7:0]  x;
    logic signed [7:0]  w;
    logic signed [31:0] acc_in;
    logic signed [31:0] acc_out;

    logic signed [31:0] clean_acc;
    logic signed [31:0] faulted_acc;
    logic        [4:0]  bit_index;

    integer sample_i;
    integer neuron_i;
    integer feature_i;
    integer bit_i;
    integer fout;

    int8_mac_accum dut_mac (
        .x(x),
        .w(w),
        .acc_in(acc_in),
        .acc_out(acc_out)
    );

    bitflip32 dut_fault (
        .din(clean_acc),
        .bit_index(bit_index),
        .dout(faulted_acc)
    );

    initial begin
        $readmemh("activations.mem", activations);
        $readmemh("weights.mem", weights);
        $readmemh("biases.mem", biases);

        fout = $fopen("rtl_faults.csv", "w");
        $fwrite(fout, "sample,neuron,bit,clean_acc,faulted_acc\n");

        for (sample_i = 0; sample_i < N_SAMPLES; sample_i = sample_i + 1) begin
            for (neuron_i = 0; neuron_i < N_CLASSES; neuron_i = neuron_i + 1) begin
                clean_acc = biases[neuron_i];

                for (feature_i = 0; feature_i < N_FEATURES; feature_i = feature_i + 1) begin
                    x = activations[sample_i*N_FEATURES + feature_i];
                    w = weights[neuron_i*N_FEATURES + feature_i];
                    acc_in = clean_acc;
                    #1;
                    clean_acc = acc_out;
                end

                for (bit_i = 0; bit_i < 32; bit_i = bit_i + 1) begin
                    bit_index = bit_i[4:0];
                    #1;
                    $fwrite(
                        fout,
                        "%0d,%0d,%0d,%0d,%0d\n",
                        sample_i,
                        neuron_i,
                        bit_i,
                        clean_acc,
                        faulted_acc
                    );
                end
            end
        end

        $fclose(fout);
        $display("FAULT_CAMPAIGN_COMPLETE");
        $finish;
    end
endmodule
