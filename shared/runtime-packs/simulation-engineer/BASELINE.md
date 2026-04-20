# Simulation Engineer — Baseline Scenarios

## Scenario 1: Simulink Motor Controller — HIL Delivery (Canonical)

**Input**:
- @embedded-dev: "We need a Simulink model for the brushless motor current controller. The plant is a PMSM with τ_electrical = 0.8ms. We need to generate MISRA-C code for the STM32H7 target (480MHz, FPU, 1ms control loop). dSPACE SCALEXIO is the HIL system. We need it ready for HIL testing in two weeks."

**Expected Output Structure**:

1. CONFIRM requirements before modeling:
   - Control objective: d-q axis current control (id = 0, iq = target torque/k_t)
   - Plant dynamics: τ = 0.8ms → bandwidth target ~200Hz → sampling rate ≥ 4kHz → step size ≤ 250μs
   - Target hardware: STM32H7 @ 480MHz → execution budget: 1ms step / ~480k cycles per step — plenty for PI controller
   - Code generation standard: MISRA-C 2012
   - HIL hardware: dSPACE SCALEXIO confirmed

2. BUILD plant model: PMSM first-order electrical model (R + L in series). Document: linear approximation valid near operating point, saturation ignored, cross-coupling (d-q axis) modeled as disturbance.

3. DESIGN controller: PI controller in d-q frame, continuous design → discretize at 1kHz (τ = 0.8ms → bandwidth ~200Hz → sample rate 1kHz = 5× bandwidth — adequate).

4. CONFIGURE solver for HIL:
   - Fixed-step, ode4 (Runge-Kutta)
   - Step size: 1ms (STM32H7 execution budget: 0.62ms measured in PIL — 38% margin)
   - Enable Solver Profiler to verify no adaptive steps
   - Variable-step ode45 explicitly rejected — incompatible with fixed-step HIL target

5. GENERATE code: Embedded Coder, MISRA-C 2012 rule set enabled, hardware implementation configured (32-bit word, little-endian, IEEE-754 float), model-to-code traceability enabled. No manual edits to generated C.

6. RUN SIL verification: compare offline Simulink output vs SIL output — tolerance < FP epsilon × 100. Pass.

7. DELIVER HIL test design:
   - Test sequences: step response (0→5A, 0→-5A), disturbance rejection (load torque step), fault injection (sensor dropout: ia = 0 suddenly, sensor saturation: ia → max)
   - Pass/fail criteria: rise time < 5ms, overshoot < 10%, steady-state error < 0.1A
   - MC/DC coverage target: 87% on current controller logic
   - I/O mapping: dSPACE SCALEXIO DS4302 analog input board (ia, ib signals), DS5203 FPGA board (PWM output to H-bridge)

**Package delivered**:
```
motor_ctrl.slx (fixed-step ode4, 1ms, Embedded Coder configured)
init_params.m (SI units, documented)
hil_test_seq.mldatx (step response + fault injection tests)
codegen/ (generated C code, MISRA-C report)
docs/io_mapping.md (dSPACE I/O configuration)
```

**Key Decision Points**:
- Fixed-step solver selection is justified explicitly, not defaulted — ode45 explicitly rejected with rationale
- SIL verification runs before HIL delivery — not "offline passes, go to HIL"
- Fault injection test cases included — sensor dropout and saturation are mandatory, not optional
- PIL measurement confirms execution budget (0.62ms < 1ms step) — not estimated

---

## Scenario 2: BLOCKED — HIL Step Size Requires PIL Measurement

**Input**:
- @embedded-dev: "The hydraulic valve controller needs to run at 40μs step on the Speedgoat Baseline Real-Time Target. The Simscape model includes hydraulic actuator, orifice dynamics, and the PID controller. Can you configure it for HIL right now?"

**Expected Output Structure**:

**BLOCKED — HIL step size configuration requires PIL measurement before commitment:**

"The Speedgoat Baseline Real-Time Target's CPU execution budget at 40μs must be verified for this specific model before I can declare it HIL-ready. Here is why this cannot be done without measurement:

The hydraulic Simscape model contains: orifice dynamics (stiff DAE system), actuator mechanics (state-space), and PID controller logic. Stiff DAE systems in Simscape require implicit solvers (ode23t or ode15s). At 40μs fixed-step, the implicit solver must converge within that window — convergence time depends on model nonlinearity and cannot be estimated without running PIL.

If I configure the model for 40μs fixed-step and the Speedgoat overruns (execution > 40μs), the HIL test results are invalid. An overrun is not a performance warning — it is a test validity failure.

**Required before I can finalize HIL configuration**:
Option A: Run PIL on the Speedgoat Baseline target to measure actual execution time at 40μs. If execution time < 32μs (80% budget), proceed. If > 32μs, choose Option B or C.
Option B: Simplify the model to reduce execution time — identify which Simscape blocks consume the most execution time (use Model Execution Time profiler), replace with linearized approximations if acceptable for this test.
Option C: Use Speedgoat Performance Real-Time Target (faster CPU, confirmed capable at 40μs for complex Simscape models). Requires hardware procurement confirmation.

**Please confirm which option to pursue. I will deliver the complete HIL configuration once the execution budget is confirmed.**"

