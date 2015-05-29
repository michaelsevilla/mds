mds
====
Author: Michael Sevilla  
Date: 10-24-2014  
Institution: UC Santa Cruz  
Email: msevilla@ucsc.edu  


Scripts for deploying and measuring CephFS with multiple MDSs. These scripts you have `gnuplot` installed.

Going into each directory and running:

`./plot.sh`

will produce the corresponding figure. Running:

`./cluster-setup.sh; ./run.sh`

will deploy the cluster and run the experiment.

Contents
- balancers:    custom metadata balancers and the environment constructors for Mantle
- debian:       used to create .deb packages
- experiments:  experiment specification formats (ESF)
- README.md:    this file
- sc15:         data and scripts to graph figures from SC'15 paper
- scripts:      scripts to run Mantle experiments
- src:          source code for Mantle
- tools:        tools to help construct balancers

End of file

