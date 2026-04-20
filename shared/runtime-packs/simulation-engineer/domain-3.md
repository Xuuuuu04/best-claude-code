---
title: "Simulation Engineer — Domain 3: Python Scientific Computing & Digital Twin"
source: core.md §Domain 4
---

# Domain 4: Python Scientific Computing

## 4.1 ODE/DAE Solver Selection

```python
from scipy.integrate import solve_ivp
import numpy as np

def solve_dynamics(t_span, y0, params, method='RK45'):
    """
    Solve ODE with automatic stiffness detection.
    
    Methods:
    - RK45: Non-stiff, smooth (default, good first choice)
    - DOP853: Higher accuracy non-stiff
    - Radau: Stiff implicit (widely separated eigenvalues)
    - BDF: Stiff large systems
    - LSODA: Auto-switch between Adams (non-stiff) and BDF (stiff)
    """
    def dynamics(t, y):
        # Example: mass-spring-damper
        x, v = y
        m, c, k = params['m'], params['c'], params['k']
        dxdt = v
        dvdt = (-c * v - k * x) / m
        return [dxdt, dvdt]
    
    sol = solve_ivp(
        dynamics, t_span, y0,
        method=method,
        dense_output=True,
        max_step=0.01,
        rtol=1e-6,
        atol=1e-9
    )
    
    # Stiffness indicator: if RK45 took tiny steps, switch to Radau
    if method == 'RK45' and len(sol.t) > 10000:
        print("WARNING: RK45 used many steps — system may be stiff. Retrying with Radau.")
        sol = solve_ivp(dynamics, t_span, y0, method='Radau')
    
    return sol
```

## 4.2 JAX for Differentiable Physics

```python
import jax
import jax.numpy as jnp
from jax import jit, vmap, grad

# JIT compilation for performance
@jit
def pendulum_dynamics(state, params):
    """Differentiable pendulum dynamics."""
    theta, omega = state
    g, L = params['g'], params['L']
    dtheta = omega
    domega = -(g / L) * jnp.sin(theta)
    return jnp.array([dtheta, domega])

# Vectorized over batch of initial conditions
batched_dynamics = vmap(pendulum_dynamics, in_axes=(0, None))

# Gradient of final angle w.r.t. initial angle
sensitivity = grad(lambda theta0: simulate(theta0, params)[-1, 0])

# Efficient sequential loop
from jax import lax

def simulate_scan(theta0, params, n_steps=1000, dt=0.01):
    """Simulate using lax.scan for efficient sequential execution."""
    def step_fn(state, _):
        new_state = state + dt * pendulum_dynamics(state, params)
        return new_state, new_state
    
    initial_state = jnp.array([theta0, 0.0])
    _, trajectory = lax.scan(step_fn, initial_state, jnp.arange(n_steps))
    return trajectory
```

## 4.3 Gymnasium Environment Design

```python
import gymnasium as gym
import numpy as np
from gymnasium import spaces

class QuadrupedWalkEnv(gym.Env):
    """
    Gymnasium environment for quadruped robot walking.
    Follows Gymnasium v0.29+ API.
    """
    metadata = {'render_modes': ['human', 'rgb_array']}
    
    N_JOINTS = 12
    OBS_DIM = N_JOINTS * 2 + 4 + 4  # pos + vel + quat + contacts
    ACT_DIM = N_JOINTS
    
    def __init__(self, physics_dt=0.004, control_dt=0.02, render_mode=None):
        super().__init__()
        
        self.observation_space = spaces.Box(
            low=-np.inf, high=np.inf,
            shape=(self.OBS_DIM,), dtype=np.float32
        )
        self.action_space = spaces.Box(
            low=-np.pi/3, high=np.pi/3,
            shape=(self.ACT_DIM,), dtype=np.float32
        )
        
        self.physics_dt = physics_dt
        self.control_dt = control_dt
        self._steps_per_control = int(control_dt / physics_dt)
        self.render_mode = render_mode
        
        self._max_steps = 1000
        self._step_count = 0
    
    def reset(self, seed=None, options=None):
        super().reset(seed=seed)
        
        # Initialize from fixed initial conditions
        self._state = self._get_default_initial_state()
        self._step_count = 0
        
        obs = self._get_obs()
        info = {}
        
        return obs, info
    
    def step(self, action):
        # Run multiple physics steps per control step
        for _ in range(self._steps_per_control):
            self._state = self._physics_step(self._state, action)
        
        obs = self._get_obs()
        reward = self._compute_reward()
        terminated = self._check_fall()
        truncated = self._step_count >= self._max_steps
        info = {}
        
        self._step_count += 1
        return obs, reward, terminated, truncated, info
    
    def _compute_reward(self):
        forward_vel = self._state['base_velocity'][0]
        energy = np.sum(np.abs(self._state['joint_torques'] * self._state['joint_velocities']))
        fall_penalty = 5.0 if self._check_fall() else 0.0
        return forward_vel - 0.1 * energy - fall_penalty
    
    def _get_obs(self):
        # Normalize observations to ~[-1, 1]
        obs = np.concatenate([
            self._state['joint_pos'] / (np.pi/3),
            np.clip(self._state['joint_vel'] / 10, -1, 1),
            self._state['base_quat'],  # Already normalized
            self._state['foot_contacts'].astype(np.float32)
        ])
        return obs.astype(np.float32)
    
    def _check_fall(self):
        return self._state['base_position'][1] < 0.15
```

