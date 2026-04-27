# BMS-DCDC Manager V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a root-level Simulink model for the 4-cluster BMS-DCDC manager defined by the requirement document.

**Architecture:** The first version uses a clear top-level Simulink shell and a code-generation-friendly MATLAB Function block for the core algorithm. Root-level MATLAB scripts hold parameters, the reusable core function, a lightweight self-test, and a model build script with Chinese annotations.

**Tech Stack:** MATLAB, Simulink, MATLAB Function Block, fixed-size arrays with `N_MAX = 4`, Git.

---

## File Structure

- Create `BMS_DCDC_Params.m`: initializes fixed 4-cluster parameters and default scenario data.
- Create `BMS_DCDC_Manager_Core.m`: implements the algorithm as a reusable MATLAB function with fixed `[4]` array outputs and Chinese comments.
- Create `BMS_DCDC_Core_SelfTest.m`: exercises discharge, charge, fault, timeout, standby, and no-available-power behavior without requiring Simulink.
- Create `build_BMS_DCDC_Manager_V1.m`: builds `BMS_DCDC_Manager_V1.slx`, places top-level blocks, injects the MATLAB Function block code, adds Chinese annotations, and saves the model.
- Create `BMS_DCDC_BusDef.m`: defines optional Simulink bus objects for the documented interfaces.
- Modify `.gitignore`: keep temporary visual-assistant files ignored.

### Task 1: Parameter Initialization

**Files:**
- Create: `BMS_DCDC_Params.m`

- [ ] **Step 1: Add fixed parameters and default scenario**

Create `BMS_DCDC_Params.m` with `N_MAX = 4`, default 4-cluster SOC/SOH/voltage/temperature/fault/communication/rated-current arrays, and reason-code constants.

- [ ] **Step 2: Run the script**

Run: `BMS_DCDC_Params`

Expected: MATLAB workspace contains `N_MAX = 4` and all documented input vectors are length 4.

### Task 2: Core Algorithm

**Files:**
- Create: `BMS_DCDC_Manager_Core.m`

- [ ] **Step 1: Implement the function signature**

Create a MATLAB function with this signature:

```matlab
function [DCDCEnableCmd, DCDCModeCmd, TargetPower, TargetCurrent, ...
    ChargeCurrentLimit, DischargeCurrentLimit, StopReason, LimitReason, ...
    AvailableChargePower, AvailableDischargePower] = ...
    BMS_DCDC_Manager_Core(SystemRunCmd, SystemTargetPower, NumClusters, MinRunCurrent, ...
    SOC, SOH, ClusterVoltage, MaxTemperature, FaultStatus, ...
    DCDCCommOK, DCDCCommTimeout, RatedChargeCurrent, RatedDischargeCurrent)
```

- [ ] **Step 2: Implement validity, derating, power allocation, and command logic**

Use fixed loops over 4 clusters. Apply `TemperatureFactor`, `SOHFactor`, available current and power limits, SOC-based charge/discharge weights, target current conversion, DCDC enable logic, and documented reason codes.

### Task 3: Core Self-Test

**Files:**
- Create: `BMS_DCDC_Core_SelfTest.m`

- [ ] **Step 1: Add assertion-based tests**

Call `BMS_DCDC_Params`, then run function assertions for:

- Discharge allocates more power to higher SOC clusters.
- Charge allocates more charging power to lower SOC clusters.
- Fault cluster target power/current are zero.
- Communication timeout sets fault mode and clears target.
- Standby clears all enables and targets.
- No available clusters clears all targets and reports no available power.

- [ ] **Step 2: Run self-test**

Run: `BMS_DCDC_Core_SelfTest`

Expected: command window prints that all BMS-DCDC core self-tests passed.

### Task 4: Bus Definitions

**Files:**
- Create: `BMS_DCDC_BusDef.m`

- [ ] **Step 1: Add optional input and output bus objects**

Define `BMS_DCDC_InputBus` and `BMS_DCDC_OutputBus` with documented signal names. Keep dimensions fixed at 4 for cluster arrays.

- [ ] **Step 2: Run the bus script**

Run: `BMS_DCDC_BusDef`

Expected: MATLAB workspace contains both bus objects.

### Task 5: Simulink Model Builder

**Files:**
- Create: `build_BMS_DCDC_Manager_V1.m`
- Generated: `BMS_DCDC_Manager_V1.slx`

- [ ] **Step 1: Build the top-level model**

Create a script that calls `new_system`, `open_system`, adds `Scenario_Source`, `Input_Bus_Builder`, `BMS_DCDC_Manager_Core`, and `Output_Bus_Builder`, adds inports/outports for all documented signals, and connects them through the core subsystem.

- [ ] **Step 2: Inject MATLAB Function code**

Inside `BMS_DCDC_Manager_Core`, place a MATLAB Function block that calls `BMS_DCDC_Manager_Core(...)` and returns all documented outputs.

- [ ] **Step 3: Add Chinese annotations**

Add Chinese annotations for top-level purpose, fixed 4-cluster dimension, power direction, fault stop logic, SOC allocation, temperature/SOH derating, reason codes, and output command meanings.

- [ ] **Step 4: Save model**

Run: `build_BMS_DCDC_Manager_V1`

Expected: root directory contains `BMS_DCDC_Manager_V1.slx`.

### Task 6: Verification and Publishing

**Files:**
- Verify: `BMS_DCDC_Params.m`
- Verify: `BMS_DCDC_Manager_Core.m`
- Verify: `BMS_DCDC_Core_SelfTest.m`
- Verify: `BMS_DCDC_BusDef.m`
- Verify: `build_BMS_DCDC_Manager_V1.m`
- Verify: `BMS_DCDC_Manager_V1.slx`

- [ ] **Step 1: Static analysis**

Run MATLAB Code Analyzer on the `.m` files when MATLAB MCP is available.

- [ ] **Step 2: Behavioral verification**

Run `BMS_DCDC_Core_SelfTest`.

- [ ] **Step 3: Model verification**

Open or read `BMS_DCDC_Manager_V1.slx` to confirm the expected top-level structure and Chinese annotations exist.

- [ ] **Step 4: Commit and push**

Stage only the Simulink/model implementation files and docs plan, commit with a terse message, then push to `origin/main`.

## Self-Review

- Spec coverage: the plan covers root model, fixed 4-cluster arrays, parameter script, core MATLAB function, bus definitions, Chinese annotations, tests, and GitHub publishing.
- Placeholder scan: no unresolved placeholders are intentionally left in the implementation tasks.
- Type consistency: file names, signal names, and function signatures match the approved design and requirement document.
