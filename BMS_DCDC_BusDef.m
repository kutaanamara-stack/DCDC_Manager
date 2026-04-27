%% BMS_DCDC_BusDef
% BMS-DCDC 管理算法 V1.0 Bus 定义。
% 第一版算法可直接使用固定维度信号；Bus 对象用于接口文档化和后续扩展。

%% 输入 Bus
inputElements = repmat(Simulink.BusElement, 1, 13);

inputElements(1).Name = 'SystemRunCmd';
inputElements(1).DataType = 'boolean';
inputElements(1).Dimensions = 1;
inputElements(1).Description = '系统运行命令，false 时所有 DCDC 停机';

inputElements(2).Name = 'SystemTargetPower';
inputElements(2).DataType = 'double';
inputElements(2).Dimensions = 1;
inputElements(2).Description = '系统目标功率，kW，正值放电，负值充电';

inputElements(3).Name = 'NumClusters';
inputElements(3).DataType = 'uint8';
inputElements(3).Dimensions = 1;
inputElements(3).Description = '实际参与计算的簇数，V1.0 范围 0 到 4';

inputElements(4).Name = 'MinRunCurrent';
inputElements(4).DataType = 'double';
inputElements(4).Dimensions = 1;
inputElements(4).Description = '最小运行电流，A';

clusterInputNames = {'SOC', 'SOH', 'ClusterVoltage', 'MaxTemperature', ...
    'FaultStatus', 'DCDCCommOK', 'DCDCCommTimeout', ...
    'RatedChargeCurrent', 'RatedDischargeCurrent'};
clusterInputTypes = {'double', 'double', 'double', 'double', ...
    'boolean', 'boolean', 'boolean', 'double', 'double'};
clusterInputDescriptions = { ...
    '每簇 SOC，范围 0 到 100%', ...
    '每簇 SOH，范围 0 到 100%', ...
    '每簇总电压，V，必须大于 0 才有效', ...
    '每簇最高温度，degC', ...
    'true 表示该簇存在严重故障', ...
    'true 表示 DCDC 当前通信正常', ...
    'true 表示 DCDC 通信超时', ...
    '每簇额定充电电流，A', ...
    '每簇额定放电电流，A'};

for idx = 1:numel(clusterInputNames)
    elemIdx = idx + 4;
    inputElements(elemIdx).Name = clusterInputNames{idx};
    inputElements(elemIdx).DataType = clusterInputTypes{idx};
    inputElements(elemIdx).Dimensions = 4;
    inputElements(elemIdx).Description = clusterInputDescriptions{idx};
end

BMS_DCDC_InputBus = Simulink.Bus;
BMS_DCDC_InputBus.Elements = inputElements;
BMS_DCDC_InputBus.Description = 'BMS-DCDC 管理算法 V1.0 输入接口，簇级数组固定 4 维';

%% 输出 Bus
outputNames = {'DCDCEnableCmd', 'DCDCModeCmd', 'TargetPower', 'TargetCurrent', ...
    'ChargeCurrentLimit', 'DischargeCurrentLimit', 'StopReason', 'LimitReason', ...
    'AvailableChargePower', 'AvailableDischargePower'};
outputTypes = {'boolean', 'uint8', 'double', 'double', ...
    'double', 'double', 'uint16', 'uint16', 'double', 'double'};
outputDescriptions = { ...
    'DCDC 启停命令', ...
    'DCDC 模式命令：0=Standby，1=Charge，2=Discharge，3=Fault', ...
    '每簇目标功率，kW，充电为负，放电为正', ...
    '每簇目标电流，A，统一正值', ...
    '充电限流，A', ...
    '放电限流，A', ...
    '停机原因码', ...
    '限流原因码', ...
    '调试输出：最大可充功率，kW', ...
    '调试输出：最大可放功率，kW'};

outputElements = repmat(Simulink.BusElement, 1, numel(outputNames));
for idx = 1:numel(outputNames)
    outputElements(idx).Name = outputNames{idx};
    outputElements(idx).DataType = outputTypes{idx};
    outputElements(idx).Dimensions = 4;
    outputElements(idx).Description = outputDescriptions{idx};
end

BMS_DCDC_OutputBus = Simulink.Bus;
BMS_DCDC_OutputBus.Elements = outputElements;
BMS_DCDC_OutputBus.Description = 'BMS-DCDC 管理算法 V1.0 输出接口，簇级数组固定 4 维';

fprintf('BMS_DCDC_InputBus and BMS_DCDC_OutputBus created.\n');
