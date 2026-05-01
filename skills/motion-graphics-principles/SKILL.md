---
name: motion-graphics-principles
description: >
  动态图形（Motion Graphics）设计原则。定义排版动画、信息层级、
  品牌动效和数据可视化动画的行业标准，确保代码生成视频具有专业视觉品质。
when_to_use: creative-media-producer 在动画实现阶段预加载，校验动效质量。
---

<skill name="motion-graphics-principles">

<overview>
动态图形是信息+时间+运动的设计学科。本 Skill 将 After Effects/Motion Design 的行业标准
翻译为 Remotion 代码可实现的原则，确保宣传视频具有专业级视觉品质。
</overview>

<principles>
  <principle id="1" name="目的性 (Purpose)">
    每个动画必须有明确目的：引导注意力、解释关系、展示变化、制造情感。
    无目的的装饰性动画 = 噪音，应删除。
  </principle>
  <principle id="2" name="层级性 (Hierarchy)">
    运动应强化信息层级，而非破坏它。最重要的元素动得最显著，次要元素动得轻微。
  </principle>
  <principle id="3" name="一致性 (Consistency)">
    同类型元素的动画方式应统一。按钮总是从下往上淡入，标题总是从左滑入。
    一致性建立用户预期，降低认知负荷。
  </principle>
  <principle id="4" name="简洁性 (Economy)">
    用最少的动画传达最多的信息。一个精心设计的 motion 胜过三个杂乱的 effect。
  </principle>
  <principle id="5" name="节奏性 (Rhythm)">
    动画的 timing 应像音乐一样有节奏。快-慢-快、强-弱-强，形成可预测的韵律。
  </principle>
</principles>

<typography_motion>
  <rule>一次只动一个排版属性（位置、大小、透明度、颜色），组合不超过 2 个</rule>
  <rule>大标题进入用 0.5-0.8s，正文用 0.3-0.5s，注释用 0.2-0.3s</rule>
  <rule>文字移动速度：观众应能追踪，不能模糊成一条线</rule>
  <rule>避免文字在动画中换行或重排——预先计算好布局</rule>

  <pattern name="Hero Title">
    <steps>
      1. 初始状态：opacity 0, translateY 40px
      2. 延迟 10 帧后开始
      3. spring 动画：translateY→0, opacity→1
      4. 收尾有轻微 overshoot（弹性）
    </steps>
    <code language="tsx">
const frame = useCurrentFrame();
const { fps } = useVideoConfig();
const progress = spring({ fps, frame: frame - 10, config: { damping: 12 } });
const opacity = progress;
const translateY = interpolate(progress, [0, 1], [40, 0]);
    </code>
  </pattern>

  <pattern name="Bullet Reveal">
    <steps>
      1. 容器使用 stagger，每条间隔 8-12 帧
      2. 每条从左侧滑入 + 淡入
      3. 当前条完全静止后，下一条开始
    </steps>
  </pattern>

  <pattern name="Data Highlight">
    <steps>
      1. 数字从 0 计数到目标值
      2. 到达目标时 scale 1.1→1.0（弹跳强调）
      3. 单位/后缀延迟 5 帧后淡入
    </steps>
  </pattern>
</typography_motion>

<color_motion>
  <rule>颜色变化应平滑过渡，避免瞬间跳变（除非刻意制造 glitch 效果）</rule>
  <rule>品牌色变化使用 HSL 插值而非 RGB，避免灰暗中间色</rule>
  <rule>背景色变化配合前景元素同步，避免对比度突变</rule>

  <pattern name="Theme Transition">
    <description>暗色→亮色主题切换</description>
    <code language="tsx">
const bgColor = interpolateColors(
  frame,
  [themeChangeStart, themeChangeEnd],
  ['#0a0a0a', '#ffffff']
);
const textColor = interpolateColors(
  frame,
  [themeChangeStart, themeChangeEnd],
  ['#ffffff', '#1a1a1a']
);
    </code>
  </pattern>
