// 执行实际预览脚本，验证只读属性与正文编辑区域的分离及刷新。
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const source = fs.readFileSync(path.join(__dirname,
  '../Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift'), 'utf8');
function section(start, end) {
  const first = source.indexOf(start);
  const last = source.indexOf(end, first);
  assert.ok(first >= 0 && last > first);
  return source.slice(first, last);
}
function preview() {
  // 最小 DOM 接口：模拟浏览器移动节点和设置 innerHTML，其余行为执行业务源码。
  const content = {
    properties: null,
    body: '<p data-source-offset="30">正文</p>',
    querySelector() { return this.properties; },
    get innerHTML() { return this.properties ? '<details></details>' + this.body : this.body; },
    set innerHTML(html) {
      this.properties = html.includes('<details') ? { open: false } : null;
      this.body = html.replace(/<details>.*?<\/details>/s, '');
    }
  };
  const container = {
    child: null,
    querySelector() { return this.child && this.child.open ? this.child : null; },
    replaceChildren() { this.child = null; },
    appendChild(node) { this.child = node; content.properties = null; }
  };
  const context = {
    content, document: { getElementById: () => container }, window: {},
    beginFollowingPosition() {}, clearTimeout() {}, ensureHeadingIDs() {}, renderMermaidDiagrams() {},
    suppressEmit: false, emitTimer: null, pendingPreviewEdit: { ranges: [] },
    previewEditInFlight: false, sourceRevision: 0
  };
  vm.createContext(context);
  vm.runInContext(section('function extractDocumentProperties()', 'let emitTimer = null;')
    + section('window.setBodyHTML = function', 'window.setSourceOffsets = function'), context);
  return { content, container, update: html => context.window.setBodyHTML(html, 1) };
}
test('属性节点移出可编辑区域，正文和定位锚点保留', () => {
  const view = preview();
  view.update('<details>属性</details>' + view.content.body);
  assert.ok(view.container.child);
  assert.equal(view.content.properties, null);
  assert.equal(view.content.innerHTML, '<p data-source-offset="30">正文</p>');
});
test('正文重绘后保持属性展开状态', () => {
  const view = preview();
  view.update('<details>属性</details>' + view.content.body);
  view.container.child.open = true;
  view.update('<details>更新属性</details><p>新正文</p>');
  assert.equal(view.container.child.open, true);
  assert.equal(view.content.innerHTML, '<p>新正文</p>');
});
test('删除属性但正文不变时，也清除旧属性展示', () => {
  const view = preview();
  view.update('<details>属性</details>' + view.content.body);
  const unchangedBody = view.content.innerHTML;
  view.update(unchangedBody);
  assert.equal(view.container.child, null);
  assert.equal(view.content.innerHTML, unchangedBody);
});
