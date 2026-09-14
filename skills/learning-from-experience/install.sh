#!/usr/bin/env bash
# ============================================================
# learning-from-experience — 一键安装脚本
# ============================================================
# 用法:
#   方式1: curl -fsSL <URL>/install.sh | bash
#   方式2: bash install.sh
#
# 功能:
#   - 创建 ~/.claude/skills/learning-from-experience/ 目录结构
#   - 写入 SKILL.md 和 pattern-catalog.md
#   - 检测 MCP 依赖（episodic-memory, claude-mem）
#   - 检测 Skill 依赖（writing-skills）
#   - 输出安装结果和后续步骤
# ============================================================

set -euo pipefail

# ── 颜色 ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$*"; }

# ── 目标路径 ──────────────────────────────────
SKILL_DIR="$HOME/.claude/skills/learning-from-experience"
REF_DIR="$SKILL_DIR/references"

# ── 步骤1: 创建目录 ──────────────────────────
info "Creating directory: $SKILL_DIR"
mkdir -p "$REF_DIR"
ok "Directory created"

# ── 步骤2: 写入 SKILL.md ─────────────────────
info "Writing SKILL.md"
cat > "$SKILL_DIR/SKILL.md" << 'SKILLEOF'
---
name: learning-from-experience
description: Use when user repeats similar requests or says "learn from this" / "save this pattern". Routes experience to SKILL.md, script/MCP proposals, or MEMORY.md rule upgrades. Does NOT duplicate Auto Memory — focuses on turning experience into reusable artifacts.
---

# Learning from Experience

**Core principle:** Auto Memory remembers. LFE upgrades — from experience to reusable artifact.

**NOT a replacement for Auto Memory.** Claude Code already auto-extracts feedback and preferences. LFE adds what Auto Memory cannot: **artifact generation** (SKILL.md, scripts, MCP proposals) and **explicit pattern promotion** (rule -> skill upgrade).

**REQUIRED:** Understand superpowers:writing-skills before generating SKILL.md. This skill decides WHAT; writing-skills decides HOW.

## When to Use

**DO trigger when:**
- User repeats a request that matches a cataloged pattern
- User says "learn from this", "save this pattern", "make a skill for this"
- A MEMORY.md rule has been reinforced 3+ times -> propose SKILL.md upgrade

**DO NOT trigger for:**
- Single-session corrections (Auto Memory handles this)
- Simple preference recording (Auto Memory handles this)
- Session-end summarization (AutoDream handles this)

## Quick Reference — Artifact Routing

| Condition | Artifact | Action |
|-----------|----------|--------|
| 3+ MEMORY.md rules on same topic | SKILL.md | Delegate to writing-skills |
| General methodology (>=3 steps) | SKILL.md | Delegate to writing-skills |
| Repeated automatable operation | Script/MCP proposal | Provide spec, user decides |
| Simple rule needing explicit user control | MEMORY.md rule | Edit with `[LFE-Pxxx]` tag |

> Note: Most simple rules should be left to Auto Memory. Only write MEMORY.md rules manually when you need explicit `[LFE-Pxxx]` tags for future migration tracking.

## Core Pattern

### Step 1: Detect Pattern Match

1. Read `~/.claude/skills/learning-from-experience/references/pattern-catalog.md`
2. Match user request keywords against catalog entries
3. **Hit found** -> AskUserQuestion: "Detected [Pxxx] pattern. Reuse / New / Improve?"
4. **No hit** -> Only proceed if user explicitly triggers ("learn from this")

**Always check catalog first.** No shortcuts.

### Step 2: Route to Artifact

Based on Quick Reference table:
- **SKILL.md** -> Output delegation package (Step 3)
- **Script/MCP** -> Provide specification, AskUserQuestion to confirm
- **MEMORY.md rule** -> Edit with `[LFE-Pxxx]` tag, update catalog (rare — prefer Auto Memory)

### Step 3: Delegate to writing-skills

For SKILL.md artifacts, output this delegation package then invoke `superpowers:writing-skills`:

```markdown
## Delegation to writing-skills
- **Pattern name**: [skill-name-with-hyphens]
- **Trigger**: [Use when... description]
- **Core process**: [step summary]
- **Known test scenarios**: [pressure scenarios from experience]
- **Key constraints**: [boundary conditions from experience]
```

### Step 4: Update Catalog

