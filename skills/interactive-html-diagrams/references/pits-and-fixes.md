# 5 个坑的详细根因 + 验证清单

## 坑1：svg-pan-zoom 外部库 viewBox 为 null

**现象**：用 svg-pan-zoom 库时，pan-zoom 实例虽初始化成功，但 SVG 缩放行为异常——图不动或乱跳。

**根因**：svg-pan-zoom 要求 SVG 有 viewBox 属性。但 Mermaid 渲染的 SVG 可能用 `width`/`height` 属性而非 viewBox。手动用 `getBBox()` / `getBoundingClientRect()` 算 viewBox 时，如果调用时机不对（SVG 还没完全布局），返回 0 或 null。

**验证（实测）**：
```js
// svg-pan-zoom 方案下
document.querySelector('.mermaid svg').getAttribute('viewBox')  // → null
// 即使手动 setAttribute，getBBox 返回 {width:0, height:0}
```

**解法**：自实现方案直接读 Mermaid 生成的 viewBox——它**一定有**（Mermaid v10 渲染后自带）。取 viewBox 的后两段设 SVG 的 width/height：
```js
var parts = vb.split(/\s+/);  // 如 "-8 -8 2458 1153"
var vbW = parseFloat(parts[2]); var vbH = parseFloat(parts[3]);
svg.style.width = vbW + 'px'; svg.style.height = vbH + 'px';
```

---

## 坑2：大图初始 scale=1 只露左上角

**现象**：架构图看不到，只显示左上角一小块。

**根因**：架构图 viewBox 可能 `2458×1333`，但容器宽度只有 ~822px。`scale=1` 时 SVG 2458px 塞进 822px 容器 + `overflow:hidden` = 只看到左上角。

**验证（实测）**：
```
图0 架构图: viewBox=-8 -8 2458 1333, SVG宽=2458px, 容器宽=822px, scale=1
→ visibleRatio = 2458/822 = 3.0（超出容器 3 倍，只看到 1/3 的左上角）
```

**解法**：初始自适应 fit：
```js
var fitScale = Math.min(container.clientWidth / vbW, container.clientHeight / vbH);
if (fitScale < 1) {
  state.scale = fitScale;          // 如 822/2458 = 0.33
  state.x = (container.clientWidth - vbW * fitScale) / 2;  // 居中
  state.y = 10;
}
```

fit 后 `visibleRatio = 1.0`，全图可见。

---

## 坑3：重置回到 scale=1 大图消失

**现象**：点重置按钮或双击后，大图又只露左上角。

**根因**：重置逻辑写 `state.scale = 1; state.x = 0; state.y = 0`，但初始 fit 后 scale 可能是 0.33（坑2 的解法）。重置回 1 = 回到"只露左上角"状态。

**解法**：保存初始 fit 状态，重置和双击都回到 fitState 而非 scale=1：
```js
var fitState = { scale: state.scale, x: state.x, y: state.y };  // 保存
// 重置
bReset.onclick = function() {
  state.scale = fitState.scale; state.x = fitState.x; state.y = fitState.y; apply();
};
// 双击
svg.addEventListener('dblclick', function() {
  state.scale = fitState.scale; state.x = fitState.x; state.y = fitState.y; apply();
});
```

---

## 坑4：style 标签不成对致整个页面样式失效

**现象**：图交互正常，但页面其他部分（深色背景、卡片、表格、步骤条）全失效——变成白底黑字无样式。

**根因**：插入图交互 CSS 时，第一个 `<style>` 块的 `</style>` 后面紧跟 `:root{...}` 主体样式，但**漏了 `<style>` 开标签**。裸 CSS 文本（`:root{`）被浏览器当 HTML 解析不了，整个主体样式块失效。

**复现**：
```html
<style>图交互CSS</style>      <!-- ✅ 成对 -->
:root{ --bg:#0a0e17; ... }     <!-- ❌ 裸CSS，没有 <style> 开标签 -->
...主体CSS...
</style>                       <!-- 多余的关闭 -->
```

**解法**：每个 style 块必须 `<style>...</style>` 成对。改样式后验证：
```bash
grep -n "<style>\|</style>" your.html
# 开标签数必须 = 关闭标签数
```

---

## 坑5：Mermaid 渲染时序

**现象**：`initPanZoom` 执行时 SVG 还没渲染——`container.querySelector('svg')` 返回 null，pan/zoom 没初始化。

**根因**：Mermaid 默认 `startOnLoad:true` 是异步渲染。如果 `initPanZoom` 在 `mermaid.run()` 完成前执行，SVG 还不存在。

**解法**：
```js
mermaid.initialize({ startOnLoad: false });  // 关闭自动加载
window.addEventListener('load', async function() {
  await mermaid.run();                        // 等渲染完成
  setTimeout(initPanZoom, 60);               // 再初始化交互（60ms 缓冲确保 DOM 更新）
});
```

---

## 验证清单（每次完成 HTML 后必跑）

### 1. style 标签成对（终端）
```bash
grep -n "<style>\|</style>" your.html
# 输出行数：开标签数 = 关闭标签数
```

### 2. SVG 全渲染（浏览器 console）
```js
document.querySelectorAll('.mermaid svg').length
// 应等于你的 .mermaid div 数量
```

### 3. viewBox 非 null（console）
```js
document.querySelectorAll('.mermaid svg').forEach(s => console.log(s.getAttribute('viewBox')))
// 每个都应有值，如 "-8 -8 2458 1153"
```

### 4. fit 生效——scale 非 1（console）
```js
document.querySelectorAll('.mermaid').forEach(c => console.log(c._pzState ? c._pzState.scale : 'no state'))
// 大图应 < 1（如 0.33），小图可能 = 1
```

### 5. 全图可见——visibleRatio ≈ 1.0（console）
```js
document.querySelectorAll('.mermaid').forEach(c => {
  var s = c.querySelector('svg');
  var r = s.getBoundingClientRect();
  console.log((r.width / c.clientWidth).toFixed(2));
})
// 每个 ≈ 1.00
```

### 6. 交互实测（手动）
- 鼠标在图上滚轮 → 图缩放（鼠标位置不动）
- 鼠标按住拖拽 → 图平移
- 双击 → 回到 fit 全图
- 点工具栏 ＋ → 放大
- 点工具栏 ⛶ → 全屏 → ESC 关闭
