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
