> Source: core.md §Anti-Patterns + §Rules (Primacy Anchor)

# Simulation Engineer — Anti-Patterns

## Named Anti-Patterns

---

### Solver-Choice-by-Default

**Definition**: Using Simulink default ode45 (variable-step) for a model destined for fixed-step HIL target. Offline simulation passes, HIL reveals behavior differences due to solver mismatch.

**Manifestations**:

BAD: Motor controller model uses ode45 (variable-step) throughout development. Offline simulation passes all tests. At HIL, the model overruns the 1ms step budget because ode45's adaptive steps cannot be used on real-time hardware.

```matlab
% BAD — Default solver, not suitable for HIL
set_param(gcs, 'Solver', 'ode45');  % Variable-step — FORBIDDEN for HIL
set_param(gcs, 'StopTime', '10');
```

GOOD: Configure fixed-step solver from the start of design. Document solver choice and justification.

```matlab
% GOOD — Fixed-step solver for HIL
cs = getActiveConfigSet(gcs);
set_param(cs, 'SolverType', 'Fixed-step');
set_param(cs, 'Solver', 'ode4');           % Runge-Kutta, fixed-step
set_param(cs, 'FixedStep', '0.001');       % 1ms step
set_param(cs, 'EnableConcurrentExecution', 'on');

% Document in model notes
set_param(gcs, 'Description', ...
    'HIL-targeted model. Fixed-step ode4, 1ms. ');
```

**Why it's dangerous**: Variable-step solvers adapt step size based on local error estimates. Real-time targets require fixed step sizes. The numerical behavior differs between variable-step and fixed-step, especially for stiff systems or systems with discontinuities.

**Correction**: Configure fixed-step solver from the start of design. Step size = min(target hardware budget, 1/20 × bandwidth). Enable Solver Profiler to verify no adaptive steps.

---

### Model-Test Divergence

**Definition**: Delivering a simulation model with passing offline tests as evidence HIL will pass, without SIL/PIL verification.

**Manifestations**:

BAD: "Offline simulation works, let's go straight to HIL." The generated code has different numerical behavior due to floating-point differences between MATLAB and target compiler. HIL fails, and the team has no idea whether the problem is the model, the code generation, or the hardware.

```
Offline: passes all tests → HIL: fails
Root cause unknown: model? codegen? hardware? I/O?
Investigation time: 2 weeks
```

GOOD: Offline → SIL (generated code on desktop, compare numerically) → PIL (on target processor, verify arithmetic) → HIL (real I/O, real timing). Each step narrows the failure space.

```
Offline: passes all tests
SIL: compare offline vs generated code numerically
  → If SIL fails: problem is code generation
  → If SIL passes: proceed to PIL
PIL: run generated code on target processor
  → If PIL fails: problem is target arithmetic or compiler
  → If PIL passes: proceed to HIL
HIL: real I/O, real timing
  → If HIL fails: problem is I/O or timing

Investigation time per step: 1-2 days
```

**Why it's dangerous**: Skipping SIL/PIL means when HIL fails, you have no idea which layer introduced the problem. The failure space spans model, code generation, compiler, target arithmetic, I/O mapping, and timing — all at once.

**Correction**: SIL verification mandatory between offline and HIL claims. PIL mandatory before HIL if target processor has different floating-point behavior.

---

### Unity Physics Determinism Blindspot

**Definition**: Building multiplayer or reproducible-replay simulation on Unity's PhysX without documenting its non-determinism.

**Manifestations**:

BAD: Multiplayer game uses PhysX for simulation state. Clients diverge after ~5 seconds because PhysX produces slightly different results on different machines due to floating-point differences and thread scheduling.

```csharp
// BAD — PhysX is NOT deterministic across machines
void FixedUpdate() {
    rigidBody.AddForce(inputForce);
    // PhysX integration — different results on client A vs client B
}
```

GOOD: Run authoritative simulation on server, broadcast state to clients, clients do visual-only interpolation. Or use custom deterministic integrator.

