# Design Decisions

## 1. Source-aware evaluation

Some samples in the dataset come from the same RTL source or design family, so they are not fully independent.

A random split could place closely related variants in both training and test sets. That would make the test set easier and could give an overly optimistic estimate of generalization.

For this reason, I grouped samples by source component during evaluation. Variants from the same source are kept in the same partition.

This makes the evaluation harder, but it better reflects the actual question I care about: whether the model can predict QoR for an unseen RTL design.
