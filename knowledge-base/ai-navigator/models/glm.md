# 智谱 GLM 模型知识库

> 状态：[部分] 核心事实已模式 A 验证（2026-04-18）
> 创建日期：2026-04-18
> 最后更新：2026-04-18

---

## 当前模型矩阵（2026-04）

数据源：[权威] GitHub 生态追踪 + HuggingFace Hub + 社区讨论（`TsingmaoAI/xw-cli` 等）

### GLM-5 系列（最新旗舰）

| 模型 | 状态 | 来源 |
|------|------|------|
| **GLM-5** | [待验证] 社区有 `GLM-5` 引用（`profbernardoj/morpheus-skill` 等），但本轮未抓到官方发布 | GitHub 生态 2026-04 |
| **GLM-4.7** | [待验证] 社区广泛使用（`TsingmaoAI/xw-cli` 支持一键部署） | GitHub 2026-04 |
| **GLM-4.7-Flash** | [待验证] 轻量版本，llama.cpp/vLLM 社区已有支持 | GitHub 2026-04 |

### GLM-4 系列（维护中）

| 模型 | 状态 |
|------|------|
| GLM-4 | [待验证] 2024 年发布的旗舰 |
| GLM-4-9B / GLM-4-9B-Chat | [待验证] 开源版本 |
| GLM-4V | [待验证] 视觉版本 |

### THUDM 开源项目

- [权威] `THUDM` GitHub org 是智谱官方开源账号
- [待验证] 本轮未直接抓到 THUDM 最新动态，通过社区引用推断 GLM-4.7/5 存在

## 生态部署

- [权威] `TsingmaoAI/xw-cli`：国产算力零门槛部署工具，支持 GLM-4.7、Qwen、MiniMax-2.1、DeepSeek-OCR 等
- [权威] `ndom91/GLM-4.7-Flash-Strix-Halo`：Strix Halo 设备上的 GLM-4.7 Flash 部署
- [权威] `ian-hailey/vllm-docker-GLM-4.7-Flash`：vLLM Docker 配置（含 glm4_moe_lite patch）
- [权威] `mitkox/SDFT`：以 GLM-4.7-Flash 为教师模型的蒸馏实验

## 关键推断

> [待验证] GLM-4.7 的命名暗示智谱采用小数点迭代（4→4.7），与 Kimi k1.5→k2.5、DeepSeek V3→V3.2 的命名策略类似
> [待验证] GLM-5 可能为下一代大版本，但官方发布信息需从智谱官网/微信公众号确认

## API 信息

- 官网：[待验证] https://www.zhipuai.cn 或类似
- API 平台：[待验证]
- 开源权重：[待验证] GLM-4.7/5 是否开源
- 定价：[待验证]

## 竞品对比（国产六小强）

| 厂商 | 最新旗舰 | 开源 | Agent 产品 |
|------|----------|------|------------|
| 阿里 Qwen | Qwen3.6-35B-A3B | [权威] 是 | qwen-code |
| DeepSeek | DeepSeek-V3 + R1 | [权威] 是 | [待验证] |
| 月之暗面 | Kimi K2.5 | [待验证] 否 | [待验证] |
| MiniMax | MiniMax-M2.7 | [待验证] | OpenRoom |
| 智谱 GLM | GLM-4.7/5 | [待验证] | [待验证] |
| 字节豆包 | [待验证] | [待验证] | Coze |

## 下一轮研究重点

- [ ] GLM-5 官方发布确认（官网/微信公众号/技术报告）
- [ ] GLM-4.7 完整技术规格
- [ ] 智谱 2026 年融资/估值动态
- [ ] GLM-4.7-Flash 与 Qwen3.6-35B-A3B 的同档对比

---

*2026-04-18 模式 A 验证：GLM-4.7 已在社区广泛部署，GLM-5 存在引用但需官方确认。智谱在国产开源生态中活跃度次于 Qwen/DeepSeek。*
