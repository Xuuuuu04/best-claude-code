# Simulation Engineer — Output Contract

## Standard Output Template

```
## Simulation Engineering Output

**Objective**: [one-sentence description]
**Tool**: [MATLAB/Simulink / Unity / Unreal / Python / multi-tool]
**Simulation Fidelity**: [Conceptual / Functional / Physics-Accurate / Real-Time HIL]
**Unit System**: [SI / Imperial / custom]
**Coordinate Frame**: [body-fixed / world-fixed / ENU / NED]

### Delivered Files
| File | Type | Description |

### Real-Time Constraint Assessment
| Parameter | Value |
| Solver type | |
| Step size | |
| Target hardware | |
| Max execution time (PIL) | |
| Timing budget | PASS/FAIL |

### Code Generation (if applicable)
| Item | Status |
| MISRA-C compliance | |
| Traceability | ENABLED/DISABLED |
| Manual edits to generated code | NONE/[list] |

### Validation Coverage
| Test type | Coverage |
| Statement | |
| MC/DC | |
| Fault injection | |

### Reproducibility
[environment setup + verification command]

### Next Steps
[→ @embedded-dev / @data-engineer / @devops / @code-review]
```

## Filled Example — Simulink HIL Delivery

```
## Simulation Engineering Output

**Objective**: Brushless motor current controller for STM32H7, HIL-validated
**Tool**: MATLAB/Simulink + Embedded Coder
**Simulation Fidelity**: Real-Time HIL
**Unit System**: SI (A, V, rad/s, N·m)
**Coordinate Frame**: d-q rotating reference frame

### Delivered Files
| File | Type | Description |
| motor_ctrl.slx | Simulink model | Fixed-step ode4, 1ms, PI controller |
| init_params.m | MATLAB script | Parameters: R=0.5Ω, L=1.2mH, kt=0.1 N·m/A |
| hil_test_seq.mldatx | Test sequence | Step response + fault injection |
| codegen/ | C code | MISRA-C 2012 compliant, traceability enabled |
| docs/io_mapping.md | Documentation | dSPACE I/O configuration |

### Real-Time Constraint Assessment
| Parameter | Value |
| Solver type | Fixed-step ode4 (Runge-Kutta) |
| Step size | 1ms |
| Target hardware | STM32H7 @ 480MHz |
| Max execution time (PIL) | 0.62ms |
| Timing budget | PASS (0.62ms < 1ms, 38% margin) |

### Code Generation
| Item | Status |
| MISRA-C compliance | PASS (0 violations) |
| Traceability | ENABLED |
| Manual edits to generated code | NONE |

### Validation Coverage
| Test type | Coverage |
| Statement | 94% |
| MC/DC | 87% |
| Fault injection | 8/8 scenarios (sensor dropout, saturation for ia, ib, theta, omega) |

### Reproducibility
```bash
# Environment setup
matlab -batch "run('init_params.m')"
sim('motor_ctrl.slx')

# Verification
matlab -batch "run('verify_hil.m')"
```

### Next Steps
→ @embedded-dev — integrate generated C code with MCU firmware
```

## Filled Example — Unity Digital Twin

```
## Simulation Engineering Output

**Objective**: Real-time digital twin of factory production line
**Tool**: Unity 2022.3 LTS
**Simulation Fidelity**: Functional
**Unit System**: SI
**Coordinate Frame**: World-fixed (Unity global coordinates)

### Delivered Files
| File | Type | Description |
| FactoryTwin/ | Unity project | Main scene + data binding scripts |
| DataBinding/MqttClient.cs | C# script | MQTT topic subscription |
| DataBinding/OpcUaClient.cs | C# script | OPC-UA node polling |
| Models/ | FBX assets | CAD import with LOD |
| docs/data_interface.md | Documentation | Topic/node mapping table |

### Real-Time Constraint Assessment
| Parameter | Value |
| Target frame rate | 60fps (desktop) |
| Measured frame rate | 72fps avg, 58fps min |
| Data update rate | 10Hz (MQTT), 5Hz (OPC-UA) |
| Performance budget | PASS |

### Validation Coverage
| Test type | Coverage |
| Data binding | 12/12 sensors verified |
| Alert visualization | 5/5 alert types tested |
| Historical trend | PASS |

### Reproducibility
```bash
# Unity version: 2022.3.20f1
# Required packages:
#   - MQTTnet 4.3.0
#   - OPC-UA Client 3.2.0
#   - TextMeshPro 3.0.6

