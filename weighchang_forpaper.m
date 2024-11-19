%% Initialize and Standardize Data
PRONIA_ROD_T0_T1_all_n = readtable('PRONIA_ROD_T0_T1_all.csv');
PRONIA_CHR_T0_T1_all_n = readtable('PRONIA_CHR_T0_T1_all.csv');
PRONIA_ROP_T0_T1_all_n = readtable('PRONIA_ROP_T0_T1_all.csv');
PRONIA_HC_T0_T1_all_n = readtable('PRONIA_HC_T0_T1_all.csv');

PRONIA_ROD_T0_T2_all_n = readtable('PRONIA_ROD_T0_T2_all.csv');
PRONIA_CHR_T0_T2_all_n = readtable('PRONIA_CHR_T0_T2_all.csv');
PRONIA_ROP_T0_T2_all_n = readtable('PRONIA_ROP_T0_T2_all.csv');
PRONIA_HC_T0_T2_all_n = readtable('PRONIA_HC_T0_T2_all.csv');;

%% Find Common Variables Across Groups
commonVariables = @(table1, table2) table1.Properties.VariableNames(contains(table1.Properties.VariableNames, table2.Properties.VariableNames));

var_names_HC = commonVariables(PRONIA_HC_T0_T2_all_n, PRONIA_ROD_T0_T2_all_n);
ind_HC = contains(PRONIA_ROD_T0_T2_all_n.Properties.VariableNames, var_names_HC);

%% Combine Data Across Groups
PRONIA_all_T0_T2_all_n = [PRONIA_ROD_T0_T2_all_n(:, ind_HC); PRONIA_CHR_T0_T2_all_n(:, ind_HC); PRONIA_HC_T0_T2_all_n(:, ind_HC)];
PRONIA_all_T0_T1_all_n = [PRONIA_ROD_T0_T1_all_n(:, ind_HC); PRONIA_CHR_T0_T1_all_n(:, ind_HC); PRONIA_HC_T0_T1_all_n(:, ind_HC)];

%% Define Subject Groups and Parameters
subjectGroups = {'PRONIA_ROD_T0_T1_all_n', 'PRONIA_CHR_T0_T1_all_n', 'PRONIA_HC_T0_T1_all_n', ...
                 'PRONIA_ROD_T0_T2_all_n', 'PRONIA_CHR_T0_T2_all_n', 'PRONIA_HC_T0_T2_all_n', ...
                 'PRONIA_all_T0_T1_all_n', 'PRONIA_all_T0_T2_all_n'};
weightChangeThresholds = [3, 5, 7]; % Percent
ageRanges = [15, 20; 20, 25; 25, 30; 30, 35; 35, 40]; % Age ranges

%% Calculate Correlations
correlations = struct();
for groupIdx = 1:numel(subjectGroups)
    groupName = subjectGroups{groupIdx};
    data = eval(groupName);

    correlations.(groupName) = struct();
    for ageIdx = 1:size(ageRanges, 1)
        ageRange = ageRanges(ageIdx, :);
        ageFilteredData = data(data.AGE >= ageRange(1) & data.AGE < ageRange(2), :);

        ageRangeKey = sprintf('age_%d_to_%d', ageRange(1), ageRange(2));
        correlations.(groupName).(ageRangeKey) = struct();

        for threshold = weightChangeThresholds
            percentWeightChange = (ageFilteredData.weightdelta_T1 ./ ageFilteredData.SOMAT_02_Weight_corr_Screening) * 100;

            % Weight gain and loss filtering
            weightGain = ageFilteredData(percentWeightChange >= threshold, :);
            weightLoss = ageFilteredData(percentWeightChange <= -threshold, :);

            % Calculate correlations
            if ~isempty(weightGain)
                [gainCorr, gainPval] = corr(weightGain.BMIgap_corrcted, weightGain.weightdelta_T1, 'Rows', 'complete');
                N_gain = size(weightGain, 1);
            else
                [gainCorr, gainPval, N_gain] = deal(NaN);
            end

            if ~isempty(weightLoss)
                [lossCorr, lossPval] = corr(weightLoss.BMIgap_corrcted, weightLoss.weightdelta_T1, 'Rows', 'complete');
                N_loss = size(weightLoss, 1);
            else
                [lossCorr, lossPval, N_loss] = deal(NaN);
            end

            % Store results
            correlations.(groupName).(ageRangeKey).(sprintf('Gain_%d_percent_corr', threshold)) = gainCorr;
            correlations.(groupName).(ageRangeKey).(sprintf('Gain_%d_percent_pval', threshold)) = gainPval;
            correlations.(groupName).(ageRangeKey).(sprintf('Gain_%d_percent_number', threshold)) = N_gain;
            correlations.(groupName).(ageRangeKey).(sprintf('Loss_%d_percent_corr', threshold)) = lossCorr;
            correlations.(groupName).(ageRangeKey).(sprintf('Loss_%d_percent_pval', threshold)) = lossPval;
            correlations.(groupName).(ageRangeKey).(sprintf('Loss_%d_percent_number', threshold)) = N_loss;
        end
    end
end

%% Display Correlations
disp(correlations);