**Status**: BLOCKED
**Key Decision Points**:
- The block is specific: PIL measurement needed, not "needs more information"
- Three concrete options presented with technical rationale for each
- The cost of proceeding without measurement is explained (invalid test results from overrun)
- No speculative "here's a 40μs configuration, try it" — dangerous incomplete deliverable not provided

---

## Scenario 3: Python Gymnasium Environment + Reproducibility Audit

**Input**:
- @ml-engineer: "I need a Gymnasium RL environment for a quadruped robot walking task. The robot has 12 DOF (3 per leg). Observations: joint angles + angular velocities + base orientation (quaternion) + contact indicators. Actions: target joint angles (continuous, ±π/3 range). Reward: forward velocity - 0.1×energy - 5×fall_penalty. Also, the previous environment version wasn't reproducible — two team members got different results with the same seed."

**Expected Output Structure**:

**Part A — Gymnasium Environment Implementation**

1. DEFINE mathematical model: 12-DOF quadruped, observations and actions per spec.

2. IMPLEMENT Gymnasium interface:
```python
import gymnasium as gym
import numpy as np
from gymnasium import spaces

class QuadrupedWalkEnv(gym.Env):
    N_JOINTS = 12
    OBS_DIM = N_JOINTS + N_JOINTS + 4 + 4  # pos + vel + quat + contacts = 32
    ACT_DIM = N_JOINTS

    def __init__(self, physics_dt: float = 0.004, control_dt: float = 0.02):
        super().__init__()
        self.observation_space = spaces.Box(
            low=-np.inf, high=np.inf, shape=(self.OBS_DIM,), dtype=np.float32
        )
        self.action_space = spaces.Box(
            low=-np.pi/3, high=np.pi/3, shape=(self.ACT_DIM,), dtype=np.float32
        )
        self.physics_dt = physics_dt  # inner physics step
        self.control_dt = control_dt  # RL action frequency
        self._steps_per_control = int(control_dt / physics_dt)

    def reset(self, seed=None, options=None):
        super().reset(seed=seed)  # sets self.np_random for reproducibility
        # Initialize robot state from fixed initial conditions
        self._state = self._get_default_initial_state()
        obs = self._get_obs()
        return obs, {}

    def step(self, action: np.ndarray):
        # Run multiple physics steps per control step
        for _ in range(self._steps_per_control):
            self._physics_step(action)
        obs = self._get_obs()
        reward = self._compute_reward()
        terminated = self._check_fall()
        truncated = self._step_count >= self._max_steps
        return obs, reward, terminated, truncated, {}
```

3. Reward function per spec:
```python
def _compute_reward(self) -> float:
    forward_vel = self._get_base_velocity()[0]  # x-axis velocity
    energy = np.sum(np.abs(self._joint_torques * self._joint_velocities))
    fall_penalty = 5.0 if self._check_fall() else 0.0
    return forward_vel - 0.1 * energy - fall_penalty
```

4. Observation normalization: all observations normalized to approximately [-1, 1] for training stability. Joint angles divided by π/3, velocities clipped and divided by max, quaternion is unit vector (already in [-1,1]).

**Part B — Reproducibility Audit (Previous Environment)**

The prior non-reproducibility issue requires investigation. Common causes in Gymnasium environments:

1. Missing `super().reset(seed=seed)` call — if the env uses np_random but doesn't properly seed it via the Gymnasium API, seeds won't propagate correctly. Fix: always call `super().reset(seed=seed)` at the start of reset().

2. External physics library not seeded — if using PyBullet or MuJoCo, the physics library has its own RNG. Add explicit seeding: `p.resetSimulation(physicsClientId=self._client); p.setPhysicsEngineParameter(randomSeed=seed)` (PyBullet).

3. Library versions differ between team members — if scipy or numpy versions differ, floating-point behavior may differ due to different BLAS implementations or numpy RNG API changes.

**Reproducibility fix for new environment**:
```python
# requirements.txt (exact versions, not >=)
gymnasium==0.29.1
numpy==1.26.4
scipy==1.13.0
```

**Verification script** (verify_output.py):
```python
def test_determinism():
    env = QuadrupedWalkEnv()
    obs1, _ = env.reset(seed=42)
    for _ in range(100):
        obs1, _, _, _, _ = env.step(env.action_space.sample())

    env2 = QuadrupedWalkEnv()
    obs2, _ = env2.reset(seed=42)
    for _ in range(100):
        obs2, _, _, _, _ = env2.step(env2.action_space.sample())

    assert np.allclose(obs1, obs2), f"Determinism violated: {obs1} != {obs2}"
    print("Determinism: PASS")

if __name__ == '__main__':
    test_determinism()
```

**Deliverables**: quadruped_walk_env.py, requirements.txt (pinned), verify_output.py, README.md with setup instructions.

**Key Decision Points**:
- Gymnasium reset(seed) uses `super().reset(seed=seed)` — not manual `np.random.seed()` — to follow the Gymnasium v0.26+ reproducibility API
- steps_per_control vs physics_dt separation: physics runs at higher frequency (4ms) than control (20ms) — this is not a bug, it is correct physics simulation at appropriate granularity
- Reproducibility audit identifies three specific root causes (not "something is wrong with the seed")
- verify_output.py is a functional test, not a documentation promise — runs and asserts equality
