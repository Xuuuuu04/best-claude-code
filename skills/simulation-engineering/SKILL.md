---
name: simulation-engineering
description: Simulation and digital-twin engineering methodology for the Harness team. Covers MATLAB/Simulink (continuous/discrete modeling, Stateflow, Embedded Coder codegen, SIL/PIL/HIL with Speedgoat/dSPACE/NI PXI), Unity C# (ECS/DOTS, ML-Agents, digital-twin data sync), Unreal Engine C++ (Chaos physics, Niagara, Pixel Streaming, Cesium), and Python scientific computing (NumPy/SciPy, JAX, Gymnasium, IsaacLab, PINN). Includes solver selection discipline, fidelity-tool fit matrix, and reproducibility contract. Loaded by @simulation-engineer via skills: frontmatter.
type: skill
---

# Simulation Engineering Skill

## 1. Fidelity-Tool Fit Matrix

| Fidelity Level | Appropriate Tool | Inappropriate Tool |
|----------------|------------------|-------------------|
| **Conceptual** | Whiteboard, Python scripts | MATLAB/Simulink |
| **Functional** | MATLAB/Simulink, Python | Unity, Unreal |
| **Physics-Accurate** | MATLAB/Simulink (with Simscape), Python (scipy) | Unity PhysX |
| **Real-Time HIL** | MATLAB/Simulink (fixed-step) + Speedgoat/dSPACE | Python, Unity |
| **Visualization** | Unity, Unreal | MATLAB/Simulink |
| **RL Training** | Unity ML-Agents, IsaacLab, Gymnasium | MATLAB/Simulink |

Forcing a tool outside its fidelity zone produces misleading validation results.

## 2. MATLAB/Simulink

**Modeling**: Continuous/discrete systems (TF, State-Space, ZOH/Tustin/matched-pole-zero); anti-aliasing filter placement. Stateflow: Moore (output depends on state only, safer for codegen) vs Mealy (output depends on transition). Simscape: electrical, mechanical, hydraulic, thermal domains; DAE solvers (ode23t/ode15s).

**Control design**: PID autotuning, LQR, MPC. Stability margins: gain margin > 6dB, phase margin > 45° as baseline. Discretize: ZOH or Tustin; sampling frequency ≥ 20× bandwidth.

**Code generation**: Embedded Coder with hardware implementation settings, MISRA-C 2012, complexity metrics, traceability (`slreportgen`, `coder.mapping.api`).

**Solver selection decision tree**:
```
HIL deployment? → YES: Fixed-step (ode4/Runge-Kutta), step = min(budget, 1/20 × bandwidth)
                → NO: Stiff? → YES: ode15s/ode23tb
                         → NO: High accuracy? → YES: ode113
                                        → NO: ode45 (default)
```

**SIL/PIL/HIL chain**: Offline → SIL (generated code on desktop, compare numerically, tolerance < FP epsilon × 100) → PIL (on target processor, verify arithmetic) → HIL (real I/O, real timing). Each step narrows the failure space.

**Real-time targets**: Speedgoat (baseline/performance), dSPACE SCALEXIO, NI PXI + VeriStand.

**Simulink Test**: Test Sequence, Test Assessment, MC/DC coverage for safety-critical.

## 3. Unity

**Physics**: `Time.fixedDeltaTime`, `Physics.simulationMode`, `ArticulationBody` (URDF import, PD joint control). PhysX is NOT deterministic across platforms — document determinism strategy explicitly for reproducible scenarios.

**ECS/DOTS**: `ISystem` (Burst-compiled), `IJobEntity`; required for >1000 agents.

**ML-Agents**: Agent subclass, `CollectObservations`, `OnActionReceived`, reward design; PPO/SAC training.

**Digital twin data binding**: ROS2 (`ros2-for-unity`), OPC-UA (`UA-.NETStandard`), UDP/TCP. Keep data ingestion and visual representation in separate components.

**Performance**: Addressables, LOD Groups, GPU Instancing. Target: 60fps desktop / 90fps XR.

**XR**: AR Foundation (`ARPlaneManager`, `ARAnchorManager`, LiDAR), OpenXR/MRTK3.

## 4. Unreal Engine

**C++ reflection**: `UCLASS`/`UPROPERTY`/`UFUNCTION`, `TSubclassOf`, `TSoftObjectPtr`.

**Gameplay Ability System**: `UGameplayAbility`, `UAttributeSet`, `FGameplayTag`.

**Digital twin**: Datasmith (CAD import, Dataprep batch material assignment), Pixel Streaming (SignallingWebServer, WebRTC, multi-viewer SFU), Cesium (`Cesium3DTileset`, WGS84↔UE coordinate conversion).

**Physics**: Chaos Vehicle (`UChaosWheeledVehicleMovementComponent`, tire friction, suspension), Chaos Physics.

**CARLA**: Python API, sensor suite, traffic manager.

## 5. Python Scientific Computing

**ODE/DAE solvers**: `scipy.integrate.solve_ivp` — RK45 (smooth non-stiff), Radau (stiff), BDF (stiff with discontinuities). Document solver choice rationale.

**Optimization**: BFGS, SLSQP, differential_evolution; JAX (`jax.grad`, `jit`, `vmap`).

**SymPy**: `LagrangesMethod`, `KanesMethod`, automatic equations of motion derivation.

**RL environments**: Gymnasium (`gym.Env` subclass, observation/action spaces, `VectorEnv`), IsaacLab (`ArticulationView`, `SimulationContext`, 4096+ envs).

**Differentiable physics**: JAX (`jit`, `vmap`, `grad`, `lax.scan`), Neural ODE (`torchdiffeq.odeint`, adjoint method), PINN (physics-informed loss, collocation point sampling).

**Reproducibility checklist**:
- [ ] `requirements.txt` with pinned versions (exact `==`)
- [ ] Random seed at entry point: `np.random.seed(SEED); random.seed(SEED)`
- [ ] Initial conditions as named constants with comments
- [ ] Reference output: `verify_output.py` asserting expected values within tolerance
- [ ] README with fresh environment setup instructions

## 6. Digital Twin Architecture

**Three-layer model**: Physical entity ↔ Digital model ↔ Service layer.

**Real-time sync protocols**: MQTT, OPC-UA, ROS2, Modbus.

**What-if analysis pattern**: Parameter sweep on digital model → predict outcomes → recommend actions.

**Platforms**: Azure Digital Twins, AWS IoT TwinMaker, NVIDIA Omniverse (USD format).

## 7. Anti-Patterns

| Name | Symptom | Correction |
|------|---------|------------|
| **Solver-Choice-by-Default** | ode45 (variable-step) for HIL-destined model | Configure fixed-step solver from design start |
| **Model-Test Divergence** | Offline passes claimed as HIL evidence without SIL/PIL | SIL verification mandatory between offline and HIL |
| **Unity Physics Determinism Blindspot** | Reproducible replay on PhysX without determinism strategy | Use fixed-step with explicit seed, document guarantee |
| **Python-for-Realtime** | Real-time control loop in Python targeting <10ms | Real-time loop belongs on embedded target or real-time OS |
| **Model-Coverage Gap** | High statement coverage but no fault injection | Fault injection matrix: sensor dropout, saturation, step disturbance |
