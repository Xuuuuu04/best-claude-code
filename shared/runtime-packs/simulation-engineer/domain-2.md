---
title: "Simulation Engineer — Domain 2: Unity & Unreal Engine"
source: core.md §Domain 2-3
---

# Domain 2: Unity

## 2.1 ECS/DOTS for Large-Scale Simulation

```csharp
using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;

// ISystem: Burst-compiled, no managed allocations
[BurstCompile]
public partial struct AgentMovementSystem : ISystem
{
    public void OnCreate(ref SystemState state)
    {
        state.RequireForUpdate<AgentMovementData>();
    }

    [BurstCompile]
    public void OnUpdate(ref SystemState state)
    {
        float deltaTime = SystemAPI.Time.DeltaTime;

        // IJobEntity: parallel entity processing
        var job = new MoveJob
        {
            DeltaTime = deltaTime
        };
        job.ScheduleParallel();
    }
}

public partial struct MoveJob : IJobEntity
{
    public float DeltaTime;

    void Execute(ref LocalTransform transform, in AgentMovementData movement)
    {
        transform.Position += movement.Velocity * DeltaTime;
    }
}

// Required when simulating >1000 independent agents
// MonoBehaviour: managed, GC pressure
// ECS/DOTS: unmanaged, Burst-compiled, cache-friendly
```

## 2.2 ML-Agents Configuration

```csharp
using Unity.MLAgents;
using Unity.MLAgents.Sensors;
using Unity.MLAgents.Actuators;

public class RobotAgent : Agent
{
    public ArticulationBody[] joints;
    public Transform target;

    public override void CollectObservations(VectorSensor sensor)
    {
        // Normalize to [-1, 1] for training stability
        foreach (var joint in joints)
        {
            sensor.AddObservation(joint.jointPosition[0] / math.PI);      // Joint angle
            sensor.AddObservation(joint.jointVelocity[0] / 10f);          // Joint velocity
        }

        // Target relative position
        Vector3 toTarget = target.position - transform.position;
        sensor.AddObservation(toTarget.x / 10f);
        sensor.AddObservation(toTarget.z / 10f);
    }

    public override void OnActionReceived(ActionBuffers actions)
    {
        // Continuous actions: target joint angles
        for (int i = 0; i < joints.Length; i++)
        {
            float targetAngle = actions.ContinuousActions[i] * math.PI / 3;
            var drive = joints[i].xDrive;
            drive.target = targetAngle;
            joints[i].xDrive = drive;
        }

        // Reward: distance to target
        float distance = Vector3.Distance(transform.position, target.position);
        AddReward(-distance * 0.01f);

        // Episode termination
        if (transform.position.y < 0.1f)  // Fallen
        {
            AddReward(-1.0f);
            EndEpisode();
        }
    }

    public override void OnEpisodeBegin()
    {
        // Reset robot pose
        transform.position = new Vector3(0, 0.5f, 0);
        foreach (var joint in joints)
        {
            joint.jointPosition = new ArticulationReducedSpace(0);
        }
    }
}
```

## 2.3 Digital Twin Data Binding

```csharp
using MQTTnet;
using MQTTnet.Client;

public class MqttDataBinding : MonoBehaviour
{
    private IMqttClient _mqttClient;
    public string brokerAddress = "192.168.1.100";
    public string topicPrefix = "factory/sensor/";

    // Separate data ingestion from visual representation
    private Dictionary<string, float> _sensorData = new();
    private readonly object _dataLock = new();

    async void Start()
    {
        var factory = new MqttFactory();
        _mqttClient = factory.CreateMqttClient();

        var options = new MqttClientOptionsBuilder()
            .WithTcpServer(brokerAddress)
            .Build();

        await _mqttClient.ConnectAsync(options);

        _mqttClient.ApplicationMessageReceivedAsync += e =>
        {
            var topic = e.ApplicationMessage.Topic;
            var payload = Encoding.UTF8.GetString(e.ApplicationMessage.Payload);
            float value = float.Parse(payload);

            lock (_dataLock)
            {
                _sensorData[topic] = value;
            }
            return Task.CompletedTask;
        };

        await _mqttClient.SubscribeAsync(topicPrefix + "#");
    }

    void Update()
    {
        // Visual representation: map sensor values to transforms/materials
        lock (_dataLock)
        {
            foreach (var kvp in _sensorData)
            {
                UpdateVisualization(kvp.Key, kvp.Value);
            }
        }
    }

    void UpdateVisualization(string sensorId, float value)
    {
        // Map to visual element
        var visual = GetVisualForSensor(sensorId);
        if (visual != null)
        {
            visual.SetValue(value);
        }
    }
}
```

---

# Domain 3: Unreal Engine

## 3.1 C++ Reflection and Blueprint Interop

```cpp
// UCLASS: Expose to Blueprint
UCLASS(Blueprintable, BlueprintType)
class MYPROJECT_API AMyActor : public AActor
{
    GENERATED_BODY()

public:
    // UPROPERTY: Expose to Blueprint
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Simulation")
    float SimulationSpeed = 1.0f;

    // UFUNCTION: Callable from Blueprint
    UFUNCTION(BlueprintCallable, Category = "Simulation")
    void StartSimulation();

    // BlueprintImplementableEvent: C++ declares, BP implements
    UFUNCTION(BlueprintImplementableEvent, Category = "Events")
    void OnSimulationComplete();

    // BlueprintNativeEvent: C++ default + BP override
    UFUNCTION(BlueprintNativeEvent, Category = "Events")
    void OnDataReceived(const FSensorData& Data);
    virtual void OnDataReceived_Implementation(const FSensorData& Data);
};
```

## 3.2 Pixel Streaming Setup

```cpp
// Enable Pixel Streaming plugin in .uproject
// Start signalling server:
// SignallingWebServer\platform_scripts\cmd\Start_SignallingServer.ps1

// Configure for multi-viewer SFU mode
UCLASS()
class APixelStreamingActor : public AActor
{
    UPROPERTY(EditAnywhere)
    bool bUseSFU = true;  // Enable Selective Forwarding Unit for multi-viewer

    void BeginPlay() override
    {
        if (bUseSFU)
        {
            FPixelStreamingModule::GetModule().AddInputHandler(
                FVector2D(0, 0), FVector2D(1920, 1080),
                FPixelStreamingInputHandler::CreateLambda(
                    [this](FString Command) { HandleInput(Command); }
                )
            );
        }
    }
};
```

## 3.3 Cesium for Unreal (GIS Integration)

```cpp
// Add CesiumGeoreference to level
// Configure WGS84 coordinates

UCLASS()
class ACesiumDigitalTwin : public AActor
{
    UPROPERTY(EditAnywhere)
    UCesiumGeoreference* Georeference;

    UPROPERTY(EditAnywhere)
    UCesium3DTileset* Tileset;

    void UpdateVehiclePosition(double Latitude, double Longitude, double Altitude)
    {
        // WGS84 to Unreal coordinates
        FVector ECEF = UCesiumWgs84Ellipsoid::GeodeticSurfaceNormal(
            FVector(Latitude, Longitude, Altitude)
        );
        FVector UE = Georeference->TransformEcefToUnreal(ECEF);

        VehicleMesh->SetWorldLocation(UE);
    }
};
```
