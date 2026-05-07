
# 原子操作类api样例介绍

## 概述

本路径下包含了与原子操作相关的API样例。样例基于Ascend C的<<<>>>直调方法，支持main函数和kernel函数在同一个文件中实现。

## 样例列表

| 目录名称                                 |  功能描述                                           |
|--------------------------------------| ------------------------------------------------- |
| [set_atomic_add](./set_atomic_add) | 本样例基于SetAtomicAdd原子操作接口，介绍数据从VECOUT向GM搬运时，原子累加的实现流程。 |
| [set_atomic_deterministic_computation](./set_atomic_deterministic_computation) | 本样例首先介绍在数据搬运随路原子操作的场景下做确定性计算的必要性和具体实现方案，随后分别介绍在单个AIV核、多AIV核和多AIC核场景下如何运用上述方案。 |
