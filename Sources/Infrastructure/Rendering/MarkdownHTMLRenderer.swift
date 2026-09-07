import Foundation

enum MarkdownHTMLRenderer {
    static func bodyHTML(from markdown: String) -> String {
        let rendered = renderBody(markdown)
        if rendered.html.isEmpty {
            return "<p data-source-offset=\"0\"><br></p>"
        }
        return rendered.html
    }

    static func sourceOffsets(from markdown: String) -> [Int] {
        renderBody(markdown).sourceOffsets
    }

    static func editableDocument(
        bodyHTML: String,
        turndownScript: String,
        accentColorCSS: String = "#0969DA",
        fontSize: Double = 14,
        backgroundColorCSS: String = "#FFFDF8",
        foregroundColorCSS: String = "#202522",
        colorSchemeCSS: String = "light"
    ) -> String {
        """
        <!DOCTYPE html>
        <html lang="zh-CN" data-color-scheme="\(colorSchemeCSS)">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <style>
            :root {
              color-scheme: \(colorSchemeCSS);
              --text: \(foregroundColorCSS);
              --bg: \(backgroundColorCSS);
              --muted: color-mix(in srgb, var(--text) 60%, var(--bg));
              --border: color-mix(in srgb, var(--text) 16%, var(--bg));
              --code-bg: color-mix(in srgb, var(--text) 6%, var(--bg));
              --quote-bg: color-mix(in srgb, var(--text) 4%, var(--bg));
              --quote-border: color-mix(in srgb, var(--link) 70%, var(--bg));
              --link: \(accentColorCSS);
              --focus: color-mix(in srgb, \(accentColorCSS) 20%, transparent);
              --font-size: \(fontSize)px;
              --preview-scale: 1.14;
              --line-height: 1.9;
              --content-inline-padding: 36px;
              --content-top-padding: 58px;
              --content-bottom-padding: 110px;
              --body-font: "Songti SC", STSong, "Times New Roman", serif;
              --heading-font: "Avenir Next", "PingFang SC", "Hiragino Sans GB", sans-serif;
              --code-font: "SFMono-Regular", "SF Mono", Menlo, Monaco, "PingFang SC", monospace;
            }
            html, body {
              margin: 0;
              padding: 0;
              background: var(--bg);
              color: var(--text);
              min-height: 100%;
            }
            body {
              font-family: var(--body-font);
              font-size: calc(var(--font-size) * var(--preview-scale));
              line-height: var(--line-height);
              letter-spacing: 0.005em;
            }
            #content {
              box-sizing: border-box;
              width: 100%;
              min-height: 100vh;
              padding: var(--content-top-padding) var(--content-inline-padding) var(--content-bottom-padding);
              outline: none;
            }
            #content:focus { box-shadow: inset 0 0 0 2px var(--focus); }
            h1, h2, h3, h4, h5, h6 {
              margin: 2em 0 0.72em;
              color: var(--text);
              font-family: var(--heading-font);
              font-weight: 650;
              letter-spacing: -0.035em;
              line-height: 1.28;
              scroll-margin-top: 20px;
            }
            h1 {
              margin-top: 0;
              font-size: 2.35em;
              line-height: 1.18;
            }
            h2 { font-size: 1.5em; }
            h3 { font-size: 1.25em; }
            p, ul, ol, pre, blockquote, table { margin: 0 0 1.35em; }
            a {
              color: var(--link);
              text-decoration-thickness: 1px;
              text-underline-offset: 4px;
            }
            code {
              border: 1px solid var(--border);
              font-family: var(--code-font);
              font-size: 0.84em;
              background: var(--code-bg);
              padding: 0.13em 0.38em;
              border-radius: 5px;
            }
            pre {
              border: 1px solid var(--border);
              border-radius: 11px;
              background: var(--code-bg);
              padding: 16px 18px;
              overflow: auto;
            }
            pre code {
              border: none;
              background: transparent;
              padding: 0;
              border-radius: 0;
              font-size: 0.86em;
            }
            .mermaid-diagram {
              position: relative;
              margin: 0 0 1em;
              padding: 10px 12px;
              overflow: hidden;
              border: 1px solid var(--border);
              border-radius: 10px;
              background: color-mix(in srgb, var(--code-bg) 45%, transparent);
            }
            .mermaid-diagram .mermaid {
              display: flex;
              justify-content: center;
              width: 100%;
            }
            .mermaid-diagram svg {
              display: block;
              width: 100%;
              max-width: 100% !important;
              height: auto;
            }
            .mermaid-large-button,
            .mermaid-lightbox-close {
              border: 1px solid var(--border);
              border-radius: 6px;
              background: color-mix(in srgb, var(--bg) 88%, transparent);
              color: var(--text);
              cursor: pointer;
              font: 500 0.72em var(--heading-font);
            }
            .mermaid-large-button {
              position: absolute;
              top: 8px;
              right: 8px;
              padding: 4px 8px;
              opacity: 0.82;
              transition: opacity 0.12s ease;
            }
            .mermaid-diagram:hover .mermaid-large-button,
            .mermaid-large-button:focus-visible {
              opacity: 1;
            }
            .mermaid-lightbox {
              position: fixed;
              inset: 0;
              z-index: 2147483647;
              display: none;
              flex-direction: column;
              background: color-mix(in srgb, var(--bg) 92%, black);
              color: var(--text);
            }
            .mermaid-lightbox.is-open {
              display: flex;
            }
            .mermaid-lightbox-toolbar {
              display: flex;
              justify-content: flex-end;
              padding: 10px 12px;
              border-bottom: 1px solid var(--border);
              background: var(--bg);
            }
            .mermaid-lightbox-close {
              padding: 6px 10px;
            }
            .mermaid-lightbox-viewport {
              flex: 1 1 auto;
              overflow: auto;
              padding: 24px;
            }
            .mermaid-lightbox-canvas {
              width: max-content;
              min-width: 100%;
              min-height: 100%;
              display: flex;
              align-items: flex-start;
              justify-content: center;
            }
            .mermaid-lightbox-canvas svg {
              display: block;
              width: auto;
              max-width: none !important;
              height: auto;
            }
            .mermaid-diagram.is-error pre {
              margin-bottom: 0.65em;
              border: 0;
              padding: 0;
              white-space: pre-wrap;
            }
            .mermaid-error-message {
              color: #cf222e;
              font-size: 0.85em;
              white-space: pre-wrap;
            }
            @media (prefers-color-scheme: dark) {
              .mermaid-error-message { color: #ff7b72; }
            }
            blockquote {
              margin: 1.8em 0;
              padding: 0.9em 1.25em;
              color: var(--muted);
              border-left: 3px solid var(--quote-border);
              border-radius: 0 9px 9px 0;
              background: var(--quote-bg);
            }
            hr {
              border: none;
              border-top: 1px solid var(--border);
              margin: 1.5em 0;
            }
            table {
              border-collapse: collapse;
              width: 100%;
              display: block;
              overflow: auto;
            }
            th, td {
              border: 1px solid var(--border);
              padding: 9px 13px;
            }
            th { background: var(--code-bg); }
            img { max-width: 100%; height: auto; border-radius: 6px; }
            #content a { cursor: text; }
            #content.is-link-open-mode a { cursor: pointer; }
            ul, ol { padding-left: 1.5em; }
            li { margin: 0.42em 0; }
            li > ul, li > ol { margin-bottom: 0; }
            li::marker { color: var(--link); }
            @media (max-width: 620px) {
              :root {
                --content-inline-padding: 22px;
                --content-top-padding: 38px;
                --content-bottom-padding: 72px;
              }
            }
          </style>
        </head>
        <body>
          <div id="content" contenteditable="true" spellcheck="true">\(bodyHTML)</div>
          <div id="mermaid-lightbox" class="mermaid-lightbox" role="dialog" aria-modal="true" aria-hidden="true" contenteditable="false">
            <div class="mermaid-lightbox-toolbar">
              <button id="mermaid-lightbox-close" class="mermaid-lightbox-close" type="button">关闭</button>
            </div>
            <div id="mermaid-lightbox-viewport" class="mermaid-lightbox-viewport">
              <div id="mermaid-lightbox-canvas" class="mermaid-lightbox-canvas"></div>
            </div>
          </div>
          <script>
          \(turndownScript)
          </script>
          <script>
          (function () {
            const content = document.getElementById('content');
            const mermaidLightbox = document.getElementById('mermaid-lightbox');
            const mermaidLightboxCanvas = document.getElementById('mermaid-lightbox-canvas');
            const mermaidLightboxViewport = document.getElementById('mermaid-lightbox-viewport');
            const mermaidLightboxClose = document.getElementById('mermaid-lightbox-close');
            const turndown = new TurndownService({
              headingStyle: 'atx',
              codeBlockStyle: 'fenced',
              bulletListMarker: '-',
              emDelimiter: '*',
              strongDelimiter: '**'
            });
            turndown.addRule('strikethrough', {
              filter: ['del', 's', 'strike'],
              replacement: function (content) { return '~~' + content + '~~'; }
            });
            turndown.addRule('listItem', {
              filter: 'li',
              replacement: function (content, node, options) {
                content = content
                  .replace(/^\\n+/, '')
                  .replace(/\\n+$/, '\\n')
                  .replace(/\\n/gm, '\\n    ');
                let prefix = options.bulletListMarker + ' ';
                const parent = node.parentNode;
                if (parent.nodeName === 'OL') {
                  const start = parent.getAttribute('start');
                  const index = Array.prototype.indexOf.call(parent.children, node);
                  prefix = (start ? Number(start) + index : index + 1) + '. ';
                }
                return prefix + content + (node.nextSibling && !/\\n$/.test(content) ? '\\n' : '');
              }
            });
            turndown.addRule('heading', {
              filter: ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
              replacement: function (content, node) {
                const level = Number(node.nodeName.charAt(1));
                const text = content.replace(/^(\\d+)\\\\\\. /, '$1. ');
                return '\\n\\n' + '#'.repeat(level) + ' ' + text + '\\n\\n';
              }
            });
            turndown.addRule('mermaid', {
              filter: function (node) {
                return node.nodeName === 'DIV' && node.classList.contains('mermaid-diagram');
              },
              replacement: function (content, node) {
                const source = decodeMermaidSource(node);
                const newline = source.endsWith('\\n') ? '' : '\\n';
                return '\\n\\n```mermaid\\n' + source + newline + '```\\n\\n';
              }
            });
            turndown.addRule('table', {
              filter: 'table',
              replacement: function (content, node) {
                const rows = Array.from(node.querySelectorAll('tr')).map(function (row) {
                  return Array.from(row.children).map(function (cell) {
                    return turndown.turndown(cell.innerHTML || '')
                      .replace(/\\n+/g, ' ')
                      .replace(/\\|/g, '\\\\|')
                      .trim();
                  });
                }).filter(function (row) {
                  return row.length > 0;
                });
                if (!rows.length) return '';

                const header = rows[0];
                const separator = header.map(function () { return '---'; });
                const bodyRows = rows.slice(1);
                const markdownRows = [header, separator].concat(bodyRows).map(function (row) {
                  return '| ' + row.join(' | ') + ' |';
                });
                const originalSeparator = node.dataset
                  ? String(node.dataset.markdownTableSeparator || '').trim()
                  : '';
                if (isTableSeparator(originalSeparator, header.length)) {
                  markdownRows[1] = originalSeparator;
                }
                return '\\n\\n' + markdownRows.join('\\n') + '\\n\\n';
              }
            });

            let emitTimer = null;
            let suppressEmit = false;
            const headingSelector = 'h1, h2, h3, h4, h5, h6';
            const sourceAnchorSelector = '[data-source-offset]';
            let scrollAnchorFrame = null;
            let pendingPositionOffset = null;
            let suppressScrollAnchorReport = false;
            let followGeneration = 0;

            // 连续被动定位只由最后一次解除抑制，避免滚动事件反向驱动源码。
            function beginFollowingPosition() {
              suppressScrollAnchorReport = true;
              const generation = ++followGeneration;
              pendingPositionOffset = null;
              if (scrollAnchorFrame !== null) {
                cancelAnimationFrame(scrollAnchorFrame);
                scrollAnchorFrame = null;
              }
              requestAnimationFrame(function () {
                requestAnimationFrame(function () {
                  if (generation === followGeneration) suppressScrollAnchorReport = false;
                });
              });
            }
            // 新的真实输入立即接管位置，不能被上一轮被动跟随的抑制窗口吞掉。
            function resumeUserPosition(event) {
              if (!event.isTrusted) return;
              ++followGeneration;
              suppressScrollAnchorReport = false;
              pendingPositionOffset = null;
            }
            window.addEventListener('wheel', resumeUserPosition, { passive: true });
            content.addEventListener('pointerdown', resumeUserPosition);
            content.addEventListener('keydown', resumeUserPosition);

            let pendingPreviewEdit = {
              range: null
            };
            const commandKey = 'Meta';
            const commandModifier = 'Meta';
            const linkOpenModeClass = 'is-link-open-mode';
            const linkSelector = 'a[href]';
            const isMacCommandPressed = function (event) {
              return Boolean(
                event && (
                  event.metaKey ||
                  (event.getModifierState && event.getModifierState(commandModifier))
                )
              );
            };
            let isLinkOpenMode = false;

            function post(payload) {
              if (window.webkit && webkit.messageHandlers && webkit.messageHandlers.bridge) {
                webkit.messageHandlers.bridge.postMessage(payload);
              }
            }

            function setLinkOpenMode(enabled) {
              if (isLinkOpenMode === enabled) return;
              isLinkOpenMode = enabled;
              content.classList.toggle(linkOpenModeClass, enabled);
            }

            function anchorFromEvent(event) {
              if (!event || !event.target) return null;
              const target = event.target.nodeType === Node.ELEMENT_NODE
                ? event.target
                : event.target.parentElement;
              if (!target || !target.closest) return null;
              return target.closest(linkSelector);
            }

            function handleLinkActivation(event) {
              const anchor = anchorFromEvent(event);
              if (!anchor || !anchor.href || !isMacCommandPressed(event)) return false;
              if ((anchor.getAttribute('href') || '').startsWith('#')) return false;
              event.preventDefault();
              post({ type: 'openURL', url: anchor.href });
              return true;
            }

            function decodeMermaidSource(block) {
              try {
                const binary = atob(block.dataset.mermaidSource || '');
                const bytes = Uint8Array.from(binary, function (character) {
                  return character.charCodeAt(0);
                });
                return new TextDecoder().decode(bytes);
              } catch (error) {
                return '';
              }
            }

            function mermaidTheme() {
              return document.documentElement.dataset.colorScheme === 'dark'
                ? 'dark'
                : 'default';
            }

            function mermaidFontSize() {
              const value = getComputedStyle(document.documentElement)
                .getPropertyValue('--font-size')
                .trim();
              return value || '14px';
            }

            function stabilizeMermaidSubgraphOrder(source) {
              const lines = source.split(/\\r?\\n/);
              const topLevelIDs = [];
              let depth = 0;

              lines.forEach(function (line) {
                const statement = line.split('%%', 1)[0].trim();
                const declaration = statement.match(
                  /^subgraph\\s+([A-Za-z_][A-Za-z0-9_-]*)/i
                );
                if (/^subgraph(?:\\s|$)/i.test(statement)) {
                  if (depth === 0 && declaration) {
                    topLevelIDs.push(declaration[1]);
                  }
                  depth += 1;
                  return;
                }
                if (/^end(?:\\s|$)/i.test(statement)) {
                  depth = Math.max(0, depth - 1);
                }
              });

              if (topLevelIDs.length < 2) return source;

              depth = 0;
              const hasExplicitSubgraphLink = lines.some(function (line) {
                const statement = line.split('%%', 1)[0].trim();
                if (/^subgraph(?:\\s|$)/i.test(statement)) {
                  depth += 1;
                  return false;
                }
                if (/^end(?:\\s|$)/i.test(statement)) {
                  depth = Math.max(0, depth - 1);
                  return false;
                }
                if (depth !== 0 || !/(?:--|==|~~|-\\.-)/.test(statement)) {
                  return false;
                }
                return topLevelIDs.some(function (id) {
                  const identifier = new RegExp(
                    '(^|[^A-Za-z0-9_-])' + id + '([^A-Za-z0-9_-]|$)'
                  );
                  return identifier.test(statement);
                });
              });

              if (hasExplicitSubgraphLink) return source;

              const orderLinks = topLevelIDs.slice(1).map(function (id, index) {
                return '    ' + topLevelIDs[index] + ' ~~~ ' + id;
              });
              const separator = source.endsWith('\\n') ? '' : '\\n';
              return source + separator + orderLinks.join('\\n');
            }

            function showMermaidError(block, source, error) {
              const sourceElement = document.createElement('pre');
              const codeElement = document.createElement('code');
              codeElement.textContent = source;
              sourceElement.appendChild(codeElement);

              const messageElement = document.createElement('div');
              messageElement.className = 'mermaid-error-message';
              const message = error && error.message
                ? error.message
                : 'Mermaid renderer is unavailable.';
              messageElement.textContent = 'Mermaid: ' + message;

              block.replaceChildren(sourceElement, messageElement);
              block.classList.remove('is-rendered');
              block.classList.add('is-error');
            }

            function mermaidNaturalWidth(svg) {
              if (!svg || !svg.viewBox || !svg.viewBox.baseVal) return null;
              const naturalWidth = Math.ceil(svg.viewBox.baseVal.width);
              return Number.isFinite(naturalWidth) && naturalWidth > 0 ? naturalWidth : null;
            }

            function fitMermaidToPreview(diagram) {
              const svg = diagram.querySelector('svg');
              if (!svg) return;
              svg.removeAttribute('width');
              svg.removeAttribute('height');
              svg.style.width = '100%';
              svg.style.height = 'auto';
              svg.style.maxWidth = '100%';
            }

            let lastMermaidTrigger = null;

            function closeMermaidLargeView() {
              mermaidLightbox.classList.remove('is-open');
              mermaidLightbox.setAttribute('aria-hidden', 'true');
              mermaidLightboxCanvas.replaceChildren();
              if (lastMermaidTrigger) {
                lastMermaidTrigger.focus();
                lastMermaidTrigger = null;
              }
            }

            function openMermaidLargeView(diagram) {
              const svg = diagram.querySelector('svg');
              if (!svg) return;
              const clone = svg.cloneNode(true);
              const naturalWidth = mermaidNaturalWidth(svg);
              clone.removeAttribute('width');
              clone.removeAttribute('height');
              clone.style.width = naturalWidth ? naturalWidth + 'px' : 'auto';
              clone.style.height = 'auto';
              clone.style.maxWidth = 'none';
              mermaidLightboxCanvas.replaceChildren(clone);
              mermaidLightbox.classList.add('is-open');
              mermaidLightbox.setAttribute('aria-hidden', 'false');
              mermaidLightboxViewport.scrollTo({ top: 0, left: 0, behavior: 'auto' });
              mermaidLightboxClose.focus();
            }

            function attachMermaidLargeView(block, diagram) {
              const button = document.createElement('button');
              button.type = 'button';
              button.className = 'mermaid-large-button';
              button.textContent = '查看大图';
              button.title = '查看大图';
              button.setAttribute('aria-label', '查看大图');
              button.setAttribute('contenteditable', 'false');
              button.addEventListener('click', function (event) {
                event.preventDefault();
                event.stopPropagation();
                lastMermaidTrigger = button;
                openMermaidLargeView(diagram);
              });
              block.appendChild(button);
            }

            let mermaidRenderRevision = 0;

            async function renderMermaidDiagrams() {
              const revision = ++mermaidRenderRevision;
              const blocks = Array.from(content.querySelectorAll('.mermaid-diagram'));
              if (!blocks.length) return;

              if (!window.mermaid) {
                blocks.forEach(function (block) {
                  showMermaidError(block, decodeMermaidSource(block), null);
                });
                return;
              }

              mermaid.initialize({
                startOnLoad: false,
                securityLevel: 'strict',
                theme: mermaidTheme(),
                fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif',
                themeVariables: {
                  fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif',
                  fontSize: mermaidFontSize()
                },
                flowchart: {
                  htmlLabels: true,
                  useMaxWidth: true,
                  nodeSpacing: 18,
                  rankSpacing: 24,
                  padding: 8,
                  diagramPadding: 4,
                  subGraphTitleMargin: {
                    top: 4,
                    bottom: 4
                  }
                }
              });

              for (const block of blocks) {
                if (revision !== mermaidRenderRevision) return;
                const source = decodeMermaidSource(block);
                const renderSource = stabilizeMermaidSubgraphOrder(source);
                const diagram = document.createElement('div');
                diagram.className = 'mermaid';
                diagram.textContent = renderSource;
                block.replaceChildren(diagram);
                block.classList.remove('is-error', 'is-rendered');

                try {
                  await mermaid.parse(renderSource);
                  await mermaid.run({ nodes: [diagram], suppressErrors: false });
                  if (revision !== mermaidRenderRevision) return;
                  fitMermaidToPreview(diagram);
                  attachMermaidLargeView(block, diagram);
                  block.classList.add('is-rendered');
                } catch (error) {
                  if (revision !== mermaidRenderRevision) return;
                  showMermaidError(block, source, error);
                }
              }

            }

            function currentBlock() {
              const selection = window.getSelection();
              let node = selection && selection.anchorNode ? selection.anchorNode : null;
              if (!node) return null;
              if (node.nodeType === Node.TEXT_NODE) {
                node = node.parentElement;
              }
              if (!node || !node.closest) return null;
              return node.closest(sourceAnchorSelector);
            }

            function sourceOffsetForBlock(block) {
              if (!block || !block.dataset) return null;
              const sourceOffset = Number(block.dataset.sourceOffset);
              return Number.isFinite(sourceOffset) ? sourceOffset : null;
            }

            function sourceBlockFromNode(node) {
              if (!node) return null;
              const element = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement;
              if (!element || !element.closest) return null;
              return element.closest(sourceAnchorSelector);
            }

            function sourceBlockForRangeBoundary(container, offset, preferPrevious) {
              if (container === content) {
                const children = Array.from(content.children);
                if (!children.length) return null;
                const index = preferPrevious
                  ? Math.max(0, Math.min(children.length - 1, offset - 1))
                  : Math.max(0, Math.min(children.length - 1, offset));
                return sourceBlockFromNode(children[index]);
              }
              return sourceBlockFromNode(container);
            }

            function sourceRangeFromBlocks(startBlock, endBlock) {
              const startSourceOffset = sourceOffsetForBlock(startBlock);
              const endSourceOffset = sourceOffsetForBlock(endBlock || startBlock);
              if (startSourceOffset === null || endSourceOffset === null) return null;
              return {
                startSourceOffset: Math.min(startSourceOffset, endSourceOffset),
                endSourceOffset: Math.max(startSourceOffset, endSourceOffset)
              };
            }

            function sourceRangeFromBlock(block) {
              return sourceRangeFromBlocks(block, block);
            }

            function mergeSourceRanges(left, right) {
              if (!left) return right;
              if (!right) return left;
              return {
                startSourceOffset: Math.min(left.startSourceOffset, right.startSourceOffset),
                endSourceOffset: Math.max(left.endSourceOffset, right.endSourceOffset)
              };
            }

            function sourceRangeFromEvent(event) {
              if (!event) return null;
              if (event.getTargetRanges) {
                const ranges = event.getTargetRanges();
                if (ranges && ranges.length) {
                  let result = null;
                  for (let index = 0; index < ranges.length; index++) {
                    const range = ranges[index];
                    const startBlock = sourceBlockForRangeBoundary(
                      range.startContainer,
                      range.startOffset,
                      false
                    );
                    const endBlock = sourceBlockForRangeBoundary(
                      range.endContainer,
                      range.endOffset,
                      true
                    );
                    result = mergeSourceRanges(result, sourceRangeFromBlocks(startBlock, endBlock));
                  }
                  if (result) return result;
                }
              }
              if (event.target) {
                return sourceRangeFromBlock(sourceBlockFromNode(event.target));
              }
              return null;
            }

            function rememberEditingRange(event) {
              const range = sourceRangeFromEvent(event) || sourceRangeFromBlock(currentBlock());
              if (range) {
                pendingPreviewEdit.range = mergeSourceRanges(pendingPreviewEdit.range, range);
              }
            }

            function isTableSeparator(value, columnCount) {
              if (!value || !value.includes('-')) return false;
              const cells = value.split('|');
              if (cells.length && cells[0].trim() === '') cells.shift();
              if (cells.length && cells[cells.length - 1].trim() === '') cells.pop();
              if (cells.length !== columnCount) return false;
              return cells.every(function (cell) {
                return /^\\s*:?-+:?\\s*$/.test(cell);
              });
            }

            function markdownForBlock(block) {
              return turndown.turndown(block.outerHTML || '').trim();
            }

            function blocksForSourceRange(range) {
              const children = Array.from(content.children);
              const previousIndex = children.reduce(function (result, child, index) {
                const sourceOffset = sourceOffsetForBlock(child);
                return sourceOffset !== null && sourceOffset < range.startSourceOffset ? index : result;
              }, -1);
              const nextIndex = children.findIndex(function (child) {
                const sourceOffset = sourceOffsetForBlock(child);
                return sourceOffset !== null && sourceOffset > range.endSourceOffset;
              });
              const endIndex = nextIndex === -1 ? children.length : nextIndex;
              return children.slice(previousIndex + 1, endIndex);
            }

            function markdownForRange(range) {
              return blocksForSourceRange(range)
                .map(markdownForBlock)
                .filter(function (markdown) { return markdown.length > 0; })
                .join('\\n\\n');
            }

            function recordPreviewEdit() {
              const range = pendingPreviewEdit.range || sourceRangeFromBlock(currentBlock());
              if (range) pendingPreviewEdit.range = range;
            }

            function emitMarkdown() {
              if (suppressEmit) return;
              const range = pendingPreviewEdit.range;
              pendingPreviewEdit.range = null;
              if (!range) return;
              post({
                type: 'markdownRangeChanged',
                startSourceOffset: range.startSourceOffset,
                endSourceOffset: range.endSourceOffset,
                markdown: markdownForRange(range)
              });
            }

            function scheduleEmit(shouldRecordBlock) {
              if (shouldRecordBlock) {
                recordPreviewEdit();
              }
              clearTimeout(emitTimer);
              emitTimer = setTimeout(emitMarkdown, 100);
            }

            function ensureHeadingIDs() {
              content.querySelectorAll(headingSelector).forEach(function (heading, index) {
                heading.id = 'yk-heading-' + index;
              });
            }

            function sourceAnchors() {
              return Array.from(content.querySelectorAll(sourceAnchorSelector)).filter(function (element) {
                return Number.isFinite(Number(element.dataset.sourceOffset));
              });
            }

            // 点击、选区和滚动共用源码块位置；不向其他区域传递键盘焦点。
            function reportPosition(sourceOffset) {
              if (suppressScrollAnchorReport || sourceOffset === null || !Number.isFinite(sourceOffset)) return;
              pendingPositionOffset = sourceOffset;
              scheduleScrollAnchorReport();
            }

            function reportSelectionPosition() {
              if (!content.contains(document.activeElement)) return;
              const selection = window.getSelection();
              if (!selection || !content.contains(selection.focusNode)) return;
              const block = sourceBlockForRangeBoundary(selection.focusNode, selection.focusOffset, false);
              reportPosition(sourceOffsetForBlock(block));
            }

            document.addEventListener('selectionchange', reportSelectionPosition);

            function visibleSourceOffset() {
              const anchors = sourceAnchors();
              if (!anchors.length) return null;
              const viewportTop = 20;
              let active = anchors[0];
              anchors.forEach(function (anchor) {
                if (anchor.getBoundingClientRect().top <= viewportTop) {
                  active = anchor;
                }
              });
              return Number(active.dataset.sourceOffset);
            }

            function scheduleScrollAnchorReport() {
              if (suppressScrollAnchorReport) return;
              if (scrollAnchorFrame !== null) return;
              scrollAnchorFrame = requestAnimationFrame(function () {
                scrollAnchorFrame = null;
                const sourceOffset = pendingPositionOffset ?? visibleSourceOffset();
                pendingPositionOffset = null;
                if (!suppressScrollAnchorReport && sourceOffset !== null) {
                  post({ type: 'positionChanged', sourceOffset: sourceOffset });
                }
              });
            }

            content.addEventListener('input', function () {
              ensureHeadingIDs();
              scheduleEmit(true);
              reportSelectionPosition();
            });
            content.addEventListener('beforeinput', rememberEditingRange);
            window.addEventListener('scroll', function () {
              scheduleScrollAnchorReport();
            }, { passive: true });

            content.addEventListener('paste', function (event) {
              const items = event.clipboardData ? event.clipboardData.items : null;
              let hasImage = false;
              if (items) {
                for (let i = 0; i < items.length; i++) {
                  if (items[i].type && items[i].type.indexOf('image') === 0) {
                    hasImage = true;
                    break;
                  }
                }
              }
              if (hasImage) {
                event.preventDefault();
                post({ type: 'pasteImages' });
              }
            });

            content.addEventListener('mousemove', function (event) {
              setLinkOpenMode(isMacCommandPressed(event));
            }, { passive: true });

            content.addEventListener('mouseleave', function () {
              setLinkOpenMode(false);
            }, { passive: true });

            content.addEventListener('mousedown', function (event) {
              handleLinkActivation(event);
            });

            content.addEventListener('click', function (event) {
              reportPosition(sourceOffsetForBlock(sourceBlockFromNode(event.target)));
              const anchor = anchorFromEvent(event);
              if (anchor) {
                event.preventDefault();
                const href = anchor.getAttribute('href') || '';
                if (href.startsWith('#')) {
                  let id;
                  try { id = decodeURIComponent(href.slice(1)); } catch (_) { return; }
                  const target = document.getElementById(id);
                  if (target && content.contains(target)) {
                    target.scrollIntoView({ behavior: 'auto', block: 'start' });
                    reportPosition(sourceOffsetForBlock(sourceBlockFromNode(target)));
                  }
                }
              }
            });

            mermaidLightboxClose.addEventListener('click', closeMermaidLargeView);
            document.addEventListener('keydown', function (event) {
              if (event.key === 'Escape' && mermaidLightbox.classList.contains('is-open')) {
                closeMermaidLargeView();
              }
              if (event.key === commandKey || isMacCommandPressed(event)) {
                setLinkOpenMode(true);
              }
            });
            document.addEventListener('keyup', function (event) {
              if (event.key === commandKey || !isMacCommandPressed(event)) {
                setLinkOpenMode(false);
              }
            });
            window.addEventListener('blur', function () {
              setLinkOpenMode(false);
            });

            content.addEventListener('dragover', function (event) {
              event.preventDefault();
            });

            content.addEventListener('drop', function (event) {
              event.preventDefault();
              post({ type: 'requestDropImport' });
            });

            window.setBodyHTML = function (html) {
              beginFollowingPosition();
              suppressEmit = true;
              const htmlValue = html && html.length ? html : '<p data-source-offset="0"><br></p>';
              if (content.innerHTML !== htmlValue) {
                content.innerHTML = htmlValue;
              }
              ensureHeadingIDs();
              suppressEmit = false;
              renderMermaidDiagrams();
            };

            window.setSourceOffsets = function (offsets) {
              const children = Array.from(content.children);
              children.forEach(function (element, index) {
                const sourceOffset = Number(offsets[index]);
                if (Number.isFinite(sourceOffset)) {
                  element.dataset.sourceOffset = String(sourceOffset);
                } else {
                  element.removeAttribute('data-source-offset');
                }
              });
            };

            window.scrollToSourceOffset = function (requestedOffset) {
              const sourceOffset = Number(requestedOffset);
              if (!Number.isFinite(sourceOffset)) return;
              const anchors = sourceAnchors();
              if (!anchors.length) return;
              let target = anchors[0];
              anchors.forEach(function (anchor) {
                if (Number(anchor.dataset.sourceOffset) <= sourceOffset) {
                  target = anchor;
                }
              });
              const targetTop = target.getBoundingClientRect().top + window.scrollY - 20;
              beginFollowingPosition();
              window.scrollTo({ top: Math.max(0, targetTop), behavior: 'auto' });
            };

            window.setAccentColor = function (color) {
              document.documentElement.style.setProperty('--link', color);
              document.documentElement.style.setProperty(
                '--focus',
                'color-mix(in srgb, ' + color + ' 20%, transparent)'
              );
            };

            window.setFontSize = function (fontSize) {
              const value = Number(fontSize);
              if (!Number.isFinite(value)) return;
              document.documentElement.style.setProperty('--font-size', value + 'px');
              renderMermaidDiagrams();
            };

            window.setAppearance = function (backgroundColor, foregroundColor, colorScheme) {
              const root = document.documentElement;
              const colorSchemeChanged = root.dataset.colorScheme !== colorScheme;
              root.dataset.colorScheme = colorScheme;
              root.style.colorScheme = colorScheme;
              root.style.setProperty('--bg', backgroundColor);
              root.style.setProperty('--text', foregroundColor);
              if (colorSchemeChanged) renderMermaidDiagrams();
            };

            window.insertImageAtCaret = function (src, alt) {
              const safeSrc = String(src).replace(/"/g, '&quot;');
              const safeAlt = String(alt || '').replace(/"/g, '&quot;');
              pendingPreviewEdit.range = pendingPreviewEdit.range || sourceRangeFromBlock(currentBlock());
              document.execCommand(
                'insertHTML',
                false,
                '<p><img src="' + safeSrc + '" alt="' + safeAlt + '" /></p>'
              );
              scheduleEmit(false);
            };

            window.focusEditor = function () {
              content.focus();
            };

            ensureHeadingIDs();
            renderMermaidDiagrams();
          })();
          </script>
        </body>
        </html>
        """
    }

