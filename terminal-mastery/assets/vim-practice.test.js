global.window = {}; global.document = { getElementById: () => null };
require(__dirname + '/vim-practice.js');
const R = window.vimReduceKey, A = window.vimApply;

let fail = 0;
function t(name, got, want) {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  const ok = g === w; if (!ok) fail++;
  console.log((ok ? 'ok  ' : 'FAIL'), name.padEnd(36), ok ? '' : '\n      got  ' + g + '\n      want ' + w);
}

t('j alone',             R({}, 'j'),                      {action:'motion',pending:'',count:'',motion:{key:'j'},cost:1});
t('3 buffers a count',   R({}, '3'),                      {action:'buffer',pending:'',count:'3'});
t('3 then j',            R({count:'3'}, 'j'),             {action:'motion',pending:'',count:'',motion:{key:'j',count:3},cost:2});
t('12 then j costs 3',   R({count:'12'}, 'j'),            {action:'motion',pending:'',count:'',motion:{key:'j',count:12},cost:3});
t('0 alone is a motion', R({}, '0'),                      {action:'motion',pending:'',count:'',motion:{key:'0'},cost:1});
t('1 then 0 = count 10', R({count:'1'}, '0'),             {action:'buffer',pending:'',count:'10'});
t('f waits for a char',  R({}, 'f'),                      {action:'buffer',pending:'f',count:''});
t('f then x',            R({pending:'f'}, 'x'),           {action:'motion',pending:'',count:'',motion:{key:'f',arg:'x',count:1},cost:2});
t('2fx costs 3',         R({pending:'f',count:'2'}, 'x'), {action:'motion',pending:'',count:'',motion:{key:'f',arg:'x',count:2},cost:3});
t('g waits',             R({}, 'g'),                      {action:'buffer',pending:'g',count:''});
t('gg',                  R({pending:'g'}, 'g'),           {action:'motion',pending:'',count:'',motion:{key:'gg',count:0},cost:2});
t('12gg',                R({pending:'g',count:'12'},'g'), {action:'motion',pending:'',count:'',motion:{key:'gg',count:12},cost:4});
t('g then x aborts',     R({pending:'g'}, 'x'),           {action:'abort',pending:'',count:''});
t('Escape resets',       R({pending:'f',count:'9'},'Escape'), {action:'reset',pending:'',count:''});
t('unknown key',         R({}, 'z'),                      {action:'unknown',pending:'',count:''});
t('Shift ignored',       R({}, 'Shift'),                  {action:'unknown',pending:'',count:''});
t('f then Shift aborts', R({pending:'f'}, 'Shift'),       {action:'abort',pending:'',count:''});

const GRID = ['alpha beta gamma','delta epsilon zeta','eta theta iota','kappa lambda mu','nu xi omicron'];
const LINE = ['    result = compute(alpha, beta) + offset  # tune later'];

function play(lines, from, keys) {
  let pos = { r: from[0], c: from[1] }, st = { pending: '', count: '' }, cost = 0;
  for (const k of keys) {
    const r = R(st, k); st = { pending: r.pending, count: r.count };
    if (r.action === 'motion') { const np = A(lines, pos, r.motion); cost += r.cost; if (np) pos = np; }
  }
  return { pos, cost };
}

const a = play(GRID, [0,0], ['3','j']);
t('3j reaches row 3',    a.pos,  {r:3,c:0});
t('  costing 2 keys',    a.cost, 2);
t('f( finds the paren',  play(LINE,[0,4],['f','(']).pos, {r:0,c:20});
t('$ hits last char',    play(LINE,[0,4],['$']).pos,     {r:0,c:55});
t('gg goes to the top',  play(GRID,[4,2],['g','g']).pos, {r:0,c:0});
t('F+ searches back',    play(LINE,[0,55],['F','+']).pos,{r:0,c:34});
t('t( stops before',     play(LINE,[0,4],['t','(']).pos, {r:0,c:19});
const one = play(LINE,[0,4],['f','e']).pos.c;
const two = play(LINE,[0,4],['2','f','e']).pos.c;
t('2fe goes past 1fe',   two > one, true);

console.log(fail ? '\n' + fail + ' FAILED' : '\nall ' + 25 + ' tests pass');
process.exit(fail ? 1 : 0);
