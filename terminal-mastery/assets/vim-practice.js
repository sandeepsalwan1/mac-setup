/* vim-practice.js - an offline Vim motion trainer that listens to real keystrokes.
   Two modes:
     motion   - a target is highlighted; reach it in as few keys as possible.
                Par is computed by breadth-first search over the motion graph,
                so it is the true optimum, not a guess.
     compose  - "make this edit"; you type the operator+object and it is checked.

   No dependencies, no network. Motion semantics follow Vim's, close enough that
   the muscle memory transfers. Where this simplifies, it says so on the page. */

(function (global) {
  'use strict';

  // ---------- motion engine ----------

  var WORD = /[A-Za-z0-9_]/;

  function cls(ch) {
    if (ch === undefined || ch === ' ' || ch === '\t') return 0; // blank
    if (WORD.test(ch)) return 1;                                 // word char
    return 2;                                                    // punctuation
  }

  function clampCol(lines, r, c) {
    var len = lines[r].length;
    return Math.max(0, Math.min(c, Math.max(0, len - 1)));
  }

  // Flatten to an absolute index so w/b/e can cross lines like Vim's do.
  function toFlat(lines, r, c) {
    var n = 0;
    for (var i = 0; i < r; i++) n += lines[i].length + 1;
    return n + c;
  }
  function fromFlat(lines, n) {
    for (var r = 0; r < lines.length; r++) {
      var len = lines[r].length + 1;
      if (n < len) return { r: r, c: Math.min(n, Math.max(0, lines[r].length - 1)) };
      n -= len;
    }
    var last = lines.length - 1;
    return { r: last, c: Math.max(0, lines[last].length - 1) };
  }
  function flatText(lines) { return lines.join('\n'); }

  function wordFwd(lines, r, c, big) {
    var t = flatText(lines), i = toFlat(lines, r, c), n = t.length;
    var k = big ? function (ch) { return cls(ch) === 0 ? 0 : 1; } : cls;
    var start = k(t[i]);
    if (start !== 0) { while (i < n && k(t[i]) === start) i++; }
    while (i < n && k(t[i]) === 0) i++;
    return fromFlat(lines, Math.min(i, n - 1));
  }

  function wordBack(lines, r, c, big) {
    var t = flatText(lines), i = toFlat(lines, r, c);
    var k = big ? function (ch) { return cls(ch) === 0 ? 0 : 1; } : cls;
    i--;
    while (i > 0 && k(t[i]) === 0) i--;
    if (i <= 0) return { r: 0, c: 0 };
    var here = k(t[i]);
    while (i > 0 && k(t[i - 1]) === here) i--;
    return fromFlat(lines, Math.max(i, 0));
  }

  function wordEnd(lines, r, c, big) {
    var t = flatText(lines), i = toFlat(lines, r, c), n = t.length;
    var k = big ? function (ch) { return cls(ch) === 0 ? 0 : 1; } : cls;
    i++;
    while (i < n && k(t[i]) === 0) i++;
    if (i >= n) return fromFlat(lines, n - 1);
    var here = k(t[i]);
    while (i + 1 < n && k(t[i + 1]) === here) i++;
    return fromFlat(lines, i);
  }

  function firstNonBlank(lines, r) {
    var m = lines[r].match(/\S/);
    return m ? m.index : 0;
  }

  function paraFwd(lines, r) {
    for (var i = r + 1; i < lines.length; i++) if (lines[i].trim() === '') return i;
    return lines.length - 1;
  }
  function paraBack(lines, r) {
    for (var i = r - 1; i >= 0; i--) if (lines[i].trim() === '') return i;
    return 0;
  }

  var PAIRS = { '(': ')', '[': ']', '{': '}' };
  var RPAIRS = { ')': '(', ']': '[', '}': '{' };

  function matchPair(lines, r, c) {
    var line = lines[r], i = c;
    while (i < line.length && !PAIRS[line[i]] && !RPAIRS[line[i]]) i++;
    if (i >= line.length) return null;
    var ch = line[i];
    var t = flatText(lines), start = toFlat(lines, r, i);
    if (PAIRS[ch]) {
      var depth = 0;
      for (var j = start; j < t.length; j++) {
        if (t[j] === ch) depth++;
        else if (t[j] === PAIRS[ch]) { depth--; if (!depth) return fromFlat(lines, j); }
      }
    } else {
      var open = RPAIRS[ch], d = 0;
      for (var k2 = start; k2 >= 0; k2--) {
        if (t[k2] === ch) d++;
        else if (t[k2] === open) { d--; if (!d) return fromFlat(lines, k2); }
      }
    }
    return null;
  }

  function findChar(lines, r, c, ch, dir, till) {
    var line = lines[r];
    if (dir > 0) {
      for (var i = c + 1; i < line.length; i++) {
        if (line[i] === ch) return { r: r, c: till ? i - 1 : i };
      }
    } else {
      for (var j = c - 1; j >= 0; j--) {
        if (line[j] === ch) return { r: r, c: till ? j + 1 : j };
      }
    }
    return null;
  }

  /* Apply one resolved motion. `m` is { key, count, arg }.
     Returns a new {r,c} or null when the motion cannot move. */
  function apply(lines, pos, m) {
    var r = pos.r, c = pos.c, n = m.count || 1, i;
    switch (m.key) {
      case 'h': return { r: r, c: Math.max(0, c - n) };
      case 'l': return { r: r, c: clampCol(lines, r, c + n) };
      case 'j': i = Math.min(lines.length - 1, r + n); return { r: i, c: clampCol(lines, i, c) };
      case 'k': i = Math.max(0, r - n); return { r: i, c: clampCol(lines, i, c) };
      case '0': return { r: r, c: 0 };
      case '^': return { r: r, c: firstNonBlank(lines, r) };
      case '$': return { r: r, c: Math.max(0, lines[r].length - 1) };
      case 'w': case 'W':
        for (i = 0; i < n; i++) { var a = wordFwd(lines, r, c, m.key === 'W'); r = a.r; c = a.c; }
        return { r: r, c: c };
      case 'b': case 'B':
        for (i = 0; i < n; i++) { var b2 = wordBack(lines, r, c, m.key === 'B'); r = b2.r; c = b2.c; }
        return { r: r, c: c };
      case 'e': case 'E':
        for (i = 0; i < n; i++) { var e2 = wordEnd(lines, r, c, m.key === 'E'); r = e2.r; c = e2.c; }
        return { r: r, c: c };
      case 'gg': i = m.count ? Math.min(lines.length, n) - 1 : 0; return { r: i, c: firstNonBlank(lines, i) };
      case 'G':  i = m.count ? Math.min(lines.length, n) - 1 : lines.length - 1; return { r: i, c: firstNonBlank(lines, i) };
      case '{': for (i = 0; i < n; i++) r = paraBack(lines, r); return { r: r, c: clampCol(lines, r, 0) };
      case '}': for (i = 0; i < n; i++) r = paraFwd(lines, r);  return { r: r, c: clampCol(lines, r, 0) };
      case '%': return matchPair(lines, r, c);
      case 'f': case 'F': case 't': case 'T': {
        // counted find: 3fx lands on the third x. Each hop searches from the
        // previous landing spot, and `till` only trims the final one, as in Vim.
        var dir = (m.key === 'f' || m.key === 't') ? 1 : -1;
        var till = (m.key === 't' || m.key === 'T');
        var pr = r, pc = c, hop;
        for (i = 0; i < n; i++) {
          hop = findChar(lines, pr, pc, m.arg, dir, false);
          if (!hop) return null;
          pr = hop.r; pc = hop.c;
        }
        return till ? { r: pr, c: pc - dir } : { r: pr, c: pc };
      }
      default: return null;
    }
  }

  // Every edge the par search may use, with its true keystroke cost.
  function edges(lines) {
    var out = [], simple = ['h','j','k','l','w','b','e','W','B','E','0','^','$','{','}','%','G'];
    simple.forEach(function (key) { out.push({ key: key, cost: 1 }); });
    out.push({ key: 'gg', cost: 2 });
    // counted motions: `12j` costs 3 keys
    ['j','k','w','b','e','l','h','G'].forEach(function (key) {
      for (var n = 2; n <= 40; n++) out.push({ key: key, count: n, cost: String(n).length + 1 });
    });
    // f/F/t/T over the characters that actually occur
    var chars = {};
    lines.forEach(function (l) { for (var i = 0; i < l.length; i++) if (l[i] !== ' ') chars[l[i]] = 1; });
    Object.keys(chars).forEach(function (ch) {
      ['f','F','t','T'].forEach(function (key) {
        out.push({ key: key, arg: ch, cost: 2 });
        // 2fx and 3fx are realistic; beyond that nobody counts occurrences.
        out.push({ key: key, arg: ch, count: 2, cost: 3 });
        out.push({ key: key, arg: ch, count: 3, cost: 3 });
      });
    });
    return out;
  }

  /* True minimum keystrokes from start to target, by uniform-cost BFS. */
  function par(lines, start, target) {
    var E = edges(lines);
    var key = function (p) { return p.r + ':' + p.c; };
    var best = {}, frontier = [{ pos: start, cost: 0 }];
    best[key(start)] = 0;
    var goal = key(target), guard = 0;
    while (frontier.length && guard++ < 60000) {
      frontier.sort(function (a, b) { return a.cost - b.cost; });
      var cur = frontier.shift();
      if (key(cur.pos) === goal) return cur.cost;
      if (cur.cost > (best[key(cur.pos)] !== undefined ? best[key(cur.pos)] : Infinity)) continue;
      for (var i = 0; i < E.length; i++) {
        var np = apply(lines, cur.pos, E[i]);
        if (!np) continue;
        var nk = key(np), nc = cur.cost + E[i].cost;
        if (best[nk] === undefined || nc < best[nk]) { best[nk] = nc; frontier.push({ pos: np, cost: nc }); }
      }
    }
    return best[goal] !== undefined ? best[goal] : null;
  }

  /* Pure key reducer: given the pending state and one key, decide what happens.
     Kept free of DOM so it can be unit tested. Returns:
       { action: 'motion'|'buffer'|'reset'|'unknown'|'abort',
         motion, cost, pending, count } */
  var KNOWN = 'hjklwbeWBE0^${}%G';

  function reduceKey(state, k) {
    var pending = state.pending || '', count = state.count || '';

    if (k === 'Escape') return { action: 'reset', pending: '', count: '' };

    // second half of f/F/t/T, or the second g of gg
    if (pending) {
      if (pending === 'g') {
        if (k !== 'g') return { action: 'abort', pending: '', count: '' };
        return {
          action: 'motion', pending: '', count: '',
          motion: { key: 'gg', count: count ? +count : 0 },
          cost: 2 + count.length
        };
      }
      if (k.length !== 1) return { action: 'abort', pending: '', count: '' };
      return {
        action: 'motion', pending: '', count: '',
        motion: { key: pending, arg: k, count: count ? +count : 1 },
        cost: 2 + count.length
      };
    }

    // a leading 0 is the motion; a later 0 is part of a count
    if (/[1-9]/.test(k) || (k === '0' && count)) {
      return { action: 'buffer', pending: '', count: count + k };
    }

    if (k.length === 1 && 'fFtT'.indexOf(k) >= 0) return { action: 'buffer', pending: k, count: count };
    if (k === 'g') return { action: 'buffer', pending: 'g', count: count };

    if (k.length === 1 && KNOWN.indexOf(k) >= 0) {
      return {
        action: 'motion', pending: '', count: '',
        motion: { key: k, count: count ? +count : undefined },
        cost: 1 + count.length
      };
    }

    return { action: 'unknown', pending: '', count: '' };
  }

  // ---------- motion trainer UI ----------

  function motionTrainer(mountId, rounds) {
    var mount = document.getElementById(mountId);
    if (!mount) return;

    var idx = 0, cursor = null, target = null, used = 0, thisPar = null;
    var pending = '', countBuf = '', totalUsed = 0, totalPar = 0, solved = 0;

    mount.innerHTML =
      '<div class="vp">' +
      '  <div class="vphead">' +
      '    <span class="vptask"></span>' +
      '    <span class="vpstat"></span>' +
      '  </div>' +
      '  <pre class="vpbuf" tabindex="0"></pre>' +
      '  <div class="vpfoot">' +
      '    <span class="vpkeys"></span>' +
      '    <span class="vpmsg"></span>' +
      '  </div>' +
      '  <div class="vphint"></div>' +
      '</div>';

    var buf   = mount.querySelector('.vpbuf');
    var task  = mount.querySelector('.vptask');
    var stat  = mount.querySelector('.vpstat');
    var keysE = mount.querySelector('.vpkeys');
    var msg   = mount.querySelector('.vpmsg');
    var hint  = mount.querySelector('.vphint');

    function load(i) {
      var R = rounds[i];
      cursor = { r: R.from[0], c: R.from[1] };
      target = { r: R.to[0], c: R.to[1] };
      used = 0; pending = ''; countBuf = '';
      thisPar = par(R.lines, cursor, target);
      task.textContent = R.task;
      hint.innerHTML = R.hint ? 'Allowed here: ' + R.hint : '';
      msg.textContent = '';
      msg.className = 'vpmsg';
      draw();
    }

    function draw() {
      var R = rounds[idx], out = '';
      for (var r = 0; r < R.lines.length; r++) {
        var line = R.lines[r].length ? R.lines[r] : ' ';
        var row = '';
        for (var c = 0; c < line.length; c++) {
          var ch = line[c] === ' ' ? ' ' : esc(line[c]);
          var isC = (r === cursor.r && c === cursor.c);
          var isT = (r === target.r && c === target.c);
          if (isC && isT) row += '<span class="vpcur vphit">' + ch + '</span>';
          else if (isC)   row += '<span class="vpcur">' + ch + '</span>';
          else if (isT)   row += '<span class="vptgt">' + ch + '</span>';
          else            row += ch;
        }
        var num = String(Math.abs(r - cursor.r) || (r + 1)).padStart(3, ' ');
        out += '<span class="vpnum">' + num + '</span>  ' + row + '\n';
      }
      buf.innerHTML = out;
      stat.textContent = 'round ' + (idx + 1) + ' / ' + rounds.length +
                         '   keys ' + used + (thisPar ? '   par ' + thisPar : '');
      keysE.textContent = (countBuf + pending) || '';
    }

    function esc(s) {
      return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    function win() {
      solved++; totalUsed += used; totalPar += thisPar || used;
      var verdict = used === thisPar ? 'optimal'
                  : used <= thisPar + 1 ? 'good'
                  : 'got there';
      msg.textContent = verdict + ' - ' + used + ' keys, par ' + thisPar;
      msg.className = 'vpmsg ' + (used === thisPar ? 'good' : used <= thisPar + 1 ? 'ok' : 'meh');
      setTimeout(function () {
        idx++;
        if (idx >= rounds.length) {
          mount.querySelector('.vp').innerHTML =
            '<div class="vpdone"><strong>Done.</strong> ' + solved + ' targets, ' +
            totalUsed + ' keys against a par of ' + totalPar + '.' +
            '<br><button class="vpagain">run it again</button></div>';
          mount.querySelector('.vpagain').addEventListener('click', function () {
            idx = 0; totalUsed = 0; totalPar = 0; solved = 0;
            motionTrainer(mountId, rounds);
            document.getElementById(mountId).querySelector('.vpbuf').focus();
          });
          return;
        }
        load(idx);
      }, 900);
    }

    buf.addEventListener('keydown', function (ev) {
      if (ev.metaKey || ev.ctrlKey || ev.altKey) return;
      if (ev.key === 'Tab') return;
      ev.preventDefault();

      var res = reduceKey({ pending: pending, count: countBuf }, ev.key);
      pending = res.pending;
      countBuf = res.count;

      if (res.action === 'motion') { step(res.motion, res.cost); return; }
      if (res.action === 'unknown') {
        msg.textContent = 'not a motion this trainer knows: ' + ev.key;
        msg.className = 'vpmsg meh';
      }
      draw();
    });

    function step(m, cost) {
      if (!m) { draw(); return; }
      var R = rounds[idx];
      var np = apply(R.lines, cursor, m);
      used += cost;
      if (np) cursor = np;
      draw();
      if (cursor.r === target.r && cursor.c === target.c) win();
      else if (!np) { msg.textContent = 'that motion cannot move from here'; msg.className = 'vpmsg meh'; }
    }

    buf.addEventListener('focus', function () { mount.querySelector('.vp').classList.add('focused'); });
    buf.addEventListener('blur',  function () { mount.querySelector('.vp').classList.remove('focused'); });

    load(0);
  }

  // ---------- compose trainer (operator + text object) ----------

  function composeTrainer(mountId, items) {
    var mount = document.getElementById(mountId);
    if (!mount) return;
    var i = 0, right = 0;

    function render() {
      if (i >= items.length) {
        mount.innerHTML = '<div class="vpdone"><strong>Done.</strong> ' + right + ' / ' +
          items.length + ' first try.</div>';
        return;
      }
      var it = items[i];
      mount.innerHTML =
        '<div class="vp compose">' +
        '  <div class="vphead"><span class="vptask">' + it.task + '</span>' +
        '  <span class="vpstat">' + (i + 1) + ' / ' + items.length + '</span></div>' +
        '  <pre class="vpbuf static">' + it.code.replace(/&/g,'&amp;').replace(/</g,'&lt;') + '</pre>' +
        '  <div class="vprow"><input class="vpin" placeholder="type the keys, e.g. ci&quot;" autocomplete="off" spellcheck="false">' +
        '  <button class="vpgo">check</button></div>' +
        '  <div class="vpmsg"></div>' +
        '</div>';
      var input = mount.querySelector('.vpin');
      var out = mount.querySelector('.vpmsg');
      var tries = 0;

      function check() {
        var v = input.value.trim();
        if (!v) return;
        var ok = it.answers.some(function (a) { return a === v; });
        tries++;
        if (ok) {
          if (tries === 1) right++;
          out.textContent = 'yes - ' + it.why;
          out.className = 'vpmsg good';
          setTimeout(function () { i++; render(); mountFocus(); }, 1400);
        } else {
          out.textContent = tries >= 2
            ? 'not quite. Answer: ' + it.answers[0] + ' - ' + it.why
            : 'not quite. Try again.';
          out.className = 'vpmsg meh';
          if (tries >= 2) setTimeout(function () { i++; render(); mountFocus(); }, 2200);
        }
      }
      mount.querySelector('.vpgo').addEventListener('click', check);
      input.addEventListener('keydown', function (e) { if (e.key === 'Enter') check(); });
    }

    function mountFocus() {
      var el = mount.querySelector('.vpin');
      if (el) el.focus();
    }

    render();
  }

  global.vimMotionTrainer = motionTrainer;
  global.vimComposeTrainer = composeTrainer;
  global.vimPar = par;
  global.vimApply = apply;
  global.vimReduceKey = reduceKey;

})(window);