# Open project in Unity 2022.3 LTS
# Import packages from Packages/manifest.json
# Run MainScene
```

### Next Steps
→ @backend — verify MQTT/OPC-UA data pipeline integration
→ @frontend — embed Unity WebGL build in operator dashboard
```

## Filled Example — Python Gymnasium Environment

```
## Simulation Engineering Output

**Objective**: Gymnasium RL environment for quadruped robot walking
**Tool**: Python + Gymnasium + NumPy
**Simulation Fidelity**: Physics-Accurate
**Unit System**: SI
**Coordinate Frame**: Body-fixed (robot base frame)

### Delivered Files
| File | Type | Description |
| quadruped_walk_env.py | Python module | Gymnasium Env subclass |
| requirements.txt | Dependency list | Pinned versions |
| verify_output.py | Test script | Determinism verification |
| README.md | Documentation | Setup and usage |

### Real-Time Constraint Assessment
| Parameter | Value |
| Physics timestep | 0.004s (250Hz) |
| Control frequency | 0.02s (50Hz) |
| Determinism | PASS (seed=42, 1000 steps identical) |

### Validation Coverage
| Test type | Coverage |
| Observation space | PASS (Box shape verified) |
| Action space | PASS (Box bounds verified) |
| Reward function | PASS (manual calculation check) |
| Termination conditions | PASS (fall detection, max steps) |
| Determinism | PASS (verify_output.py) |

### Reproducibility
```bash
# Setup
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Verify
python verify_output.py  # Should print: Determinism: PASS

# Run
python -c "from quadruped_walk_env import QuadrupedWalkEnv; env = QuadrupedWalkEnv(); env.reset(seed=42)"
```

### Next Steps
→ @ml-engineer — integrate with RL training pipeline (PPO/SAC)
```

## BLOCKED Output Template

```
## Simulation Engineering Output

**Objective**: [description]
**Tool**: [tool]
**Simulation Fidelity**: [level]
**Status**: BLOCKED

**Blocked On**: [specific technical blocker]
**Blocked By**: [who can unblock]

**Rationale**: [why this blocks delivery]

**Resolution Options**:
1. [Option A: description + trade-offs]
2. [Option B: description + trade-offs]
3. [Option C: description + trade-offs]

**Recommended Next Step**: [option + rationale]
```

## Filled Example — BLOCKED (HIL Step Size)

```
## Simulation Engineering Output

**Objective**: Hydraulic valve controller HIL on Speedgoat Baseline
**Tool**: MATLAB/Simulink + Simscape
**Simulation Fidelity**: Real-Time HIL
**Status**: BLOCKED

**Blocked On**: HIL step size configuration requires PIL measurement
**Blocked By**: Hardware availability for PIL test

**Rationale**: The Speedgoat Baseline target's CPU execution budget at 40μs must be verified for this specific model before declaring HIL-ready. The hydraulic Simscape model contains stiff DAE systems requiring implicit solvers. At 40μs fixed-step, convergence time depends on model nonlinearity and cannot be estimated without PIL measurement. If execution > 40μs, HIL test results are invalid (overrun = test validity failure).

**Resolution Options**:
1. Run PIL on Speedgoat Baseline to measure execution time. If < 32μs (80% budget), proceed.
2. Simplify model: replace nonlinear Simscape blocks with linearized approximations.
3. Upgrade to Speedgoat Performance Real-Time Target (faster CPU, confirmed capable at 40μs).

**Recommended Next Step**: Option 1 — PIL measurement is the most direct path. If execution time exceeds budget, evaluate Option 2 (model simplification) before Option 3 (hardware upgrade).
```
