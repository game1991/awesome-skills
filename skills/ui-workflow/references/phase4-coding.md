# Phase 4 落码规范（使用前提：handoff.md 已获用户确认）

## handoff.md 契约 schema（Phase 3 收口时产出）

```markdown
# 落码契约（冻结，Phase 4 唯一实现依据）
## 页面：<名称>
- 路由：/xxx（组件路径 src/views/Xxx/index.vue，懒加载）
- 组件映射：筛选区→Form+Select / 表格→Table / 行删除→Popconfirm
  （写通用语义名，落码时映射到实际实现：默认原生 HTML/CSS，或项目选定的组件库）
- 数据源：GET /api/xxx（adapter: XxxService，映射见 api-contract.md）
- deviation（仅列与默认形态不同的点，未列出=按默认形态）：
  1. 表格密度 compact
  2. 主色 #2b6de8（项目主题变量覆盖实现，非组件级覆写）
- 未实现状态：仪表盘卡片级错误角标 → 按默认 Alert 处理
```

规则：deviation 必须穷举；契约没写的定制点落码时一律按默认形态，禁止自由发挥。

## 组件库策略（可插拔）

- **默认**：输出通用 HTML/原生实现（语义化标签 + 原生表单控件 + CSS），
  不依赖任何组件库，保证任何项目开箱即用。
- **可选适配层**：项目已选定组件库（Ant Design、Element Plus 等）时，把契约中的
  通用语义组件名（Form/Table/Modal…）映射到该库组件，先查该库官方文档确认 API 再生成。
- 组件映射只发生在"契约通用名 → 库组件"这一层，业务代码不直接散用库组件名，
  便于后续换库。

## 编排顺序

1. 查组件 API：默认实现查 MDN（原生控件能力）；使用组件库时查其官方文档
   （Properties/Events/Slots/Demos）。
2. 定页面骨架、间距、按钮位置、表格/表单布局（参照原型 token 与 pages-map.md 布局决策）。
3. 生成代码（顺序）：api-contract 的 TS 类型 → service 层 adapter → 组件 → 路由表。

## 优先级仲裁（冲突时以此为准）

```
handoff.md（用户冻结的定制）  >  pages-map.md（访谈决策）  >  通用默认值
```
- 骨架与间距以 pages-map.md 的布局决策 + 原型 token 为准；
- 视觉定制以 handoff.md 为准，实现方式优先用 CSS 变量覆盖（与原型 token 同源），
  不做组件级深度覆写。

## API adapter 规则

- mock-data.json 的形状 = adapter 的输出形状；真实响应形状 = adapter 的输入。
- service 层显式写字段映射（含枚举映射表），组件内禁止出现字段改名。
- 后端未就绪时：adapter 预留 `mock: true` 开关直接读 mock-data.json。

## 验收（两道，都要过）

1. **保真对比**：用 superpowers-chrome 分别打开原型与本地跑起的项目页面，
   同视口（1280×800）截图，逐页对比：布局结构 / 字段齐全 / 操作齐全 / 状态标签 / 文案。
   差异项分类：漏实现（修代码）｜故意 deviation（核对 handoff）｜默认形态差异（确认可接受）。
2. **可用性审查**：Skill 调用 `web-design-guidelines`，对照其清单过一遍。

## 收尾

- pages-map.md 头部改 `status: done`，原型目录 README 标注
  `archived: 代码为准，本目录不再维护`。
- 清理浏览器临时文件：`rm -f crg-*.png page-*.png && rm -rf .playwright-mcp`。
