---
title: "Simulation Engineer — Domain 1: MATLAB/Simulink & Stateflow"
source: core.md §Domain 1
---

# Domain 1: MATLAB/Simulink

## 1.1 Simulink Model Configuration for HIL

```matlab
% Complete HIL configuration script
function configure_hil_model(model_name, step_size, target_hw)
    load_system(model_name);
    cs = getActiveConfigSet(model_name);
    
    % Solver: fixed-step for HIL
    set_param(cs, 'SolverType', 'Fixed-step');
    set_param(cs, 'Solver', 'ode4');
    set_param(cs, 'FixedStep', num2str(step_size));
    set_param(cs, 'EnableConcurrentExecution', 'on');
    
    % Hardware implementation
    switch target_hw
        case 'STM32H7'
            set_param(cs, 'ProdHWDeviceType', 'ARM Compatible->ARM Cortex-M');
            set_param(cs, 'TargetBitPerChar', 8);
            set_param(cs, 'TargetBitPerShort', 16);
            set_param(cs, 'TargetBitPerInt', 32);
            set_param(cs, 'TargetBitPerLong', 32);
        case 'Speedgoat'
            set_param(cs, 'ProdHWDeviceType', 'Intel->x86-64 (Linux 64)');
    end
    
    % Code generation
    set_param(cs, 'SystemTargetFile', 'ert.tlc');
    set_param(cs, 'GenerateCodeOnly', 'off');
    set_param(cs, 'GenCodeInfo', 'on');
    
    % Traceability
    set_param(cs, 'GenerateTraceInfo', 'on');
    set_param(cs, 'GenerateTraceReport', 'on');
    
    % MISRA-C
    set_param(cs, 'EnableMISRA', 'on');
    set_param(cs, 'MISRAVersion', '2012');
    
    save_system(model_name);
end
```

## 1.2 Stateflow: Moore vs Mealy

```matlab
% Moore machine: outputs depend only on state (safer for codegen)
% Recommended for safety-critical applications

% State entry actions (Moore)
entry: led = ON;      % Output set on state entry
entry: counter = 0;   % Initialize counter

% During actions
during: counter = counter + 1;

% Mealy machine: outputs depend on transitions (more expressive)
% Use when output must change immediately on input change

% Transition actions (Mealy)
[button_pressed] / led = ON;   % Output on transition
[timer_expired] / led = OFF;
```

## 1.3 Embedded Coder Traceability

```matlab
% Generate traceability report
slreportgen.report.ModelAdvisor(model_name, ...
    'Configuration', 'Embedded Coder');

% Bidirectional traceability: model block <-> generated code
% In generated code:
% /* Model block: motor_ctrl/PI_Controller/Gain */
% rtb_Gain = 0.5F * rtu_SpeedError;

% In model: right-click block -> Code -> Navigate to Code
```

## 1.4 PIL Verification Script

```matlab
function pil_verification(model_name)
    % Configure PIL
    set_param(model_name, 'SimulationMode', 'processor-in-the-loop');
    
    % Run simulation
    simOut = sim(model_name);
    
    % Compare PIL vs Normal mode
    normal_out = simOut.get('yout');
    
    set_param(model_name, 'SimulationMode', 'normal');
    simOut_normal = sim(model_name);
    pil_out = simOut_normal.get('yout');
    
    % Numeric equivalence check
    tolerance = eps('single') * 100;
    max_diff = max(abs(normal_out - pil_out));
    
    if max_diff < tolerance
        fprintf('PIL verification: PASS (max diff: %e)\n', max_diff);
    else
        fprintf('PIL verification: FAIL (max diff: %e)\n', max_diff);
    end
    
    % Execution time measurement
    exec_time = get_param(model_name, 'ExecutionTime');
    fprintf('PIL execution time: %.3f ms\n', exec_time * 1000);
end
```

---

# Domain 2: HIL/SIL/PIL

## 2.1 SIL vs PIL vs HIL Distinction

| Level | Code Location | What it Verifies | Timing |
|---|---|---|---|
| SIL | Generated C on host PC | Numerical equivalence | Not real-time |
| PIL | Generated C on target processor | Processor arithmetic | Not real-time |
| HIL | Generated C on target + real I/O | Timing + I/O behavior | Real-time |

## 2.2 dSPACE SCALEXIO Configuration

```matlab
% dSPACE configuration
set_param(gcs, 'RTWCompilerOptimization', 'on');
set_param(gcs, 'TargetHWDeviceType', 'dSPACE->SCALEXIO');

% I/O mapping
createMapping('AnalogInput', 'DS4302', 1, 'ia');
createMapping('AnalogInput', 'DS4302', 2, 'ib');
createMapping('PWMOutput', 'DS5203', 1, 'pwm_a');
```

## 2.3 Simulink Test: Test Sequence

```matlab
% Test Sequence for step response + fault injection
test_seq = sltest.testsequence.TestSequence('hil_test_seq');

% Step response test
test_seq.addStep('step_response', ...
    'at(t == 0, enter: ia_ref = 5.0)', ...
    'after(t >= 0.01, verify: abs(ia - ia_ref) < 0.1)');

% Fault injection: sensor dropout
test_seq.addStep('sensor_dropout', ...
    'at(t == 0.05, enter: ia = 0)', ...
    'after(t >= 0.06, verify: fault_detected == true)');

% Fault injection: sensor saturation
test_seq.addStep('sensor_saturation', ...
    'at(t == 0.1, enter: ia = 100.0)', ...
    'after(t >= 0.11, verify: saturation_flag == true)');
```
