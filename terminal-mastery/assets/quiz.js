/* quiz.js - reusable retrieval-practice widget.
   Offline, no dependencies. Renders from a declarative array so lessons
   never inline quiz logic.

   Usage in a lesson:
     <div id="quiz"></div>
     <script src="../assets/quiz.js"></script>
     <script>renderQuiz('quiz', [
       { q: 'Question text?',
         a: ['option one', 'option two', 'option three'],
         correct: 1,
         why: 'Explanation shown after answering.' }
     ]);</script>

   Design rule from the teaching method: answer options are kept close to the
   same length so formatting never leaks the answer. Feedback is immediate,
   which is what turns a quiz into a feedback loop instead of a test.        */

function renderQuiz(mountId, items) {
  var mount = document.getElementById(mountId);
  if (!mount) return;
  var answered = 0, right = 0;

  var score = document.createElement('div');
  score.className = 'score';

  function updateScore() {
    score.textContent = answered
      ? 'recalled ' + right + ' / ' + answered
      : '';
  }

  items.forEach(function (item) {
    var box = document.createElement('div');
    box.className = 'quiz';

    var q = document.createElement('p');
    q.className = 'q';
    q.textContent = item.q;
    box.appendChild(q);

    var opts = document.createElement('div');
    opts.className = 'opts';

    var why = document.createElement('div');
    why.className = 'why';
    why.textContent = item.why || '';

    item.a.forEach(function (text, i) {
      var b = document.createElement('button');
      b.type = 'button';
      b.textContent = text;
      b.addEventListener('click', function () {
        if (box.dataset.done) return;
        box.dataset.done = '1';
        answered++;
        if (i === item.correct) right++;
        Array.prototype.forEach.call(opts.children, function (el, j) {
          el.disabled = true;
          if (j === item.correct) el.classList.add('right');
          else if (j === i) el.classList.add('wrong');
        });
        why.classList.add('show');
        updateScore();
      });
      opts.appendChild(b);
    });

    box.appendChild(opts);
    box.appendChild(why);
    mount.appendChild(box);
  });

  mount.appendChild(score);
}