    private static func renderBody(_ markdown: String) -> RenderedBody {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let source = markdown as NSString
        var lineOffsets = [0]
        if source.length > 0 {
            for location in 0..<source.length where source.character(at: location) == 10 {
                lineOffsets.append(location + 1)
            }
        }
        var html: [String] = []
        var sourceOffsets: [Int] = []
        var index = 0
        var inCodeBlock = false
        var codeBlockOffset = 0
        var codeLanguage = ""
        var codeLines: [String] = []
        var paragraph: [String] = []
        var paragraphOffset = 0
        // 栈中每层保留一个尚未关闭的 li，子列表才能放在父条目内部。
        var listLevels: [ListLevel] = []
        var listHTML = ""
        var listOffset = 0
        var headingIndex = 0

        func appendBlock(_ value: String, sourceOffset: Int) {
            html.append(value)
            sourceOffsets.append(sourceOffset)
        }

        func sourceAttribute(_ sourceOffset: Int) -> String {
            " data-source-offset=\"\(sourceOffset)\""
        }

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            let text = paragraph.joined(separator: " ")
            appendBlock(
                "<p\(sourceAttribute(paragraphOffset))>\(renderInline(text))</p>",
                sourceOffset: paragraphOffset
            )
            paragraph.removeAll(keepingCapacity: true)
        }

