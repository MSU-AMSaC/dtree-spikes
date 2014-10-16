This is a repository for source code associated with a signal processing
research project at Michigan State University's Advanced Microsystems and
Circuits (AMSaC) lab, homepage at http://www.egr.msu.edu/amsac.
It consists of digital hardware (Verilog HDL) and testing/supplementary
scripts (various languages) for a real-time neural action potential
classification algorithm, as described in the paper

Y. Yang, C. S. Boling, A. J. Mason, "Power-area efficient VLSI implementation
of decision tree based spike classification for neural recording implants",
IEEE BioCAS 2014.

Extracellular recordings of neural data using intracortical microelectrodes
have shown promise for medical and rehabilitative neuroscience applications,
e.g. brain-machine interfaces. The principal complications with this approach
are 1) massive bandwidth and power requirements as systems scale to the
hundreds/thousands of channels required for next-generation neurotechnologies
and 2) determining which individual cell is responsible for producing a
specific recorded action potential ("spike") in the neural time series.
This work attempts to improve the power performance of a parallel digital
hardware approach to the latter problem, simultaneously reducing the
system bandwidth requirements by transmitting only neuron IDs.

For more details and related work please visit
http://www.egr.msu.edu/amsac/nsp.htm.