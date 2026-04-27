%% BMS_DCDC_Params
% BMS-DCDC 管理算法 V1.0 参数初始化脚本。
% 第一版固定支持 4 个电池簇，所有簇级数组维度均为 [1x4]。

N_MAX = uint8(4);

%% 系统级默认输入
SystemRunCmd = true;
SystemTargetPower = 300.0;   % kW，正值放电，负值充电
NumClusters = uint8(4);
MinRunCurrent = 2.0;         % A，小于该电流时关闭 DCDC

%% 簇级默认输入，维度固定为 4
SOC = [90.0, 60.0, 30.0, 75.0];                 % %
SOH = [95.0, 90.0, 85.0, 70.0];                 % %
ClusterVoltage = [750.0, 748.0, 745.0, 746.0];  % V
MaxTemperature = [35.0, 38.0, 50.0, 42.0];      % degC
FaultStatus = [false, false, false, false];
DCDCCommOK = [true, true, true, true];
DCDCCommTimeout = [false, false, false, false];
RatedChargeCurrent = [150.0, 150.0, 150.0, 150.0];     % A
RatedDischargeCurrent = [150.0, 150.0, 150.0, 150.0];  % A

%% 温度和 SOH 降额标定
TempBreakpoints = [-10.0, 0.0, 45.0, 55.0, 60.0];
TempFactors = [0.0, 0.3, 1.0, 0.6, 0.3, 0.0];
SOHFactorMin = 0.5;
SOHFactorMax = 1.0;

%% 模式码：DCDCModeCmd
MODE_STANDBY = uint8(0);
MODE_CHARGE = uint8(1);
MODE_DISCHARGE = uint8(2);
MODE_FAULT = uint8(3);

%% 停机原因码：StopReason
STOP_NONE = uint16(0);
STOP_SYSTEM_STOP = uint16(1);
STOP_CLUSTER_FAULT = uint16(2);
STOP_DCDC_COMM_TIMEOUT = uint16(3);
STOP_DCDC_COMM_ERROR = uint16(4);
STOP_INVALID_VOLTAGE = uint16(5);
STOP_NO_AVAILABLE_POWER = uint16(6);

%% 限流原因码：LimitReason
LIMIT_NONE = uint16(0);
LIMIT_TEMP_DERATING = uint16(1);
LIMIT_SOH_DERATING = uint16(2);
LIMIT_TEMP_AND_SOH_DERATING = uint16(3);

%% 测试场景基础数据
% TC02 放电 SOC 分配：SOC 高的簇目标功率更大。
TC02_SystemTargetPower = 300.0;
TC02_SOC = [90.0, 60.0, 30.0, 75.0];

% TC03 充电 SOC 分配：SOC 低的簇充电功率更大。
TC03_SystemTargetPower = -300.0;
TC03_SOC = [90.0, 60.0, 30.0, 75.0];

% TC04 温度限流：第 3 簇 50 degC，应降额。
TC04_MaxTemperature = [35.0, 38.0, 50.0, 42.0];

% TC06 通信超时：第 2 簇超时后停机并进入故障模式。
TC06_DCDCCommTimeout = [false, true, false, false];
