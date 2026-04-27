# BMS-DCDC 管理算法 V1.0 测试报告

## 测试对象

- 模型：`BMS_DCDC_Manager_V1.slx`
- 核心算法：`BMS_DCDC_Manager_Core.m`
- 参数脚本：`BMS_DCDC_Params.m`
- 自检脚本：`BMS_DCDC_Core_SelfTest.m`
- 工程验证脚本：`BMS_DCDC_Verify.m`

## 测试环境

- MATLAB R2024b Update 6
- Simulink installed
- 测试命令：

```matlab
cd('D:\JJJ\Gitee\Algorithm_New\Developing\MK8\DCDC_Control')
BMS_DCDC_Verify
```

## 测试范围

V1.0 测试覆盖需求文档中的 TC01 到 TC08。测试以 MATLAB 断言脚本为主，验证核心算法行为；`BMS_DCDC_Verify.m` 同时检查模型文件存在、顶层结构、输入端口和输出端口。

## 测试用例

| 编号 | 场景 | 输入条件 | 检查点 |
| --- | --- | --- | --- |
| TC01 | 故障簇退出 | 第 2 簇 `FaultStatus=true` | 第 2 簇 `DCDCEnableCmd=false`，`DCDCModeCmd=3`，目标功率/电流/限流为 0，`StopReason=2` |
| TC02 | 放电 SOC 分配 | `SystemTargetPower=300kW`，SOC 为 90/60/30/75 | 目标功率满足 SOC 高的簇更大：簇1 > 簇4 > 簇2 > 簇3 |
| TC03 | 充电 SOC 分配 | `SystemTargetPower=-300kW`，SOC 为 90/60/30/75 | 充电功率绝对值满足 SOC 低的簇更大：簇3 > 簇2 > 簇4 > 簇1 |
| TC04 | 温度限流 | 第 2 簇温度从 35 degC 升至 50 degC | 第 2 簇放电限流、可用放电功率和目标功率下降，`LimitReason=1` |
| TC05 | SOH 限流 | 第 2 簇 SOH 从 100% 降至 70% | 第 2 簇放电限流、可用放电功率和目标功率下降，`LimitReason=2` |
| TC06 | 通信超时停机 | 第 2 簇 `DCDCCommTimeout=true` | 第 2 簇 `DCDCEnableCmd=false`，`DCDCModeCmd=3`，目标功率/电流为 0，`StopReason=3` |
| TC07 | 系统待机 | `SystemTargetPower=0` | 所有簇停机，模式为待机，目标功率/电流、限流和可用功率为 0 |
| TC08 | 无可用簇 | 所有簇温度为 65 degC，温度系数为 0 | 所有簇停机，目标功率/电流、限流和可用功率为 0，`StopReason=6` |

## 模型结构检查

`BMS_DCDC_Verify.m` 检查以下顶层模块存在：

- `Scenario_Source`
- `Input_Bus_Builder`
- `BMS_DCDC_Manager_Core`
- `Output_Bus_Builder`

同时检查 13 个输入端口和 10 个输出端口存在，端口名称与需求文档一致。

## Code Analyzer 检查

验证脚本检查以下 MATLAB 文件：

- `BMS_DCDC_Params.m`
- `BMS_DCDC_Manager_Core.m`
- `BMS_DCDC_Core_SelfTest.m`
- `BMS_DCDC_BusDef.m`
- `build_BMS_DCDC_Manager_V1.m`

验收标准：Code Analyzer 无消息。

## 验收结论

当 `BMS_DCDC_Verify` 正常结束并打印 `BMS-DCDC Manager V1 verification completed.` 时，表示：

- TC01 到 TC08 的核心算法断言通过。
- MATLAB Code Analyzer 检查通过。
- `BMS_DCDC_Manager_V1.slx` 存在且顶层结构满足设计要求。
