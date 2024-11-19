%% Clear Workspace and Load Libraries
clear;
addpath(genpath('/opt/NM/NeuroMiner_1.1/NeuroMiner_1.1/'));

%% Load Datasets
HC_sel = readtable('table_with_IXI_PRONIA_NORM_MUc_unif_AGE_ABMI_withBMIgapcorrected_16022022.xlsx');
HC_remaining = readtable('table_remaning_missingageremoved_HC_MUC_NORM_IXI_PRONIA_withBMIgapcorrected_16022022.xlsx');
PRONIA_ROP = readtable('table_with_PRONIAROP_withBMIgapcorrected_16022022.xlsx');
PRONIA_ROD = readtable('table_with_PRONIAROD_withBMIgapcorrected_16022022.xlsx');
PRONIA_CHR = readtable('table_with_PRONIACHR_withBMIgapcorrected_16022022.xlsx');
MUC_SCZ = readtable('table_with_MUC_SCZ_withBMIgapcorrected_16022022.xlsx');
ROP_SZC_ROP_NOTSCZ = readtable('ROP-SZC_ROP-NOTSCZ_ROD_HC_classification_4Adyasha.xlsx');

NM_reg = load('/volume/projects/AK_BMI/Analysis/NM_analysis/NM_struct/NM_IXI_NORM_MUC_PRONIA_HC_12112022.mat');
extractionfolder = 'figures/';

%% Separate Data by Site
pronia_norm = HC_sel(contains(HC_sel.Site_name, {'MilanNig', 'UBARI', 'UBS', 'UKK', 'UMUENS', 'Uni BHAM', 'Uni Turku', 'Uni Udine', 'LMU'}), :);
ixi_norm = HC_sel(contains(HC_sel.Site_name, {'Guys', 'HH', 'IOP'}), :);
MUC_norm = HC_sel(contains(HC_sel.Site_name, {'MUC'}), :);
NORM_norm = HC_sel(contains(HC_sel.Site_name, {'Oslo'}), :);

pronia_remaining = HC_remaining(contains(HC_remaining.Site_name, {'MilanNig', 'UBARI', 'UBS', 'UKK', 'UMUENS', 'Uni BHAM', 'Uni Turku', 'Uni Udine', 'LMU'}), :);
ixi_remaining = HC_remaining(contains(HC_remaining.Site_name, {'Guys', 'HH', 'IOP'}), :);
MUC_remaining = HC_remaining(contains(HC_remaining.Site_name, {'MUC'}), :);
NORM_remaining = HC_remaining(contains(HC_remaining.Site_name, {'Oslo'}), :);

%% Visualize Histogram
figure;
histogram(NM_reg.NM.label, 'BinWidth', 0.5);
title('BMI Histogram');

%% Calculate and Visualize BMI Gaps
BMI_HC_bal = NM_reg.NM.label;
predicted_BMI_HC = NM_reg.NM.analysis{2}.GDdims{1}.Regr.mean_predictions;
BMIgap_HC = predicted_BMI_HC - BMI_HC_bal;

figure;
scatter(BMI_HC_bal, BMIgap_HC);
title('BMI Gap vs. HC Balanced BMI');
xlabel('BMI Balanced');
ylabel('BMI Gap');

%% Perform Correlation Analysis
[r_corr, p_corr] = corr(BMI_HC_bal, BMIgap_HC);
fprintf('Correlation Coefficient: %.3f, p-value: %.3f\n', r_corr, p_corr);

%% Gender-Specific BMI Gap Analysis
BMI_gap_female = HC_sel.BMIgap_HC_sel_corrcted(HC_sel.Sex == 2);
BMI_gap_male = HC_sel.BMIgap_HC_sel_corrcted(HC_sel.Sex == 1);
[h_gender, p_gender] = ttest2(BMI_gap_female, BMI_gap_male);

fprintf('Gender BMI Gap t-test: h = %d, p = %.3f\n', h_gender, p_gender);

%% Calculate Statistics for Corrected BMI Gaps
BMIgap_corrected_HC = HC_sel.BMIgap_HC_sel_corrcted;
BMIgap_corrected_MUC_Scz = MUC_SCZ.BMIgap_MUCSCZ_corrcted;
BMIgap_corrected_ROP = PRONIA_ROP.BMIgap_ROP_corrcted;
BMIgap_corrected_CHR = PRONIA_CHR.BMIgap_CHR_corrcted;
BMIgap_corrected_ROD = PRONIA_ROD.BMIgap_ROD_corrcted;

mean_corrected_BMIgap_HC = mean(BMIgap_corrected_HC);
std_corrected_BMIgap_HC = std(BMIgap_corrected_HC);

fprintf('Corrected BMI Gap (HC): Mean = %.2f, Std = %.2f\n', mean_corrected_BMIgap_HC, std_corrected_BMIgap_HC);

%% Boxplot Visualization for Corrected BMI Gaps
figure;
boxplot([BMIgap_corrected_HC; BMIgap_corrected_MUC_Scz; BMIgap_corrected_ROP; BMIgap_corrected_CHR; BMIgap_corrected_ROD], ...
    [ones(size(BMIgap_corrected_HC, 1), 1); 2 * ones(size(BMIgap_corrected_MUC_Scz, 1), 1); ...
    3 * ones(size(BMIgap_corrected_ROP, 1), 1); 4 * ones(size(BMIgap_corrected_CHR, 1), 1); ...
    5 * ones(size(BMIgap_corrected_ROD, 1), 1)]);
title('Corrected BMI Gap by Group');
set(gca, 'XTickLabel', {'HC', 'MUC SCZ', 'ROP', 'CHR', 'ROD'});
xlabel('Groups');
ylabel('Corrected BMI Gap');

%% Save Boxplot
saveas(gcf, fullfile(extractionfolder, 'Corrected_BMIgap_Boxplot.png'));

%% Age-Specific Analysis for MUC SCZ
median_age = median(MUC_SCZ.Age);
MUC_SCZ.MedianSplit = MUC_SCZ.Age >= median_age;

BMIgap_above_median_age = mean(MUC_SCZ(MUC_SCZ.MedianSplit, :).BMIgap_MUCSCZ_corrcted);
BMIgap_below_median_age = mean(MUC_SCZ(~MUC_SCZ.MedianSplit, :).BMIgap_MUCSCZ_corrcted);

fprintf('MUC SCZ - Above Median Age BMI Gap: %.2f\n', BMIgap_above_median_age);
fprintf('MUC SCZ - Below Median Age BMI Gap: %.2f\n', BMIgap_below_median_age);

%% Save Final Analysis Results
save(fullfile(extractionfolder, 'BMIgap_Analysis_Results.mat'), 'BMIgap_corrected_HC', 'BMIgap_corrected_MUC_Scz', 'BMIgap_corrected_ROP', 'BMIgap_corrected_CHR', 'BMIgap_corrected_ROD');