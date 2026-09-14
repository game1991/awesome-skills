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

**解法**：初始自适应 fit，水平垂直双向都按剩余空间居中：
```js
var fitScale = Math.min(container.clientWidth / vbW, container.clientHeight / vbH);
if (fitScale < 1) {
  state.scale = fitScale;          // 如 822/2458 = 0.33
  state.x = (container.clientWidth - vbW * fitScale) / 2;   // 水平居中
  state.y = (container.clientHeight - vbH * fitScale) / 2;  // 垂直居中
}
```

fit 后 `visibleRatio = 1.0`，全图可见。

> ⚠️ **坑6 提前预警**：`state.y` 不能写死成常量（如 `10`）——那样垂直方向永远偏上、不在画布正中。必须和 `state.x` 一样按剩余空间居中计算。详见坑6。

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

## 坑6：fit 居中只算水平、垂直写死常量致图偏上不在画布正中

**现象**：大图初始能看到全图，但整体偏上、不在画布正中；重置/双击后同样偏上。宽扁图（如关系图 viewBox 3056×626）尤其明显——水平被 fit 充满，垂直有大量留白却全堆在下方，图贴在顶部。

**根因**：fit 逻辑里水平方向按剩余空间居中计算，垂直方向却图省事写死成常量：
```js
state.x = (container.clientWidth - vbW * fitScale) / 2;  // ✅ 水平居中
state.y = 10;                                            // ❌ 写死，永远偏上
```
重置/双击保存的 `fitState` 复制了这个错误的 y，所以重置后同样偏上。`10` 大概率是当初为避开顶部工具栏随手给的偏移，没做对称计算。

**验证（实测）**：
```js
document.querySelectorAll('.mermaid').forEach(c => {
  var s = c._pzState;
  var r = c.getBoundingClientRect();
  var vbH = parseFloat(c.querySelector('svg').getAttribute('viewBox').split(/\s+/)[3]);
  console.log('y=' + s.y.toFixed(1),
    '期望y=' + ((r.height - vbH * s.scale) / 2).toFixed(1));
})
// y 若远小于期望y → 偏上；写死常量时 y 恒为 10 而期望y 可能是 100+
```

**解法**：垂直和水平对称，都按剩余空间居中：
```js
state.x = (container.clientWidth - vbW * fitScale) / 2;
state.y = (container.clientHeight - vbH * fitScale) / 2;
```
`fitScale = min(宽比, 高比)` 受哪个维度限制，该方向就被 fit 充满（余量≈0），另一个方向有余量做居中——这是正确行为，图始终在画布正中。

---

## 坑7：全屏模式没做 fit 居中，大图全屏后只露局部

**现象**：点全屏按钮后，大图在全屏 overlay 里要么只露左上角（scale=1）、要么拉伸变形（clone 宽高设 100%），双击重置也回不到正中。

**根因**：全屏 `openFullscreen` 复制 SVG 时没复用主图的 fit 逻辑，且有两处缺陷：
```js
clone.style.width = '100%'; clone.style.height = '100%';  // ❌ 拉伸变形
var fState = { scale: 1, x: 0, y: 0 };                    // ❌ 大图只露左上角
clone.ondblclick = function() { fState.scale = 1; ... };   // ❌ 重置回 0,0 非居中
```

**还有个隐蔽时序坑**：`overlay.classList.add('active')` 若在计算 `body.clientWidth` 之后执行，计算时 overlay 仍 `display:none`，`body.clientWidth=0` → `fFit=0` → `scale=0` 图消失。必须**先 add('active') 让 body 有真实尺寸，再算 fit**。

