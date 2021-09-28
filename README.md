# Automated-Event-Classification
The files available in this repository were used to obtain the results presented in the paper "Automated Event Classification in Power PlantsBased on DFR Data and Symmetrical Components". The Matlab and Simulink files generate the dataset. The JupiterNotebook are used: 1) to convert .mat files to .npy files; 2) to training and validation of the CNN; 3) to validation of the CNN; 4) to the fuzzy classification.

# Folders and its content
## Matlab
It contains all matlab functions used to generate the .mat dataset. It also contains the simulink model. The main matlab function calls the simulink models during its execution. Each simulink simulation results in two .mat output files, one for the CNN based classifier and other for the classifier based on fuzzy logic.


