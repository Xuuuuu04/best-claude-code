# reg_sync样例

## 概述
本样例基于RegBase编程范式实现UB(Unified Buffer)读或写操作的同步机制，支持多种场景，通过环境变量选择场景。
    <table>
  	 	<tr>
 	 		<td>scenarioNum</td>
 	 		<td>同步场景</td>
 	 	</tr>
 	 	<tr>
 	 		<td>1</td>
 	 		<td>寄存器保序</td>
 	 	</tr>
 	 	<tr>
 	 		<td>2</td>
 	 		<td>LocalMemBar（写读依赖）</td>
 	 	</tr>
 	 </table>


## 支持的产品
- Ascend 950PR/Ascend 950DT

## 目录结构介绍
```
├── reg_sync
│   ├── scripts
│   │   ├── gen_data.py                // 输入数据和真值数据生成脚本
│   ├── CMakeLists.txt                 // 编译工程文件
│   ├── data_utils.h                   // 数据读入写出函数
│   ├── reg_sync.asc                   // AscendC算子实现 & 调用样例
│   └── README.md                      // 样例介绍
```

## 样例描述

### 场景1：寄存器保序

**样例功能**：对输入向量 x 进行原地 exp 计算，结果写回同一地址。

**样例规格**：
<table>
<tr><td rowspan="1" align="center">样例类型(OpType)</td><td colspan="3" align="center">AIV样例</td></tr>
<tr><td rowspan="2" align="center">样例输入</td><td align="center">name</td><td align="center">shape</td><td align="center">data type</td></tr>
<tr><td align="center">x</td><td align="center">[1, 1024]</td><td align="center">float</td></tr>
<tr><td rowspan="1" align="center">样例输出</td><td align="center">z</td><td align="center">[1, 1024]</td><td align="center">float</td></tr>
<tr><td rowspan="1" align="center">核函数名</td><td colspan="3" align="center">reg_sync</td></tr>
</table>

- 样例实现  
RegSyncVf函数内：
1. LoadAlign和StoreAlign操作同一地址
2. 读写入同一寄存器：读LoadAlign后写StoreAlign
3. 硬件自动保证StoreAlign等待LoadAlign完成，不用加LocalMemBar
- 调用实现  
  使用内核调用符`<<<>>>`调用核函数，启动1个核。

### 场景2：LocalMemBar（写读依赖）

**样例功能**：计算向量的绝对值之和：`sum = Σ|x[i]|`

**样例规格**：
<table>
<tr><td rowspan="1" align="center">样例类型(OpType)</td><td colspan="3" align="center">AIV样例</td></tr>
<tr><td rowspan="2" align="center">样例输入</td><td align="center">name</td><td align="center">shape</td><td align="center">data type</td></tr>
<tr><td align="center">x</td><td align="center">[1, 8]</td><td align="center">float</td></tr>
<tr><td rowspan="1" align="center">样例输出</td><td align="center">sum</td><td align="center">[1, 1]</td><td align="center">float</td></tr>
<tr><td rowspan="1" align="center">核函数名</td><td colspan="3" align="center">reg_sync</td></tr>
</table>

- 样例实现  
UbSyncVf函数内：
1. 从UB读取输入数据到RegTensor
2. 计算绝对值得到|x|
3. 将|x|写入UB的临时缓冲区
4. 调用LocalMemBar等待写入完成（读等写同步）
5. 从UB临时缓冲区读取|x|
6. 累加求和并输出结果
- 调用实现  
  使用内核调用符`<<<>>>`调用核函数，启动1个核。

**LocalMemBar必要性说明**：
步骤3将|x|写入UB，步骤5需从同一UB地址读取。存在读后写依赖（RAW），读操作必须等待写操作完成。若缺少LocalMemBar，步骤5可能读到未更新的旧数据。LocalMemBar确保UB写入完成后再执行读取操作。


## 编译运行
在本样例根目录下执行如下步骤，编译并执行算子。
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
  SCENARIO=1
  mkdir -p build && cd build;                                                   # 创建并进入build目录
  cmake -DCMAKE_ASC_ARCHITECTURES=dav-3510 -DSCENARIO_NUM=$SCENARIO ..;make -j; # 编译工程（默认npu模式）
  python3 ../scripts/gen_data.py -scenarioNum=$SCENARIO                         # 生成测试输入数据
  ./demo                                                                        # 执行编译生成的可执行程序，执行样例
  ```

  使用 CPU调试 或 NPU仿真 模式时，添加 `-DCMAKE_ASC_RUN_MODE=cpu` 或 `-DCMAKE_ASC_RUN_MODE=sim` 参数即可。

  示例如下：
  ```bash
  SCENARIO=1
  cmake -DCMAKE_ASC_RUN_MODE=cpu -DCMAKE_ASC_ARCHITECTURES=dav-3510 -DSCENARIO_NUM=$SCENARIO ..;make -j; # cpu调试模式
  cmake -DCMAKE_ASC_RUN_MODE=sim -DCMAKE_ASC_ARCHITECTURES=dav-3510 -DSCENARIO_NUM=$SCENARIO ..;make -j; # NPU仿真模式
  ```

  > **注意：** 切换编译模式或场景前需清理 cmake 缓存，可在 build 目录下执行 `rm CMakeCache.txt` 后重新 cmake。

- 编译选项说明

| 选项　　　　　 | 可选值　　　　　　　　　　　| 说明　　　　　　　　　　　　　　　　　　　　　　　|
| ----------------| -----------------------------| ---------------------------------------------------|
| `CMAKE_ASC_RUN_MODE` | `npu`（默认）、`cpu`、`sim` | 运行模式：NPU 运行、CPU调试、NPU仿真　　　　　　　|
| `CMAKE_ASC_ARCHITECTURES` | `dav-3510` | NPU 架构：dav-3510 对应 Ascend 950PR/Ascend 950DT |
| `SCENARIO_NUM` | `1`、`2`　　　　　　　　　　| 场景编号：1=寄存器保序，2=LocalMemBar　　　　　　　|

- 执行结果  
  执行结果如下，说明精度对比成功。
  ```bash
  test pass!
  ```