        // 只有最外层列表携带源码锚点，维持预览整块回写和位置映射的一致性。
        func closeListLevel() {
            guard let level = listLevels.popLast() else { return }
            let tag = level.kind == .unordered ? "ul" : "ol"
            listHTML += "</li></\(tag)>"
            if listLevels.isEmpty {
                appendBlock(listHTML, sourceOffset: listOffset)
                listHTML = ""
            }
        }

        func flushList() {
            while !listLevels.isEmpty {
                closeListLevel()
            }
        }

        // 缩进增加时进入子列表，回退时关闭子列表，同级类型变化时另起列表。
        func appendListItem(_ text: String, kind: ListKind, indentation: Int, sourceOffset: Int) {
            while let level = listLevels.last, indentation < level.indentation {
                closeListLevel()
            }
            if let level = listLevels.last, indentation == level.indentation, kind != level.kind {
                closeListLevel()
            }
            if let level = listLevels.last, indentation == level.indentation {
                listHTML += "</li><li>"
            } else {
                let tag = kind == .unordered ? "ul" : "ol"
                let attribute = listLevels.isEmpty ? sourceAttribute(sourceOffset) : ""
                if listLevels.isEmpty {
                    listOffset = sourceOffset
                }
                listHTML += "<\(tag)\(attribute)><li>"
                listLevels.append(ListLevel(kind: kind, indentation: indentation))
            }
            listHTML += renderInline(text)
        }

