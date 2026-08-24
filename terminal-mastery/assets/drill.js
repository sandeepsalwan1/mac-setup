/* drill.js - the action-first lesson component.
   A lesson is a sequence of things you DO, each with a checkable result.
   Offline, no dependencies.

   Step shapes:
     { section: 'Heading' }                       a divider
     { do: 'i',            see: 'what happens' }  a keystroke
     { do: 'nvim x.txt', cmd: true, see: '...' }  a shell command (gets a copy button)
     { ..., note: 'one line of why' }             optional
     { ..., warn: 'the trap here' }               optional

   Progress is per-page and saved, so you can stop mid-drill and come back. */

function renderDrill(mountId, steps) {
  var mount = document.getElementById(mountId);
  if (!mount) return;

  var KEY = 'drill:' + location.pathname.split('/').pop();
  var state = {};
  try { state = JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) { state = {}; }
  var save = function () { localStorage.setItem(KEY, JSON.stringify(state)); };

  var doable = steps.filter(function (s) { return !s.section; });

  var bar = document.createElement('div');
  bar.className = 'dbar';
  bar.innerHTML = '<div class="dtrack"><div class="dfill"></div></div><span class="dpct"></span>';
  mount.appendChild(bar);
  var fill = bar.querySelector('.dfill');
  var pct = bar.querySelector('.dpct');

  function repaint() {
    var done = doable.filter(function (_, i) { return state[i]; }).length;
    fill.style.width = (done / doable.length * 100) + '%';
    pct.textContent = done + ' / ' + doable.length;
    if (done === doable.length) bar.classList.add('complete');
    else bar.classList.remove('complete');
  }

  var n = 0;
  steps.forEach(function (s) {
    if (s.section) {
      var h = document.createElement('h3');
      h.className = 'dsection';
      h.textContent = s.section;
      mount.appendChild(h);
      return;
    }

    var idx = n++;
    var row = document.createElement('div');
    row.className = 'dstep';

    var box = document.createElement('button');
    box.className = 'dbox';
    box.type = 'button';
    box.setAttribute('aria-label', 'mark step done');
    box.textContent = '✓';

    var body = document.createElement('div');
    body.className = 'dbody';

    var act = document.createElement('div');
    act.className = 'dact';
    var code = document.createElement('code');
    code.className = s.cmd ? 'dcmd' : 'dkey';
    code.textContent = s.do;
    act.appendChild(code);

    if (s.cmd) {
      var cp = document.createElement('button');
      cp.className = 'dcopy';
      cp.type = 'button';
      cp.textContent = 'copy';
      cp.addEventListener('click', function (e) {
        e.stopPropagation();
        navigator.clipboard.writeText(s.do).then(function () {
          cp.textContent = 'copied';
          setTimeout(function () { cp.textContent = 'copy'; }, 1200);
        }).catch(function () { cp.textContent = 'select it'; });
      });
      act.appendChild(cp);
    }
    body.appendChild(act);

    if (s.see) {
      var see = document.createElement('div');
      see.className = 'dsee';
      see.innerHTML = s.see;
      body.appendChild(see);
    }
    if (s.note) {
      var note = document.createElement('div');
      note.className = 'dnote';
      note.innerHTML = s.note;
      body.appendChild(note);
    }
    if (s.warn) {
      var warn = document.createElement('div');
      warn.className = 'dwarn';
      warn.innerHTML = s.warn;
      body.appendChild(warn);
    }

    function toggle() {
      if (state[idx]) delete state[idx]; else state[idx] = true;
      row.classList.toggle('on', !!state[idx]);
      save(); repaint();
    }
    box.addEventListener('click', toggle);
    act.addEventListener('click', function (e) {
      if (e.target.classList.contains('dcopy')) return;
      toggle();
    });

    if (state[idx]) row.classList.add('on');
    row.appendChild(box);
    row.appendChild(body);
    mount.appendChild(row);
  });

  var reset = document.createElement('button');
  reset.className = 'dreset';
  reset.type = 'button';
  reset.textContent = 'reset this drill';
  reset.addEventListener('click', function () {
    state = {}; save();
    mount.querySelectorAll('.dstep').forEach(function (r) { r.classList.remove('on'); });
    repaint();
  });
  mount.appendChild(reset);

  repaint();
}
