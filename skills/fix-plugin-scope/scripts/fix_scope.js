#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

function getConfigPath() {
  return path.join(os.homedir(), '.claude', 'plugins', 'installed_plugins.json');
}

function main() {
  const filePath = getConfigPath();

  if (!fs.existsSync(filePath)) {
    console.log(`ERROR [FIX_PLUGIN_SCOPE]: File not found: ${filePath}`);
    console.log('HINT: Check if kscc is installed and has plugins configured.');
    process.exit(1);
  }

  let data;
  try {
    const raw = fs.readFileSync(filePath, 'utf-8');
    data = JSON.parse(raw);
  } catch (e) {
    console.log(`ERROR [FIX_PLUGIN_SCOPE]: Failed to parse JSON: ${filePath}`);
    console.log(`DETAIL: ${e.message}`);
    console.log('HINT: The file may be corrupted. Consider backing up and reinstalling plugins.');
    process.exit(1);
  }

  if (!data.plugins || typeof data.plugins !== 'object' || Array.isArray(data.plugins)) {
    console.log(`ERROR [FIX_PLUGIN_SCOPE]: Unexpected JSON structure in ${filePath}`);
    console.log('HINT: Expected a top-level "plugins" object. The file may be from an incompatible kscc version.');
    process.exit(1);
  }

  let fixed = 0;
  for (const [market, entries] of Object.entries(data.plugins)) {
    if (!Array.isArray(entries)) {
      console.log(`WARN [FIX_PLUGIN_SCOPE]: Skipping non-array entry '${market}'`);
      continue;
    }
    for (const entry of entries) {
      if (entry.scope === 'project') {
        entry.scope = 'user';
        delete entry.projectPath;
        fixed++;
      }
    }
  }

  if (fixed === 0) {
    console.log('OK [FIX_PLUGIN_SCOPE]: No project-scoped plugins found. Everything looks good!');
    process.exit(0);
  }

  const tmpPath = filePath + '.tmp';
  try {
    fs.writeFileSync(tmpPath, JSON.stringify(data, null, 2), 'utf-8');
    fs.renameSync(tmpPath, filePath);
  } catch (e) {
    console.log(`ERROR [FIX_PLUGIN_SCOPE]: Failed to write file: ${filePath}`);
    console.log(`DETAIL: ${e.message}`);
    console.log('HINT: kscc may be running and locking the file. Close kscc and retry.');
    try { fs.unlinkSync(tmpPath); } catch (_) {}
    process.exit(1);
  }

  try {
    const verify = fs.readFileSync(filePath, 'utf-8');
    JSON.parse(verify);
  } catch (e) {
    console.log(`ERROR [FIX_PLUGIN_SCOPE]: File verification failed after write: ${filePath}`);
    console.log(`DETAIL: ${e.message}`);
    console.log('HINT: The write may have been interrupted. Re-run this script.');
    process.exit(1);
  }

  console.log(`OK [FIX_PLUGIN_SCOPE]: Fixed ${fixed} plugin entries (project -> user scope)`);
  console.log('NEXT: Restart kscc session and run /plugins to verify the fix.');
  process.exit(0);
}

main();
