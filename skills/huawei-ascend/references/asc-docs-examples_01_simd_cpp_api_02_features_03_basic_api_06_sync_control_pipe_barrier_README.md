# PipeBarrier样例

## 概述

本样例基于PipeBarrier实现核内多流水同步控制，完整展示了数据搬入、向量计算、数据搬出全流程中的同步机制。样例涵盖了PIPE_MTE2（搬入流水）、PIPE_V（矢量计算流水）、PIPE_MTE3（搬出流水）三种流水类型的单流水同步，以及使用SetFlag/WaitFlag进行的多流水同步。

## 支持的产品

- Ascend 950PR/Ascend 950DT
- Atlas A3 训练系列产品/Atlas A3 推理系列产品
- Atlas A2 训练系列产品/Atlas A2 推理系列产品

## 目录结构介绍

```
├── pipe_barrier
│   ├── scripts
│   │   ├── gen_data.py         // 输入数据和真值数据生成脚本
│   │   └── verify_result.py    // 验证输出数据和真值数据是否一致的验证脚本
│   ├── CMakeLists.txt          // 编译工程文件
│   ├── data_utils.h            // 数据读入写出函数
│   └── pipe_barrier.asc        // Ascend C样例实现 & 调用样例
```

## 样例功能描述

本样例在核内同步场景下，展示了完整数据处理流程中的多级流水同步控制。样例包含三个处理阶段：

### 1. 搬入阶段（PIPE_MTE2同步）

当多条数据搬入指令的搬入目的地址Unified Buffer存在重叠时，需要使用PipeBarrier<PIPE_MTE2>阻塞MTE2搬入流水，保证数据搬入顺序正确。

本样例中，src1和src2在UB上分配的地址区间有128个float元素的重叠：
```
src1Addr = 256 * sizeof(float)         // src1起始地址，元素个数为256
src2Addr = (256 + 128) * sizeof(float) // src2起始地址，元素个数为256
```

为保证src2的数据不被src1在重叠区间覆盖，必须先搬入src2，再搬入src1：
```
DataCopy(src2Local, src2Global, srcDataSize); // 先搬入src2
PipeBarrier<PIPE_MTE2>();                     // 阻塞MTE2流水
DataCopy(src1Local, src1Global, srcDataSize); // 后搬入src1
```

### 2. 计算阶段（PIPE_V同步）

使用SetFlag/WaitFlag进行MTE2->V多流水同步，确保所有数据搬入完成后才开始向量计算：
```
SetFlag<HardEvent::MTE2_V>(EVENT_ID0);
WaitFlag<HardEvent::MTE2_V>(EVENT_ID0);
```

执行Add计算得到中间结果，然后使用PipeBarrier<PIPE_V>阻塞矢量流水，确保Add完成后再执行Mul：
```
Add(dstLocal, src0Local, src1Local, srcDataSize);  // dst = src0 + src1
PipeBarrier<PIPE_V>();                              // 阻塞PIPE_V流水
Mul(dst2Local, dstLocal, src0Local, srcDataSize);  // dst2 = dst * src0 = (src0+src1)*src0
```

### 3. 搬出阶段（PIPE_MTE3同步）

使用SetFlag/WaitFlag进行V->MTE3多流水同步，确保所有向量计算完成后才开始数据搬出：
```
SetFlag<HardEvent::V_MTE3>(EVENT_ID0);
WaitFlag<HardEvent::V_MTE3>(EVENT_ID0);
```

使用PipeBarrier<PIPE_MTE3>阻塞MTE3搬出流水，保证dst搬出完成后再搬出dst2：
```
DataCopy(dstGlobal, dstLocal, dstDataSize);  // 搬出dst
PipeBarrier<PIPE_MTE3>();                     // 阻塞MTE3流水
DataCopy(dst2Global, dst2Local, dstDataSize); // 搬出dst2
```


### 样例规格

<table>
<caption>表1：样例输入输出规格</caption>
<tr><td rowspan="1" align="center">样例类型</td><td colspan="4" align="center">核内多流水同步</td></tr>
<tr><td rowspan="3" align="center">样例输入</td><td align="center">name</td><td align="center">shape</td><td align="center">data type</td><td align="center">format</td></tr>
<tr><td align="center">src0</td><td align="center">[256]</td><td align="center">float</td><td align="center">ND</td></tr>
<tr><td align="center">src1</td><td align="center">[256]</td><td align="center">float</td><td align="center">ND</td></tr>
<tr><td align="center">src2</td><td align="center">[256]</td><td align="center">float</td><td align="center">ND</td></tr>
<tr><td rowspan="1" align="center">样例输出</td><td align="center">output</td><td align="center">[512]</td><td align="center">float</td><td align="center">ND</td></tr>
<tr><td rowspan="1" align="center">核函数名</td><td colspan="5" align="center">pipe_barrier_custom</td></tr>
</table>

**输出数据布局说明：**
- output[0:256]：Add结果 dst = src0 + src1
- output[256:512]：Mul结果 dst2 = dst * src0 = (src0 + src1) * src0

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
  mkdir -p build && cd build;      # 创建并进入build目录
  cmake .. -DCMAKE_ASC_ARCHITECTURES=dav-2201;make -j;    # 编译工程
  python3 ../scripts/gen_data.py   # 生成测试输入数据
  ./demo                           # 执行编译生成的可执行程序，执行样例
  python3 ../scripts/verify_result.py output/output.bin output/golden.bin  # 验证输出结果是否正确
  ```

  使用CPU调试或NPU仿真模式时，添加 `-DCMAKE_ASC_RUN_MODE=cpu` 或 `-DCMAKE_ASC_RUN_MODE=sim` 参数即可。
  
  示例如下：
  ```bash
  cmake .. -DCMAKE_ASC_RUN_MODE=cpu -DCMAKE_ASC_ARCHITECTURES=dav-2201;make -j; # CPU调试模式
  cmake .. -DCMAKE_ASC_RUN_MODE=sim -DCMAKE_ASC_ARCHITECTURES=dav-2201;make -j; # NPU仿真模式
  ```
  > **注意：** 切换编译模式前需清理 cmake 缓存，可在 build 目录下执行 `rm CMakeCache.txt` 后重新 cmake。

- 编译选项说明

  | 选项 | 可选值 | 说明 |
  |------|--------|------|
  | `CMAKE_ASC_RUN_MODE` | `npu`（默认）、`cpu`、`sim` | 运行模式：NPU 运行、CPU调试、NPU仿真 |
  | `CMAKE_ASC_ARCHITECTURES` | `dav-2201`（默认）、`dav-3510` | NPU 架构：dav-2201 对应 Atlas A2/A3 系列、dav-3510 对应 Ascend 950PR/Ascend 950DT |

- 执行结果

  执行结果如下，说明精度对比成功。
  ```bash
  test pass!
  ```