**解法**：全屏也做 fit + 双向居中，双击重置回到该 fit 状态，且先激活 overlay 再算尺寸：
```js
body.appendChild(clone);
overlay.classList.add('active');   // ← 先激活，body 才有 clientWidth
var p = (clone.getAttribute('viewBox') || '').split(/\s+/);
var fFit = 1, fCx = 0, fCy = 0;
if (p.length === 4) {
  var vbW = parseFloat(p[2]), vbH = parseFloat(p[3]);
  clone.style.width = vbW + 'px'; clone.style.height = vbH + 'px';
  clone.style.transformOrigin = '0 0';
  fFit = Math.min(body.clientWidth / vbW, body.clientHeight / vbH);
  if (fFit > 1) fFit = 1;
  fCx = (body.clientWidth - vbW * fFit) / 2;
  fCy = (body.clientHeight - vbH * fFit) / 2;
}
var fState = { scale: fFit, x: fCx, y: fCy };
// 双击重置回到 fit 居中
clone.ondblclick = function() { fState.scale = fFit; fState.x = fCx; fState.y = fCy; fApply(); };
```

**验证**：全屏后检查 `clone.style.transform` 的 scale 非 0、图位于 overlay 正中。

> **同源坑（坑8 的全屏版）**：全屏的 `body.onmousedown`/`clone.ondblclick` 若也不加 `preventDefault` + `altKey` 放行，全屏内双击同样会选词弹右键菜单、且无法 Alt 选中复制。修复时**主图与全屏必须对称**：`body.onmousedown` 加 `if(e.altKey) return; e.preventDefault();`，`clone.ondblclick` 同样；keydown/keyup 给 `fullscreen-body` 也加 `alt-select` class（CSS 要补 `.fullscreen-body.alt-select` 规则），`closeFullscreen`/`blur` 里清理该 class。详见坑8 解法。

---

## 坑8：双击重置绑在 svg 上，真实鼠标双击不触发

**现象**：左下角提示"双击重置"，但用真实鼠标在图上双击没反应——图不归位。程序化 `dispatchEvent(new MouseEvent('dblclick'))` 却能触发，让人误判监听没坏。

**根因**：双击监听绑在 `svg` 元素上：
```js
svg.addEventListener('dblclick', function() { ... });  // ❌ 绑 svg
```
但 Mermaid 渲染的 SVG 内部子节点（`<rect>`/`<text>`/`<path>`）才是双击命中的实际 `e.target`，而某些浏览器/渲染下 dblclick 冒泡到 svg 会被吞掉或时序错位。容器 `<div class="mermaid">` 是稳定的外层，事件必然冒泡到它，绑 container 最稳。

**还有一个并发坑**：拖拽 `mousedown` 无条件置 `dragging=true`，双击时两次 click 间手指微抖触发 `mousemove` → `apply()` 把刚重置的图又拖走，看起来"闪一下又没归位"。需加移动阈值区分"点击"和"拖拽"。

**还有第三个坑（右键菜单）**：`mousedown`/`dblclick` 没调 `e.preventDefault()`，浏览器执行默认行为——双击 SVG 内的文本/按钮文字时**选中文本**（实测 `selectionchange` 触发、选中了工具栏"＋"字），选中后浏览器/系统在选区上弹出右键菜单（复制/搜索），用户感觉"双击调出了右键菜单"。pan/zoom 必须拦掉这个默认行为。

**解法**：双击绑 container + 拖拽加 5px 移动阈值 + 两处 `preventDefault()`：
```js
// 拖拽带阈值：移动 < 5px 视为点击，不拖拽；preventDefault 阻止文本选择/原生拖放
var dragging = false, lastX = 0, lastY = 0, downX = 0, downY = 0, moved = false;
container.addEventListener('mousedown', function(e) {
  if (e.target.closest('.zoom-bar')) return;
  e.preventDefault();   // ← 阻止 mousedown 默认行为（选词/拖放起点）
  dragging = true; moved = false;
  lastX = downX = e.clientX; lastY = downY = e.clientY;
});
window.addEventListener('mousemove', function(e) {
  if (!dragging) return;
  if (Math.abs(e.clientX - downX) > 5 || Math.abs(e.clientY - downY) > 5) moved = true;
  state.x += e.clientX - lastX; state.y += e.clientY - lastY;
  lastX = e.clientX; lastY = e.clientY; apply();
});
window.addEventListener('mouseup', function() { dragging = false; });

// 双击绑 container（非 svg），冒泡捕获最稳；preventDefault 阻止双击选词
container.addEventListener('dblclick', function(e) {
  if (e.target.closest('.zoom-bar')) return;
  e.preventDefault();   // ← 阻止 dblclick 选词默认行为
  state.scale = fitState.scale; state.x = fitState.x; state.y = fitState.y; apply();
});
```

