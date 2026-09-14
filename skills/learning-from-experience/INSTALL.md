# learning-from-experience 安装指南

## 概述

`learning-from-experience` 是一个 Claude Code skill，用于从日常对话中自动检测重复模式，并将经验转化为可复用产物（MEMORY.md 规则、SKILL.md 文件、脚本/MCP 提案）。

**适用场景**：所有使用 Claude Code 的开发者，尤其是经常重复操作的人群。

---

## 依赖分析

### 必需依赖（零）

**没有必需依赖。** 核心功能（模式检测、规则提取、catalog 追踪）只依赖 Claude Code 内置工具（Read、Edit、Write、AskUserQuestion），无需任何外部软件。

### 可选依赖

| 依赖 | 提供的能力 | 不安装的影响 | 安装方式 |
|------|-----------|-------------|---------|
| **episodic-memory** | 语义搜索历史对话，跨会话验证模式频次 | 无法自动验证历史出现次数，模式频次仅限当前会话 | `/plugin install episodic-memory@superpowers-marketplace` |
| **claude-mem** | 结构化记忆查询（observations、decisions） | 无法查询已有结构化记忆，可能产生重复规则 | `/plugin install claude-mem@<marketplace>` |
| **writing-skills** | 委托生成 SKILL.md（TDD 流程） | 无法生成正式 skill 文件，但 MEMORY.md 规则和脚本提案仍可正常工作 | `/plugin install superpowers@superpowers-marketplace` |

**结论**：即使全部可选依赖都不装，核心功能仍可正常使用。可选依赖仅增强体验。

---

## 安装方式

### 方式1：一键安装脚本（推荐）

```bash
# 从远程（需要先把 install.sh 放到可访问的位置）
curl -fsSL <URL>/install.sh | bash

# 或从本地（如果已经 clone 了仓库）
bash ~/.claude/skills/learning-from-experience/install.sh
```

脚本会自动：
1. 创建 `~/.claude/skills/learning-from-experience/` 目录
2. 写入 `SKILL.md` 和 `references/pattern-catalog.md`
3. 检测可选依赖并输出状态

### 方式2：手动安装

```bash
# 1. 创建目录
mkdir -p ~/.claude/skills/learning-from-experience/references

# 2. 复制文件（从仓库或同事处获取）
cp SKILL.md ~/.claude/skills/learning-from-experience/
cp references/pattern-catalog.md ~/.claude/skills/learning-from-experience/references/
```

### 方式3：作为插件分发（未来）

打包成 Claude Code 插件后，用户只需：
```
/plugin install learning-from-experience@<marketplace>
```

当前版本先以独立 skill 分发，验证价值后再插件化。

---

## 安装后验证

1. 启动新的 Claude Code 会话
2. 输入重复性请求（如连续两次 "帮我生成一个 UUID"）
3. 应该看到 agent 提示"检测到重复模式"

或直接测试触发：
```
learn from this
save this pattern
```

---

## 可选：配置会话结束自动归纳

如果希望在每次会话结束时自动触发经验提取，创建 hook 脚本：

```bash
mkdir -p ~/.claude/hooks
cat > ~/.claude/hooks/session-end << 'EOF'
#!/bin/bash
# 会话结束时提醒 learning-from-experience 归纳
# 注意：此 hook 仅为提醒，实际归纳仍需 Claude 在会话内执行
echo "[learning-from-experience] Session ending — consider running /learn"
EOF
chmod +x ~/.claude/hooks/session-end
```

> **注意**：Claude Code 的 session-end hook 执行时 Claude 已无法对话，所以这个 hook 仅作为提醒。真正的自动归纳需要等待 Claude Code 支持会话结束前的 agent 交互。

---

## 多人共享说明

### 共享什么

- **SKILL.md** — 可以共享，团队通用方法论
- **pattern-catalog.md** — **不建议共享**，每人经验不同

### 推荐分发结构

```
团队仓库/
  skills/
    learning-from-experience/
      SKILL.md                    # 共享
      install.sh                  # 共享
      references/
        pattern-catalog.template  # 共享（模板，不含个人数据）
```

`install.sh` 会从模板创建每个用户自己的 `pattern-catalog.md`。

### 不共享什么

- `~/.claude/skills/learning-from-experience/references/pattern-catalog.md` — 包含个人模式数据
- `MEMORY.md` 中的 `[LFE-Pxxx]` 规则 — 个人偏好

---

## 卸载

```bash
rm -rf ~/.claude/skills/learning-from-experience
```

如需清理 MEMORY.md 中的相关规则，搜索 `[LFE-` 标签并删除对应行。

---

## 常见问题

**Q: 安装后 skill 没有触发？**
A: 确保 SKILL.md 在 `~/.claude/skills/learning-from-experience/` 目录下（不是子目录）。重启 Claude Code 会话。

**Q: 没有安装 episodic-memory 会怎样？**
A: 核心功能正常。只是无法自动搜索历史对话验证频次，需要用户手动告知"这个操作我做过很多次了"。

**Q: 可以和团队成员共享 pattern catalog 吗？**
A: 不建议。每个人的重复模式不同，catalog 应保持独立。但 SKILL.md 文件本身可以共享。

**Q: 会自动写入 MEMORY.md 吗？**
A: 不会。每次写入前都会通过 AskUserQuestion 确认，用户有完全控制权。
