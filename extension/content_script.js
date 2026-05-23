if (window.__extPickerLoaded) {
  // Already injected — skip re-initialisation to avoid duplicate listeners
} else {
window.__extPickerLoaded = true;

let active       = false;
let overlay      = null;  // full-page transparent event capture layer
let highlightBox = null;  // blue rect drawn over hovered element
let tooltip      = null;  // tag info tooltip
let currentEl    = null;  // element currently under cursor

function getOpeningTag(el) {
  const tag   = el.tagName.toLowerCase();
  const attrs = Array.from(el.attributes)
    .map(a => `${a.name}="${a.value}"`)
    .join(' ');
  return attrs ? `<${tag} ${attrs}>` : `<${tag}>`;
}

// Find the real page element underneath the overlay at viewport coords (x, y)
function targetAt(x, y) {
  const hits = document.elementsFromPoint(x, y);
  return hits.find(el => el !== overlay && el !== highlightBox && el !== tooltip) || null;
}

function positionHighlight(el) {
  if (!el) { highlightBox.style.display = 'none'; return; }
  const r = el.getBoundingClientRect();
  highlightBox.style.left    = r.left   + 'px';
  highlightBox.style.top     = r.top    + 'px';
  highlightBox.style.width   = r.width  + 'px';
  highlightBox.style.height  = r.height + 'px';
  highlightBox.style.display = 'block';
}

function onMouseMove(e) {
  const el = targetAt(e.clientX, e.clientY);
  currentEl = el;
  positionHighlight(el);

  if (tooltip && el) {
    tooltip.textContent    = getOpeningTag(el);
    tooltip.style.display  = 'block';
    const tx = Math.min(e.clientX + 14, window.innerWidth  - 10 - tooltip.offsetWidth);
    const ty = Math.min(e.clientY + 14, window.innerHeight - 10 - tooltip.offsetHeight);
    tooltip.style.left = Math.max(0, tx) + 'px';
    tooltip.style.top  = Math.max(0, ty) + 'px';
  }
}

function onScroll() {
  // Keep highlight aligned as the page scrolls under the fixed overlay
  positionHighlight(currentEl);
}

function onClick(e) {
  e.preventDefault();
  e.stopPropagation();
  if (!currentEl) return;

  const tag  = getOpeningTag(currentEl);
  const html = currentEl.outerHTML;

  chrome.runtime.sendMessage({ type: 'elementPicked', tag, html });
  // Stay in picking mode — user can keep selecting more elements
}

function activate() {
  if (active) return;
  active    = true;
  currentEl = null;

  // Highlight box — drawn below the overlay so it's visible but doesn't capture events
  highlightBox = document.createElement('div');
  highlightBox.style.cssText = [
    'position:fixed', 'z-index:2147483645', 'pointer-events:none',
    'box-sizing:border-box', 'border:2px solid #0078d4',
    'background:rgba(0,120,212,0.08)', 'display:none',
    'top:0', 'left:0', 'width:0', 'height:0', 'transition:none'
  ].join(';');

  // Tooltip — above everything, no pointer events
  tooltip = document.createElement('div');
  tooltip.style.cssText = [
    'position:fixed', 'z-index:2147483647', 'pointer-events:none',
    'background:#1e1e1e', 'color:#9cdcfe', 'font:11px/1.6 monospace',
    'padding:2px 8px', 'border-radius:3px', 'border:1px solid #555',
    'max-width:420px', 'white-space:nowrap', 'overflow:hidden',
    'text-overflow:ellipsis', 'display:none', 'top:0', 'left:0'
  ].join(';');

  // Transparent overlay — captures all mouse events, sits above page content
  overlay = document.createElement('div');
  overlay.style.cssText = [
    'position:fixed', 'z-index:2147483646', 'top:0', 'left:0',
    'width:100%', 'height:100%', 'cursor:crosshair', 'background:transparent'
  ].join(';');

  document.body.appendChild(highlightBox);
  document.body.appendChild(tooltip);
  document.body.appendChild(overlay);

  overlay.addEventListener('mousemove', onMouseMove);
  overlay.addEventListener('click', onClick);
  window.addEventListener('scroll', onScroll, true);
}

function deactivate() {
  if (!active) return;
  active    = false;
  currentEl = null;
  window.removeEventListener('scroll', onScroll, true);
  if (overlay)      { overlay.remove();      overlay      = null; }
  if (highlightBox) { highlightBox.remove(); highlightBox = null; }
  if (tooltip)      { tooltip.remove();      tooltip      = null; }
}

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg.type === 'activate')        { activate();   sendResponse({ ok: true }); }
  else if (msg.type === 'deactivate') { deactivate(); sendResponse({ ok: true }); }
});

} // end __extPickerLoaded guard
