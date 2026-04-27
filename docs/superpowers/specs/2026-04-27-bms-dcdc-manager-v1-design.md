# BMS-DCDC 管理算法 V1.0 Simulink 模型设计

## 背景

根据 `Requirement/BMS_DCDC_MATLAB_Simulink_Req_V1_0.docx`，第一版模型用于实现簇级 DCDC 管理算法，目标是简单可用、逻辑清晰、便于仿真验证和后续嵌入式代码生成。

本设计固定支持 4 个电池簇，所有簇级输入输出数组维度均为 `[4]`。实际参与计算的簇数由 `NumClusters` 指定。

## 交付物

- `BMS_DCDC_Manager_V1.slx`：根目录下的顶层 Simulink 模型。
- `BMS_DCDC_Params.m`：根目录下的参数初始化脚本，包含 `N_MAX = 4`、默认输入、温度/SOH 降额参数、示例测试场景数据。
- `BMS_DCDC_Manager_Core.m` 或模型内 MATLAB Function 代码：核心算法实现。
- `BMS_DCDC_BusDef.m`：可选交付物。若当前 Simulink 环境支持顺利，则提供输入输出 Bus 定义；若 Bus 定义影响快速可用目标，则第一版先采用固定维度信号。

## 模型结构

顶层模型名称为 `BMS_DCDC_Manager_V1.slx`，根目录保存。

顶层结构：

- `Scenario_Source`：提供 V1.0 样例输入和仿真激励。
- `Input_Bus_Builder`：组织系统级输入和 4 簇数组输入。
- `BMS_DCDC_Manager_Core`：核心算法子系统，内部优先使用一个可代码生成的 MATLAB Function Block。
- `Output_Bus_Builder`：汇总 DCDC 启停、模式、目标功率、目标电流、限流、原因码和调试功率输出。

模型内添加中文备注，说明模块职责、4 簇固定维度、功率方向、原因码、降额逻辑和输出含义。信号名保持英文，便于代码生成和协议对接。

## 输入接口

系统级输入：

- `SystemRunCmd`：系统运行命令，布尔量。
- `SystemTargetPower`：系统目标功率，单位 kW，正值放电，负值充电。
- `NumClusters`：实际参与计算簇数，范围 0 到 4。
- `MinRunCurrent`：最小运行电流，单位 A。

簇级输入数组，维度均为 `[4]`：

- `SOC`
- `SOH`
- `ClusterVoltage`
- `MaxTemperature`
- `FaultStatus`
- `DCDCCommOK`
- `DCDCCommTimeout`
- `RatedChargeCurrent`
- `RatedDischargeCurrent`

## 输出接口

簇级输出数组，维度均为 `[4]`：

- `DCDCEnableCmd`
- `DCDCModeCmd`
- `TargetPower`
- `TargetCurrent`
- `ChargeCurrentLimit`
- `DischargeCurrentLimit`
- `StopReason`
- `LimitReason`
- `AvailableChargePower`
- `AvailableDischargePower`

## 核心算法

核心算法集中在 `BMS_DCDC_Manager_Core` 中实现。第一版使用固定长度 `for` 循环遍历 4 个簇，避免动态数组、字符串和 cell。

每个周期执行以下步骤：

1. 判断簇有效性。系统停机、簇故障、DCDC 通信超时、通信异常、电压无效、簇编号超过 `NumClusters` 时，该簇退出运行。
2. 根据最高温度计算 `TemperatureFactor`。
3. 根据 SOH 计算 `SOHFactor = min(1.0, max(0.5, SOH / 100))`。
4. 计算最大可用充电/放电电流。
5. 计算最大可用充电/放电功率。
6. 根据 `SystemTargetPower` 选择待机、充电或放电模式。
7. 放电时按 `SOC * TemperatureFactor * SOHFactor` 计算权重，SOC 高的簇多出力。
8. 充电时按 `(100 - SOC) * TemperatureFactor * SOHFactor` 计算权重，SOC 低的簇多充电。
9. 按权重分配目标功率，并限制不超过对应簇最大可用功率。
10. 计算 `TargetCurrent = abs(TargetPower) * 1000 / ClusterVoltage`。
11. 若簇有效、目标电流大于 `MinRunCurrent` 且目标功率不为 0，则输出 DCDC 使能；否则关闭。

## 状态码

`DCDCModeCmd`：

- `0`：Standby，待机。
- `1`：Charge，充电。
- `2`：Discharge，放电。
- `3`：Fault，故障。

`StopReason`：

- `0`：NONE，无停机原因。
- `1`：SYSTEM_STOP，系统停机。
- `2`：CLUSTER_FAULT，电池簇严重故障。
- `3`：DCDC_COMM_TIMEOUT，DCDC 通信超时。
- `4`：DCDC_COMM_ERROR，DCDC 通信异常。
- `5`：INVALID_VOLTAGE，簇电压无效。
- `6`：NO_AVAILABLE_POWER，无可用充放电能力。

`LimitReason`：

- `0`：NONE，无限流。
- `1`：TEMP_DERATING，温度限流。
- `2`：SOH_DERATING，SOH 限流。
- `3`：TEMP_AND_SOH_DERATING，温度与 SOH 共同限流。

## 温度降额

温度分段沿用需求文档：

- `T < -10`：系数 0
- `-10 <= T < 0`：系数 0.3
- `0 <= T <= 45`：系数 1.0
- `45 < T <= 55`：系数 0.6
- `55 < T <= 60`：系数 0.3
- `T > 60`：系数 0

## 测试场景

模型和参数脚本应支持以下场景的快速仿真：

- `TC01`：故障簇退出。
- `TC02`：放电 SOC 分配。
- `TC03`：充电 SOC 分配。
- `TC04`：温度限流。
- `TC05`：SOH 限流。
- `TC06`：通信超时停机。
- `TC07`：系统待机。
- `TC08`：无可用簇。

第一版至少在模型内提供一个默认场景，覆盖 4 簇输入、正常放电、故障簇和温度/SOH 降额。后续可扩展为独立测试模型或 Simulink Test 用例。

## 实施约束

- 根目录直接生成模型和脚本。
- 信号名、变量名使用英文和下划线，避免中文信号名影响代码生成。
- 中文备注用于模型可读性和需求追踪，不作为代码变量名。
- 第一版不实现功率二次分配、斜率限制、复杂状态机、主动均衡优化、DCDC 内部控制环、PCS/EMS 策略。
- 若所有可用权重之和为 0，则目标功率、电流和限流清零，并输出无可用功率原因。

## 验收标准

- 根目录存在 `BMS_DCDC_Manager_V1.slx` 和 `BMS_DCDC_Params.m`。
- 模型可打开，顶层结构包含输入、核心、输出和测试激励区域。
- 核心算法支持固定 4 簇数组输入输出。
- 模型内存在中文备注，说明主要接口和算法逻辑。
- 放电时 SOC 更高且未降额的簇分配更高功率。
- 充电时 SOC 更低且未降额的簇分配更高充电功率。
- 故障、通信超时、通信异常、系统停机、电压无效时对应簇停机且目标清零。
- 温度和 SOH 降额会降低可用电流、可用功率和分配权重。
