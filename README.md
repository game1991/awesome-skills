# awesome-skills

A curated collection of **original, production-tested Agent Skills** for [Claude Code](https://claude.com/claude-code) (and compatible CLIs) — distilled from real-world engineering work: monitoring systems, UI delivery pipelines, incident postmortems, and daily agent collaboration.

> English docs · 中文说明见下方 [中文简介](#中文简介)

## Install

```bash
# In Claude Code / compatible CLI:
/plugin marketplace add game1991/awesome-skills
/plugin install touchstone@awesome-skills   # ...or any skill below
```

Skills are standard `SKILL.md` folders — you can also copy any `skills/<name>/` directory into your `~/.claude/skills/` manually.

## Skills

| Skill | What it does |
|---|---|
| [touchstone](skills/touchstone/) | **Flagship.** Project conclusion lifecycle as a five-state machine (`BETA → RC → GA → SUPERSEDED → EOL`). Conclusions are only promoted to "fact" with explicit user sign-off; overturned conclusions are never deleted — they get superseded links. Kills the "AI confidently cites an outdated conclusion" failure mode. |
| [ui-workflow](skills/ui-workflow/) | Five-stage UI delivery: layered interview → high-fidelity HTML prototype → confirm & iterate → production code, with a **pluggable component-library layer** (works with Ant Design, Element Plus, or plain HTML). |
| [director-mode](skills/director-mode/) | Director / lead-engineer collaboration mode: the human acts as chief architect, the agent as senior programmer — with a decision ledger, impact map, dual-channel reporting, gate nodes, and adversarial self-verification. |
| [learning-from-experience](skills/learning-from-experience/) | Routes "save this pattern" moments to the right artifact — SKILL.md upgrade, script/MCP proposal, or memory rule — without duplicating auto-memory. |
| [web-search-cn](skills/web-search-cn/) | Searches the Chinese web via a Baidu → Sogou fallback chain when built-in web search returns US-only results. |
| [interactive-html-diagrams](skills/interactive-html-diagrams/) | Makes every Mermaid diagram in an HTML document interactive — wheel zoom anchored at cursor, drag pan, double-click reset to fit, fullscreen overlay. Zero external libs: one Mermaid CDN + pure JS SVG `transform`. |
| [fix-plugin-scope](skills/fix-plugin-scope/) | Diagnoses and fixes "not cached at (not recorded)" plugin errors caused by wrong scope markers in `installed_plugins.json`. |

## Why touchstone?

Most agent workflows have no notion of a conclusion's **expiry**. A fact verified last month gets cited as truth this month. `touchstone` gives every repo a `TOUCHSTONE.md` where conclusions move through an explicit state machine — only user-confirmed, end-to-end-verified conclusions become citable facts, and overturned ones stay visible with bidirectional links instead of being silently deleted.

## Pairing well with

- [mattpocock/skills](https://github.com/mattpocock/skills) — excellent engineering workflow skills (grilling, TDD, to-spec…).
- [anthropics/skills](https://github.com/anthropics/skills) — official skills, including `mcp-builder`.
- [obra/superpowers](https://github.com/obra/superpowers) — process skills for brainstorming, debugging, and TDD.

## License

MIT — see [LICENSE](LICENSE).

---

## 中文简介

一套**原创**、经过真实工程打磨的 **Agent Skills** 合集,面向 [Claude Code](https://claude.com/claude-code) 及兼容 CLI——沉淀自监控系统、UI 交付流水线、故障复盘与日常 Agent 协作。

**安装**:

```bash
/plugin marketplace add game1991/awesome-skills
/plugin install touchstone@awesome-skills
```

**收录 7 个 skill**,亮点:

- **touchstone(旗舰)**:项目结论五态生命周期(`BETA → RC → GA → SUPERSEDED → EOL`)。结论只有经用户明示归档才能当事实引用;被推翻的结论不删除,而是双向链接标记 SUPERSEDED——消灭"AI 自信地引用过时结论"这一失败模式。
- **ui-workflow**:分层访谈 → 高保真 HTML 原型 → 确认迭代 → 落码,组件库可插拔(默认通用 HTML,可适配 Ant Design / Element Plus)。
- **director-mode**:指挥官-主程协作模式——决策台账、影响面地图、双通道汇报、门禁节点、对抗性自证。
- **learning-from-experience**:把"记一下这个模式"路由到正确的载体——SKILL.md 升级、脚本/MCP 提案或记忆规则,不与自动记忆重复。
- **web-search-cn**:内置搜索对中国内容覆盖差时,走百度→搜狗降级链搜中文互联网。
- **interactive-html-diagrams**:HTML 文档里每个 Mermaid 图支持滚轮缩放(以鼠标为锚点)、拖拽平移、双击重置、全屏——零外部库,单 Mermaid CDN + 纯 JS SVG `transform`,附踩坑集。
- **fix-plugin-scope**:修复 `installed_plugins.json` scope 标记错误导致的插件 "not cached" 报错。

全部原创,MIT 协议。推荐搭配 [mattpocock/skills](https://github.com/mattpocock/skills)、[anthropics/skills](https://github.com/anthropics/skills) 使用。
