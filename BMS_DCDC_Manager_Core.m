function [DCDCEnableCmd, DCDCModeCmd, TargetPower, TargetCurrent, ...
    ChargeCurrentLimit, DischargeCurrentLimit, StopReason, LimitReason, ...
    AvailableChargePower, AvailableDischargePower] = ...
    BMS_DCDC_Manager_Core(SystemRunCmd, SystemTargetPower, NumClusters, MinRunCurrent, ...
    SOC, SOH, ClusterVoltage, MaxTemperature, FaultStatus, ...
    DCDCCommOK, DCDCCommTimeout, RatedChargeCurrent, RatedDischargeCurrent)
%#codegen
% BMS-DCDC 管理算法 V1.0 核心逻辑。
% 固定支持 4 个电池簇；目标电流统一为正值，方向由 DCDCModeCmd 区分。

N_MAX = 4;

MODE_STANDBY = uint8(0);
MODE_CHARGE = uint8(1);
MODE_DISCHARGE = uint8(2);
MODE_FAULT = uint8(3);

STOP_NONE = uint16(0);
STOP_SYSTEM_STOP = uint16(1);
STOP_CLUSTER_FAULT = uint16(2);
STOP_DCDC_COMM_TIMEOUT = uint16(3);
STOP_DCDC_COMM_ERROR = uint16(4);
STOP_INVALID_VOLTAGE = uint16(5);
STOP_NO_AVAILABLE_POWER = uint16(6);

LIMIT_NONE = uint16(0);
LIMIT_TEMP_DERATING = uint16(1);
LIMIT_SOH_DERATING = uint16(2);
LIMIT_TEMP_AND_SOH_DERATING = uint16(3);

DCDCEnableCmd = false(1, N_MAX);
DCDCModeCmd = zeros(1, N_MAX, 'uint8');
TargetPower = zeros(1, N_MAX);
TargetCurrent = zeros(1, N_MAX);
ChargeCurrentLimit = zeros(1, N_MAX);
DischargeCurrentLimit = zeros(1, N_MAX);
StopReason = zeros(1, N_MAX, 'uint16');
LimitReason = zeros(1, N_MAX, 'uint16');
AvailableChargePower = zeros(1, N_MAX);
AvailableDischargePower = zeros(1, N_MAX);

ValidFlag = false(1, N_MAX);
TemperatureFactor = zeros(1, N_MAX);
SOHFactor = zeros(1, N_MAX);
ChargeWeight = zeros(1, N_MAX);
DischargeWeight = zeros(1, N_MAX);

for idx = 1:N_MAX
    % 簇有效性判断：系统停机、故障、通信异常、超时、电压无效、超出实际簇数均退出。
    if ~SystemRunCmd
        StopReason(idx) = STOP_SYSTEM_STOP;
    elseif idx > double(NumClusters)
        StopReason(idx) = STOP_SYSTEM_STOP;
    elseif FaultStatus(idx)
        StopReason(idx) = STOP_CLUSTER_FAULT;
    elseif DCDCCommTimeout(idx)
        StopReason(idx) = STOP_DCDC_COMM_TIMEOUT;
    elseif ~DCDCCommOK(idx)
        StopReason(idx) = STOP_DCDC_COMM_ERROR;
    elseif ClusterVoltage(idx) <= 0.0
        StopReason(idx) = STOP_INVALID_VOLTAGE;
    else
        StopReason(idx) = STOP_NONE;
        ValidFlag(idx) = true;
    end

    TemperatureFactor(idx) = localTemperatureFactor(MaxTemperature(idx));
    SOHFactor(idx) = min(1.0, max(0.5, SOH(idx) / 100.0));

    if TemperatureFactor(idx) < 1.0 && SOHFactor(idx) < 1.0
        LimitReason(idx) = LIMIT_TEMP_AND_SOH_DERATING;
    elseif TemperatureFactor(idx) < 1.0
        LimitReason(idx) = LIMIT_TEMP_DERATING;
    elseif SOHFactor(idx) < 1.0
        LimitReason(idx) = LIMIT_SOH_DERATING;
    else
        LimitReason(idx) = LIMIT_NONE;
    end

    if ValidFlag(idx)
        ChargeCurrentLimit(idx) = RatedChargeCurrent(idx) * TemperatureFactor(idx) * SOHFactor(idx);
        DischargeCurrentLimit(idx) = RatedDischargeCurrent(idx) * TemperatureFactor(idx) * SOHFactor(idx);
        AvailableChargePower(idx) = ClusterVoltage(idx) * ChargeCurrentLimit(idx) / 1000.0;
        AvailableDischargePower(idx) = ClusterVoltage(idx) * DischargeCurrentLimit(idx) / 1000.0;
        ChargeWeight(idx) = (100.0 - SOC(idx)) * TemperatureFactor(idx) * SOHFactor(idx);
        DischargeWeight(idx) = SOC(idx) * TemperatureFactor(idx) * SOHFactor(idx);
    else
        LimitReason(idx) = LIMIT_NONE;
        DCDCModeCmd(idx) = MODE_FAULT;
    end
