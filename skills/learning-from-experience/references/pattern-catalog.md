# Pattern Catalog

## Format
Each pattern contains:
- **ID**: P001, P002, ... (sequential)
- **Keywords**: comma-separated, for real-time matching
- **Product**: MEMORY.md section + label, or SKILL.md path
- **Frequency**: number of times triggered
- **Status**: observing / confirmed / pending
- **Last triggered**: YYYY-MM-DD

## Detected Patterns

<!-- New patterns are appended here by learning-from-experience skill -->
<!-- Format:
### P001: [Pattern Name]
- Keywords: [keywords]
- Product: [MEMORY.md section `[LFE-P001]` or `~/.claude/skills/<name>/SKILL.md`]
- Frequency: [N]
- Status: [observing | confirmed | pending]
- Last triggered: [date]
-->

### P001: Pattern-Catalog 三态生命周期
- Keywords: pattern catalog, observing, confirmed, pending, 频次追踪, 模式升级
- Product: pending → `~/.claude/skills/pattern-lifecycle/SKILL.md` 或 MEMORY.md `[LFE-P001]`
- Frequency: 1
- Status: pending
- Last triggered: 2026-05-15

### P002: 监控告警规则分析
- Keywords: monitoring, alarm, callback, rule, chain, diff, series, 同比, 环比, 告警回调
- Product: `~/.claude/skills/alarm-logic-analysis/SKILL.md`
- Frequency: 1
- Status: confirmed
- Last triggered: 2026-06-13
- NOTE: catalog 标 confirmed 但 SKILL.md 文件未落地（幽灵记录），2026-07-24 复核发现，待补建或改 observing

### P003: 告警回调缺失事故排查与报告
- Keywords: 回调缺失, callback, 未收到告警, mock 探针, 二分法, has_alarm, alarm_callback_log, series 高峰点数, 连续点数, R0, 根因报告, incident report
- Product: `<project>/.claude/skills/callback-incident-investigation/SKILL.md`（项目级，含 HTML 报告模板 templates/incident-report-template.html）
- Frequency: 1
- Status: confirmed
- Last triggered: 2026-07-24
- 关联：P002（告警判定算法）是本模式的领域知识来源；本模式关注"回调缺失排查+报告"，与 P002 正交

## Migration Rules
- When 3+ MEMORY.md rules under same topic → propose SKILL.md upgrade
- When SKILL.md contradicts MEMORY.md rule → ask user which to keep
- When pattern status is "pending" for 2+ sessions → remind user

### P004: 报告可信度审查（对抗审查+事实核查+渲染验证）
- Keywords: 审查报告, 确保结论可靠, 根因分析审查, 发布前检查, 对抗审查, 事实核查, 渲染验证, error 占位
- Product: `~/.kscc/skills/report-credibility-review/SKILL.md`
- Frequency: 1
- Status: confirmed
- Last triggered: 2026-09-17
- NOTE: 来源 marmot SLI 报告实战（subagent 审查抓出 4 个实质错误）；与 doubt-driven-development 边界已写入 SKILL.md

### P005: skill 安装副本与上游仓库失同步
- Keywords: skill 模板 bug, 复发, 上游仓库, awesome-skills, 同步, 手搓补丁
- Product: MEMORY.md `dblclick-contextmenu-bug`（marmot 项目记忆）
- Frequency: 2（2026-09 初次反馈 + 2026-09-16 复发）
- Status: confirmed
- Last triggered: 2026-09-17
- NOTE: 遇模板类 bug 先对比上游 git 仓库并整体同步安装副本；已同步 interactive-html-diagrams（上游含完整交互修复）

### P006: HTML 内嵌 Mermaid 渲染正确性（webfont 竞态致 foreignObject 裁字）
- Keywords: mermaid, foreignObject, 裁字, 标签缺字, webfont, 字体预热, fonts.load, 几何断言, CLIPPED, 渲染正确性, console 零报错
- Product: `~/.kscc/skills/interactive-html-diagrams/SKILL.md`（原则 6 + 坑表第 9 行 + 验收 REQUIRED 第 6 项）；template.html 内置 fontsReady 预热 + fixLabelOverflow；pits-and-fixes.md 坑 9 详述
- Frequency: 1
- Status: confirmed
- Last triggered: 2026-10-18
- NOTE: 真实事故——beidou-consumer-flow.html 按既有 7 项验收全过（SVG 数/viewBox/fit/console 无错）仍漏检 5 处永久裁字。两层教训：① skill 清单要按"坑族"补全（交互族之外还有渲染正确性族），不能只记当下疼的那条；② 验收断言必须区分"渲染了没有"与"渲染对了没有"，几何量测（scrollWidth ≤ FO width）是裁字唯一判据。修复范式：fonts.load 预热（根修）+ 渲染后 FO 扩容兜底，两层缺一不可
