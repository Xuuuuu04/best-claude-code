# Cast样例

## 概述

本样例基于Cast实现源操作数和目的操作数Tensor的数据类型及精度转换。本样例实现half到int32_t、half到int4b_t两种场景下的转换。

## 支持的产品

- Ascend 950PR/Ascend 950DT
- Atlas A3 训练系列产品/Atlas A3 推理系列产品
- Atlas A2 训练系列产品/Atlas A2 推理系列产品

## 目录结构介绍

```plain
├── cast
│   ├── scripts
│   │   ├── gen_data.py         // 输入数据和真值数据生成脚本
│   │   └── verify_result.py    // 验证输出数据和真值数据是否一致的验证脚本
│   ├── CMakeLists.txt          // 编译工程文件
│   ├── data_utils.h            // 数据读入写出函数
│   └── cast.asc                // Ascend C样例实现 & 调用样例
```

## 样例描述

- 样例功能：  
  CastCustom样例根据源操作数和目的操作数Tensor的数据类型进行精度转换。
- 样例规格：  
  <table>
  <caption>表1：样例规格</caption>
  <tr><td rowspan="1" align="center">样例类型(OpType)</td><td colspan="4" align="center"> cast </td></tr>

  <tr><td rowspan="3" align="center">样例输入</td></tr>
  <tr><td align="center">name</td><td align="center">shape</td><td align="center">data type</td><td align="center">format</td></tr>
  <tr><td align="center">x</td><td align="center">[1, 512]</td><td align="center">half</td><td align="center">ND</td></tr>
  <tr><td rowspan="2" align="center">样例输出</td></tr>
  <tr><td align="center">y</td><td align="center">[1, 512]</td><td align="center">int32_t/int4b_t</td><td align="center">ND</td></tr>

  <tr><td rowspan="1" align="center">核函数名</td><td colspan="4" align="center">cast_custom</td></tr>
  </table>

- 场景说明：  
  <table>
  <caption>表2：SCENARIO参数说明</caption>
  <tr><td align="center">SCENARIO</td><td align="center">输入类型</td><td align="center">输出类型</td><td align="center">说明</td></tr>
  <tr><td align="center">0</td><td align="center">half</td><td align="center">int4b_t</td><td align="center">half转int4b_t</td></tr>
  <tr><td align="center">1</td><td align="center">half</td><td align="center">int32_t</td><td align="center">half转int32_t</td></tr>
  </table>

- 样例实现：  
  本样例中实现的是固定shape为输入x[1, 512]，输出y[1, 512]的CastCustom样例，支持half到int32_t和half到int4b_t两种转换场景。

  - Kernel实现

    计算逻辑是：Ascend C提供的矢量计算接口的操作元素都为LocalTensor，输入数据需要先搬运进片上存储，然后使用Cast基础API接口完成cast计算，得到最终结果，再搬出到外部存储上。对于int4b_t场景，由于int4b_t使用int8_t类型传递，需要进行ReinterpretCast类型转换。

  - 调用实现  
    使用内核调用符<<<>>>调用核函数，通过SCENARIO参数控制转换场景。

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
  SCENARIO=1
  mkdir -p build && cd build;      # 创建并进入build目录
  cmake -DSCENARIO=$SCENARIO -DCMAKE_ASC_ARCHITECTURES=dav-2201 ..;make -j;    # 编译工程，默认npu模式
  python3 ../scripts/gen_data.py --scenario $SCENARIO  # 生成测试输入数据
  ./demo                        # 执行编译生成的可执行程序，执行样例
  python3 ../scripts/verify_result.py output/output.bin output/golden.bin   # 验证输出结果是否正确，确认算法逻辑正确
  ```

  使用 CPU调试 或 NPU仿真 模式时，添加 `-DCMAKE_ASC_RUN_MODE=cpu` 或 `-DCMAKE_ASC_RUN_MODE=sim` 参数即可。
  
  示例如：

  ```bash
  cmake -DSCENARIO=$SCENARIO -DCMAKE_ASC_RUN_MODE=cpu -DCMAKE_ASC_ARCHITECTURES=dav-2201 ..;make -j; # cpu调试模式
  cmake -DSCENARIO=$SCENARIO -DCMAKE_ASC_RUN_MODE=sim -DCMAKE_ASC_ARCHITECTURES=dav-2201 ..;make -j; # NPU仿真模式
  ```

  > **注意：** 切换编译模式前需清理 cmake 缓存，可在 build 目录下执行 `rm CMakeCache.txt` 后重新 cmake。

- 编译选项说明

  | 选项 | 可选值 | 说明 |
  |------|--------|------|
  | `CMAKE_ASC_RUN_MODE` | `npu`（默认）、`cpu`、`sim` | 运行模式：NPU 运行、CPU调试、NPU仿真 |
  | `CMAKE_ASC_ARCHITECTURES` | `dav-2201`（默认）、`dav-3510` | NPU 架构：dav-2201 对应 Atlas A2/A3 系列，dav-3510 对应 Ascend 950PR/Ascend 950DT |
  | `SCENARIO` | `0`（默认）、`1` | 场景：0 对应half转int4b_t，1 对应half转int32_t |

- 执行结果

  执行结果如下，说明精度对比成功。

  ```bash
  test pass!
  ```
