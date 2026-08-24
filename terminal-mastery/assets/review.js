/* review.js - spaced, interleaved recall over the whole question bank.
   Leitner boxes: get one right and it moves up a box and comes back later;
   get it wrong and it drops to box 1 and comes back tomorrow.

   Spacing and interleaving are the two things that turn "I recognised that"
   into "I can retrieve that under pressure". A lesson quiz only proves the
   first. This page is the second. */

(function (global) {
  'use strict';

  var KEY = 'review-schedule-v1';
  var DAYS = [0, 1, 2, 4, 8, 16, 32];        // interval per box, box 1..6
  var MS = 86400000;

  function today() { return Math.floor(Date.now() / MS); }

  function load() {
    try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) { return {}; }
  }
  function save(s) { localStorage.setItem(KEY, JSON.stringify(s)); }

  function buildPool(bank, meta) {
    var pool = [];
    Object.keys(bank).forEach(function (lk) {
      bank[lk].forEach(function (q, i) {
        pool.push({ id: lk + ':' + i, lesson: lk, meta: meta[lk], q: q });
      });
    });
    return pool;
  }

  function due(pool, sched) {
    var t = today();
    return pool.filter(function (item) {
      var s = sched[item.id];
      return !s || s.due <= t;
    });
  }

  // Interleave: never two from the same lesson back to back when avoidable.
  function interleave(items) {
    var byLesson = {};
    items.forEach(function (it) { (byLesson[it.lesson] = byLesson[it.lesson] || []).push(it); });
    Object.keys(byLesson).forEach(function (k) { shuffle(byLesson[k]); });
    var out = [], keys = Object.keys(byLesson), last = null, guard = 0;
    while (out.length < items.length && guard++ < 10000) {
      var avail = keys.filter(function (k) { return byLesson[k].length; });
      if (!avail.length) break;
      var pick = avail.filter(function (k) { return k !== last; });
      var k2 = (pick.length ? pick : avail)[Math.floor(Math.random() * (pick.length ? pick.length : avail.length))];
      out.push(byLesson[k2].shift());
      last = k2;
    }
    return out;
  }

  function shuffle(a) {
    for (var i = a.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var t = a[i]; a[i] = a[j]; a[j] = t;
    }
    return a;
  }

  function grade(sched, id, correct) {
    var s = sched[id] || { box: 1 };
    s.box = correct ? Math.min(6, (s.box || 1) + 1) : 1;
    s.due = today() + DAYS[s.box];
    s.seen = (s.seen || 0) + 1;
    sched[id] = s;
    save(sched);
    return s;
  }

  function render(mountId, opts) {
    var mount = document.getElementById(mountId);
    if (!mount) return;

    var pool = buildPool(global.QBANK, global.QMETA);
    var sched = load();
    var queue = interleave(due(pool, sched));
    if (opts && opts.all) queue = interleave(pool.slice());

    var i = 0, right = 0, answered = 0;

    function boxCounts() {
      var c = [0, 0, 0, 0, 0, 0, 0];
      pool.forEach(function (it) { c[(sched[it.id] && sched[it.id].box) || 0]++; });
      return c;
    }

    function summary() {
      var c = boxCounts(), learned = pool.length - c[0];
      var solid = c[4] + c[5] + c[6];
      return { total: pool.length, learned: learned, solid: solid, c: c };
    }

    function head() {
      var s = summary();
      return '<div class="rvhead">' +
        '<span class="rvcount">' + queue.length + ' due</span>' +
        '<span class="rvbars">' +
          [1,2,3,4,5,6].map(function (b) {
            return '<i class="b' + b + '" style="flex:' + (s.c[b] || 0) + '" title="box ' + b + ': ' + (s.c[b] || 0) + '"></i>';
          }).join('') +
          '<i class="b0" style="flex:' + s.c[0] + '" title="not seen: ' + s.c[0] + '"></i>' +
        '</span>' +
        '<span class="rvmeta">' + s.solid + ' / ' + s.total + ' solid</span>' +
        '</div>';
    }

    function done() {
      var s = summary();
      mount.innerHTML = head() +
        '<div class="rvdone">' +
        (answered
          ? '<strong>' + right + ' / ' + answered + '</strong> this session.<br>' +
            'Nothing else is due. Come back tomorrow - that gap is the point.'
          : '<strong>Nothing due right now.</strong><br>Spacing is doing its job. ' +
            'Come back tomorrow, or drill everything anyway.') +
        '<br><button class="rvall">review all ' + s.total + ' anyway</button>' +
        '</div>';
      mount.querySelector('.rvall').addEventListener('click', function () {
        render(mountId, { all: true });
      });
    }

    function step() {
      if (i >= queue.length) { done(); return; }
      var item = queue[i], q = item.q, m = item.meta;
      var order = shuffle(q.a.map(function (text, idx) { return { text: text, idx: idx }; }));

      mount.innerHTML = head() +
        '<div class="rvcard">' +
        '  <div class="rvtag">' + (i + 1) + ' / ' + queue.length +
             ' &middot; <a href="lessons/' + m.href + '">' + String(m.n).padStart(2, '0') + ' ' + m.title + '</a></div>' +
        '  <p class="rvq"></p>' +
        '  <div class="rvopts"></div>' +
        '  <div class="rvwhy"></div>' +
        '</div>';

      mount.querySelector('.rvq').textContent = q.q;
      var opts = mount.querySelector('.rvopts');
      var why = mount.querySelector('.rvwhy');
      var locked = false;

      order.forEach(function (o) {
        var b = document.createElement('button');
        b.textContent = o.text;
        b.addEventListener('click', function () {
          if (locked) return;
          locked = true;
          answered++;
          var ok = o.idx === q.correct;
          if (ok) right++;
          var s = grade(sched, item.id, ok);
          Array.prototype.forEach.call(opts.children, function (el, j) {
            el.disabled = true;
            if (order[j].idx === q.correct) el.classList.add('right');
            else if (order[j].idx === o.idx) el.classList.add('wrong');
          });
          why.innerHTML = '<span class="rvverdict ' + (ok ? 'good' : 'bad') + '">' +
            (ok ? 'box ' + s.box + ' - back in ' + DAYS[s.box] + ' day' + (DAYS[s.box] === 1 ? '' : 's')
                : 'back to box 1 - again tomorrow') +
            '</span>' + q.why +
            '<button class="rvnext">next</button>';
          why.classList.add('show');
          var nx = why.querySelector('.rvnext');
          nx.addEventListener('click', function () { i++; step(); });
          nx.focus();
        });
        opts.appendChild(b);
      });
    }

    step();
  }

  global.renderReview = render;
  global.resetReview = function () { localStorage.removeItem(KEY); };

})(window);
