---
name: cinematography-language
description: >
  电影镜头语言知识库。定义运镜、构图、光影、节奏与情感映射，
  用于指导代码生成视频的视觉叙事质量。
when_to_use: 多媒体内容生成师 在分镜设计和动画实现阶段预加载。
paths: ["**/*.storyboard", "**/video/**", "**/animation/**"]
---

<skill name="cinematography-language">

<overview>
镜头语言是视觉叙事的基础。本 Skill 将电影工业的镜头语法翻译为代码可实现的参数，
让 Remotion 动画具备电影级的视觉表现力。
</overview>

<camera_movements>
  <movement name="Push In (推镜)" code="scale: 1→1.5, translateZ 或模拟">
    <emotion>聚焦、紧张、揭示</emotion>
    <use>强调关键信息、制造悬念</use>
    <ease>ease-in-out，前慢后快</ease>
  </movement>
  <movement name="Pull Out (拉镜)" code="scale: 1.5→1">
    <emotion>释怀、开阔、收尾</emotion>
    <use>展示全局、场景结束</use>
    <ease>ease-out</ease>
  </movement>
  <movement name="Pan (摇镜)" code="translateX: 0→±width">
    <emotion>探索、环顾、并列</emotion>
    <use>横向展示多个元素</use>
    <ease>linear 或 slight ease-in-out</ease>
  </movement>
  <movement name="Tilt (俯仰)" code="translateY: 0→±height">
    <emotion>敬畏、渺小、宏伟</emotion>
    <use>纵向空间展示</use>
  </movement>
  <movement name="Dolly Zoom (滑动变焦)" code="scale↑ + translateZ↓ 同时">
    <emotion>眩晕、冲击、不安</emotion>
    <use>强调心理变化</use>
    <note>Remotion 中通过同时调整 scale 和 position 模拟</note>
  </movement>
  <movement name="Tracking (跟拍)" code="主体 position 固定，背景 translateX">
    <emotion>陪伴、前进、旅程</emotion>
    <use>时间轴、流程展示</use>
  </movement>
  <movement name="Rack Focus (变焦)" code="blur 层切换">
    <emotion>转移注意力、对比</emotion>
    <use>前景/背景信息切换</use>
    <note>用 CSS filter: blur() + opacity 层叠实现</note>
  </movement>
</camera_movements>

<framing_rules>
  <rule id="headroom">上方留白 = 主体高度的 10%-15%</rule>
  <rule id="noseroom">运动方向前方留白 ≥ 运动方向后方</rule>
  <rule id="looking-space">人物/主体朝向侧需更多空间</rule>
  <rule id="rule-of-thirds">兴趣点放在三分线交点，避免居中（除非刻意）</rule>
  <rule id="leading-lines">用画面中的线条（文字行、图形边）引导视线</rule>
  <rule id="depth">通过 scale + opacity + blur 创造前中后景层次</rule>
</framing_rules>

<timing_rhythm>
  <concept name="节拍 (Beat)">视觉变化的节奏点，与音乐 BPM 或信息密度对应</concept>
  <concept name="停顿 (Pause)">信息密集段后的静止，让观众消化。0.5-1.5 秒</concept>
  <concept name="加速 (Acceleration)">信息高潮前的节奏加快，scene 时长缩短</concept>
  <concept name="减速 (Deceleration)">结尾或 CTA 前的节奏放缓，制造仪式感</concept>

  <formula>信息密度 = 屏幕元素数 / scene 时长(秒)</formula>
  <guideline>信息密度控制在 2-4 元素/秒，峰值不超过 6</guideline>
</timing_rhythm>

<color_mood_mapping>
  | 色调 | 情感 | 适用场景 |
  |:--|:--|:--|
  | 暖色（橙/红/金） | 热情、紧迫、喜庆 | 促销、节日、 food |
  | 冷色（蓝/青/紫） | 科技、冷静、专业 | SaaS、企业、AI |
  | 高对比（黑+亮色） | 高端、力量、时尚 | 奢侈品、发布会 |
  | 低饱和（灰+单强调色）| 沉稳、可信、极简 | 金融、咨询、B2B |
  | 渐变色 | 活力、年轻、创意 | 互联网、娱乐 |
  | 单色+纹理 | 质感、手工、人文 | 文创、非遗、教育 |
</color_mood_mapping>

<typography_in_motion>
  <principle>文字动画必须服务阅读，不能阻碍阅读</principle>
  <rule>标题进入动画 ≤ 0.8 秒，正文 ≤ 0.5 秒</rule>
  <rule>一行文字同时出现的字数 ≤ 15 个中文字符或 25 个英文字母</rule>
  <rule>字幕停留时间 ≥ 阅读时间 = 字数 × 0.25 秒（中文）/ 0.15 秒（英文）</rule>
  <rule>文字动画方向应与阅读方向一致（中文：左→右 或 下→上）</rule>
  <rule>避免文字在动画过程中产生模糊或变形</rule>

  <animation_patterns>
    <pattern name="Title Reveal">从下方滑入 + opacity，spring 弹性收尾</pattern>
    <pattern name="Typewriter">逐字显示，适合代码/技术内容</pattern>
    <pattern name="Word-by-Word">逐词淡入，适合 slogan</pattern>
    <pattern name="Line Reveal">逐行从遮罩中滑出，适合长文本</pattern>
    <pattern name="Scale Pop">scale 0→1 + 轻微 overshoot，适合数据/数字</pattern>
  </animation_patterns>
</typography_in_motion>

<depth_techniques>
  <technique name="视差 (Parallax)">
    <param>前景 speed=1.2, 中景 speed=1.0, 背景 speed=0.8</param>
    <use>横向滚动、页面切换</use>
  </technique>
  <technique name="景深 (Depth of Field)">
    <param>焦点层 sharp, 前后层 blur(2-8px) + opacity(0.6)</param>
    <use>聚焦主体、营造空间感</use>
  </technique>
  <technique name="阴影层次">
    <param>box-shadow: 0 {N}px {2N}px rgba(0,0,0,0.1)</param>
    <use>悬浮元素、卡片、按钮</use>
  </technique>
  <technique name="透视">
    <param>perspective + rotateX/Y 微角度</param>
    <use>3D 卡片翻转、空间展示</use>
  </technique>
</depth_techniques>

<common_mistakes>
  <mistake>同一方向运动连续超过 3 个 scene → 视觉疲劳</mistake>
  <mistake>所有元素同时动画 → 信息混乱，缺乏焦点</mistake>
  <mistake>文字过小（移动端 < 24px 等效）→ 无法阅读</mistake>
  <mistake>颜色对比度不足 → WCAG 失败，无法辨识</mistake>
  <mistake>动画过慢（>2s 进入）→ 拖慢节奏，流失注意力</mistake>
  <mistake>忽略安全区域 → 被平台 UI 遮挡（TikTok 底部 150px）</mistake>
</common_mistakes>

</skill>
