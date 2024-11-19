# BMIgapCodeRepo

This repository contains MATLAB scripts for analyzing BMIgap, clinical measures, and group-wise statistics in clinical and healthy populations. The analysis includes PANSS,  weight changes, and demographic statistics, using datasets from various mulziste studies.

Table of Contents

	1.	Introduction
	2.	Dataset Description
	3.	Code Summary
	4.	Requirements
	5.	Usage
	6.	Acknowledgments

##Introduction

This project focuses on:
	•	BMIgap computation and correction for clinical and healthy control groups.
	•	Group-wise statistical comparisons across demographics, weight changes, and clinical measures.
	•	Analysis of correlations, ANOVA, and t-tests for evaluating the relationships between BMIgap and clinical variables.

Dataset Description

Main Datasets:

	1.	PRONIA: Contains clinical data for ROD, CHR, ROP, and HC groups.
	2.	MUC_SCZ: Data specific to MUC schizophrenia patients.
	3.	Additional Clinical Scores:
	•	PANSS: Positive, Negative, and General subscales.

##Code Summary

1. BMIgap Computation

	•	Scripts to calculate BMIgap (difference between predicted and actual BMI) for different groups.
	•	Correction methods for BMIgap using Partial Correlation Regression.

2. Clinical Measures Integration

	•	Aggregates PANSS, into composite variables.
	•	Merges clinical data with group-specific datasets (PRONIA_ROD, PRONIA_CHR, etc.).

3. Weight Change Analysis

	•	Analyzes correlations between BMIgap and weight changes across age ranges and thresholds.
	•	Categorizes subjects based on weight gain/loss.

4. Group Comparisons

	•	Performs:
	•	ANOVA to assess group differences in clinical and BMI-related variables.
	•	t-tests for pairwise comparisons.

5. Statistical Summaries

	•	Generates descriptive statistics (mean, standard deviation) for clinical measures across groups.

6. Visualization

	•	Creates scatter plots, boxplots, and histograms for BMIgap, clinical measures, and demographic statistics.

7. Utility Functions

	•	Modular functions for:
	•	Computing subscale totals (e.g., PANSS_Gen).
	•	Automating ANOVA and t-test workflows.
	•	Filtering and grouping data by age, weight change, or demographic criteria.

##Requirements

	•	MATLAB (R2020b or later)
	•	Data files (PRONIA, MUC_SCZ, and clinical datasets)
	•	Statistics and Machine Learning Toolbox

##Usage

	1.	Clone the repository:

git clone https://github.com/yourusername/BMIgap-Analysis.git
cd BMIgap-Analysis


	2.	Load datasets into the appropriate MATLAB workspace variables:
	•	Place the clinical data files in the data/ directory.
	•	Update paths in scripts as needed.
	3.	Run the scripts:
	•	BMIgap Analysis:

run BMIgapAnalysis.m


	•	Clinical Data Integration:

run ClinicalIntegration.m


	•	Group Comparisons:

run GroupComparisons.m


	4.	Results:
	•	Outputs include visualizations and .mat files summarizing statistical results.

##Contributer
- [Ariane Wiegand](https://github.com/arianewiegand)

