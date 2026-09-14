# HTML 原型模板规范（Phase 2 使用）

## 交付形态（定死，不每次发明）

- **单文件** `ui-prototype/index.html`：所有页面用 hash 路由共存一个文件
  （`#/list`、`#/detail/:id`、`#/create`），左侧固定页面导航侧栏列出全部页面。
- **hash 路由实现**：`window.addEventListener('hashchange', render)` + 简单路由表，
  `#/detail/:id` 类参数路由用路径段解析。禁止引入任何构建工具/npm 依赖。
- 每页导航侧栏高亮当前页；列表页点行跳详情演示真实流转（携带 mock id）。

## 结构分层

```
<style>
  /* 1. :root 唯一 token 块 —— 全部视觉变量只写这里 */
  /* 2. 布局骨架 class（.sidebar/.main/.filter-bar/.table-area） */
  /* 3. 组件 class（.k-btn/.k-table/.k-tag/.k-modal/.k-form-item） */
</style>
<div id="app"></div>
<script>
  /* mock 数据：fetch('./mock-data.json') 或直接内联 —— 优先外置文件 */
  /* 路由表 + render 函数 + 各页面 renderXxx() */
</script>
```

## Token 规则

- `:root` 变量名采用通用 design token 命名（形如 `--color-primary`、`--color-success` 等），
  全文档命名风格保持一致，**禁止发明无规律变量名**。与落码目标库有出入的用注释标注 `/* 近似值 */`。
- token 覆盖：主色/成功/警告/危险、文字三级灰、边框色、圆角（默认 2px）、
  间距阶梯（4/8/12/16/24）、字号阶梯（12/14/16/20）、行高、阴影一层。
- 用户在 Phase 3 确认的任何非默认值（换主色、加大圆角）记入 pages-map.md 的 deviation 区。

## 组件形态基线（通用中后台视觉）

| 原型 class | 对应语义组件 | 关键视觉 |
|---|---|---|
| `.k-btn` | Button | 主按钮实底主色、次按钮描边、危险按钮红 |
| `.k-table` | Table | 表头灰底、行 hover、斑马纹关闭 |
| `.k-tag` | Tag | 状态标签圆角小标签 |
| `.k-modal` | Modal | 遮罩 + 居中白卡 + 右上关闭 |
| `.k-form-item` | FormItem | label 左对齐、required红星 |
| `.k-pagination` | Pagination | 右对齐、总数前置 |

## 状态矩阵（每页必须产出，四种页面类型通用 checklist）

| 状态 | 列表页 | 表单页 | 详情页 | 仪表盘 |
|---|---|---|---|---|
| loading | 表格骨架屏 | — | 骨架屏 | 卡片骨架屏 |
| empty | 空态插图+主操作 | — | 404 空态 | 卡片空值 `--` |
| error | 页面 Alert+重试 | 校验失败红字+定位 | 无权限页 | 卡片级错误角标 |
| 危险操作 | Popconfirm | 提交中按钮禁用防重 | — | — |

原型中：至少做一页含空态+错误态的可切换样例（导航侧栏底部加"状态演示"入口），
多角色页面顶部加角色切换器（admin/viewer），切换后操作列显隐跟随。

## mock-data.json 规范

- 结构来自 api-contract.md（同名同形，Phase 4 机械复用）。
- 列表返回 `{list: [...], total: N, page: 1, pageSize: 20}`。
- 每张表 mock ≥8 条含边界值：超长文本、空值、最小/最大时间、全部枚举值至少出现一次。
- 状态字段用枚举值而非魔法字符串。
