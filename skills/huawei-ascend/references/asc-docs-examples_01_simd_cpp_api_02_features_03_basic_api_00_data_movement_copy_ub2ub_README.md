# Copy接口多场景示例

## 概述

本样例介绍Copy接口在多种场景下的使用方法。Copy接口用于在Unified Buffer内部进行数据搬运（VECIN、VECCALC、VECOUT之间），支持mask连续模式和counter模式。样例支持通过编译参数切换不同场景，便于开发者理解Copy接口的使用方法。

数据搬运过程包括：Global Memory（GM）→VECIN队列、VECIN→VECOUT（使用Copy API）、VECOUT队列→Global Memory（GM）。其中Copy API通过mask参数控制参与计算的元素数量，通过DataBlock参数控制数据块的地址步长，实现对数据搬运过程的精细化管理。

## 支持的产品

- Ascend 950PR/Ascend 950DT
- Atlas A3 训练系列产品/Atlas A3 推理系列产品
- Atlas A2 训练系列产品/Atlas A2 推理系列产品

## 目录结构介绍

```
├── copy_ub2ub
│   ├── scripts
│   │   ├── gen_data.py             // 输入数据和真值数据生成脚本
│   │   └── verify_result.py        // 验证输出数据和真值数据是否一致的验证脚本
│   ├── CMakeLists.txt              // 编译工程文件
│   ├── data_utils.h                // 数据读入写出函数
│   └── copy.asc                  // Ascend C样例实现 & 调用样例
```

## 场景说明

本样例通过编译参数 `SCENARIO_NUM` 选择不同场景，所有场景数据格式为 ND，核函数名为 `copy_custom`。

<table border="2">
<caption>表1：场景配置对照表</caption>
<tr><th>scenarioNum</th><th>输入Shape</th><th>输出Shape</th><th>搬运模式</th><th>说明</th></tr>
<tr><td>1</td><td>[1, 512]</td><td>[1, 512]</td><td>mask连续模式</td><td>简单数据搬运，源和目的空间相同</td></tr>
<tr><td>2</td><td>[18, 64]</td><td>[18, 8]</td><td>mask连续模式</td><td>从大空间搬运部分数据，源和目的空间不同</td></tr>
<tr><td>3</td><td>[18, 64]</td><td>[18, 8]</td><td>counter模式</td><td>使用counter模式从大空间搬运部分数据</td></tr>
</table>

### 场景详细说明

**场景1：mask连续模式，源和目的空间相同**
- 输入输出：[1, 512]个int32元素
- 参数配置：mask=64, repeatTime=8, stride={1, 1, 8, 8}
- 说明：每次迭代处理64个元素，迭代8次，共搬运512个元素

**场景2：mask连续模式，源和目的空间不同**
- 输入：[18, 64]个int32元素（共1152个）
- 输出：[18, 8]个int32元素（共144个）
- 参数配置：mask=8, repeatTime=18, stride={1, 1, 1, 8}
- 说明：从每行64个元素中搬运前8个，共18行；srcRepeatSize=1跳过64个元素（8个block），dstRepeatSize=8紧凑排列

**场景3：counter模式，源和目的空间不同**
- 输入：[18, 64]个int32元素（共1152个）
- 输出：[18, 8]个int32元素（共144个）
- 参数配置：使用SetVectorMask设置counter模式，mask=144, repeatTime=1, stride={1, 8, 8, 8}
- 说明：counter模式下mask代表每次repeat处理的元素个数，每次迭代处理144个元素（全部行），迭代1次

## 编译运行

在本样例根目录下执行如下步骤，编译并执行样例。
- 配置环境变量  
  请根据当前环境上CANN开发套件包的[安装方式](../../../../../../docs/quick_start.md#prepare&install)，选择对应配置环境变量的命令。
  - 默认路径，root用户安装CANN软件包
    ```bash
    source /usr/local/Ascend/cann/set_env.sh
    ```

  - 默认路径，非root用户安装CANN软件包
    ```bash
    source $HOME/Ascend/cann/set_env.sh
    ```

  - 指定路径install_path，安装CANN软件包
    ```bash
    source ${install_path}/cann/set_env.sh
    ```
    
- 样例执行
  ```bash
  SCENARIO_NUM=1
  mkdir -p build && cd build;      # 创建并进入build目录
  cmake -DSCENARIO_NUM=$SCENARIO_NUM -DCMAKE_ASC_ARCHITECTURES=dav-2201 ..;make -j;    # 编译工程，默认npu模式
  python3 ../scripts/gen_data.py -scenarioNum=$SCENARIO_NUM   # 生成测试输入数据
  ./demo                           # 执行编译生成的可执行程序，执行样例
  python3 ../scripts/verify_result.py output/output.bin output/golden.bin  # 验证输出结果是否正确
  ```

  使用CPU调试或NPU仿真模式时，添加`-DCMAKE_ASC_RUN_MODE=cpu`或`-DCMAKE_ASC_RUN_MODE=sim`参数即可。
  
  示例如：
  ```bash
  cmake -DSCENARIO_NUM=$SCENARIO_NUM -DCMAKE_ASC_RUN_MODE=cpu -DCMAKE_ASC_ARCHITECTURES=dav-2201 ..;make -j; # cpu调试模式
  cmake -DSCENARIO_NUM=$SCENARIO_NUM -DCMAKE_ASC_RUN_MODE=sim -DCMAKE_ASC_ARCHITECTURES=dav-2201 ..;make -j; # NPU仿真模式
  ```
  > **注意：** 切换编译模式前需清理 cmake 缓存，可在 build 目录下执行 `rm CMakeCache.txt` 后重新 cmake。

- 编译选项说明

  | 选项 | 可选值 | 说明 |
  |------|--------|------|
  | `CMAKE_ASC_RUN_MODE` | `npu`（默认）、`cpu`、`sim` | 运行模式：NPU 运行、CPU调试、NPU仿真 |
  | `CMAKE_ASC_ARCHITECTURES` | `dav-2201`（默认）、`dav-3510` | NPU 架构：dav-2201 对应 Atlas A2/A3 系列、dav-3510 对应 Ascend 950PR/Ascend 950DT |
  | `SCENARIO_NUM` | `1`（默认）、`2`、`3` | 场景编号 |

- 执行结果

  执行结果如下，说明精度对比成功。
  ```bash
  test pass!
  ```
