// touchstone SessionStart hook — fail-open：任何异常静默退出(exit 0)，绝不阻塞会话启动
let raw = '';
process.stdin.on('data', c => raw += c);
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(raw || '{}');
    const cwd = input.cwd || process.cwd();
    const { execSync } = require('child_process');
    let root;
    try { root = execSync('git rev-parse --show-toplevel', { cwd, encoding: 'utf8', timeout: 3000, stdio: ['pipe', 'pipe', 'ignore'] }).trim(); }
    catch { process.exit(0); }
    const fs = require('fs');
    const f = root.replace(/\\/g, '/') + '/TOUCHSTONE.md';
    if (!fs.existsSync(f)) process.exit(0);
    const content = fs.readFileSync(f, 'utf8');
    if (content.includes('�')) process.exit(0); // 非 UTF-8 读取失败，跳过
    const lines = content.split('\n');
    const idx = lines.findIndex(l => l.includes('候选区'));
    const head = lines.slice(0, 30).join('\n');
    const cand = idx >= 0 ? lines.length - idx : 0;
    const out = `[touchstone] 本仓库结论基准索引区（前30行）。完整内容与写规则：读 ${f} 与 touchstone skill。候选区约 ${cand} 条待裁决${cand >= 10 ? '（已超上限，提醒用户批量裁决）' : ''}。\n` + head;
    process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: out.slice(0, 6000) } }));
  } catch { process.exit(0); }
});
