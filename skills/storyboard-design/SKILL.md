---
name: storyboard-design
description: >
  分镜设计协议。将创意 brief 转化为时间线级别的画面序列，
  定义每个 scene 的镜头、内容、动画和转场，作为代码实现的蓝图。
when_to_use: creative-media-producer 在阶段 2 预加载，也供视觉设计师参考动态内容结构。
---

<skill name="storyboard-design">

<overview>
分镜是代码生成视频的设计图纸。它把创意意图翻译为帧级别的指令，
让下游实现者（Remotion 代码）能精确复现导演的视觉构想。
</overview>

<scene_structure>
  <field name="scene_id" required="true">格式 S01、S02...，对应 Sequence 的 from 参数</field>
  <field name="title" required="true">一句话概括本 scene 功能</field>
  <field name="duration_frames" required="true">时长（帧数）。换算：秒 × fps</field>
  <field name="duration_seconds" required="true">时长（秒），便于人类阅读</field>
  <field name="time_range" required="true">时间轴位置：[起始帧, 结束帧]</field>

  <field name="shot_type" required="true">镜头类型（见下方镜头类型表）</field>
  <field name="composition" required="true">构图方式（见下方构图法则表）</field>
  <field name="key_message" required="true">本 scene 必须传达的核心信息，≤20 字</field>
  <field name="visual_elements" required="true">画面中所有视觉元素列表（文本、图形、图片、视频）</field>
  <field name="animation" required="true">动画手法：进入、强调、退出</field>
  <field name="transition_in" required="true">入转场（见转场表）</field>
  <field name="transition_out" required="true">出转场（见转场表）</field>
  <field name="audio_note" required="false">配音/音乐提示（节奏点、语气）</field>
  <field name="reference" required="false">参考画面描述或链接</field>
</scene_structure>

<shot_types>
  | 类型 | 描述 | 适用场景 |
  |:--|:--|:--|
  | 全景 (Wide/Establishing) | 展示环境/场景全貌 | 开场、地点切换 |
  | 中景 (Medium) | 人物腰部以上或主体大部分 | 产品介绍、对话 |
  | 特写 (Close-up) | 主体局部占满画面 | 强调细节、数据、情感 |
  | 极特写 (Extreme Close-up) | 单一元素（数字、图标） | 数据揭示、Logo |
  | 空镜 (Cutaway) | 与主体相关的环境/细节 | 过渡、节奏缓冲 |
  | 推镜 (Push-in) | 画面逐渐放大靠近主体 | 引导注意力、制造紧张 |
  | 拉镜 (Pull-out) | 画面逐渐后退展示更多 | 揭示全局、收尾 |
</shot_types>

<composition_rules>
  | 法则 | 说明 | 适用 |
  |:--|:--|:--|
  | 三分法 | 画面横竖各三分，主体放交点 | 通用 |
  | 中心对称 | 主体居中，左右平衡 | 正式、稳重 |
  | 引导线 | 用线条引导视线到主体 | 流程展示、时间轴 |
  | 留白 | 主体占 30%-50%，其余留白 | 高端、简洁 |
  | 层次叠加 | 前景+中景+背景三层 | 深度感、空间感 |
  | 对角线 | 主体沿对角线排列 | 动感、活力 |
</composition_rules>

<transition_types>
  | 转场 | 技术实现 | 情感效果 |
  |:--|:--|:--|
  | 硬切 (Cut) | 直接切换，无过渡 | 干脆、快速 |
  | 淡入淡出 (Fade) | opacity 0→1 或 1→0 | 柔和、抒情 |
  | 交叉溶解 (Cross-dissolve) | A.opacity↓ 同时 B.opacity↑ | 时间流逝、回忆 |
  | 滑动 (Slide) | translateX/Y 移入移出 | 信息推进、并列 |
  | 缩放 (Zoom) | scale 变化 | 强调、聚焦 |
  | 擦除 (Wipe) | clip-path 或 mask 展开 | 揭示、对比 |
  | 故障 (Glitch) | 色偏+位移+切片 | 科技、潮流 |
</transition_types>

<animation_primitives>
  <primitive name="Fade" params="[startOpacity, endOpacity], [startFrame, endFrame]">透明度变化</primitive>
  <primitive name="Slide" params="direction, distance, [startFrame, endFrame]">平移进入/退出</primitive>
  <primitive name="Scale" params="[startScale, endScale], [startFrame, endFrame]">缩放强调</primitive>
  <primitive name="Rotate" params="[startDeg, endDeg], [startFrame, endFrame]">旋转</primitive>
  <primitive name="Typewriter" params="text, speed">逐字显示</primitive>
  <primitive name="Stagger" params="children, delayFrames, animation">子元素依次动画</primitive>
  <primitive name="Parallax" params="speed, direction">视差滚动</primitive>
  <primitive name="Morph" params="fromShape, toShape, [startFrame, endFrame]">形状变换（SVG）</primitive>
</animation_primitives>

<rhythm_guidelines>
  <rule>开场 3 秒必须抓住注意力——动态强、信息密度高</rule>
  <rule>每 5-7 秒变换一次镜头类型或动画手法，防止视觉疲劳</rule>
  <rule>信息展示采用"总-分-总"节奏：先给结论，再给细节，最后重复结论</rule>
  <rule>CTA（行动号召）前留 0.5-1 秒停顿，制造期待</rule>
  <rule>结尾 Logo 停留 2-3 秒，确保品牌记忆</rule>
</rhythm_guidelines>

<storyboard_template>
```markdown
# Storyboard: {标题}

**Task ID**: {task-id}
**总时长**: {N} 秒 ({N×fps} 帧 @ {fps}fps)
**分辨率**: {width}×{height}
**平台**: {platform}

## 创意方向
{1-2 段描述}

## Scene 清单

### S01: {标题}
- **时长**: 3.0s (90f)
- **时间轴**: [0, 90]
- **镜头**: 极特写 → 推镜
- **构图**: 中心对称
- **核心信息**: {信息}
- **视觉元素**: Logo、品牌色背景
- **动画**: Logo scale 0→1 spring, 背景色渐变
- **入转场**: Fade from black
- **出转场**: Slide left
- **音频**: 轻快节奏起始

### S02: {标题}
...

## 时间轴总览
| Scene | 起始帧 | 结束帧 | 时长 | 转场 |
|:--|:--|:--|:--|:--|
| S01 | 0 | 90 | 3.0s | Fade in |
| S02 | 90 | 240 | 5.0s | Slide left |
...

## 风险与备选
- {风险描述}: {备选方案}
```
</storyboard_template>

<quality_checklist>
  <check id="duration-match">所有 scene 时长之和等于总时长</check>
  <check id="message-clear">每个 scene 有且只有一个核心信息</check>
  <check id="visual-variety">相邻 scene 镜头类型不同</check>
  <check id="transition-consistency">同类型转场不连续出现超过 2 次</check>
  <check id="readable-duration">文字 scene 停留时间 ≥ 字数 × 0.3 秒</check>
  <check id="brand-align">配色/字体与品牌调性一致</check>
</quality_checklist>

</skill>
