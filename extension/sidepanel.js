const THEMES = {
  dark:      { background: '#1e1e1e', foreground: '#d4d4d4', cursor: '#aeafad', selection: '#264f78',
               uiFg: '#cccccc', uiDim: '#666666', uiInput: '#2d2d2d', uiBorder: '#444444', uiAccent: '#0078d4' },
  light:     { background: '#ffffff', foreground: '#383a42', cursor: '#526fff', selection: '#c8d3e9',
               uiFg: '#383a42', uiDim: '#999999', uiInput: '#f0f0f0', uiBorder: '#cccccc', uiAccent: '#526fff' },
  solarized: { background: '#002b36', foreground: '#839496', cursor: '#839496', selection: '#073642',
               uiFg: '#93a1a1', uiDim: '#586e75', uiInput: '#073642', uiBorder: '#073642', uiAccent: '#268bd2' },
  dracula:   { background: '#282a36', foreground: '#f8f8f2', cursor: '#f8f8f2', selection: '#44475a',
               uiFg: '#f8f8f2', uiDim: '#6272a4', uiInput: '#383a4a', uiBorder: '#44475a', uiAccent: '#bd93f9' },
  onedark:   { background: '#282c34', foreground: '#abb2bf', cursor: '#528bff', selection: '#3e4451',
               uiFg: '#abb2bf', uiDim: '#5c6370', uiInput: '#333842', uiBorder: '#3e4451', uiAccent: '#528bff' },
};

let configHost = localStorage.getItem('vce-host') || 'localhost';
const TERM_PORT   = 7681;
const HELPER_PORT = 7682;

function terminalBaseUrl() { return `https://${configHost}:${TERM_PORT}/`; }
function helperBaseUrl()   { return `https://${configHost}:${HELPER_PORT}`; }
let terminal     = document.getElementById('terminal');
const themeSelect = document.getElementById('theme-select');
const pickBtn    = document.getElementById('pick-btn');
const info       = document.getElementById('info');
const openBtn    = document.getElementById('open-btn');
const openPanel  = document.getElementById('open-panel');
const urlInput   = document.getElementById('url-input');
const urlGo      = document.getElementById('url-go');
const sendInput  = document.getElementById('send-input');
const sendBtn    = document.getElementById('send-btn');
const clearBtn     = document.getElementById('clear-btn');
const certBanner   = document.getElementById('cert-banner');
const certLink     = document.getElementById('cert-link');
const configBtn    = document.getElementById('config-btn');
const configDialog = document.getElementById('config-dialog');
const configHostEl = document.getElementById('config-host');
const cfgTermUrl   = document.getElementById('cfg-term-url');
const cfgHelperUrl = document.getElementById('cfg-helper-url');
const configCancel = document.getElementById('config-cancel');
const configSave   = document.getElementById('config-save');

let picking         = false;
let selectedContent = '';
let selectedTags    = [];

function updateInfoDisplay() {
  if (selectedTags.length === 0) {
    info.textContent = '—';
    info.classList.remove('selected');
    return;
  }
  const count = selectedTags.length;
  info.textContent = selectedTags.join('\n') + '\n' + count + ' element' + (count > 1 ? 's' : '') + ' selected';
  info.classList.add('selected');
}

function extractShortUrl(url) {
  if (!url) return '';
  if (/^https?:\/\//i.test(url)) {
    const m = url.match(/^https?:\/\/[^/]+\/(.*)/i);
    return m ? (m[1] || '/') : url;
  }
  // file:/// or other protocol:/// — return from the third slash onward
  const m = url.match(/^[^/]*\/\/(\/.+)/);
  return m ? m[1] : url;
}

// ── certificate check ────────────────────────────────────────────────────────

certLink.addEventListener('click', () => {
  chrome.tabs.create({ url: terminalBaseUrl() });
});

async function checkCertificate() {
  try {
    await fetch(terminalBaseUrl(), { mode: 'no-cors' });
    if (certBanner.classList.contains('visible')) {
      certBanner.classList.remove('visible');
      reloadTerminal(buildUrl(themeSelect.value));
    }
  } catch {
    certBanner.classList.add('visible');
  }
}

// Poll every 3 seconds so the terminal reconnects automatically once the
// user trusts the cert and returns to the extension
setInterval(checkCertificate, 3000);

// ── theme ────────────────────────────────────────────────────────────────────

function applyTheme(key) {
  const t = THEMES[key];
  const r = document.documentElement.style;
  r.setProperty('--term-bg',   t.background);
  r.setProperty('--ui-fg',     t.uiFg);
  r.setProperty('--ui-dim',    t.uiDim);
  r.setProperty('--ui-input',  t.uiInput);
  r.setProperty('--ui-border', t.uiBorder);
  r.setProperty('--ui-accent', t.uiAccent);
}

function buildUrl(key) {
  const { background, foreground, cursor, selection } = THEMES[key];
  return terminalBaseUrl() + '?theme=' + encodeURIComponent(JSON.stringify({ background, foreground, cursor, selection }));
}

function nudgeResize(iframe) {
  // Briefly shrink the iframe by 1px so xterm.js's ResizeObserver fires and
  // recalculates column count with the correct settled layout width.
  const w = iframe.offsetWidth;
  if (!w) return;
  iframe.style.width = (w - 1) + 'px';
  requestAnimationFrame(() => iframe.style.removeProperty('width'));
}

