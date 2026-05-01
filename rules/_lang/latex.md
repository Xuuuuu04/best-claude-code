---
description: LaTeX 学术排版规范。编辑 .tex/.bib/.cls/.sty 文件时激活。
paths:
  - "**/*.tex"
  - "**/*.bib"
  - "**/*.cls"
  - "**/*.sty"
---

<rule>
  <!-- ====== 文档结构 ====== -->
  <pattern>

```latex
\documentclass[conference]{IEEEtran}  % 或 cvpr, neurips_20xx, acl, article, report, book
\usepackage[utf8]{inputenc}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{natbib}       % \citep{}, \citet{}
\usepackage{hyperref}     % 超链接
\usepackage{amsmath,amssymb}  % 数学
\usepackage{cleveref}     % \cref{} 智能引用

\title{...}
\author{...}
\begin{document}
\maketitle
...
\bibliographystyle{...}
\bibliography{references}
\end{document}
```

  </pattern>

  <!-- ====== 图片 ====== -->
  <convention>优先 PDF 矢量图：`\includegraphics[width=\linewidth]{fig.pdf}`</convention>
  <constraint severity="blocker">禁止硬编码路径</constraint>
  <convention>标题在图片下方：`\caption{}`</convention>
  <convention>引用：`Figure~\ref{fig:xxx}` 或 `\cref{fig:xxx}`</convention>

  <!-- ====== 表格 ====== -->
  <convention>使用 booktabs，不显示竖线：</convention>
  <pattern>

```latex
\begin{table}
\centering
\caption{结果对比}
\label{tab:results}
\begin{tabular}{@{}llcc@{}}
\toprule
& & 指标A & 指标B \\
\midrule
& 方法1 & 0.95 & 0.82 \\
& 方法2 & 0.97 & 0.85 \\
\bottomrule
\end{tabular}
\end{table}
```

  </pattern>

  <!-- ====== 数学 ====== -->
  <convention>行内：`$E = mc^2$`</convention>
  <convention>独立公式（编号）：`\begin{equation} ... \end{equation}`</convention>
  <convention>多行对齐：`\begin{align} ... \end{align}`</convention>
  <constraint severity="warning">不使用 `$$...$$`（LaTeX 标准是 `\[...\]` 或 equation 环境）</constraint>

  <!-- ====== 引用 ====== -->
  <convention>natbib: `\citep{key}` (括号引用) `\citet{key}` (文本引用)</convention>
  <constraint severity="blocker">所有 `\cite` 必须在 .bib 中有对应条目</constraint>
  <constraint severity="blocker">不伪造引用</constraint>

  <!-- ====== 交叉引用 ====== -->
  <convention>标签：`\label{sec:xxx}` `\label{fig:xxx}` `\label{tab:xxx}` `\label{eq:xxx}`</convention>
  <convention>引用：`\ref{sec:xxx}` (数字) `\cref{sec:xxx}` (含类型前缀)</convention>
  <convention>编译两次以解析引用</convention>

  <!-- ====== 常见错误 ====== -->
  <constraint severity="blocker">特殊字符未转义：`&` `%` `$` `#` `_` `{` `}` `~` `^` `\` — 需加 `\`</constraint>
  <constraint severity="blocker">图片路径含空格</constraint>
  <constraint severity="warning">overfull/underfull hbox — 调整断词或重写</constraint>
  <constraint severity="warning">引用 `??` — 需要多遍编译</constraint>
  <constraint severity="blocker">缺失 `\bibliographystyle` — bibtex 报错</constraint>

  <!-- ====== 编译 ====== -->
  <convention>pdflatex 链：`pdflatex → bibtex → pdflatex ×2`</convention>
  <convention>latexmk 自动：`latexmk -pdf main.tex`</convention>
  <constraint severity="warning">检查 warning，不要只看编译成功</constraint>

</rule>
