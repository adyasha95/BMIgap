% Clear workspace and add required paths
clear;
addpath(genpath('/opt/NM/NeuroMiner_1.1/NeuroMiner_1.1/'));

%% Load input data tables
HC_sel_path = '/table_with_IXI_PRONIA_NORM_MUC_HC_unif_AGE_ABMI_27102022.xlsx';
HC_remaining_path = '/table_remaning_missingageremoved_HC_MUC_NORM_IXI_PRONIA_27102022.xlsx';
PRONIA_ROP_path = '/table_with_PRONIAROP_22112022.xlsx';
PRONIA_ROD_path = '/table_with_PRONIAROD_22112022.xlsx';
PRONIA_CHR_path = '/table_with_PRONIACHR_22112022.xlsx';
MUC_SCZ_path = '/table_with_MUC_SCZ_14112022.xlsx';

HC_sel = readtable(HC_sel_path);
HC_remaining = readtable(HC_remaining_path);
PRONIA_ROP = readtable(PRONIA_ROP_path);
PRONIA_ROD = readtable(PRONIA_ROD_path);
PRONIA_CHR = readtable(PRONIA_CHR_path);
MUC_SCZ = readtable(MUC_SCZ_path);

%% Load NeuroMiner results
NM_reg = load('/volume/projects/AK_BMI/Analysis/NM_analysis/NM_struct/NM_IXI_NORM_MUC_PRONIA_HC_12112022.mat');
BMI_HC_bal = NM_reg.NM.label;

% Extract predicted BMI from NeuroMiner
predicted_BMI_HC = NM_reg.NM.analysis{2}.GDdims{1}.Regr.mean_predictions;
predicted_BMI_HCremaining = NM_reg.NM.analysis{2}.OOCV{5}.RegrResults{1,1}.MeanCV2PredictedValues;
predicted_BMI_MUC_Scz = NM_reg.NM.analysis{2}.OOCV{4}.RegrResults{1,1}.MeanCV2PredictedValues;
predicted_BMI_ROP = NM_reg.NM.analysis{2}.OOCV{6}.RegrResults{1,1}.MeanCV2PredictedValues;
predicted_BMI_ROD = NM_reg.NM.analysis{2}.OOCV{7}.RegrResults{1,1}.MeanCV2PredictedValues;
predicted_BMI_CHR = NM_reg.NM.analysis{2}.OOCV{8}.RegrResults{1,1}.MeanCV2PredictedValues;

%% Calculate BMI gaps
BMIgap_HC = predicted_BMI_HC - BMI_HC_bal;
BMIgap_HC_apply = predicted_BMI_HCremaining - HC_remaining.BMI;
BMIgap_MUC_Scz = predicted_BMI_MUC_Scz - MUC_SCZ.BMI;
BMIgap_ROP = predicted_BMI_ROP - PRONIA_ROP.BMI;
BMIgap_ROD = predicted_BMI_ROD - PRONIA_ROD.BMI;
BMIgap_CHR = predicted_BMI_CHR - PRONIA_CHR.BMI;

%% Visualize BMI gaps
scatter(BMI_HC_bal, BMIgap_HC);
title('BMI Gap vs. HC Balanced BMI');
xlabel('BMI HC Balanced');
ylabel('BMI Gap');

%% K-fold cross-validation setup
k = 5;
c = cvpartition(length(BMIgap_HC), 'KFold', k);

% Initialize variables
sY = nan(size(BMIgap_HC));
patgroup_BMIgap = BMIgap_CHR;
patgroup_BMI = PRONIA_CHR.BMI;
sY_pat = nan(length(patgroup_BMIgap), k);

% Cross-validation loop
for i = 1:c.NumTestSets
    idx_tr = training(c, i);
    idx_ts = test(c, i);

    % Training and testing sets
    Y_tr = BMIgap_HC(idx_tr);
    Y_ts = BMIgap_HC(idx_ts);

    % Setup input structure for partial correlations
    IN.TrCovars = BMI_HC_bal(idx_tr);
    IN.TsCovars = BMI_HC_bal(idx_ts);
    IN.nointercept = '';
    IN.subgroup = '';
    IN.beta = '';
    IN.revertflag = '';
    IN.METHOD = 1;

    % Regress out BMI in training data
    [sY_tr, IN_tr] = nk_PartialCorrelationsObj(Y_tr, IN);

    % Apply method to test data
    [sY_ts, IN_ts] = nk_PartialCorrelationsObj(Y_ts, IN_tr);

    % Apply method to patient data
    IN_tr.TsCovars = patgroup_BMI;
    [sY_pat(:, i), IN_pat] = nk_PartialCorrelationsObj(patgroup_BMIgap, IN_tr);

    % Store corrected values
    sY(idx_ts) = sY_ts;
end

% Compute corrected BMI gaps
BMIgap_HC_sel_corrected = sY;
BMIgap_ROP_corrected = mean(sY_pat, 2);
BMIgap_ROD_corrected = mean(sY_pat, 2);
BMIgap_CHR_corrected = mean(sY_pat, 2);
BMIgap_MUC_SCZ_corrected = mean(sY_pat, 2);
BMIgap_HCremain_corrected = mean(sY_pat, 2);

%% Scatter plots of corrected BMI gaps
scatter(BMIgap_HC_sel_corrected, BMI_HC_bal);
title('Corrected BMI Gap vs. HC Balanced BMI');
xlabel('Corrected BMI Gap');
ylabel('BMI HC Balanced');

%% Add corrected BMI gaps to tables
HC_sel = addvars(HC_sel, BMIgap_HC, BMIgap_HC_sel_corrected);
HC_remaining = addvars(HC_remaining, BMIgap_HC_apply, BMIgap_HCremain_corrected);
MUC_SCZ = addvars(MUC_SCZ, BMIgap_MUC_Scz, BMIgap_MUC_SCZ_corrected);
PRONIA_ROP = addvars(PRONIA_ROP, BMIgap_ROP, BMIgap_ROP_corrected);
PRONIA_ROD = addvars(PRONIA_ROD, BMIgap_ROD, BMIgap_ROD_corrected);
PRONIA_CHR = addvars(PRONIA_CHR, BMIgap_CHR, BMIgap_CHR_corrected);

%% Save updated tables
writetable(HC_sel, '/table_with_IXI_PRONIA_NORM_MUc_unif_AGE_ABMI_withBMIgapcorrected_16022022.xlsx', 'Sheet', 1);
writetable(HC_remaining, '/table_remaning_missingageremoved_HC_MUC_NORM_IXI_PRONIA_withBMIgapcorrected_16022022.xlsx', 'Sheet', 1);
writetable(MUC_SCZ, '/table_with_MUC_SCZ_withBMIgapcorrected_16022022.xlsx', 'Sheet', 1);
writetable(PRONIA_ROP, '/table_with_PRONIAROP_withBMIgapcorrected_16022022.xlsx', 'Sheet', 1);
writetable(PRONIA_ROD, '/table_with_PRONIAROD_withBMIgapcorrected_16022022.xlsx', 'Sheet', 1);
writetable(PRONIA_CHR, '/table_with_PRONIACHR_withBMIgapcorrected_16022022.xlsx', 'Sheet', 1);