Append or update pattern in `pattern-catalog.md`:
- New pattern: assign next Pxxx ID, status "observing" (frequency 1) or "confirmed" (frequency >=3)
- Existing pattern: increment frequency, update last-triggered date, change status if threshold met
- When 3+ rules under same topic -> mark for SKILL.md upgrade proposal

## What LFE Does NOT Do (Left to Built-in)

| Built-in handles | LFE does not |
|-----------------|-------------|
| Auto-extract feedback from corrections | Auto Memory |
| Auto-consolidate memories across sessions | AutoDream |
| Record simple user preferences | Auto Memory |
| Semantic search of past conversations | episodic-memory plugin |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing simple rules to MEMORY.md | Leave to Auto Memory — LFE only writes tagged rules for migration tracking |
| Creating SKILL.md directly | Delegate to writing-skills for TDD quality |
| Triggering on every session end | AutoDream handles consolidation — LFE only triggers on explicit pattern match |
| Skipping catalog check | Always scan catalog first — prevents duplicates |
| No user confirmation before creating | Always AskUserQuestion before any artifact |
SKILLEOF
ok "SKILL.md written ($SKILL_DIR/SKILL.md)"

# ── 步骤3: 写入 pattern-catalog.md ───────────
info "Writing pattern-catalog.md"
cat > "$REF_DIR/pattern-catalog.md" << 'CATALOGEOF'
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

## Migration Rules
- When 3+ MEMORY.md rules under same topic → propose SKILL.md upgrade
- When SKILL.md contradicts MEMORY.md rule → ask user which to keep
- When pattern status is "pending" for 2+ sessions → remind user
CATALOGEOF
ok "pattern-catalog.md written ($REF_DIR/pattern-catalog.md)"

# ── 步骤4: 检查 MCP 依赖 ─────────────────────
info "Checking optional MCP dependencies..."

MCP_OK=true

# 检查 episodic-memory
if command -v episodic-memory &>/dev/null; then
    ok "episodic-memory CLI found"
else
    warn "episodic-memory CLI not found — semantic search of past conversations will be skipped"
    warn "  Install: /plugin install episodic-memory@superpowers-marketplace"
    MCP_OK=false
fi

# 检查 claude-mem (通过 MCP 工具是否可用间接判断)
# claude-mem 是运行时 MCP 工具，安装脚本无法直接检测
warn "claude-mem availability can only be checked at runtime"
info "  If claude-mem MCP tools appear in your session, they will be used automatically"

# ── 步骤5: 检查 Skill 依赖 ───────────────────
info "Checking skill dependency: writing-skills"

if [ -f "$HOME/.claude/plugins/cache/superpowers-marketplace/superpowers/"*/skills/writing-skills/SKILL.md ] 2>/dev/null; then
    ok "writing-skills found (superpowers plugin)"
else
    warn "writing-skills not found — SKILL.md product generation will be unavailable"
    warn "  Install: /plugin install superpowers@superpowers-marketplace"
    warn "  (You can still use MEMORY.md rules and script proposals without it)"
fi

# ── 步骤6: 输出结果 ─────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
printf "${GREEN}learning-from-experience installed successfully!${NC}\n"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Installed files:"
echo "  $SKILL_DIR/SKILL.md"
echo "  $REF_DIR/pattern-catalog.md"
echo ""
echo "Optional dependencies status:"
if [ "$MCP_OK" = true ]; then
    printf "  ${GREEN}episodic-memory: available${NC}\n"
else
    printf "  ${YELLOW}episodic-memory: not found (see warnings above)${NC}\n"
fi
printf "  ${YELLOW}claude-mem: check at runtime${NC}\n"
if [ -f "$HOME/.claude/plugins/cache/superpowers-marketplace/superpowers/"*/skills/writing-skills/SKILL.md ] 2>/dev/null; then
    printf "  ${GREEN}writing-skills: available${NC}\n"
else
    printf "  ${YELLOW}writing-skills: not found${NC}\n"
fi
echo ""
echo "Quick start:"
echo "  1. Start a new Claude Code session"
echo "  2. The skill will activate automatically when you repeat requests"
echo "  3. Or trigger manually by saying: 'learn from this', 'save this pattern'"
echo ""
echo "Optional: Set up session-end hook for automatic extraction:"
echo "  echo '#!/bin/bash' > ~/.claude/hooks/session-end"
echo "  echo '# Trigger learning-from-experience at session end' >> ~/.claude/hooks/session-end"
echo "  chmod +x ~/.claude/hooks/session-end"
echo ""
