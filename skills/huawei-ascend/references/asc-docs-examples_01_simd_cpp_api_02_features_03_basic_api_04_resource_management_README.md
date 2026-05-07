# 资源管理类api样例介绍

## 概述

本路径下包含了与资源管理相关的多个API的样例。每个样例均基于Ascend C的<<<>>>直调方法，支持main函数和kernel函数在同一个cpp文件中实现。

## 样例列表

|  目录名称                                                  |  功能描述                                             |
| ----------------------------------------------------------- | --------------------------------------------------- |
| [tpipe_reuse](./tpipe_reuse) | 本样例基于TPipe::Init和TPipe::Destory，实现TPipe重复申请与使用。|
| [get_tpipe_ptr](./get_tpipe_ptr) | 样例基于GetTPipePtr获取全局TPipe指针，核函数无需显式传入TPipe指针，即可进行TPipe相关的操作。 |
| [tbufpool_management](./tbufpool_management) | 本样例基于TPipe::InitBufPool和TBufPool::InitBufPool接口实现TBufPool内存资源管理，展示TBufPool资源分配、内存划分、内存复用和自定义TBufPool等使用方式。|
| [list_tensor_desc_input](./list_tensor_desc_input) | 本样例基于静态Tensor编程模型实现AddN样例，采用ListTensorDesc结构处理动态输入参数，结合静态内存分配与事件同步机制实现数据搬运与计算任务的协同调度。 |
| [tmp_buffer](./tmp_buffer) | 本样例基于TPipe::InitBuffer接口初始化TBuf内存空间，并在计算过程中使用TBuf临时缓冲区进行数据转换，实现了bfloat16_t数据类型的向量加法（Add）样例。 |
| [static_tensor_programming](./static_tensor_programming) | 本样例介绍基于静态Tensor方式编程的场景下Add样例的实现方法，并提供核函数直调方法。|
| [get_ub_size](./get_ub_size) | 本样例展示GetUBSizeInBytes和GetRuntimeUBSize接口使用方法，用于获取用户最大可使用的UB（Unified Buffer）大小（单位为Byte）。|
