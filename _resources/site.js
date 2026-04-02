document.addEventListener('DOMContentLoaded', function() {
  // Syntax highlighting
  hljs.highlightAll();

  // Lazy load images
  document.querySelectorAll('.markdown img').forEach(function(img) {
    img.loading = 'lazy';
    img.decoding = 'async';
  });

  // Copy button for code blocks
  document.querySelectorAll('.markdown pre').forEach(function(pre) {
    var wrapper = document.createElement('div');
    wrapper.className = 'code-block-wrapper';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);
    var btn = document.createElement('button');
    btn.textContent = 'Copy';
    btn.className = 'copy-btn';
    btn.addEventListener('click', function() {
      var code = pre.querySelector('code');
      var text = code ? code.textContent : pre.textContent;
      navigator.clipboard.writeText(text).then(function() {
        btn.textContent = 'Copied!';
        setTimeout(function() { btn.textContent = 'Copy'; }, 2000);
      });
    });
    wrapper.appendChild(btn);
  });

  // Style blockquote attributions (paragraphs starting with em dash)
  document.querySelectorAll('.markdown blockquote p').forEach(function(p) {
    var text = p.textContent.trim();
    if (text.charAt(0) === '\u2014') {
      p.classList.add('blockquote-attribution');
    }
  });

  // Style stage pipeline items
  document.querySelectorAll('.markdown p').forEach(function(p) {
    var strong = p.querySelector('strong');
    if (strong && /^Stage \d/.test(strong.textContent)) {
      p.classList.add('stage-item');
    }
  });

  // Wrap tables in scrollable container
  document.querySelectorAll('.markdown table').forEach(function(table) {
    var wrapper = document.createElement('div');
    wrapper.className = 'table-wrapper';
    table.parentNode.insertBefore(wrapper, table);
    wrapper.appendChild(table);
  });

  // Make headers hash-linkable
  document.querySelectorAll('.markdown h1[id], .markdown h2[id], .markdown h3[id], .markdown h4[id]').forEach(function(h) {
    var link = document.createElement('a');
    link.href = '#' + h.id;
    link.className = 'header-anchor';
    link.setAttribute('aria-hidden', 'true');
    link.textContent = '#';
    h.insertBefore(link, h.firstChild);
  });
});
