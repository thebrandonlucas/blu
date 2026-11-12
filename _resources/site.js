/*
 * The site's JavaScript. The pages are site.roc's; the roc-signals app in
 * signals/ draws them in the browser and decides everything about them. This
 * file only does what the app cannot:
 *
 * - mounts the app (#app names its module and runtime) beside the static
 *   page (#static);
 * - defines <blu-markup>, which shows a document's HTML (its data-html),
 *   highlights its code, adds copy buttons, and hands a click on a link to
 *   another page of the site back to the app as a change event;
 * - defines <blu-ready>, which the app draws once it shows the page, and
 *   which takes the static page away.
 *
 * Without the app (no JavaScript, no WebAssembly, or the data could not be
 * read), the static page stays and gets the same treatment of its code,
 * tables and images.
 */
(function () {
  'use strict';

  // Kaifiles are close enough to Nix for useful highlighting until they have
  // a dedicated highlight.js grammar.
  if (window.hljs) {
    hljs.registerAliases(['kaifile'], { languageName: 'nix' });
  }

  // What site.js has always done to a document's text, now to any element
  // holding one.
  function enhance(root) {
    if (window.hljs) {
      root.querySelectorAll('pre code').forEach(function (code) { hljs.highlightElement(code); });
    }

    root.querySelectorAll('img').forEach(function (img) {
      img.loading = 'lazy';
      img.decoding = 'async';
    });

    // Copy button for code blocks
    root.querySelectorAll('pre').forEach(function (pre) {
      var wrapper = document.createElement('div');
      wrapper.className = 'code-block-wrapper';
      pre.parentNode.insertBefore(wrapper, pre);
      wrapper.appendChild(pre);
      var btn = document.createElement('button');
      btn.textContent = 'Copy';
      btn.className = 'copy-btn';
      btn.addEventListener('click', function () {
        var code = pre.querySelector('code');
        var text = code ? code.textContent : pre.textContent;
        navigator.clipboard.writeText(text).then(function () {
          btn.textContent = 'Copied!';
          setTimeout(function () { btn.textContent = 'Copy'; }, 2000);
        });
      });
      wrapper.appendChild(btn);
    });

    // Style stage pipeline items
    root.querySelectorAll('p').forEach(function (p) {
      var strong = p.querySelector('strong');
      if (strong && /^Stage \d/.test(strong.textContent)) {
        p.classList.add('stage-item');
      }
    });

    // Wrap tables in scrollable container
    root.querySelectorAll('table').forEach(function (table) {
      var wrapper = document.createElement('div');
      wrapper.className = 'table-wrapper';
      table.parentNode.insertBefore(wrapper, table);
      wrapper.appendChild(table);
    });
  }

  // A link the app can follow without loading a page: to a page of this site
  // (not a file or a feed), and not to a place on a page, which the browser
  // scrolls to.
  function inside(link) {
    if (link.origin !== location.origin || link.target || link.hasAttribute('download')) return false;
    if (/\.[a-z0-9]+$/i.test(link.pathname) && !/\.html$/.test(link.pathname)) return false;
    return !link.hash;
  }

  customElements.define('blu-markup', class extends HTMLElement {
    static observedAttributes = ['data-html'];

    constructor() {
      super();
      this.value = '';
      this.addEventListener('click', (event) => {
        if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        const link = event.target.closest('a[href]');
        if (!link || !this.contains(link) || !inside(link)) return;
        event.preventDefault();
        this.value = link.pathname + link.search;
        this.dispatchEvent(new Event('change', { bubbles: true }));
      });
    }

    attributeChangedCallback(name, previous, html) {
      if (html === previous) return;
      this.innerHTML = html || '';
      enhance(this);
    }
  });

  // The app's page is the static one, so the reader stays where they were:
  // at the same height, or at the place the address names.
  customElements.define('blu-ready', class extends HTMLElement {
    connectedCallback() {
      const page = document.getElementById('static');
      if (!page) return;
      const y = window.scrollY;
      const hash = decodeURIComponent(location.hash.slice(1));
      page.remove();
      const target = hash && document.getElementById(hash);
      if (target) target.scrollIntoView();
      else window.scrollTo(0, y);
    }
  });

  function start() {
    // Keep copyright years current
    document.querySelectorAll('[data-current-year]').forEach(function (year) {
      year.textContent = new Date().getFullYear();
    });

    const page = document.getElementById('static');
    if (page) page.querySelectorAll('.markdown, .quotation blockquote').forEach(enhance);

    const node = document.getElementById('app');
    if (!node || typeof WebAssembly !== 'object') return;
    import(node.dataset.runtime)
      .then((runtime) => runtime.mountRocEngineApp({ wasmUrl: node.dataset.wasm, root: node, onFault: console.error }))
      .catch(console.error);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