```csharp
// GOOD — Authoritative server, deterministic replay
public class DeterministicSimulation : MonoBehaviour {
    private PhysicsScene _physicsScene;
    private float _fixedDeltaTime = 0.02f;

    void Awake() {
        // Create isolated physics scene for determinism
        var sceneParams = new PhysicsSceneParameters(PhysicsSimulationMode2D.Script);
        _physicsScene = PhysicsSceneExtensions.GetPhysicsScene(
            gameObject.scene
        );
    }

    void FixedUpdate() {
        // Step physics with explicit timestep
        Physics.Simulate(_fixedDeltaTime);
    }

    // Server-authoritative: broadcast state, clients interpolate
    public void ApplyServerState(ServerState state) {
        // Interpolate to server state, don't simulate locally
    }
}
```

**Why it's dangerous**: Non-determinism in multiplayer creates divergent game states that are impossible to reconcile. In reproducible testing, non-determinism means a test that passes once may fail the next time with the same inputs.

**Correction**: Use deterministic simulation for reproducible scenarios. Document the determinism guarantee (or lack thereof). For multiplayer, use authoritative server with client-side prediction.

---

### Python-for-Realtime

**Definition**: Writing a real-time control loop in Python using `time.sleep()` targeting deterministic periodicity. Python's GIL and garbage collector produce unpredictable pauses.

**Manifestations**:

BAD: Real-time control loop in Python targeting 1ms periodicity. Garbage collection pauses cause 5-20ms jitter, violating real-time constraints.

```python
# BAD — Python for hard real-time
import time

while True:
    control_output = compute_control(sensor_reading)
    send_to_actuator(control_output)
    time.sleep(0.001)  # Target 1ms — but GC can pause for 10ms+
```

GOOD: Real-time loop runs on embedded target (Embedded Coder C) or real-time OS. Python handles analysis, configuration, and offline computation.

```python
# GOOD — Python for analysis, not real-time control
def analyze_control_performance(log_data: pd.DataFrame) -> Dict:
    """Offline analysis of control loop performance."""
    return {
        'mean_cycle_time': log_data['dt'].mean(),
        'max_cycle_time': log_data['dt'].max(),
        'jitter': log_data['dt'].std(),
        'overrun_count': (log_data['dt'] > 0.001).sum()
    }

# Real-time control runs on target MCU in C
```

**Why it's dangerous**: Python's garbage collector can pause execution for 10-100ms unpredictably. The GIL prevents true parallelism. These characteristics make Python fundamentally unsuitable for hard real-time loops.

**Correction**: Real-time control loops belong on embedded targets (Embedded Coder generated C) or real-time OS threads. Python is for analysis, configuration, and offline computation.

---

### Model-Coverage Gap

**Definition**: Achieving high statement/branch coverage on control logic while leaving sensor edge cases, actuator saturation, and fault injection untested.

**Manifestations**:

BAD: Test suite achieves 95% statement coverage on the controller but never tests sensor dropout, actuator saturation, or emergency stop conditions. HIL testing reveals the controller crashes when a sensor fails.

```
Coverage report: 95% statement, 90% branch
Untested: sensor dropout, actuator saturation, emergency stop
HIL result: controller crashes on sensor failure
```

GOOD: Fault injection matrix mandatory — test every sensor/actuator failure mode.

```matlab
% GOOD — Fault injection test matrix
function test_fault_injection()
    sensors = {'ia', 'ib', 'theta', 'omega'};
    faults = {'dropout', 'saturation', 'noise', 'delay'};

    for i = 1:length(sensors)
        for j = 1:length(faults)
            test_name = sprintf('%s_%s', sensors{i}, faults{j});
            result = run_hil_test(test_name);
            assert(result.passed, 'Fault injection failed: %s', test_name);
        end
    end
end
```

**Why it's dangerous**: Real systems fail at the edges — sensors drop out, actuators saturate, communications glitch. A controller that only works in nominal conditions is not production-ready.

**Correction**: Fault injection matrix mandatory for every sensor and actuator: dropout (signal goes to zero), saturation (signal at max), noise (high variance), delay (latency exceeds budget). Document expected behavior for each fault mode.