**验证（真实鼠标，非 dispatchEvent）**：放大偏离 fit 后真实双击 → 应回到 fit 居中，且 `window.getSelection().toString()` 为空（未选中文字）、无右键菜单弹出。用 `dispatchEvent` 测不出这些坑，必须真实双击。

### 配套：按住 Alt 选中复制节点文字

`preventDefault` 挡住了误选，但也挡死了"用户想复制节点文字"的正当需求。解决：按 Alt 时放行原生选词，其余时候照常拖拽。

```js
container.addEventListener('mousedown', function(e) {
  if (e.target.closest('.zoom-bar')) return;
  if (e.altKey) return;   // ← 按住 Alt：放行浏览器选词，不拖拽
  e.preventDefault();
  dragging = true; ...
});
container.addEventListener('dblclick', function(e) {
  if (e.target.closest('.zoom-bar')) return;
  if (e.altKey) return;   // ← 同理，Alt 时连双击也放行
  e.preventDefault();
  ...
});
```
配 CSS + keydown/keyup 切 `alt-select` class，按住时光标变 `text`、`user-select:text` 给视觉提示：
```css
.mermaid.alt-select, .mermaid.alt-select svg{cursor:text;user-select:text;-webkit-user-select:text}
```
```js
document.addEventListener('keydown', function(e){ if(e.key==='Alt') document.querySelectorAll('.mermaid').forEach(c=>c.classList.add('alt-select')); });
document.addEventListener('keyup', function(e){ if(e.key==='Alt') document.querySelectorAll('.mermaid').forEach(c=>c.classList.remove('alt-select')); });
window.addEventListener('blur', function(){ document.querySelectorAll('.mermaid').forEach(c=>c.classList.remove('alt-select')); });
```
提示条写明"按住 Alt 选中文字"。验证：按住 Alt 光标变 I、mousedown 后无平移（拖拽被跳过）；真实拖选产生选区后 Ctrl+C 可复制（需真实键鼠，`dispatchEvent` 合不出选区）。

> **全屏同理**：全屏 overlay 是独立的一套 pan/zoom（`body.onmousedown`/`clone.ondblclick`），上面三处修复（preventDefault、altKey 放行、alt-select 切光标）都必须对全屏再做一遍，否则全屏内双击仍弹右键菜单、无法 Alt 选中复制。坑7 已标注这个"主图与全屏对称"原则。

---

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

### 6. fit 居中——y 按剩余空间居中非写死常量（console）
```js
document.querySelectorAll('.mermaid').forEach(c => {
  var s = c._pzState;
  var r = c.getBoundingClientRect();
  var vb = c.querySelector('svg').getAttribute('viewBox').split(/\s+/);
  var vbW = parseFloat(vb[2]), vbH = parseFloat(vb[3]);
  console.log('scale=' + s.scale.toFixed(3),
    'x=' + s.x.toFixed(1) + '/' + ((r.width - vbW * s.scale) / 2).toFixed(1),
    'y=' + s.y.toFixed(1) + '/' + ((r.height - vbH * s.scale) / 2).toFixed(1));
})
// x/y 应分别等于期望值（剩余空间居中），而非写死常量如 10
```

### 7. 交互实测（手动，必须真实鼠标，dispatchEvent 测不出坑8）
- 鼠标在图上滚轮 → 图缩放（鼠标位置不动）
- 鼠标按住拖拽 → 图平移
- **放大偏离后，真实鼠标双击 → 回到 fit 全图且位于画布正中**（坑8 关键验收点）
- 点工具栏 ＋ → 放大
- 点工具栏 ⛶ → 全屏 → 图 fit 居中显示 → ESC 关闭
- 全屏内双击 → 回到 fit 居中（非左上角）