</color_motion>

<shape_motion>
  <rule>图形变形优先使用 SVG path 动画（morph），避免切图</rule>
  <rule>圆角变化、尺寸变化使用 spring，比 linear 更自然</rule>
  <rule>线条绘制使用 stroke-dashoffset 动画（"画线"效果）</rule>

  <pattern name="Line Draw">
    <code language="tsx">
const pathLength = interpolate(frame, [start, end], [0, 1]);
// SVG: strokeDasharray={length} strokeDashoffset={length * (1 - pathLength)}
    </code>
  </pattern>

  <pattern name="Shape Morph">
    <note>使用 flubber 或 d3-interpolate 在 SVG paths 之间插值</note>
    <code language="tsx">
import { interpolate } from 'flubber';
const pathInterpolator = interpolate(pathA, pathB);
const d = pathInterpolator(progress);
    </code>
  </pattern>
</shape_motion>

<data_visualization_motion>
  <rule>图表动画应揭示数据故事，不只是让图表"活"起来</rule>
  <rule>按数据重要性顺序动画，最重要的数据最先/最显著出现</rule>
  <rule>坐标轴和网格先出现（建立参考系），数据后进入</rule>
  <rule>数据点进入后停留足够时间让观众读取数值</rule>

  <pattern name="Bar Chart Reveal">
    <steps>
      1. 坐标轴淡入（10 帧）
      2. 各 bar 从底部 grow 到目标高度（ stagger 5 帧）
      3. 数值 label 在 bar 到达高度后弹出
      4. 趋势线最后绘制（如果存在）
    </steps>
  </pattern>

  <pattern name="Pie Chart Reveal">
    <steps>
      1. 从 12 点钟方向顺时针展开
      2. 每段间隔 3-5 帧
      3. 段 label 在段完全展开后淡入
      4. 强调段（最大/最小）在全部展开后高亮（scale 1.05）
    </steps>
  </pattern>
</data_visualization_motion>

<brand_motion>
  <requirement>品牌动效应形成可识别的"签名"，观众看到动效能联想到品牌</requirement>
  <element name="Logo Animation">
    <rule>每次出现使用同一套动画（如：缩放+旋转+淡入）</rule>
    <rule>结尾 Logo 停留时间 ≥ 2 秒</rule>
    <rule>Logo 动画速度应稳重，不花哨</rule>
  </element>
  <element name="Color Usage">
    <rule>品牌主色使用面积 ≤ 30%，辅色 ≤ 50%，中性色 ≥ 20%</rule>
    <rule>强调色只用于 CTA 和关键数据点</rule>
  </element>
  <element name="Transition Signature">
    <rule>同系列视频使用一致的转场风格（如：全部用 wipe，或全部用 slide）</rule>
    <rule>转场时长统一（如：全部 15 帧 = 0.5s）</rule>
  </element>
</brand_motion>

<ease_reference>
  | 名称 | 曲线 | 用途 |
  |:--|:--|:--|
  | linear | 直线 | 匀速运动、进度条 |
  | ease | 慢-快-慢 | 通用进入/退出 |
  | ease-in | 慢-快 | 退出、消失 |
  | ease-out | 快-慢 | 进入、出现 |
  | ease-in-out | 慢-快-慢 | 强调、重要变化 |
  | spring | 物理弹性 | 活泼、现代、按钮 |
</ease_reference>

<quality_checklist>
  <check id="purpose">每个动画元素都有明确目的</check>
  <check id="readability">文字动画不阻碍阅读</check>
  <check id="contrast">所有文字与背景对比度 ≥ 4.5:1</check>
  <check id="timing">动画时长与信息重要性匹配</check>
  <check id="consistency">同类型元素动画方式一致</check>
  <check id="platform">安全区域未超出（移动端底部 150px）</check>
  <check id="brand">配色/字体与品牌指南一致</check>
  <check id="loop">首尾可无缝循环（如需）</check>
</quality_checklist>

</skill>
