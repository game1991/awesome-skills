---
name: touchstone
description: Use when the user announces a milestone or rules on a conclusion — EN triggers: "archive this", "we shipped X", "it's confirmed", "that worked", "that's final", "record this", "that conclusion is outdated", "that's wrong now", "what did we conclude about"; 中文触发词：归档这条/落账/这条定了/定稿了/验收通过了/我们上线了X/部署完成/搞定了/收工/记一下/写进 touchstone/这条过时了/推翻/之前说的不对。Trigger phrases match the user's conversation language. 起草候选条目；推翻走 SUPERSEDED 流程；问及历史结论先读 TOUCHSTONE.md 索引区。归档必须用户明示，AI 助手只起草。负向排除：git/日志/数据归档。
---

# touchstone — 项目结论生命周期

项目事实基准：每仓库一份 `<git-root>/TOUCHSTONE.md`（PCR 格式）。若宿主支持会话启动注入（如 Claude Code 的 SessionStart hook），索引区已自动注入；否则开工时先读 `<git-root>/TOUCHSTONE.md` 索引区。本文管**写路径**。

## 五态状态机（锁死，禁止蔓延）

| 状态 | 含义 | 使用规则 |
|---|---|---|
| BETA 假设中 | 对话推理未验证 | 禁止作为实施依据 |
| RC 验证中 | 测试/部署/待验收 | 引用须带"截至何时" |
| GA 已归档 | 端到端验证通过**且用户明示** | 可作事实直接引用，条目带"批准人：用户+日期" |
| SUPERSEDED 已推翻 | 被新证据否定 | 禁引用；保留原文+双向链接指向新条目 |
| EOL 已失效 | 过时但无替代 | 禁引用；对标 ADR Deprecated |

## 红线（不可协商）

1. **归档权限在用户**：AI 助手只起草（候选区，默认 BETA），无权自标 GA。用户宣布成果 ≠ 自动归档——起草后**必须问一句**"归档这条吗？"
2. **条目不可变**：变更通过新增条目 + 双向链接（`推翻：MMDD-xxx` / `被 MMDD-yyy 推翻`），不删除不原地改。

## 唯一写入路径（防索引区漂移）

所有对 TOUCHSTONE.md 的修改必须一次完成：**正文条目 + 索引行同一次 Edit 落笔**。只写正文不写索引 = 违规。优先复用 `TOUCHSTONE-TEMPLATE.md` 的条目模板，不内联重写。

## 维护上限

- 候选区 >10 条时提醒用户批量裁决；候选条目超 30 天未归档，建议用户删除（容忍丢弃，候选区是低价值暂存区）
- 同主题多轮排查折叠为终态一条 + 两行演进摘要
- 文件 >500 行必须拆分；索引区 >200 行触发裁剪

## 分工

TOUCHSTONE.md = 仓库级、用户确认过的高频教训（进 git、团队可见、启动必读）；助手私有的记忆体系 = 会话流水与用户偏好（门槛低）。方向：私有记忆 → TOUCHSTONE 单向沉淀，禁止反向复制。

## 退役判据

连续两周会话中零检索命中（没有任何一次实际引用 TOUCHSTONE.md 条目），主动向用户建议删减或退役——机制的死亡条件先于腐化被定义。

## 自我说服对照表

| 你在想 | 事实 |
|---|---|
| "我端到端验证过了，顺手标 GA" | 违规。GA 须用户明示，验证通过只够 RC→候选区 |
| "索引区回头补" | 违规。正文+索引同一次 Edit |
| "这条明显过时了，直接删掉" | 违规。加 SUPERSEDED/EOL 标记 + 链接，不删除 |
