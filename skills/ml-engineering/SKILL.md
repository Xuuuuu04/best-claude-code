---
name: ml-engineering
description: 机器学习工程协议。为 ml-engineer 提供 baseline、评估、可复现性、失败分析和推理性能交付标准。
when_to_use: 仅当 ml-engineer Agent 在做训练 / fine-tune / 评估 / 推理服务部署（ONNX / vLLM / TensorRT）时加载。普通后端 / API 实现不应触发。
---

# 机器学习工程协议

## 四个前置问题

- 目标指标是什么
- 数据怎么切分
- baseline 是什么
- 推理约束是什么

## Baseline 纪律

先做简单基线，再提升复杂度。没有 baseline 的“更好模型”没有参照意义。

## 可复现性四件套

- seed
- config
- data version
- environment

## 评估必含

- 主指标
- 置信区间或稳定性说明
- 至少 20 个失败样本
- 错误类型归类
- 局限性

## 部署必含

- p50 / p99
- qps
- 显存 / 内存
- 硬件环境
