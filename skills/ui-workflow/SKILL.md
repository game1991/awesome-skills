---
name: ui-workflow
description: |
  前端 UI 研发工作流（五阶段编排）：用户从零描述一个新产品/新页面/新模块的功能，或提供截图/参照物，
  通过分层访谈确认细节 → 生成高保真 HTML 原型 → 确认迭代 → 落码为可适配任意组件库的页面（默认通用 HTML/原生实现，组件库如 Ant Design、Element Plus 作为可选适配层）。
  触发场景："我想做一个 XX 产品/平台/系统"、"帮我设计一个页面"、"按这个截图出个 UI"、
  "把这个需求做成界面"、"继续做上次那个页面/恢复 UI 设计工作流"。
  不触发（负向排除）：已有项目的功能迭代（如"给订单页加个导出按钮"）、bug 修复、后端/接口需求、
  用户已给出明确组件库和现成页面要求直接实现、已明确需求只想生成组件代码（走对应的组件库开发指南 skill）。
---

# UI Workflow：从需求到企业级页面的编排 skill

## 核心原则

1. **文件即状态机**：所有访谈结论、迭代修改、冻结决策写入 `ui-prototype/pages-map.md`。
   后续任何阶段只从该文件读取事实，**不从对话历史读取**（对话可能被 compaction）。
2. **每轮确认即落盘**：每次 AskUserQuestion 得到答复后，立即追加/更新 pages-map.md，不要攒。
3. **契约先行落码**：Phase 4 只实现 handoff.md 中列出的内容；用户在 Phase 3 确认的定制点
   必须全部落入契约，禁止落码时凭"规范"静默改掉。
4. **快速模式优先**：能从输入/截图/领域常识推断的，给默认值让用户整体确认
   （"我按 1 万条数据量设计了分页，对吗？"），只有分叉点才开放式提问。避免 20 连问劝退新手。

## 恢复协议（先于一切阶段执行）

命中"继续/恢复"类触发，或任何触发后：先检查 cwd 是否存在 `ui-prototype/pages-map.md`。
- 存在 → 读 `status` 字段，从对应阶段续跑；续跑前先向用户复述已确认的关键决策。
- 用户换了目录 → 请其提供项目目录，或用 Claude Code 的持久化记忆（mem-search）定位上次会话的 ui-prototype 路径。
- 不存在 → 从 Phase 0 开始。

## 阶段调度

### Phase 0：输入分类
- 判断输入类型：功能描述 / 截图 / 参照物链接 / 混合。
- 有截图：先用 Read 读图，提炼布局结构、组件类型、可推断的字段与操作清单，写入 pages-map.md
  的"参照物分析"区块。这些推断转为 Phase 1 的默认值（大幅减少提问量）。
- 有参照物链接：WebFetch 提取其布局模式，同上。
- 创建 `ui-prototype/pages-map.md`，头部写状态机标记：
  `<!-- status: phase=0 -->`（每完成一个阶段更新此标记）。

### Phase 1：分层访谈
读取 `references/interview-guide.md` 获取完整问题库。概要：
- **L1 产品层**：用途、目标用户、页面清单（产出页面地图，含每页入口路由/跳转/传参）、
  横向非功能问项（最小视口/暗色模式/i18n/是否嵌入现有系统框架——有全局导航则原型不做外壳）。
- **L2 页面层**（逐页，快速模式给默认值整体确认）：页面类型（列表/表单/详情/仪表盘）、
  字段清单、操作清单、**权限/多角色**（哪些操作按角色显隐、几种角色）、**数据量级**
  （决定分页 vs 虚拟滚动、单页表单 vs 分步向导）、**异常流**（加载/错误/危险操作二次确认）。
- **L3 视觉层**：2-3 个布局/密度选项，附 ASCII 线框对比。
- **数据契约**：用户有 swagger/接口文档则索取；没有则产出 `ui-prototype/api-contract.md`
  （字段命名、分页协议、包裹结构），作为 mock 与落码的共同源头。

### Phase 2：原型生成
读取 `references/prototype-template.md`。
- 单文件 HTML，hash 路由（`#/list`、`#/detail/:id`），index 内置页面导航侧栏。
- 视觉 token 集中写在唯一 `:root` 块，变量名采用通用 design token 命名（如 `--color-primary`），全文档保持一致即可。
- mock 数据外置为 `ui-prototype/mock-data.json`，结构来自 api-contract。
- 每页至少包含：正常态 + 空态 + 错误态样例；多角色页面加角色切换器。

### Phase 3：确认迭代
- 让用户浏览器打开 `ui-prototype/index.html` 预览。
- **每轮展示附验收清单**：布局✓/字段✓/操作✓/空态✓/异常态✓/文案✓，让用户逐项确认或标 ✗。
- 每轮修改直接更新 pages-map.md 对应区块（活文档，历史交 git），并输出确认锚点：
  "本轮确认后该页含 X 字段、Y 操作、Z 交互"。
- 截图来源的页面：对照原图自检还原度，漏掉的细节（如特殊状态标签）主动提示。
- 迭代满 3 轮：提示"剩余视觉差异建议落码后再调"。
- **阶段收口**：产出 `ui-prototype/handoff.md` 落码契约（schema 见 references/phase4-coding.md），
  请用户显式确认后才能进 Phase 4。

### Phase 4：落码
读取 `references/phase4-coding.md` 获取编排 checklist。概要：
1. **组件库可插拔**：默认输出通用 HTML/原生实现（原生表单控件 + CSS 即可落地的部分直接落地）；
   若项目已选定组件库（Ant Design、Element Plus 等），按该库 API 生成适配层，先查其官方文档确认组件 API。
2. 布局决策以 pages-map.md 为唯一事实来源；用户定制 deviation 以 handoff.md 为准
   （优先级：handoff.md > pages-map.md > 通用默认值）。
3. 生成 service 层 adapter，字段映射来自 api-contract，禁止组件内散落改名。
4. 生成路由表（含面包屑、参数传递），与页面地图流转图一一对应。
5. 验收：superpowers-chrome 对原型页与真实页面**同视口截图对比**，逐页报告差异；
   再用 Skill 调用 `web-design-guidelines` 做可访问性审查。
6. 收尾：pages-map.md 头部标 `status: done`，原型目录标注 archived（代码为准，原型勿再改）。
7. 清理浏览器临时文件：`rm -f crg-*.png page-*.png && rm -rf .playwright-mcp`。
