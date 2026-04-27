%% BMS_DCDC_Verify
% BMS-DCDC 管理算法 V1.0 工程验证脚本。

fprintf('Verifying BMS-DCDC Manager V1 project...\n');

%% 核心行为自检
BMS_DCDC_Core_SelfTest;

%% MATLAB Code Analyzer
filesToCheck = { ...
    'BMS_DCDC_Params.m', ...
    'BMS_DCDC_Manager_Core.m', ...
    'BMS_DCDC_Core_SelfTest.m', ...
    'BMS_DCDC_BusDef.m', ...
    'build_BMS_DCDC_Manager_V1.m'};

for idx = 1:numel(filesToCheck)
    issues = checkcode(filesToCheck{idx}, '-id');
    if isempty(issues)
        fprintf('Code Analyzer: %s has no messages.\n', filesToCheck{idx});
    else
        fprintf('Code Analyzer: %s has %d message(s).\n', filesToCheck{idx}, numel(issues));
        for issueIdx = 1:numel(issues)
            fprintf('  %s line %d: %s\n', issues(issueIdx).id, issues(issueIdx).line, issues(issueIdx).message);
        end
    end
end

%% Simulink 模型结构检查
modelName = 'BMS_DCDC_Manager_V1';
assert(exist([modelName '.slx'], 'file') == 4, 'Model file BMS_DCDC_Manager_V1.slx was not found.');

load_system(modelName);
expectedBlocks = { ...
    [modelName '/Scenario_Source'], ...
    [modelName '/Input_Bus_Builder'], ...
    [modelName '/BMS_DCDC_Manager_Core'], ...
    [modelName '/Output_Bus_Builder']};

for idx = 1:numel(expectedBlocks)
    [~, blockName] = fileparts(expectedBlocks{idx});
    assert(~isempty(find_system(modelName, 'SearchDepth', 1, 'Name', blockName)), ...
        'Expected top-level block is missing: %s', expectedBlocks{idx});
end

expectedInports = {'SystemRunCmd', 'SystemTargetPower', 'NumClusters', 'MinRunCurrent', ...
    'SOC', 'SOH', 'ClusterVoltage', 'MaxTemperature', 'FaultStatus', ...
    'DCDCCommOK', 'DCDCCommTimeout', 'RatedChargeCurrent', 'RatedDischargeCurrent'};
expectedOutports = {'DCDCEnableCmd', 'DCDCModeCmd', 'TargetPower', 'TargetCurrent', ...
    'ChargeCurrentLimit', 'DischargeCurrentLimit', 'StopReason', 'LimitReason', ...
    'AvailableChargePower', 'AvailableDischargePower'};

for idx = 1:numel(expectedInports)
    assert(~isempty(find_system(modelName, 'SearchDepth', 1, 'BlockType', 'Inport', 'Name', expectedInports{idx})), ...
        'Expected inport is missing: %s', expectedInports{idx});
end

for idx = 1:numel(expectedOutports)
    assert(~isempty(find_system(modelName, 'SearchDepth', 1, 'BlockType', 'Outport', 'Name', expectedOutports{idx})), ...
        'Expected outport is missing: %s', expectedOutports{idx});
end

close_system(modelName, 0);

fprintf('BMS-DCDC Manager V1 verification completed.\n');