        while index < lines.count {
            let line = lines[index]

            if line.hasPrefix("```") {
                flushParagraph()
                flushList()
                if inCodeBlock {
                    let code = escapeHTML(codeLines.joined(separator: "\n"))
                    if codeLanguage.lowercased() == "mermaid" {
                        let encodedSource = Data(codeLines.joined(separator: "\n").utf8).base64EncodedString()
                        appendBlock(
                            "<div class=\"mermaid-diagram\"\(sourceAttribute(codeBlockOffset)) data-mermaid-source=\"\(encodedSource)\" contenteditable=\"false\"><div class=\"mermaid\">\(code)</div></div>",
                            sourceOffset: codeBlockOffset
                        )
                    } else {
                        let languageClass = codeLanguage.isEmpty ? "" : " class=\"language-\(escapeHTML(codeLanguage))\""
                        appendBlock(
                            "<pre\(sourceAttribute(codeBlockOffset))><code\(languageClass)>\(code)</code></pre>",
                            sourceOffset: codeBlockOffset
                        )
                    }
                    codeLines.removeAll(keepingCapacity: true)
                    codeLanguage = ""
                    inCodeBlock = false
                } else {
                    inCodeBlock = true
                    codeBlockOffset = lineOffsets[index]
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                index += 1
                continue
            }

            if inCodeBlock {
                codeLines.append(line)
                index += 1
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                // 回写产生的列表间空行不能打断父子关系；非列表块仍正常结束列表。
                repeat {
                    index += 1
                } while index < lines.count && lines[index].trimmingCharacters(in: .whitespaces).isEmpty
                let nextLine = index < lines.count ? lines[index].trimmingCharacters(in: .whitespaces) : ""
                if matchUnorderedListItem(nextLine) == nil && matchOrderedListItem(nextLine) == nil {
                    flushList()
                }
                continue
            }

            if isThematicBreak(line) {
                flushParagraph()
                flushList()
                appendBlock("<hr\(sourceAttribute(lineOffsets[index])) />", sourceOffset: lineOffsets[index])
                index += 1
                continue
            }

            if let heading = parseHeading(trimmed) {
                flushParagraph()
                flushList()
                let id = "yk-heading-\(headingIndex)"
                appendBlock(
                    "<h\(heading.level) id=\"\(id)\"\(sourceAttribute(lineOffsets[index]))>\(renderInline(heading.text))</h\(heading.level)>",
                    sourceOffset: lineOffsets[index]
                )
                headingIndex += 1
                index += 1
                continue
            }

            if trimmed.hasPrefix("> ") || trimmed == ">" {
                flushParagraph()
                flushList()
                let quoteOffset = lineOffsets[index]
                var quoteLines: [String] = []
                while index < lines.count {
                    let current = lines[index].trimmingCharacters(in: .whitespaces)
                    if current.hasPrefix("> ") {
                        quoteLines.append(String(current.dropFirst(2)))
                    } else if current == ">" {
                        quoteLines.append("")
                    } else {
                        break
                    }
                    index += 1
                }
                let quoteBody = quoteLines
                    .map { $0.isEmpty ? "<br />" : renderInline($0) }
                    .joined(separator: "<br />")
                appendBlock(
                    "<blockquote\(sourceAttribute(quoteOffset))><p>\(quoteBody)</p></blockquote>",
                    sourceOffset: quoteOffset
                )
                continue
            }

            if let unordered = matchUnorderedListItem(trimmed) {
                flushParagraph()
                appendListItem(unordered, kind: .unordered, indentation: listIndentation(line), sourceOffset: lineOffsets[index])
                index += 1
                continue
            }

            if let ordered = matchOrderedListItem(trimmed) {
                flushParagraph()
                appendListItem(ordered, kind: .ordered, indentation: listIndentation(line), sourceOffset: lineOffsets[index])
                index += 1
                continue
            }

            if looksLikeTableHeader(trimmed), index + 1 < lines.count, isTableSeparator(lines[index + 1]) {
                flushParagraph()
                flushList()
                let tableOffset = lineOffsets[index]
                let headerCells = splitTableRow(trimmed)
                let separatorLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
                index += 2
                var rows: [[String]] = []
                while index < lines.count {
                    let rowLine = lines[index].trimmingCharacters(in: .whitespaces)
                    if rowLine.isEmpty || !rowLine.contains("|") { break }
                    rows.append(splitTableRow(rowLine))
                    index += 1
                }
                var table = "<table\(sourceAttribute(tableOffset)) data-markdown-table-separator=\"\(escapeHTML(separatorLine))\"><thead><tr>"
                table += headerCells.map { "<th>\(renderInline($0))</th>" }.joined()
                table += "</tr></thead><tbody>"
                for row in rows {
                    table += "<tr>"
                    table += row.map { "<td>\(renderInline($0))</td>" }.joined()
                    table += "</tr>"
                }
                table += "</tbody></table>"
                appendBlock(table, sourceOffset: tableOffset)
                continue
            }

            flushList()
            if paragraph.isEmpty {
                paragraphOffset = lineOffsets[index]
            }
            paragraph.append(trimmed)
            index += 1
        }

        if inCodeBlock {
            let code = escapeHTML(codeLines.joined(separator: "\n"))
            appendBlock(
                "<pre\(sourceAttribute(codeBlockOffset))><code>\(code)</code></pre>",
                sourceOffset: codeBlockOffset
            )
        }
        flushParagraph()
        flushList()

        return RenderedBody(html: html.joined(separator: "\n"), sourceOffsets: sourceOffsets)
    }

