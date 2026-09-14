---
name: interactive-html-diagrams
description: Use when creating HTML documents containing Mermaid diagrams (architecture/sequence/relationship/flowchart) that need zoom, pan/drag, or fullscreen interaction; or when Mermaid charts in an HTML doc are static, too small to read, or only showing the top-left corner of a large diagram.
---

# Interactive HTML Diagrams

## Overview

Mermaid 默认渲染成静态 SVG，不能缩放拖拽——大图（架构图/复杂时序图）看不清细节。本 skill 提供一套**自实现 pan/zoom** 方案，让 HTML 里的每个 Mermaid 图都支持滚轮缩放、拖拽平移、双击重置、全屏查看。

**核心原则：不依赖 svg-pan-zoom 等外部库**——只用 mermaid 一个 CDN，纯原生 JS + SVG `transform`，完全可控、加载稳。

## When to Use

- 新写含 Mermaid 图的 HTML 文档（架构图/时序图/关系图/流程图）
- 现有 HTML 的 Mermaid 图是静态的，用户要求加缩放/拖拽/全屏
- 大图只显示左上角（viewBox 远大于容器宽度）
- 团队要求统一 HTML 作图交互标准

**When NOT to use:**
- 纯 Markdown 文档（无 HTML/JS 运行环境）
- 图很小且不需要交互（简单 3 节点流程图）

## Quick Start

直接拷贝 `references/template.html` 的三部分到你的 HTML 文档：

1. **CSS**（图交互 + 全屏 modal 样式）→ 放入 `<style>` 块
2. **全屏 overlay HTML** → 放 `<body>` 末尾
3. **JS**（Mermaid 渲染 + pan/zoom + 全屏）→ 放 `<body>` 末尾

Mermaid 图照常用 `<div class="mermaid">graph TB ... </div>`，JS 自动扫描所有 `.mermaid` 容器初始化交互。

**完整模板见：** [references/template.html](references/template.html)

## Core Principles（5 条，照搬别改）

| # | 原则 | 为什么 |
|---|------|--------|
| 1 | 自实现 pan/zoom，不引 svg-pan-zoom 库 | 少一个 CDN = 少一个加载失败点；纯 JS transform 完全可控 |
| 2 | 用 mermaid 生成的 viewBox 设 SVG 像素尺寸 | mermaid 的 SVG 自带 viewBox，直接取后两段设 width/height；不自己算（getBBox 时机不对返回 null） |
| 3 | 初始自适应 fit | 大图 viewBox 可能 2000+px，容器仅 ~800px，scale=1 只看到左上角。初始 `fitScale=min(容器宽/vbW,容器高/vbH)` 自动缩小+居中 |
| 4 | 重置回到 fit 而非 scale=1 | 否则大图重置后又只露左上角。保存 fitState，重置/双击都回到 fitState |
| 5 | style 标签必须成对 | `<style>...</style>`，改样式后 `grep -n "<style>\|</style>"` 验证开=关 |

## Interaction Features

| 交互 | 方式 |
|------|------|
| 缩放 | 鼠标滚轮（以鼠标位置为原点，所指内容不动） |
| 平移 | 鼠标按住拖拽 |
| 重置 | 双击 / 点工具栏 ⟲ 按钮（回到 fit 全图） |
| 放大/缩小 | 工具栏 ＋/－ 按钮 |
| 全屏 | 工具栏 ⛶ 按钮（弹出 overlay，独立 pan/zoom，ESC 关闭） |

工具栏在每个图右上角，左下角有操作提示。

## Common Mistakes（5 个坑，详见 references/pits-and-fixes.md）

| 坑 | 现象 | 根因 | 解法 |
|----|------|------|------|
| svg-pan-zoom viewBox null | pan-zoom 初始化但缩放异常 | 库要求 SVG 有 viewBox，手动算返回 0 | 自实现，直接读 mermaid 的 viewBox |
| 大图 scale=1 只露左上角 | 架构图看不全 | viewBox 2458px > 容器 822px | 初始 fit 自适应缩小 |
| 重置回 scale=1 大图消失 | 重置后图又没了 | 重置写 scale=1，但初始是 0.33 | 保存 fitState，重置回 fit |
| style 标签不成对 | 页面其他样式全失效 | `</style>` 后裸 CSS 无 `<style>` 开标签 | 每块成对，grep 验证 |
| Mermaid 渲染时序 | pan/zoom 初始化时 SVG 没渲染 | startOnLoad 异步 | startOnLoad:false + await run + setTimeout 60ms |

## Verification（每次必跑）

1. `grep -n "<style>\|</style>"` — 开=关
2. 浏览器 console：`document.querySelectorAll('.mermaid svg').length` = 图数量
3. console：每个图 `viewBox` 非 null
4. console：每个图 `_pzState.scale` 非 1（大图 < 1，fit 生效）
5. 实测：滚轮缩放 + 拖拽 + 全屏 + ESC

## Deep Dive

- [references/template.html](references/template.html) — 完整可拷贝 HTML 模板（CSS+JS+骨架）
- [references/pits-and-fixes.md](references/pits-and-fixes.md) — 5 个坑的详细根因分析 + 验证清单

## Adaptation Notes

- **主题色**：模板用深色科技风（`--bg:#0a0e17` `--accent:#06b6d4`），改为你的项目配色即可
- **Mermaid 主题**：JS 里 `theme:'dark'` + themeVariables，浅色文档改 `theme:'base'` + 浅色变量
- **全屏标题**：取图的 `closest('.card')` 里的 h3/h2/h4，按你的 HTML 结构调整 `openFullscreen` 里的选择器
