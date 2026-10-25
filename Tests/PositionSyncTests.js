// 直接执行预览中的同步脚本，验证真实输入接管与被动跟随的边界。
// 运行：node --test Tests/PositionSyncTests.js
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

const source = fs.readFileSync(path.join(__dirname,
  '../Sources/Infrastructure/Rendering/MarkdownHTMLRenderer.swift'), 'utf8');

// 从业务源码提取原函数，避免测试维护另一份同步实现。
function section(start, end) {
  const first = source.indexOf(start);
  const last = source.indexOf(end, first);
  assert.ok(first >= 0 && last > first, `缺少脚本边界：${start}`);
  return source.slice(first, last);
}

function preview() {
  const frames = new Map();
  const listeners = new Map();
  const messages = [];
  let frameID = 0;
  const contentTarget = {};
  const context = {
    post: message => messages.push(message),
    requestAnimationFrame: callback => { frames.set(++frameID, callback); return frameID; },
    cancelAnimationFrame: id => frames.delete(id),
    document: {
      documentElement: { clientWidth: 800, clientHeight: 600 },
      addEventListener() {}
    },
    content: {
      contains: target => target === contentTarget,
      addEventListener() {},
      querySelectorAll: () => [0, 100, 200].map(offset => ({
        dataset: { sourceOffset: String(offset) },
        getBoundingClientRect: () => ({ top: offset + 20 - context.window.scrollY })
      }))
    },
    window: {
      scrollY: 0,
      addEventListener: (name, callback) => listeners.set(name, callback),
      scrollTo: ({ top }) => {
        context.window.scrollY = top;
        listeners.get('scroll')();
      }
    }
  };
  vm.createContext(context);
  vm.runInContext("const sourceAnchorSelector = '[data-source-offset]';\n"
    + section('let scrollAnchorFrame = null;', 'let pendingPreviewEdit =')
    + section('function sourceAnchors()', "content.addEventListener('input'")
    + section("window.addEventListener('scroll',", "content.addEventListener('paste',")
    + section('window.scrollToSourceOffset = function', 'window.setAccentColor = function'), context);

  return {
    messages,
    input(type, isTrusted = true, key) {
      context.inputEvent = { type, isTrusted, key, target: contentTarget };
      vm.runInContext('resumeUserPosition(inputEvent)', context);
    },
    select(offset) { vm.runInContext(`reportPosition(${offset})`, context); },
    follow(offset, token = '') { context.window.scrollToSourceOffset(offset, token); },
    scroll(offset) { context.window.scrollY = offset; listeners.get('scroll')(); },
    scrollbar() { listeners.get('pointerdown')({ isTrusted: true, type: 'pointerdown', clientX: 805, clientY: 20 }); },
    flush() {
      const callbacks = Array.from(frames.values());
      frames.clear();
      callbacks.forEach(callback => callback());
    },
    positions() { return messages.filter(message => message.type === 'positionChanged'); }
  };
}

test('被动跟随在后续帧和延迟滚动通知后仍保持静默', () => {
  const view = preview();
  view.follow(100);
  for (let frame = 0; frame < 20; frame++) {
    view.scroll(frame % 2 ? 0 : 200);
    view.flush();
  }
  assert.equal(view.messages.length, 0);
});

test('方向键只报告光标，自动滚动不覆盖光标位置', () => {
  const view = preview();
  view.input('keydown');
  view.select(100);
  view.scroll(200);
  view.flush();
  view.scroll(0);
  view.flush();
  assert.equal(view.positions().length, 1);
  assert.equal(view.positions()[0].sourceOffset, 100);
});

test('被动定位取消尚未发送的位置回报，新的滚轮输入可以接管', () => {
  const view = preview();
  view.input('keydown');
  view.select(100);
  view.follow(200);
  view.flush();
  assert.equal(view.positions().length, 0);
  view.input('wheel');
  view.scroll(100);
  view.flush();
  assert.equal(view.positions().length, 1);
  assert.equal(view.positions()[0].sourceOffset, 100);
});

test('合成输入不能接管，拖动滚动条可以接管', () => {
  const view = preview();
  view.follow(100);
  view.input('wheel', false);
  view.scroll(200);
  view.flush();
  assert.equal(view.messages.length, 0);
  view.scrollbar();
  view.scroll(200);
  view.flush();
  assert.equal(view.positions()[0].sourceOffset, 200);
});

test('方向键后同一帧按下修饰键，仍发送最后的光标位置', () => {
  const view = preview();
  view.input('keydown');
  view.select(100);
  view.input('keydown', true, 'Shift');
  view.flush();
  assert.equal(view.positions().length, 1);
  assert.equal(view.positions()[0].sourceOffset, 100);
});

test('同一帧的后续滚轮输入不丢弃尚未发送的视口位置', () => {
  const view = preview();
  view.input('wheel');
  view.scroll(200);
  view.input('wheel');
  view.flush();
  assert.equal(view.positions().length, 1);
  assert.equal(view.positions()[0].sourceOffset, 200);
});

test('滚轮后按修饰键，不切换模式或丢弃待发送的视口位置', () => {
  const view = preview();
  view.input('wheel');
  view.scroll(200);
  view.input('keydown', true, 'Shift');
  view.flush();
  assert.equal(view.positions().length, 1);
  assert.equal(view.positions()[0].sourceOffset, 200);
});

test('光标操作切换为滚轮时，由最新视口替代旧光标位置', () => {
  const view = preview();
  view.input('keydown');
  view.select(100);
  view.input('wheel');
  view.scroll(200);
  view.flush();
  assert.equal(view.positions().length, 1);
  assert.equal(view.positions()[0].sourceOffset, 200);
});

test('搜索前已发出的消息保留旧 token，后续输入携带新定位 token', () => {
  const view = preview();
  view.input('wheel');
  view.scroll(100);
  view.flush();
  const oldMessage = view.positions()[0];

  view.follow(200, 'search-1');
  view.scroll(0);
  view.flush();
  assert.equal(view.positions().length, 1);
  assert.equal(oldMessage.positionToken, '');

  view.input('keydown');
  view.select(200);
  view.flush();
  assert.equal(view.positions()[1].positionToken, 'search-1');

  view.follow(100, 'search-2');
  view.input('wheel');
  view.scroll(200);
  view.flush();
  assert.equal(view.positions()[2].positionToken, 'search-2');
  assert.equal(oldMessage.positionToken, '');
});
