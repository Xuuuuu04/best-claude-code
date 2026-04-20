# 其他中国 AI 厂商 — 汇总

> last_updated: 2026-04-18
> 涵盖：腾讯 HunYuan / 智谱 GLM / 字节豆包 / 百度 ERNIE / 科大讯飞

---

## 1. 腾讯 HunYuan（[权威] HF `tencent/*`）

### 2026-Q1~Q2 新品

| 模型 | 发布 | 备注 |
|---|---|---|
| `tencent/HY-World-2.0` | 2026-04-10 | **3D 世界模型** — 重建/生成/模拟 3D 世界（HF papers 头条） |
| `tencent/DisCa` | 2026-04-09 | |
| `tencent/Unicom-Unified-Multimodal-Modeling-via-Compressed-Continuous-Semantic-Representations` | 2026-04-09 | 统一多模态压缩语义表示 |
| `tencent/Unified_Audio_Schema` | 2026-04-03 | 音频 schema |
| `tencent/HY-Embodied-0.5` | 2026-04-02 | 具身智能 |
| `tencent/Sequential-Hidden-Decoding-8B-n2/n4/n8` | 2026-03-10~31 | 序列隐式解码 |
| `tencent/HY-OmniWeaving` | 2026-03-31 | Omni 多模态 |
| `tencent/POINTS-Seeker` | 2026-03-24 | 视觉搜索 |
| `tencent/VersaViT` | 2026-03-20 | 通用 ViT |
| `tencent/Covo-Audio-Chat` | 2026-03-16 | 音频对话 |
| `tencent/HY-WU` | 2026-03-05 | |
| `tencent/Penguin-Encoder` | 2026-03-05 | |

**战略重心**：从文生图转向**多模态 + 具身 + 3D 世界模型** — 对标 Google Genie、NVIDIA Cosmos 系

---

## 2. 智谱 GLM（THUDM）

- HF author listing (`THUDM`) 返回空，[待验证] — 可能已迁仓
- 官网：`https://zhipuai.cn/` / `https://bigmodel.cn/`
- 官方 GLM 线历史：GLM-4 / GLM-4-Air / GLM-4-Flash / GLM-4-Plus / GLM-Z1（推理）/ GLM-4.5 / GLM-4.6
- **2026-04 当前主力（公开资料）**：GLM-4.6 / GLM-Z1-Plus
- 开放 API：`https://bigmodel.cn/dev/api`

## 3. 字节跳动 ByteDance（豆包 / Doubao）

HF `ByteDance/*` listing（[权威]）：

| 模型 | 发布 |
|---|---|
| `Dolphin-v2` | 2025-12-01 |
| `Sa2VA-Qwen3-VL-2B/4B` | 2025-11-27 / 10-21 | 基于 Qwen3-VL 的视觉 agent |
| `BindWeave` | 2025-11-04 |
| `Ouro-2.6B-Thinking` / `Ouro-2.6B` / `Ouro-1.4B` / `-Thinking` | 2025-10-28 | Thinking 系 |
| `Video-As-Prompt-Wan2.1-14B` / `CogVideoX-5B` | 2025-10-22 | 视频作为 prompt |
| `Sa2VA-Qwen2_5-VL-7B` / `-3B` / `InternVL3-14B/8B` | 2025-10-16 | 多 backbone Sa2VA |
| `Dolphin-1.5` | 2025-10-17 |

**豆包商业版**：火山引擎 `https://www.volcengine.com/` 提供 Doubao-1.5-pro / Doubao-seed 线 [待验证最新]

## 4. 百度 ERNIE

- ERNIE-Image（2026 开源文生图）[权威 GitHub]
- ERNIE 4.5 / ERNIE-X1 系列（文心）
- 千帆平台 `https://qianfan.cloud.baidu.com/`

## 5. 科大讯飞 星火

- 星火 X1 / 星火大模型 V4
- 开放平台 `https://xinghuo.xfyun.cn/`

## 6. 共同趋势

1. **多模态全面渗透**：文本 + 图像 + 视频 + 音频 + 3D 世界
2. **Agent / Thinking 并入**：每家都有 -Thinking / 推理变体
3. **小模型矩阵**：0.6B~4B 端侧模型密集发布
4. **视频生成**：Hailuo / Kling / Veo / Sora 全面竞争
5. **合规**：国内均完成大模型备案

## 7. 下轮研究

- [ ] GLM 最新模型（THUDM HF 空仓需换搜索路径）
- [ ] 豆包 / Doubao-seed 最新版本与定价
- [ ] 讯飞星火 V5 是否发布
- [ ] ERNIE 最新旗舰
- [ ] HY-World 2.0 是否能与 Genie-3 / Cosmos 对标