function reloadTerminal(url) {
  const next = document.createElement('iframe');
  next.id = 'terminal';
  next.src = url;
  next.addEventListener('load', () => nudgeResize(next), { once: true });
  terminal.replaceWith(next);
  terminal = next;
}


requestAnimationFrame(() => {
  terminal.src = buildUrl(themeSelect.value);
  terminal.addEventListener('load', () => {
    nudgeResize(terminal);
    setTimeout(() => nudgeResize(terminal), 250);
    checkCertificate();
  }, { once: true });
});

themeSelect.addEventListener('change', () => {
  applyTheme(themeSelect.value);
  reloadTerminal(buildUrl(themeSelect.value));
});

// ── open ─────────────────────────────────────────────────────────────────────

openBtn.addEventListener('click', () => {
  openPanel.classList.toggle('visible');
  urlInput.value = '';
  if (openPanel.classList.contains('visible')) urlInput.focus();
});

async function getActiveTab() {
  const windows = await chrome.windows.getAll({ windowTypes: ['normal'], populate: true });
  // Prefer a focused normal window that actually has tabs (the side panel is its
  // own window with no tabs, so `focused` alone can resolve to it).
  const win = windows.find(w => w.focused && w.tabs?.length > 0)
           || windows.find(w => w.tabs?.length > 0);
  if (!win) return null;
  return win.tabs.find(t => t.active) || null;
}

async function openUrl() {
  let url = urlInput.value.trim();
  if (!url) return;
  if (!/^(https?|file):\/\//i.test(url)) url = 'https://' + url;
  await chrome.tabs.create({ url });
  openPanel.classList.remove('visible');
}

urlGo.addEventListener('click', openUrl);
urlInput.addEventListener('keydown', e => { if (e.key === 'Enter') openUrl(); });

// ── inspector ────────────────────────────────────────────────────────────────

async function sendToTab(tabId, msg) {
  try {
    const resp = await chrome.tabs.sendMessage(tabId, msg);
    // If the listener is from an invalidated extension context it silently
    // swallows the message and returns undefined instead of { ok: true }.
    if (!resp?.ok) throw new Error('no ack');
  } catch {
    try {
      await chrome.scripting.executeScript({
        target: { tabId },
        func: () => { delete window.__extPickerLoaded; },
      });
      await chrome.scripting.executeScript({ target: { tabId }, files: ['content_script.js'] });
      await chrome.tabs.sendMessage(tabId, msg);
    } catch {
      info.textContent = 'Cannot inspect this page';
      info.classList.remove('copied');
      picking = false;
      pickBtn.classList.remove('active');
      pickBtn.textContent = 'Select';
    }
  }
}

pickBtn.addEventListener('click', async () => {
  picking = !picking;
  pickBtn.classList.toggle('active', picking);
  pickBtn.textContent = picking ? 'Cancel' : 'Select';
  const tab = await getActiveTab();
  if (tab) await sendToTab(tab.id, { type: picking ? 'activate' : 'deactivate' });
});

chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === 'elementPicked') {
    selectedTags.push(msg.tag);
    selectedContent += (selectedContent ? '\n' : '') + msg.html;
    updateInfoDisplay();
  }
});

clearBtn.addEventListener('click', () => {
  selectedContent = '';
  selectedTags    = [];
  updateInfoDisplay();
});

// ── config dialog ────────────────────────────────────────────────────────────

function updateCfgPreview() {
  const h = configHostEl.value.trim() || 'localhost';
  cfgTermUrl.textContent   = `https://${h}:${TERM_PORT}`;
  cfgHelperUrl.textContent = `https://${h}:${HELPER_PORT}`;
}

configBtn.addEventListener('click', () => {
  configHostEl.value = configHost;
  updateCfgPreview();
  configDialog.classList.toggle('visible');
});

configHostEl.addEventListener('input', updateCfgPreview);

configCancel.addEventListener('click', () => {
  configDialog.classList.remove('visible');
});

configSave.addEventListener('click', () => {
  const newHost = configHostEl.value.trim() || 'localhost';
  configHost = newHost;
  localStorage.setItem('vce-host', configHost);
  configDialog.classList.remove('visible');
  applyTheme(themeSelect.value);
  reloadTerminal(buildUrl(themeSelect.value));
});

// ── send to terminal (via local tmux helper on port 7682) ────────────────────

async function doSend() {
  let text = sendInput.value.trim();
  if (!text) return;
  sendBtn.disabled = true;
  try {
    if (selectedContent) {
      const tab = await getActiveTab();
      const shortUrl = extractShortUrl(tab?.url || '');
      text = `This request is about page/file: ${shortUrl}, specifically about the following parts:\n${selectedContent}\n\n${text}`;
    }
    await fetch(helperBaseUrl(), { method: 'POST', body: text });
    sendInput.value = '';
    if (selectedContent) {
      selectedContent = '';
      selectedTags    = [];
      updateInfoDisplay();
    }
  } catch {
    sendInput.placeholder = 'Helper not running — see instructions';
    setTimeout(() => { sendInput.placeholder = 'Send to terminal…'; }, 3000);
  } finally {
    sendBtn.disabled = false;
    sendInput.focus();
  }
}

sendBtn.addEventListener('click', doSend);
sendInput.addEventListener('keydown', e => {
  if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); doSend(); }
});