    private struct RenderedBody {
        let html: String
        let sourceOffsets: [Int]
    }

    private enum ListKind {
        case unordered
        case ordered
    }

    /// 保存列表类型和标记缩进，用于恢复父子结构及同级列表边界。
    private struct ListLevel {
        let kind: ListKind
        let indentation: Int
    }

    /// 按四列制表位计算缩进，兼容空格、Tab 以及混合缩进。
    private static func listIndentation(_ line: String) -> Int {
        var columns = 0
        for character in line {
            if character == " " {
                columns += 1
            } else if character == "\t" {
                columns += 4 - columns % 4
            } else {
                break
            }
        }
        return columns
    }

    /// 分隔线优先于列表识别：最多缩进三格，至少三个同类标记，允许空格和 Tab 间隔。
    private static func isThematicBreak(_ line: String) -> Bool {
        let indentation = line.prefix { $0 == " " }.count
        guard indentation <= 3 else { return false }
        let content = line.dropFirst(indentation)
        guard let marker = content.first, marker == "*" || marker == "-" || marker == "_" else {
            return false
        }
        var markerCount = 0
        for character in content {
            if character == marker {
                markerCount += 1
            } else if character != " " && character != "\t" {
                return false
            }
        }
        return markerCount >= 3
    }

    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        for character in line {
            if character == "#" {
                level += 1
            } else {
                break
            }
        }
        guard level >= 1, level <= 6 else { return nil }
        let rest = line.dropFirst(level)
        guard rest.first == " " || rest.isEmpty else { return nil }
        let text = rest.trimmingCharacters(in: .whitespaces)
        return (level, text)
    }

    private static func matchUnorderedListItem(_ line: String) -> String? {
        for prefix in ["- ", "* ", "+ "] where line.hasPrefix(prefix) {
            return String(line.dropFirst(prefix.count))
        }
        return nil
    }

    private static func matchOrderedListItem(_ line: String) -> String? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let number = line[..<dotIndex]
        guard !number.isEmpty, number.allSatisfy(\.isNumber) else { return nil }
        let after = line[line.index(after: dotIndex)...]
        guard after.first == " " else { return nil }
        return after.dropFirst().trimmingCharacters(in: .whitespaces)
    }

    private static func looksLikeTableHeader(_ line: String) -> Bool {
        line.contains("|")
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") || trimmed.contains("-") else { return false }
        return trimmed.unicodeScalars.allSatisfy { scalar in
            CharacterSet(charactersIn: "|-: ").contains(scalar)
        } && trimmed.contains("-")
    }

    private static func splitTableRow(_ line: String) -> [String] {
        var cells = line.split(separator: "|", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        if cells.first?.isEmpty == true { cells.removeFirst() }
        if cells.last?.isEmpty == true { cells.removeLast() }
        return cells
    }

    private static func renderInline(_ text: String) -> String {
        var result = escapeHTML(text)

        // 先隐藏代码内容，避免后续强调、链接等规则再次解析；前缀必须与原文无冲突。
        var codeTokenPrefix = "\u{001F}code"
        while result.contains(codeTokenPrefix) {
            codeTokenPrefix += "\u{001F}"
        }
        var codeFragments: [(token: String, html: String)] = []
        if let regex = try? NSRegularExpression(pattern: "`([^`]+)`") {
            let source = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: source.length))
            // 从后往前替换，保持尚未处理的 UTF-16 区间有效。
            for (index, match) in matches.enumerated().reversed() {
                let token = "\(codeTokenPrefix)\(index)\u{001F}"
                let code = source.substring(with: match.range(at: 1))
                codeFragments.append((token: token, html: "<code>\(code)</code>"))
                result = (result as NSString).replacingCharacters(in: match.range, with: token)
            }
        }
        result = replacePattern(
            in: result,
            pattern: #"!\[([^\]]*)\]\(([^)\s]+)\)"#,
            template: #"<img src="$2" alt="$1" />"#
        )
        result = replacePattern(
            in: result,
            pattern: #"\[([^\]]+)\]\(([^)\s]+)\)"#,
            template: #"<a href="$2">$1</a>"#
        )
        result = replacePattern(
            in: result,
            pattern: #"\*\*([^*]+)\*\*"#,
            template: "<strong>$1</strong>"
        )
        result = replacePattern(
            in: result,
            pattern: #"__([^_]+)__"#,
            template: "<strong>$1</strong>"
        )
        result = replacePattern(
            in: result,
            pattern: #"\*([^*]+)\*"#,
            template: "<em>$1</em>"
        )
        result = replacePattern(
            in: result,
            pattern: #"_([^_]+)_"#,
            template: "<em>$1</em>"
        )
        result = replacePattern(
            in: result,
            pattern: #"~~([^~]+)~~"#,
            template: "<del>$1</del>"
        )

        for fragment in codeFragments {
            result = result.replacingOccurrences(of: fragment.token, with: fragment.html)
        }
        return result
    }

    private static func replacePattern(in text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
