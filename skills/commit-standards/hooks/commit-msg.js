#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const COMMIT_MSG_FILE = process.argv[2];

const ALLOWED_TYPES = [
  'feat',
  'fix',
  'refactor',
  'perf',
  'docs',
  'test',
  'build',
  'ci',
  'chore',
  'revert',
];

const INVALID_PATTERNS = [
  /^(update|fix stuff|misc|changes|wip|added|modified|fixed)$/i,
  /^[^a-z]/, // must start with lowercase
];

const EXEMPT_TYPES = ['merge', 'revert'];

function readCommitMessage() {
  return fs.readFileSync(COMMIT_MSG_FILE, 'utf8');
}

function parseCommitMessage(msg) {
  const lines = msg.trim().split('\n');
  const header = lines[0] || '';
  const match = header.match(/^(\w+)(?:\(([^)]+)\))?:\s*(.+)$/);
  
  if (!match) {
    return { valid: false, error: 'Invalid format. Use: type(scope): summary' };
  }
  
  const [, type, scope, summary] = match;
  
  if (!ALLOWED_TYPES.includes(type)) {
    return { valid: false, error: `Invalid type: ${type}. Allowed: ${ALLOWED_TYPES.join(', ')}` };
  }
  
  for (const pattern of INVALID_PATTERNS) {
    if (pattern.test(summary)) {
      return { valid: false, error: `Invalid summary: "${summary}". Use imperative mood, lowercase.` };
    }
  }
  
  if (summary.length > 72) {
    return { valid: false, error: `Summary too long (${summary.length}/72 chars)` };
  }
  
  const isExempt = EXEMPT_TYPES.some(t => 
    type.includes(t) || header.includes('fixup!') || header.includes('squash!')
  );
  
  const hasBody = lines.length > 1 && lines.slice(1).some(l => l.trim());
  
  if (!isExempt && !hasBody) {
    return { valid: false, error: 'Commit body required. Explain what, why, and impact.' };
  }
  
  return { valid: true, type, scope, summary };
}

function main() {
  const msg = readCommitMessage();
  const result = parseCommitMessage(msg);
  
  if (!result.valid) {
    console.error(`\n❌ Commit rejected: ${result.error}\n`);
    process.exit(1);
  }
  
  console.log(`\n✓ Commit validated: ${result.type}${result.scope ? `(${result.scope})` : ''}: ${result.summary}\n`);
  process.exit(0);
}

main();