end

% 系统待机：目标功率为 0 时所有有效簇保持待机。
if SystemTargetPower == 0.0 || ~SystemRunCmd
    for idx = 1:N_MAX
        if StopReason(idx) == STOP_NONE
            DCDCModeCmd(idx) = MODE_STANDBY;
        else
            DCDCModeCmd(idx) = localModeForStop(StopReason(idx), MODE_STANDBY, MODE_FAULT);
        end
        ChargeCurrentLimit(idx) = 0.0;
        DischargeCurrentLimit(idx) = 0.0;
        AvailableChargePower(idx) = 0.0;
        AvailableDischargePower(idx) = 0.0;
        LimitReason(idx) = LIMIT_NONE;
    end
    return;
end

if SystemTargetPower > 0.0
    weightSum = localValidPowerWeightSum(DischargeWeight, AvailableDischargePower);
    if weightSum <= 0.0
        [StopReason, DCDCModeCmd, ChargeCurrentLimit, DischargeCurrentLimit, ...
            AvailableChargePower, AvailableDischargePower, LimitReason] = ...
            localNoAvailablePower(ValidFlag, StopReason, DCDCModeCmd, MODE_STANDBY, ...
            STOP_NO_AVAILABLE_POWER, ChargeCurrentLimit, DischargeCurrentLimit, ...
            AvailableChargePower, AvailableDischargePower, LimitReason);
        return;
    end

    for idx = 1:N_MAX
        if ValidFlag(idx) && AvailableDischargePower(idx) > 0.0 && DischargeWeight(idx) > 0.0
            requestedPower = SystemTargetPower * DischargeWeight(idx) / weightSum;
            TargetPower(idx) = min(requestedPower, AvailableDischargePower(idx));
            TargetCurrent(idx) = TargetPower(idx) * 1000.0 / ClusterVoltage(idx);
            ChargeCurrentLimit(idx) = 0.0;
            DCDCModeCmd(idx) = MODE_DISCHARGE;
        elseif ValidFlag(idx)
            StopReason(idx) = STOP_NO_AVAILABLE_POWER;
            DCDCModeCmd(idx) = MODE_STANDBY;
            ChargeCurrentLimit(idx) = 0.0;
            DischargeCurrentLimit(idx) = 0.0;
        end
    end
