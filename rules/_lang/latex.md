---
description: LaTeX 学术排版规范。编辑 .tex/.bib/.cls/.sty 文件时激活。
paths:
  - "**/*.tex"
  - "**/*.bib"
  - "**/*.cls"
  - "**/*.sty"
---

# LaTeX 排版规范

## 文档结构

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

## 图片
- 优先 PDF 矢量图：`\includegraphics[width=\linewidth]{fig.pdf}`
- 禁止硬编码路径
- 标题在图片下方：`\caption{}`
- 引用：`Figure~\ref{fig:xxx}` 或 `\cref{fig:xxx}`

## 表格
- 使用 booktabs，不显示竖线：
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

## 数学
- 行内：`$E = mc^2$`
- 独立公式（编号）：`\begin{equation} ... \end{equation}`
- 多行对齐：`\begin{align} ... \end{align}`
- 不使用 `$$...$$`（LaTeX 标准是 `\[...\]` 或 equation 环境）

## 引用
- natbib: `\citep{key}` (括号引用) `\citet{key}` (文本引用)
- 所有 `\cite` 必须在 .bib 中有对应条目
- 不伪造引用

## 交叉引用
- 标签：`\label{sec:xxx}` `\label{fig:xxx}` `\label{tab:xxx}` `\label{eq:xxx}`
- 引用：`\ref{sec:xxx}` (数字) `\cref{sec:xxx}` (含类型前缀)
- 编译两次以解析引用

## 常见错误
1. ❌ 特殊字符未转义：`&` `%` `$` `#` `_` `{` `}` `~` `^` `\` — 需加 `\`
2. ❌ 图片路径含空格
3. ❌ overfull/underfull hbox — 调整断词或重写
4. ❌ 引用 `??` — 需要多遍编译
5. ❌ 缺失 `\bibliographystyle` — bibtex 报错

## 编译
- pdflatex 链：`pdflatex → bibtex → pdflatex ×2`
- latexmk 自动：`latexmk -pdf main.tex`
- 检查 warning，不要只看编译成功
