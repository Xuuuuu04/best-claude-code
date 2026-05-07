---
name: remotion-development
description: >
  Remotion 开发协议。React 组件化视频生成的最佳实践：
  项目结构、动画原语、渲染管线、多平台导出和性能优化。
when_to_use: 多媒体内容生成师 在代码实现和渲染阶段预加载。
---

<skill name="remotion-development">

<overview>
Remotion 是用 React 写视频的框架。本 Skill 定义项目结构、组件模式、动画原语和渲染流程，
确保代码级视频生成可维护、可复用、可批量生产。
</overview>

<project_structure>
```
remotion-project/
├── src/
│   ├── index.tsx              # 入口，注册所有 Composition
│   ├── Root.tsx               # Composition 定义和 props 映射
│   ├── tokens/                # 品牌常量
│   │   ├── colors.ts
│   │   ├── typography.ts
│   │   ├── spacing.ts
│   │   ├── motion.ts
│   │   └── sizes.ts
│   ├── components/            # 可复用动画组件
│   │   ├── AnimatedText.tsx
│   │   ├── Reveal.tsx
│   │   ├── Slide.tsx
│   │   ├── Counter.tsx
│   │   ├── ProgressBar.tsx
│   │   ├── LogoReveal.tsx
│   │   ├── LowerThird.tsx
│   │   └── transitions/       # 转场组件
│   │       ├── Fade.tsx
│   │       ├── SlideTransition.tsx
│   │       ├── ZoomTransition.tsx
│   │       └── WipeTransition.tsx
│   ├── scenes/                # 场景组件（按 storyboard 编号）
│   │   ├── S01_Intro.tsx
│   │   ├── S02_Features.tsx
│   │   └── ...
│   ├── compositions/          # 完整视频 Composition
│   │   ├── ProductPromo.tsx
│   │   └── SocialCut.tsx
│   ├── hooks/                 # 动画逻辑 hooks
│   │   ├── useFadeIn.ts
│   │   ├── useSlideIn.ts
│   │   ├── useScale.ts
│   │   └── useStagger.ts
│   └── types.ts               # 共享类型
├── public/                    # 静态资源
│   ├── images/
│   ├── videos/
│   └── audio/
├── out/                       # 渲染输出（gitignored）
└── remotion.config.ts         # 配置
```
</project_structure>

<animation_primitives>
  <primitive name="interpolate">
    <description>线性/曲线插值，最基础的时间→值映射</description>
    <code language="tsx">
import { interpolate } from 'remotion';
const opacity = interpolate(frame, [0, 30], [0, 1], {
  extrapolateLeft: 'clamp',
  extrapolateRight: 'clamp',
});
    </code>
    <note>必须加 extrapolate clamp 防止越界</note>
  </primitive>

  <primitive name="spring">
    <description>物理弹簧动画，自然有弹性</description>
    <code language="tsx">
import { spring } from 'remotion';
const scale = spring({
  fps,
  frame,
  config: { damping: 10, mass: 0.5, stiffness: 100 },
});
    </code>
    <config>
      damping: 阻力（10-20 常用）
      mass: 质量（0.5-1 常用）
      stiffness: 刚度（100-200 常用）
    </config>
  </primitive>

  <primitive name="useCurrentFrame">
    <description>获取当前帧号，所有动画的时钟源</description>
    <code language="tsx">const frame = useCurrentFrame();</code>
    <rule>禁止用于条件渲染（如 if (frame > 100) return null），用 Sequence 替代</rule>
  </primitive>

  <primitive name="useVideoConfig">
    <description>获取 fps、width、height、durationInFrames</description>
    <code language="tsx">const { fps, width, height, durationInFrames } = useVideoConfig();</code>
  </primitive>

  <primitive name="Sequence">
    <description>时间线编排，每个 scene 是一个 Sequence</description>
    <code language="tsx">
<Sequence from={0} durationInFrames={90}>
  <IntroScene />
</Sequence>
<Sequence from={90} durationInFrames={150}>
  <FeatureScene />