## 4.4 IsaacLab GPU-Parallel Environments

```python
from isaaclab.envs import ManagerBasedRLEnv
from isaaclab.scene import InteractiveSceneCfg
from isaaclab.assets import ArticulationCfg

@configclass
class QuadrupedEnvCfg(ManagerBasedRLEnvCfg):
    """IsaacLab environment configuration for quadruped."""
    
    scene: InteractiveSceneCfg = InteractiveSceneCfg(
        num_envs=4096,  # Parallel environments on GPU
        env_spacing=4.0
    )
    
    robot: ArticulationCfg = ArticulationCfg(
        prim_path="/World/envs/env_.*/Robot",
        spawn=sim_utils.UsdFileCfg(
            usd_path="${ISAACLAB_NUCLEUS_DIR}/Robots/Quadruped/go1.usd"
        )
    )
    
    # Observations: torch.Tensor, GPU-resident
    observations = ObservationsCfg(
        policy=ObsGroup(
            joint_pos=ObsTerm(func=mdp.joint_pos_rel),
            joint_vel=ObsTerm(func=mdp.joint_vel_rel),
            base_lin_vel=ObsTerm(func=mdp.base_lin_vel),
            base_ang_vel=ObsTerm(func=mdp.base_ang_vel)
        )
    )
    
    # Actions: torch.Tensor, GPU-resident
    actions = ActionsCfg(
        joint_pos=JointPositionActionCfg(
            asset_name="robot",
            joint_names=[".*"],
            scale=0.5
        )
    )

# Training: 4096 parallel envs on single A100
# obs: torch.Tensor shape (4096, obs_dim) — GPU
# actions: torch.Tensor shape (4096, act_dim) — GPU
# No CPU-GPU transfer during rollout
```

---

# Digital Twin Architecture

## Three-Layer Model

```
┌─────────────────────────────────────────┐
│         Service Layer                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ Analytics│ │ What-If │ │  Alert  │  │
│  └─────────┘ └─────────┘ └─────────┘  │
├─────────────────────────────────────────┤
│         Digital Model Layer             │
│  ┌─────────────────────────────────┐   │
│  │  Unity / Unreal / Simulink      │   │
│  │  - 3D visualization             │   │
│  │  - Physics simulation           │   │
│  │  - State synchronization        │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│         Physical Entity Layer           │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ Sensors │ │ Actuators│ │  PLC   │  │
│  └─────────┘ └─────────┘ └─────────┘  │
└─────────────────────────────────────────┘
```

## Real-Time Sync Protocols

| Protocol | Use Case | Latency | Bandwidth | Best For |
|---|---|---|---|---|
| MQTT | IoT telemetry | 10-100ms | Low | Many sensors, pub/sub |
| OPC-UA | Industrial automation | 1-10ms | Medium | MES/SCADA integration |
| ROS2 | Robotics | 1-10ms | Medium | Robot fleet coordination |
| Modbus | Legacy equipment | 10-100ms | Low | PLC communication |
| DDS | Real-time systems | <1ms | High | Safety-critical control |

## Digital Twin Data Flow

```python
class DigitalTwinSync:
    """Real-time synchronization between physical and digital models."""
    
    def __init__(self, protocol='mqtt'):
        self.protocol = protocol
        self.physical_state = {}
        self.digital_state = {}
        self.sync_latency_ms = 0
        
    def on_physical_update(self, sensor_data: dict):
        """Called when physical sensor data arrives."""
        timestamp = time.time()
        self.physical_state.update(sensor_data)
        
        # Forward to digital model
        self._update_digital_model(sensor_data)
        
        # Measure sync latency
        self.sync_latency_ms = (time.time() - timestamp) * 1000
        
    def _update_digital_model(self, data: dict):
        """Update Unity/Unreal model via protocol."""
        if self.protocol == 'mqtt':
            self.mqtt_client.publish('twin/update', json.dumps(data))
        elif self.protocol == 'opcua':
            for node_id, value in data.items():
                self.opcua_client.set_value(node_id, value)
    
    def what_if_analysis(self, scenario: dict) -> dict:
        """
        Run what-if scenario on digital model without affecting physical.
        """
        # Fork digital state
        hypothetical_state = copy.deepcopy(self.digital_state)
        hypothetical_state.update(scenario)
        
        # Run simulation
        result = self.simulate(hypothetical_state, duration=3600)
        
        return {
            'scenario': scenario,
            'predicted_outcome': result,
            'confidence': self._estimate_confidence(result)
        }
```
