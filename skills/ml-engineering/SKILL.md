---
name: ml-engineering
description: 机器学习工程协议。为 ml-engineer 提供 baseline、评估、可复现性、失败分析和推理性能交付标准。
when_to_use: 仅当 ml-engineer Agent 在做训练 / fine-tune / 评估 / 推理服务部署（ONNX / vLLM / TensorRT）时加载。普通后端 / API 实现不应触发。
---

<skill name="ml-engineering">

<knowledge domain="pre-flight">
<principle>开始前必须回答四个前置问题</principle>
<checklist name="four-questions">
  <item>目标指标是什么</item>
  <item>数据怎么切分</item>
  <item>baseline 是什么</item>
  <item>推理约束是什么</item>
</checklist>
</knowledge>

<convention name="baseline-discipline">
先做简单基线，再提升复杂度。没有 baseline 的"更好模型"没有参照意义。
</convention>

<convention name="reproducibility">
<principle>可复现性四件套</principle>
<checklist>
  <item>seed</item>
  <item>config</item>
  <item>data version</item>
  <item>environment</item>
</checklist>
</convention>

<knowledge domain="evaluation">
<principle>评估必含五项</principle>
<checklist>
  <item>主指标</item>
  <item>置信区间或稳定性说明</item>
  <item>至少 20 个失败样本</item>
  <item>错误类型归类</item>
  <item>局限性</item>
</checklist>
</knowledge>

<knowledge domain="deployment">
<principle>部署必含四项</principle>
<checklist>
  <item>p50 / p99</item>
  <item>qps</item>
  <item>显存 / 内存</item>
  <item>硬件环境</item>
</checklist>
</knowledge>

</skill>