</Sequence>
    </code>
    <note>from 和 durationInFrames 必须精确匹配 storyboard</note>
  </primitive>

  <primitive name="AbsoluteFill">
    <description>全屏定位容器，等同于 position:absolute; inset:0</description>
    <code language="tsx">
<AbsoluteFill style={{ backgroundColor: tokens.colors.bg }}>
  {children}
</AbsoluteFill>
    </code>
  </primitive>
</animation_primitives>

<composition_registration>
  <code language="tsx">
export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="ProductPromo"
        component={ProductPromo}
        durationInFrames={900}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={{ theme: 'dark' }}
      />
      <Composition
        id="ProductPromoVertical"
        component={ProductPromo}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1920}
        defaultProps={{ theme: 'dark', layout: 'vertical' }}
      />
    </>
  );
};
  </code>
  <rule>多平台变体通过不同 Composition + props 实现，不复制代码</rule>
</composition_registration>

<render_commands>
  <command name="本地渲染">
    npx remotion render src/index.tsx ProductPromo out/promo.mp4
  </command>
  <command name="指定编码器">
    npx remotion render src/index.tsx ProductPromo out/promo.mp4 --codec=h264
  </command>
  <command name="GIF 输出">
    npx remotion render src/index.tsx ProductPromo out/promo.gif --codec=gif
  </command>
  <command name="静态图序列">
    npx remotion render src/index.tsx ProductPromo out/frame-%04d.png --codec=png-sequence
  </command>
  <command name="单帧截图">
    npx remotion still src/index.tsx ProductPromo out/poster.png --frame=150
  </command>
  <command name="预览 Studio">
    npx remotion studio
  </command>
</render_commands>

<performance_rules>
  <rule>复杂动画拆分为独立组件，避免单次重渲染过多 DOM</rule>
  <rule>图片/视频用 &lt;Img&gt; 和 &lt;OffthreadVideo&gt;，不用原生 img/video</rule>
  <rule>OffthreadVideo 比 Video 快 2x（Rust 解码，保持文件句柄）</rule>
  <rule>使用 React.memo 包裹不随帧变化的组件</rule>
  <rule>避免在 render 中创建新对象/数组（用 useMemo）</rule>
  <rule>字体文件提前预加载，避免首帧闪烁</rule>
</performance_rules>

<common_pitfalls>
  <pitfall id="css-transition">CSS transition/animation 在服务端渲染时不确定，必须用 interpolate/spring</pitfall>
  <pitfall id="settimeout">setTimeout/setInterval/requestAnimationFrame 与帧渲染不同步</pitfall>
  <pitfall id="random">Math.random() 每帧结果不同 → 画面抖动。用 seed-random 或 remotion 的 random()</pitfall>
  <pitfall id="window">window/document 在服务端渲染时不存在，必须用延迟加载或条件判断</pitfall>
  <pitfall id="date">new Date() 每帧变化 → 不一致。用 frame 作为时间源</pitfall>
  <pitfall id="unmounted">组件在 Sequence 外（frame &lt; from）时仍被渲染但不显示，注意副作用</pitfall>
</common_pitfalls>

<responsive_patterns>
  <pattern name="props-driven layout">
    <description>通过 props.layout 切换横竖屏布局</description>
    <code language="tsx">
const isVertical = layout === 'vertical';
return (
  <div style={{
    flexDirection: isVertical ? 'column' : 'row',
    padding: isVertical ? tokens.spacing.mobile : tokens.spacing.desktop,
  }}>
    {children}
  </div>
);
    </code>
  </pattern>
  <pattern name="relative sizing">
    <description>使用百分比或 vmin/vmax 而非固定 px</description>
    <code language="tsx">
const fontSize = Math.min(width, height) * 0.05; // 5% of smaller dimension
    </code>
  </pattern>
</responsive_patterns>

<audio_handling>
  <component>&lt;Audio src={staticFile('audio/bg.mp3')} /&gt;</component>
  <note>staticFile() 将路径映射到 public/ 目录</note>
  <note>音量用 interpolate 控制：volume={interpolate(frame, [0, 30], [0, 1])}</note>
  <note>音频与画面不同步时，检查 fps 是否一致（素材 fps vs Composition fps）</note>
</audio_handling>

</skill>