else
    systemChargePower = abs(SystemTargetPower);
    weightSum = localValidPowerWeightSum(ChargeWeight, AvailableChargePower);
    if weightSum <= 0.0
        [StopReason, DCDCModeCmd, ChargeCurrentLimit, DischargeCurrentLimit, ...
            AvailableChargePower, AvailableDischargePower, LimitReason] = ...
            localNoAvailablePower(ValidFlag, StopReason, DCDCModeCmd, MODE_STANDBY, ...
            STOP_NO_AVAILABLE_POWER, ChargeCurrentLimit, DischargeCurrentLimit, ...
            AvailableChargePower, AvailableDischargePower, LimitReason);
        return;
    end

    for idx = 1:N_MAX
        if ValidFlag(idx) && AvailableChargePower(idx) > 0.0 && ChargeWeight(idx) > 0.0
            requestedPower = systemChargePower * ChargeWeight(idx) / weightSum;
            clusterChargePower = min(requestedPower, AvailableChargePower(idx));
            TargetPower(idx) = -clusterChargePower;
            TargetCurrent(idx) = clusterChargePower * 1000.0 / ClusterVoltage(idx);
            DischargeCurrentLimit(idx) = 0.0;
            DCDCModeCmd(idx) = MODE_CHARGE;
        elseif ValidFlag(idx)
            StopReason(idx) = STOP_NO_AVAILABLE_POWER;
            DCDCModeCmd(idx) = MODE_STANDBY;
            ChargeCurrentLimit(idx) = 0.0;
            DischargeCurrentLimit(idx) = 0.0;
        end
    end
end

for idx = 1:N_MAX
    % 目标电流大于最小运行电流且目标功率非零时才使能 DCDC。
    if ValidFlag(idx) && TargetCurrent(idx) > MinRunCurrent && TargetPower(idx) ~= 0.0
        DCDCEnableCmd(idx) = true;
    elseif ValidFlag(idx) && StopReason(idx) == STOP_NONE
        DCDCModeCmd(idx) = MODE_STANDBY;
    else
        DCDCModeCmd(idx) = localModeForStop(StopReason(idx), MODE_STANDBY, MODE_FAULT);
    end

    if ~DCDCEnableCmd(idx) && StopReason(idx) ~= STOP_NONE
        TargetPower(idx) = 0.0;
        TargetCurrent(idx) = 0.0;
        ChargeCurrentLimit(idx) = 0.0;
        DischargeCurrentLimit(idx) = 0.0;
        AvailableChargePower(idx) = 0.0;
        AvailableDischargePower(idx) = 0.0;
        LimitReason(idx) = LIMIT_NONE;
    end
end

end

function factor = localTemperatureFactor(temperature)
% 温度分段降额系数。
if temperature < -10.0
    factor = 0.0;
elseif temperature < 0.0
    factor = 0.3;
elseif temperature <= 45.0
    factor = 1.0;
elseif temperature <= 55.0
    factor = 0.6;
elseif temperature <= 60.0
    factor = 0.3;
else
    factor = 0.0;
end
end

function mode = localModeForStop(stopReason, standbyMode, faultMode)
% 系统停机、无可用功率和未参与簇保持待机；故障、通信和电压问题进入故障模式。
if stopReason == uint16(1) || stopReason == uint16(6)
    mode = standbyMode;
else
    mode = faultMode;
end
end

function weightSum = localValidPowerWeightSum(weight, availablePower)
weightSum = 0.0;
for idx = 1:4
    if availablePower(idx) > 0.0 && weight(idx) > 0.0
        weightSum = weightSum + weight(idx);
    end
end
end

function [StopReason, DCDCModeCmd, ChargeCurrentLimit, DischargeCurrentLimit, ...
    AvailableChargePower, AvailableDischargePower, LimitReason] = ...
    localNoAvailablePower(ValidFlag, StopReason, DCDCModeCmd, standbyMode, noPowerReason, ...
    ChargeCurrentLimit, DischargeCurrentLimit, AvailableChargePower, AvailableDischargePower, LimitReason)
for idx = 1:4
    if ValidFlag(idx)
        StopReason(idx) = noPowerReason;
        DCDCModeCmd(idx) = standbyMode;
    end
    ChargeCurrentLimit(idx) = 0.0;
    DischargeCurrentLimit(idx) = 0.0;
    AvailableChargePower(idx) = 0.0;
    AvailableDischargePower(idx) = 0.0;
    LimitReason(idx) = uint16(0);
end
end
