/* Prod Life III explorer: the game overview, the mechanics demos, the room idea and the notes board. */
(function () {
  "use strict";
  var A = window.APP, S = A.S, E = A.E, PL = A.PL, C = PL.config, $ = A.$, $$ = A.$$, esc = A.esc, h = A.h, num = A.num, money = A.money, signed = A.signed, store = A.store;
  var W = C.WalkIns, O = W.Odds;
  var cardLink = function (id, label) { return E.byId[id] ? '<button type="button" class="linkish" data-open="' + id + '">' + esc(label || E.byId[id].tag) + "</button>" : ""; };
  function wireOpen(root) { $$("[data-open]", root).forEach(function (b) { if (!b._w) { b._w = 1; b.addEventListener("click", function () { A.openCard(b.getAttribute("data-open")); }); } }); }
  function shot(file, cap, wide) { return '<figure><img class="shot' + (wide ? " wide" : "") + '" src="img/' + file + '" alt="' + esc(cap) + '" data-cap="' + esc(cap) + '" loading="lazy"><figcaption>' + esc(cap) + "</figcaption></figure>"; }

  /* ================= 1. THE GAME ================= */
  A.views.game = function (root) {
    var nWalk = PL.cards.filter(function (c) { return c._type === "walkin"; }).length, nPhone = PL.cards.filter(function (c) { return c._type === "phone" || c._type === "news"; }).length;
    root.appendChild(h('<div class="vhead"><h2 style="font-size:2rem;color:var(--pink)">PROD LIFE III</h2><p style="font-size:1.05rem;color:var(--ink)">A Roblox game where you play a music producer\'s career. You make the beats, people walk in wanting things, and you live with what you pick.</p><p class="small">Zenji · where it stands on November 10, 2026 · built in about three weeks · nothing published yet</p></div>'));
    var counts = h('<div class="counts">' + [
      [PL.cards.length, "cards you can open and play", "cards"], [nWalk, "walk-in situations", "cards"], [nPhone, "phone DMs and news", "cards"], [PL.meta.followups, "follow-ups that come back", "cards"],
      [PL.visitors.length, "characters and senders", "systems"], [PL.briefs.length, "artist requests", "systems"], [C.Gear.length, "things on the gear rack", "systems"], [6, "rooms you can walk into", "rooms"]
    ].map(function (x) { return '<button type="button" data-go="' + x[2] + '"><b>' + x[0] + "</b><span>" + x[1] + "</span></button>"; }).join("") + "</div>");
    root.appendChild(counts);
    $$("[data-go]", counts).forEach(function (b) { b.addEventListener("click", function () { A.go(b.getAttribute("data-go")); }); });
    var start = h('<div class="row"><button type="button" class="btn hot" data-go="play">Play a career with the real cards</button><button type="button" class="btn" data-go="cards">Browse every card</button><button type="button" class="btn" data-go="systems">Try the beat maker rules</button><button type="button" class="btn" data-go="rooms">The room idea</button></div>');
    root.appendChild(start);
    $$("[data-go]", start).forEach(function (b) { b.addEventListener("click", function () { A.go(b.getAttribute("data-go")); }); });
    root.appendChild(h('<div><h3 style="margin-bottom:8px">What it looks like right now</h3><div class="shots">' + [
      ["start.jpg", "Where you spawn: the control room"], ["visitor.jpg", "A visitor walks in"], ["card.jpg", "His card: three choices"], ["result.jpg", "The result"],
      ["beatmaker.jpg", "The beat maker"], ["keys.jpg", "KEYS: the piano roll"], ["requests.jpg", "Artist requests"], ["phone.jpg", "The phone"],
      ["career.jpg", "Career tab"], ["story.jpg", "Your story, by day"], ["firsts.jpg", "The twelve firsts"], ["banner.jpg", "A fame tier banner"],
      ["cypher.jpg", "The cypher board"], ["hall.jpg", "THE HALL"], ["west.jpg", "THE WEST SUITE"]
    ].map(function (x) { return shot(x[0], x[1]); }).join("") + '</div><p class="small dim" style="margin-top:6px">Roblox Studio captures from Nov 5. Visitors are plain blocks and use parody names for now; both change before launch.</p></div>'));
    root.appendChild(h('<div class="timeline">' + [["Oct 22", "Studio, beat maker, requests, stars, FIRE, gear, cyphers"], ["Oct 23", "Piano roll. THE HALL and THE WEST SUITE"], ["Oct 24", "Visitors walk in with choices"], ["Oct 26", "Became Prod Life III"], ["Oct 28–29", "The phone, 40+ cards, sounds"], ["Oct 30", "Career clock, story, fame tiers"], ["Nov 4–5", "Saves made safe, proven on a real store"], ["Nov 6", "Your beat changes odds, cold streaks, people remember"], ["Nov 10", "Your own room joins the launch list"]].map(function (x, i, a) { return '<div class="' + (i === a.length - 1 ? "now" : "") + '"><b>' + x[0] + "</b>" + x[1] + "</div>"; }).join("") + "</div>"));
    root.appendChild(h('<div class="grid2"><div class="box"><h3><span class="tag work">Working</span></h3><ul class="plain small"><li>Beat maker: drums, piano roll, kits, swing</li><li>Requests from six artists that pay and rate you</li><li>Visitors, the phone, follow-ups</li><li>Career stats, fame tiers, career clock, story</li><li>Gear, FIRE, sampling, the cypher</li><li>THE HALL and THE WEST SUITE</li><li>Your beat tilts odds. You can go cold</li><li>Saves with protection against lost progress</li></ul></div>' +
      '<div class="box"><h3><span class="tag fix">Built, fixes open</span></h3><p class="small">Six characters who remember you. A few of their cards repeat too often; that\'s the next fix.</p><h3><span class="tag launch">Launch list, in order</span></h3><ol class="small" style="margin:0;padding-left:1.2em"><li>Made-up names for everyone</li><li>A random first visitor</li><li>Day One: choices from second one</li><li>Phone and tablet fixes</li><li>Server safety fixes</li><li>The new visitor look</li><li>Beat maker upgrade</li><li>Your own room</li><li>Final full check</li></ol></div>' +
      '<div class="box"><h3>The honest part</h3><ul class="plain small"><li>Never published. No stranger has played it.</li><li>Never on a real phone, never with two real players.</li><li>Real saves worked on a test store Nov 5. Studio uses a practice store, so each Play starts fresh.</li><li>Last full test run: 192 of 205. The 13 misses were a stray click on mute, not the code. A clean rerun is still to do.</li><li>The beat maker is a one-bar loop plus a piano roll. It isn\'t FL.</li></ul></div></div>'));
    root.appendChild(h('<div class="pnote"><ul><li>Don\'t read this page. Click "Play a career" and take the first visitor, then deliver a beat, then take two more visitors. That shows the loop in a minute.</li><li>Then open "Every card" and let them pick one. Flip to Developer (D) to show the odds.</li><li>Numbers if asked: 62 scripts, about 17,000 lines, 205 automated checks, 160 commits since Oct 22.</li><li>Keys: 1 to 6 switch places, D flips Player/Developer, N these notes, L the live demo route.</li></ul></div>'));
  };

  /* ================= 4. HOW IT WORKS ================= */
  var TC = ["255,60,160", "0,170,255", "225,200,140", "0,255,140", "170,90,255"], BASS = ["", "0", "+3", "+5", "+7", "−2"];
  var bm = { grid: E.DEFAULT_GRID.map(function (r) { return r.split(""); }), bpm: 142, swing: 0, brief: "j1", keys: { notes: 0, distinct: 0 } };
  var cold = { aura: 0, gap: 0, state: null, rearm: false }, oddsS = { base: 50, aura: 0, followers: 0, beat: "off", rel: 0 }, fameF = 800;
  var SUB = [["beat", "Beat maker"], ["odds", "The odds"], ["cold", "Going cold"], ["fame", "Fame and unlocks"], ["people", "Who remembers you"], ["day", "A day in numbers"]];
  A.views.systems = function (root) {
    root.appendChild(h('<div class="vhead"><h2>How it works</h2><p>Each of these runs on the game\'s real numbers. Change something and watch what the rules do.</p></div>'));
    var nav = h('<div class="subnav">' + SUB.map(function (s) { return '<button type="button" class="fchip' + (S.sys === s[0] ? " on" : "") + '" data-s="' + s[0] + '">' + s[1] + "</button>"; }).join("") + "</div>");
    root.appendChild(nav);
    var body = h('<div style="display:grid;gap:16px"></div>'); root.appendChild(body);
    $$("[data-s]", nav).forEach(function (b) { b.addEventListener("click", function () { S.sys = b.getAttribute("data-s"); $$("[data-s]", nav).forEach(function (x) { x.classList.toggle("on", x === b); }); draw(); }); });
    function draw() { body.innerHTML = ""; ({ beat: beat, odds: odds, cold: coldV, fame: fame, people: people, day: day })[S.sys](body); wireOpen(body); A.wireShots(body); }
    draw();
  };

  function beat(body) {
    var wrap = h('<div class="grid2" style="grid-template-columns:minmax(0,1.5fr) minmax(0,1fr)"><div id="bm-l" style="display:grid;gap:12px;min-width:0"></div><div id="bm-r" style="display:grid;gap:12px;align-content:start;min-width:0"></div></div>');
    body.appendChild(wrap);
    var L = $("#bm-l", wrap), R = $("#bm-r", wrap);
    function beatObj() { return { grid: bm.grid.map(function (r) { return r.join(""); }), bpm: bm.bpm, swing: bm.swing, keys: bm.keys }; }
    function drawGrid() {
      L.innerHTML = "";
      var g = '<div class="bm"><div class="row" style="justify-content:space-between"><span class="hud" style="color:var(--pink)">Beat maker</span><div class="row"><button type="button" class="btn sm" id="bpm-d">−</button><span class="hud">' + bm.bpm + ' BPM</span><button type="button" class="btn sm" id="bpm-u">+</button><select id="bm-swing" class="inp" style="width:auto"><option value="0">Swing 0%</option><option value="25">Swing 25%</option><option value="50">Swing 50%</option></select><button type="button" class="btn sm" id="bm-clear">Clear</button><button type="button" class="btn sm" id="bm-def">Starting beat</button></div></div><div class="bmgrid">';
      E.TRACKS.forEach(function (t, ti) {
        g += '<span class="tl" style="color:rgb(' + TC[ti] + ')">' + t + "</span>";
        for (var i = 0; i < 16; i++) { var v = bm.grid[ti][i]; g += '<button type="button" class="pad' + (Math.floor(i / 4) % 2 ? " b4" : "") + (v !== "0" ? " onp" : "") + '" style="--tc:rgb(' + TC[ti] + ')" data-t="' + ti + '" data-i="' + i + '" aria-label="' + t + " step " + (i + 1) + '">' + (ti === 3 && +v > 1 ? "×" + v : ti === 4 && v !== "0" ? BASS[+v] : "") + "</button>"; }
      });
      g += '</div><p class="small dim">One bar, 16 steps, five rows, like the game. Tap a hat again for a roll (×2, ×3). Tap an 808 again to change its note. No sound here; the real one plays in Studio.</p></div>';
      var el = h(g); L.appendChild(el);
      $("#bm-swing", el).value = String(bm.swing);
      $$(".pad", el).forEach(function (b) { b.addEventListener("click", function () {
        var t = +b.getAttribute("data-t"), i = +b.getAttribute("data-i"), v = +bm.grid[t][i], max = t === 3 ? 3 : t === 4 ? 5 : 1;
        bm.grid[t][i] = String(v >= max ? 0 : v + 1); drawGrid(); drawSide();
      }); });
      $("#bpm-d", el).addEventListener("click", function () { bm.bpm = Math.max(60, bm.bpm - 5); drawGrid(); drawSide(); });
      $("#bpm-u", el).addEventListener("click", function () { bm.bpm = Math.min(200, bm.bpm + 5); drawGrid(); drawSide(); });
      $("#bm-swing", el).addEventListener("change", function (e) { bm.swing = +e.target.value; drawSide(); });
      $("#bm-clear", el).addEventListener("click", function () { bm.grid = E.TRACKS.map(function () { return "0000000000000000".split(""); }); drawGrid(); drawSide(); });
      $("#bm-def", el).addEventListener("click", function () { bm.grid = E.DEFAULT_GRID.map(function (r) { return r.split(""); }); drawGrid(); drawSide(); });
      L.appendChild(h('<div class="shots" style="grid-template-columns:1fr 1fr">' + shot("beatmaker.jpg", "The real beat maker in Studio") + shot("keys.jpg", "The real piano roll (KEYS)") + "</div>"));
      A.wireShots(L);
    }
    function drawSide() {
      R.innerHTML = "";
      var brief = PL.briefs.filter(function (b) { return b.id === bm.brief; })[0], art = PL.artists.filter(function (a) { return a.id === brief.artist; })[0], res = E.checkBrief(brief, beatObj());
      var needsKeys = res.asks.concat(res.bonus ? [res.bonus] : []).some(function (a) { return a.keys; });
      var gear = { Bass: "Sub Boom 808 (free)", Rolls: "Roll FX ($250)", Swing: "Swing Unit ($350)" };
      var askRow = function (a, bonus) { return '<div class="ask' + (a.ok ? " ok" : "") + '"><span class="t">' + (a.ok ? "✓" : "○") + "</span><span>" + esc(a.text) + (bonus ? ' <span class="dim">(bonus, for the third star)</span>' : "") + (a.needs ? ' <span class="dim">· needs ' + gear[a.needs] + "</span>" : "") + "</span></div>"; };
      var mult = function (x) { return res.stars === 3 ? Math.floor(x * 1.5 + 0.5) : x; }, feed = C.Career.DeliveryFeed[String(res.stars)];
      var yours = res.changed >= 8;
      var box = h('<div class="box"><h3>The request</h3><select id="bm-brief" class="inp">' + PL.artists.map(function (a) { return '<optgroup label="' + esc(a.name) + " · " + esc(a.style) + " · level " + a.level + '">' + PL.briefs.filter(function (b) { return b.artist === a.id; }).map(function (b) { return '<option value="' + b.id + '"' + (b.id === bm.brief ? " selected" : "") + ">“" + esc(b.title) + "” · " + money(b.reward.cred) + (b.starter ? " · starter" : "") + "</option>"; }).join("") + "</optgroup>"; }).join("") + "</select>" +
        '<p class="small muted">' + esc(art.name) + " wants " + esc(art.style) + ". Asks tick as you build, same as in the game.</p>" + res.asks.map(function (a) { return askRow(a); }).join("") + (res.bonus ? askRow(res.bonus, true) : "") +
        (needsKeys ? '<div class="lab"><label>Notes on the keys<input type="number" min="0" id="k-n" value="' + bm.keys.notes + '"></label><label>Different notes<input type="number" min="0" id="k-d" value="' + bm.keys.distinct + '"></label></div><p class="small dim">The piano roll isn\'t rebuilt on this page, so say what your keys part has.</p>' : "") +
        '<div class="ask' + (yours ? " ok" : "") + '"><span class="t">' + (yours ? "✓" : "○") + "</span><span>It has to be yours: " + res.changed + " of 8 pads changed from the starting beat</span></div></div>");
      R.appendChild(box);
      $("#bm-brief", box).addEventListener("change", function (e) { bm.brief = e.target.value; drawSide(); });
      if (needsKeys) { $("#k-n", box).addEventListener("change", function (e) { bm.keys.notes = Math.max(0, +e.target.value || 0); drawSide(); }); $("#k-d", box).addEventListener("change", function (e) { bm.keys.distinct = Math.max(0, +e.target.value || 0); drawSide(); }); }
      var done = S.run.done[brief.id], tilt = (res.stars - O.beatCenter) * O.beatPer, canDeliver = res.stars >= 2 && yours;
      var out = h('<div class="box"><h3>If you delivered this</h3><div class="stars">' + [1, 2, 3].map(function (i) { return i <= res.stars ? "★" : "<s>★</s>"; }).join("") + "</div>" +
        (res.stars ? '<div class="hudrow">' + A.chips({ money: mult(brief.reward.cred), xp: mult(brief.reward.xp), aura: feed.aura, followers: feed.followers }, "") + '</div><p class="small">' + esc(art.name) + ": “" + esc(art.quotes[String(res.stars)]) + '”</p><p class="small muted">Paid the first time only. Three stars pays 1.5×.</p>' : '<p class="small muted">Not passing yet. Every ask has to tick for two stars.</p>') +
        '<h3 style="margin-top:6px">What it does to your career</h3><p class="small">Visitors judge you by your best of your last three beats. With this one, the ' + PL.cards.filter(function (c) { return c._mech.beat; }).length + " cards that use your beat roll at <b>" + (res.stars ? (tilt > 0 ? "+" : tilt < 0 ? "−" : "") + Math.abs(tilt) : "−9") + " points</b>" + (res.stars === 3 ? " (even), and +3 once it has 3 FIREs" : res.stars === 2 ? "" : " (the same as having no beat)") + ". " + (res.stars === 3 ? "A three-star delivery also ends a cold streak." : "") + '</p><div class="row"><button type="button" class="btn sm hot" id="bm-deliver"' + (canDeliver && !done ? "" : " disabled") + ">Deliver it into my career run</button><button type=\"button\" class=\"btn sm\" id=\"bm-cards\">See the cards that use your beat</button></div>" + (done ? '<p class="small dim">Already delivered in your run.</p>' : "") + "</div>");
      R.appendChild(out);
      $("#bm-cards", out).addEventListener("click", function () { S.mech = { beat: true }; S.type = "all"; S.who = ""; S.q = ""; S.onlyOpen = false; var first = PL.cards.filter(function (c) { return c._mech.beat; })[0]; S.sel = first.id; A.go("cards"); });
      $("#bm-deliver", out).addEventListener("click", function () {
        var b = E.clone(S.run), r = E.deliver(S.run, brief, res.stars);
        S.runLog.unshift({ day: S.run.day, title: "Delivered “" + brief.title + "” to " + art.name, sub: "★".repeat(res.stars), applied: r.applied, events: r.events });
        S.runCur = { kind: "info", before: b, title: "“" + brief.title + "” · " + "★".repeat(res.stars), text: art.name + ": “" + art.quotes[String(res.stars)] + "”", events: r.events };
        A.go("play");
      });
    }
    drawGrid(); drawSide();
  }

  function slider(label, id, min, max, step, val, show) { return '<div class="slider"><label for="' + id + '">' + label + '</label><input type="range" id="' + id + '" min="' + min + '" max="' + max + '" step="' + step + '" value="' + val + '"><b id="' + id + '-v">' + show + "</b></div>"; }
  function odds(body) {
    var box = h('<div class="box"><h3>What decides a roll</h3><p class="small muted">Every risky choice has a base chance. Four things move it, and the result always stays between ' + O.min + "% and " + O.max + "%. Players never see any of this.</p>" +
      slider("The choice's base", "o-base", 10, 90, 5, oddsS.base, oddsS.base + "%") + slider("Your Aura", "o-aura", -400, 600, 10, oddsS.aura, oddsS.aura) + slider("Your followers", "o-fol", 0, 20000, 500, oddsS.followers, num(oddsS.followers)) +
      '<div class="slider"><label for="o-beat">Your best beat</label><select id="o-beat" class="inp"><option value="off">This choice doesn\'t use it</option><option value="0">No beat delivered</option><option value="2">★★</option><option value="3">★★★</option><option value="4">★★★ with 3 FIREs</option></select><span></span></div>' +
      slider("How they feel about you", "o-rel", -3, 3, 1, oddsS.rel, oddsS.rel) + '<div id="o-out" style="display:grid;gap:8px"></div></div>');
    body.appendChild(box);
    $("#o-beat", box).value = oddsS.beat;
    function out() {
      var a = E.auraPts(oddsS.aura), f = E.folPts(oddsS.followers), b = oddsS.beat === "off" ? 0 : (+oddsS.beat - O.beatCenter) * O.beatPer, r = oddsS.rel * O.relPer, raw = oddsS.base + a + f + b + r, ch = Math.max(O.min, Math.min(O.max, raw));
      $("#o-out", box).innerHTML = '<div class="meter"><i style="width:' + ch + '%"></i><em style="left:' + O.min + '%"></em><em style="left:' + O.max + '%"></em><b>' + ch + '% it goes your way</b></div><div class="math"><span>' + oddsS.base + '</span><span class="t">base</span><span>' + (a >= 0 ? "+" : "−") + Math.abs(a) + '</span><span class="t">Aura (1 point per ' + O.auraPer + ", up to ±" + O.auraCap + ")</span><span>+" + f + '</span><span class="t">followers (1 per ' + num(O.followersPer) + ", up to +" + O.followersCap + ")</span>" + (oddsS.beat === "off" ? "" : "<span>" + (b >= 0 ? "+" : "−") + Math.abs(b) + '</span><span class="t">your beat (3 points per step from three stars)</span>') + "<span>" + (r >= 0 ? "+" : "−") + Math.abs(r) + '</span><span class="t">relationship (' + O.relPer + ' points per step)</span><span class="t">=</span><span class="res">' + ch + "%</span>" + (raw !== ch ? '<span class="t">(' + raw + " before the " + O.min + " to " + O.max + " limit)</span>" : "") + "</div>";
    }
    [["o-base", "base", function (v) { return v + "%"; }], ["o-aura", "aura", String], ["o-fol", "followers", num], ["o-rel", "rel", String]].forEach(function (x) {
      $("#" + x[0], box).addEventListener("input", function (e) { oddsS[x[1]] = +e.target.value; $("#" + x[0] + "-v", box).textContent = x[2](+e.target.value); out(); });
    });
    $("#o-beat", box).addEventListener("change", function (e) { oddsS.beat = e.target.value; out(); });
    out();
    var n = function (f) { return PL.cards.reduce(function (a, c) { return a + (c.choices || []).filter(f).length; }, 0); };
    body.appendChild(h('<div class="grid2"><div class="box"><h3>Kinds of choices in the game</h3><table class="t"><tbody><tr><td><b>' + n(function (x) { return x.sure && !x.beatMin; }) + '</b></td><td>Safe. Always the same outcome.</td></tr><tr><td><b>' + n(function (x) { return !x.sure && !x.beatMin && !x.ready; }) + '</b></td><td>A roll, with the math above.</td></tr><tr><td><b>' + n(function (x) { return x.beat; }) + '</b></td><td>A roll your beat tilts.</td></tr><tr><td><b>' + n(function (x) { return x.rare; }) + '</b></td><td>Have a rare outcome that rolls first, at 8%.</td></tr><tr><td><b>' + n(function (x) { return x.beatMin; }) + "</b></td><td>No roll at all: you win only with a three-star beat. " + cardLink("rival_war", "The diss track") + '</td></tr><tr><td><b>' + n(function (x) { return x.ready; }) + "</b></td><td>Rolls on how ready you are (level, placements, followers, Aura). " + cardLink("two_sessions", "Two sessions") + '</td></tr><tr><td><b>' + n(function (x) { return x.cost; }) + "</b></td><td>Cost money up front.</td></tr></tbody></table></div>" +
      '<div class="box"><h3>Where each stat comes from</h3><table class="t"><tbody><tr><td>Money</td><td>Requests, visitors, FIRE ($30), flips ($50), cypher wins ($500). Never from the phone.</td></tr><tr><td>Aura</td><td>Visitors, the phone, three-star deliveries, cypher wins. Can go negative; heals 5 a day.</td></tr><tr><td>Followers</td><td>Visitors, the phone, deliveries, FIRE, flips. They set your fame tier.</td></tr><tr><td>Placements, hits, sponsors</td><td>Only from visitors. The choices are the only way up.</td></tr><tr><td>XP and level</td><td>The music: saving beats, requests, dailies, cyphers. Visitors give none.</td></tr></tbody></table></div></div>'));
  }

  function coldV(body) {
    var box = h('<div class="box"><h3>Going cold</h3><p class="small muted">Slack off or wreck your reputation and the game goes quiet on you. Move the sliders.</p>' + slider("Your Aura", "c-aura", -120, 100, 5, cold.aura, cold.aura) + slider("Days since you delivered", "c-gap", 0, 6, 1, cold.gap, cold.gap) + '<div id="c-out" style="display:grid;gap:10px"></div></div>');
    body.appendChild(box);
    function step(ev) { var r = E.coldStep(cold.state, cold.rearm, cold.aura, 10, 10 - cold.gap, ev || "check"); cold.state = r[0]; cold.rearm = r[1]; if (ev) cold.gap = 0; }
    function out() {
      step();
      var c = cold.state;
      $("#c-out", box).innerHTML = '<div class="row"><span class="chip ' + (c ? "cold" : "pos") + '">' + (c ? "❄ COLD" : "WARM") + "</span><span>" + (c ? (c.reason === "aura" ? "Aura fell under " + W.Cold.aura + "." : W.Cold.quietDays + " played days with no delivery.") : "People are calling.") + (cold.rearm ? ' <span class="dim">Aura has to climb back to ' + W.Cold.rearmAura + " before it can chill you again.</span>" : "") + "</span></div>" +
        '<table class="t"><thead><tr><th></th><th>Warm</th><th>Cold</th></tr></thead><tbody><tr><td>Visitors a day</td><td>' + W.DailyMax + "</td><td><b>" + W.Cold.dailyMax + "</b></td></tr><tr><td>Phone messages a day</td><td>" + C.Phone.DailyMax + "</td><td><b>0</b>, except the one below</td></tr><tr><td>Busy-day bursts</td><td>15% chance</td><td><b>Never</b></td></tr><tr><td>On screen</td><td></td><td>A grey COLD chip on the HUD</td></tr></tbody></table>" +
        '<div class="row"><button type="button" class="btn sm" id="c-del"' + (c ? "" : " disabled") + '>Deliver a ★★★ beat</button><button type="button" class="btn sm" id="c-fire"' + (c ? "" : " disabled") + ">Get a FIRE from another player</button><span class=\"small muted\">The only two ways out.</span></div>";
      $("#c-del", box).addEventListener("click", function () { step("delivery3"); $("#c-gap", box).value = 0; $("#c-gap-v", box).textContent = 0; out(); });
      $("#c-fire", box).addEventListener("click", function () { step("fire"); $("#c-gap", box).value = 0; $("#c-gap-v", box).textContent = 0; out(); });
    }
    $("#c-aura", box).addEventListener("input", function (e) { cold.aura = +e.target.value; $("#c-aura-v", box).textContent = cold.aura; out(); });
    $("#c-gap", box).addEventListener("input", function (e) { cold.gap = +e.target.value; $("#c-gap-v", box).textContent = cold.gap; out(); });
    out();
    var cn = E.byId.cold_news, o = cn.choices[0].good;
    body.appendChild(h('<div class="grid2"><div class="gcard phone"><div class="ghead"><span class="portrait" style="background:rgb(230,60,60)"></span><div><b>' + esc(A.whoName("feed")) + "</b><span>NEWS</span></div><em></em></div><p class=\"gline\">" + esc(cn.line) + '</p><div class="gres neutral"><b>' + esc(o.headline) + "</b><p>" + esc(o.text) + '</p></div></div><div class="box"><h3>The one message that gets through</h3><p class="small">When you go cold the game sends this card once. ' + cardLink("cold_news", "Open it in the library") + '.</p><p class="small muted">Days you don\'t play never count against you. A cold streak ends with a YOU\'RE BACK banner and a line in your story: “You got people talking again.”</p><p class="small muted">Sponsors work the same way on a smaller scale: each one has an Aura bar (100 to 400). Drop under it and ' + cardLink("sponsor_drop", "they pull the deal") + ", unless the rep likes you, in which case you get " + cardLink("sponsor_warning", "a warning first") + ".</p></div></div>"));
  }

  var BANNER = { BUZZING: "YOU'RE BUZZING · 1,000 followers · someone's coming by", KNOWN: "YOU'RE KNOWN · 5,000 followers · late-night tv is asking about you", FAMOUS: "YOU'RE FAMOUS · 20,000 followers · the gossip pages noticed", ICON: "YOU'RE AN ICON · 100,000 followers · a record label wants a meeting" };
  function fame(body) {
    var T = C.Life.Tiers, box = h('<div class="box"><h3>Fame tiers</h3>' + slider("Followers", "f-fol", 0, 120000, 250, fameF, num(fameF)) + '<div id="f-out" style="display:grid;gap:10px"></div></div>');
    body.appendChild(box);
    function out() {
      var ti = E.tierIndex(fameF), t = T[ti], next = T[ti + 1];
      $("#f-out", box).innerHTML = '<div class="tiers">' + T.map(function (x, i) { return '<div class="' + (i === ti ? "on" : i < ti ? "past" : "") + '"><b>' + x.id + "</b>" + (x.followers ? num(x.followers) : "start") + "</div>"; }).join("") + "</div>" +
        (ti ? '<p><span class="chip pink">' + esc(BANNER[t.id]) + '</span></p><p class="small">Crossing it the first time sends a one-time visitor a visit or two later: ' + cardLink(C.Life.TierVisits[t.id]) + ". It never costs anything and can't go badly.</p>" : '<p class="small muted">Everyone starts LOCAL. The first tier is at 1,000 followers.</p>') +
        (next ? '<p class="small muted">' + num(next.followers - fameF) + " more to " + next.id + ". Followers also add up to +" + O.followersCap + " points on every roll (you're at +" + E.folPts(fameF) + ").</p>" : "");
      wireOpen(box);
    }
    $("#f-fol", box).addEventListener("input", function (e) { fameF = +e.target.value; $("#f-fol-v", box).textContent = num(fameF); out(); });
    out();
    var p = S.run, hall = E.gateCheck(C.Career.Gates[0], p);
    var chk = function (ok) { return '<span style="color:' + (ok ? "var(--green)" : "var(--red)") + '">' + (ok ? "✓" : "✗") + "</span>"; };
    body.appendChild(h('<div class="grid2"><div class="box"><h3>THE HALL, against your career run</h3>' + hall.rows.map(function (r) { return '<div class="req">' + chk(r.ok) + "<span>" + num(r.need) + " " + r.k + '</span><span class="dim">you have ' + num(r.have) + "</span></div>"; }).join("") + '<div class="req">' + chk(hall.money.ok) + "<span>" + money(hall.money.need) + '</span><span class="dim">you have ' + money(hall.money.have) + '</span></div><p class="small muted">The only room with a gate today. THE WEST SUITE is open to everyone. In the pacing sim a typical player opens THE HALL around day 4.</p>' + shotMini("hall.jpg", "THE HALL") + '</div><div class="box"><h3>Levels come from the music</h3><div class="tw"><table class="t"><thead><tr><th>Level</th><th>XP</th><th>Rank</th><th>Opens</th></tr></thead><tbody>' + C.Levels.map(function (xp, i) { var lv = i + 1, arts = PL.artists.filter(function (a) { return a.level === lv; }).map(function (a) { return a.name; }); return "<tr" + (p.level === lv ? ' style="background:var(--panel2)"' : "") + "><td>" + lv + "</td><td>" + num(xp) + "</td><td>" + esc(C.Ranks[i]) + "</td><td>" + esc(arts.length ? arts.join(", ") + " send requests" : "") + "</td></tr>"; }).join("") + "</tbody></table></div></div></div>"));
    body.appendChild(h('<div class="box"><h3>The gear rack: what money is for today</h3><div class="tw"><table class="t"><thead><tr><th>Item</th><th>What it does</th><th>Price</th><th>Needs</th><th>Your run</th></tr></thead><tbody>' + C.Gear.map(function (g) {
      var needs = ["level " + g.level].concat(Object.keys(g.needs || {}).map(function (k) { return num(g.needs[k]) + " " + k; })), ok = p.level >= g.level && Object.keys(g.needs || {}).every(function (k) { return p[k] >= g.needs[k]; });
      return "<tr><td><b>" + esc(g.name) + "</b></td><td>" + esc(g.desc) + "</td><td>" + (g.price ? money(g.price) : "free") + "</td><td>" + (g.level > 1 || g.needs ? esc(needs.filter(function (x) { return x !== "level 1"; }).join(", ")) : "") + "</td><td>" + (p.gear[g.id] ? "owned" : ok ? (p.money >= g.price ? chk(true) + " can buy" : "short " + money(g.price - p.money)) : chk(false) + " locked") + "</td></tr>";
    }).join("") + "</tbody></table></div><p class=\"small muted\">Some gear needs more than money: a placement, a sponsor, Aura. That's the same pattern the room ladder would use.</p></div>"));
  }
  function shotMini(file, cap) { return '<img class="shot" style="max-width:320px" src="img/' + file + '" alt="' + esc(cap) + '" data-cap="' + esc(cap) + '" loading="lazy">'; }

  function people(body) {
    var REC = ["rival", "mom", "homekid", "navx", "rep", "blogger"];
    body.appendChild(h('<p class="muted" style="max-width:70ch">Six characters keep a score from −3 to +3 and remember specific things you did. The score moves their rolls 4 points a step. What they remember opens some cards and closes others. All of this is read from the card data.</p>'));
    REC.forEach(function (id) {
      var v = E.visitorById[id], mine = PL.cards.filter(function (c) { return c.visitor === id; }), flags = Object.keys(PL.relFlags[id] || {});
      var rows = flags.map(function (f) {
        var full = id + "." + f, setBy = [], clearBy = [], opens = [], closes = [];
        PL.cards.forEach(function (c) {
          var outs = []; (c.choices || []).forEach(function (ch) { ["good", "bad", "rare"].forEach(function (k) { if (ch[k]) outs.push(ch[k]); }); }); if (c.resolve) { outs.push(c.resolve.good); if (c.resolve.bad) outs.push(c.resolve.bad); }
          if (outs.some(function (o) { return o.rel && o.rel.flag === f && (o.rel.who || c.visitor) === id; })) setBy.push(c.id);
          if (outs.some(function (o) { return o.rel && o.rel.clear === f && (o.rel.who || c.visitor) === id; })) clearBy.push(c.id);
          if (c.needs && c.needs.flags && c.needs.flags.indexOf(full) >= 0) opens.push(c.id);
          if (c.under && c.under.flags && c.under.flags.indexOf(full) >= 0) closes.push(c.id);
        });
        var L = function (a) { return a.length ? a.map(function (x) { return cardLink(x); }).join(", ") : '<span class="dim">nothing</span>'; };
        return "<tr><td><code>" + esc(f) + "</code></td><td>" + L(setBy) + "</td><td>" + L(opens) + "</td><td>" + L(closes) + (clearBy.length ? '<br><span class="dim">forgotten after: </span>' + L(clearBy) : "") + "</td></tr>";
      });
      var scoreGated = mine.filter(function (c) { return (c.needs && c.needs.rel != null) || (c.under && c.under.rel != null); });
      var e = S.run.rel[id];
      body.appendChild(h('<div class="box"><div class="row" style="justify-content:space-between"><div class="row"><span class="portrait" style="width:28px;height:28px;border-radius:6px;background:rgb(' + v.color.join(",") + ')"></span><h4>' + esc(v.names.parody.replace("{sponsor}", "YOUR SPONSOR")) + ' <span class="dim" style="font-weight:400">· at launch: ' + esc(v.names.fiction.replace("{sponsor}", "YOUR SPONSOR")) + '</span></h4></div><span class="small">' + mine.length + " cards · in your run: " + A.pips(e ? e.score : 0) + '</span></div><div class="tw"><table class="t"><thead><tr><th>They remember</th><th>After</th><th>Which opens</th><th>Which closes</th></tr></thead><tbody>' + rows.join("") + "</tbody></table></div>" +
        (scoreGated.length ? '<p class="small">Needs a certain score: ' + scoreGated.map(function (c) { return cardLink(c.id) + " (" + (c.needs && c.needs.rel != null ? c.needs.rel + " or more" : "under " + c.under.rel) + ")"; }).join(", ") + "</p>" : "") +
        '<p class="small"><button type="button" class="linkish" data-who="' + id + '">See all ' + mine.length + " of their cards</button></p></div>"));
    });
    $$("[data-who]", body).forEach(function (b) { b.addEventListener("click", function () { S.who = b.getAttribute("data-who"); S.type = "all"; S.mech = {}; S.q = ""; S.onlyOpen = false; S.sel = PL.cards.filter(function (c) { return c.visitor === S.who; })[0].id; A.go("cards"); }); });
  }

  function day(body) {
    var R = function (a) { return a[0] + " to " + a[1]; };
    body.appendChild(h('<div class="grid2"><div class="box"><h3>Visitors</h3><table class="t"><tbody><tr><td>A day</td><td><b>' + W.DailyMax + "</b> at most (" + W.Cold.dailyMax + " while cold)</td></tr><tr><td>First ever</td><td>" + R(W.FirstEver) + " seconds after you spawn</td></tr><tr><td>Between visits</td><td>" + R(W.Gap) + " seconds in the studio</td></tr><tr><td>Busy day</td><td>" + Math.round(W.Rush.Chance * 100) + "% chance of " + R(W.Rush.Size) + " visitors back to back</td></tr><tr><td>Same person again</td><td>Not within " + W.ArtistCooldown + " visits</td></tr><tr><td>Follow-ups</td><td>Come back " + R(W.FollowupAt) + " visits later (some much later)</td></tr><tr><td>Which card</td><td>From the ones you've seen least, so the deck rotates</td></tr><tr><td>Ignored card</td><td>He leaves after " + W.ExpireSeconds / 60 + " minutes. Nothing changes</td></tr></tbody></table></div>" +
      '<div class="box"><h3>The phone</h3><table class="t"><tbody><tr><td>A day</td><td><b>' + C.Phone.DailyMax + "</b> at most, none while cold</td></tr><tr><td>Between messages</td><td>" + R(C.Phone.Gap) + " seconds</td></tr><tr><td>What it moves</td><td>Aura and followers only. Never money</td></tr><tr><td>Unread</td><td>Gone after " + C.Phone.ExpireSeconds / 60 + " minutes</td></tr></tbody></table><h3>The music</h3><table class=\"t\"><tbody><tr><td>Daily requests</td><td>" + C.Daily.Count + " a day, " + money(C.Daily.Cred) + " and " + C.Daily.XP + " XP each</td></tr><tr><td>Streak</td><td>" + money(C.Daily.StreakBonus["3"]) + " at 3 days, " + money(C.Daily.StreakBonus["7"]) + " at 7</td></tr><tr><td>Weekly single</td><td>" + money(C.Weekly.Cred) + " and " + C.Weekly.XP + " XP. Three stars earns a plaque</td></tr></tbody></table></div>" +
      '<div class="box"><h3>Other players</h3><table class="t"><tbody><tr><td>FIRE</td><td>' + money(C.Cred.Sources.Fire.amount) + " and " + C.Career.Sources.Fire.followers.amount + " followers to the producer. " + C.Fire.PairDaily + " a day between the same two people</td></tr><tr><td>Flip</td><td>Sample a beat on air, change 8+ pads. " + money(C.Cred.Sources.Flip.amount) + " and " + C.Career.Sources.Flip.followers.amount + " followers to the original producer</td></tr><tr><td>Cypher</td><td>" + C.Cypher.MinEntrants + " to " + C.Cypher.MaxEntrants + " producers, one brief, " + C.Cypher.BuildSeconds / 60 + " minutes. Win: " + money(C.Cypher.Reward.WinCred) + ", " + C.Career.Sources.Cypher.aura.amount + " Aura</td></tr></tbody></table><h3>The clock</h3><table class=\"t\"><tbody><tr><td>Career day</td><td>One per real day you play</td></tr><tr><td>Career year</td><td>" + C.Life.DaysPerYear + " career days</td></tr><tr><td>Aura in the red</td><td>Heals " + C.Career.Sources.AuraHeal.aura.max + " a day</td></tr></tbody></table></div></div>"));
  }

  /* ================= 5. THE ROOM IDEA ================= */
  var MODELS = {
    own: { name: "Climb all four", line: "Bedroom → Home studio → THE HALL → THE WEST SUITE. Each one becomes yours.", rungs: ["bed", "home", "hall", "west"] },
    shared: { name: "Two of your own, two shared", line: "Your bedroom and home studio are yours to customize. THE HALL and THE WEST SUITE stay shared premium rooms your career unlocks.", rungs: ["bed", "home", "hall-s", "west-s"] },
    nov4: { name: "The Nov 4 plan", line: "Your Room → Pro Room → Your Suite behind your own door. THE HALL and THE WEST SUITE stay as they are today, beside the ladder.", rungs: ["yr", "pro", "suite", "legends"] }
  };
  var RUNG = {
    bed: { name: "Bedroom", built: false, own: true, blurb: "A desk, a laptop, a bad speaker. Your first beats and first visitors happen here.", have: "A laptop beat maker and the 808. Nothing on the walls.", gate: "You start here." },
    home: { name: "Home studio", built: false, own: true, blurb: "Real monitors, a booth corner, room for people to come to you.", have: "Space for the gear you've bought and your first plaques.", gate: "To decide. Draft it below." },
    hall: { name: "THE HALL", built: true, img: "hall.jpg", own: true, blurb: "Rebuilt from Abbey Road's Studio Two. In this version it becomes your room.", have: "A full live room. Would need a copy per player, or one player in it at a time.", gate: "Today: 1 placement, 300 Aura, $5,000." },
    west: { name: "THE WEST SUITE", built: true, img: "west.jpg", own: true, blurb: "Rebuilt from Interscope's LA studios. The top of the climb.", have: "Control room, live room, piano booth, lobby.", gate: "Today: open to everyone. Would need a gate." },
    "hall-s": { name: "THE HALL", built: true, img: "hall.jpg", own: false, blurb: "Stays one shared room per server. Your career opens the door, like today.", have: "Access, not ownership. Nothing to customize or save.", gate: "Today: 1 placement, 300 Aura, $5,000. Already works." },
    "west-s": { name: "THE WEST SUITE", built: true, img: "west.jpg", own: false, blurb: "Stays shared. It gets a gate so it means something.", have: "Access, not ownership.", gate: "Today: open to everyone. Would need a gate." },
    yr: { name: "Your Room", built: false, own: true, blurb: "Your own door in the shared building, your name in neon, furniture from day one.", have: "Your furniture, your career on the walls.", gate: "You start with it." },
    pro: { name: "Pro Room", built: false, own: true, blurb: "A bigger room behind the same door. Furniture and plaques move with you.", have: "More space, same stuff carried over.", gate: "$1,500 was a placeholder, never decided." },
    suite: { name: "Your Suite", built: false, own: true, blurb: "The biggest room of your own.", have: "Everything you've collected, room to show it.", gate: "To decide." },
    legends: { name: "THE HALL + THE WEST SUITE", built: true, img: "hall.jpg", own: false, blurb: "Unchanged. Shared rooms beside your ladder, not part of it.", have: "What's there today.", gate: "THE HALL: 1 placement, 300 Aura, $5,000. West Suite: open." }
  };
  A.views.rooms = function (root) {
    root.appendChild(h('<div class="vhead"><h2>Start in your bedroom, work your way up</h2><p>Today everyone spawns into the same finished studio. I want your space to show how far you\'ve come. <span class="tag idea">Proposal</span> Nothing on this page is built except THE HALL and THE WEST SUITE.</p></div>'));
    var seg = h('<div class="row"><span class="seglabel" style="padding:0">Version</span>' + Object.keys(MODELS).map(function (k) { return '<button type="button" class="fchip' + (S.roomModel === k ? " on" : "") + '" data-m="' + k + '">' + MODELS[k].name + "</button>"; }).join("") + "</div>");
    root.appendChild(seg);
    var body = h('<div style="display:grid;gap:16px"></div>'); root.appendChild(body);
    $$("[data-m]", seg).forEach(function (b) { b.addEventListener("click", function () { S.roomModel = b.getAttribute("data-m"); S.room = 0; $$("[data-m]", seg).forEach(function (x) { x.classList.toggle("on", x === b); }); draw(); }); });
    function draft() { return (store.data.rooms.draft || {}); }
    function draw() {
      var M = MODELS[S.roomModel]; body.innerHTML = "";
      body.appendChild(h('<p style="font-size:1.02rem">' + esc(M.line) + "</p>"));
      var lad = h('<div class="ladder">' + M.rungs.map(function (k, i) { var r = RUNG[k]; return '<button type="button" class="rung' + (i === S.room ? " on" : "") + (r.own ? "" : " shared") + '" data-r="' + i + '">' + (r.img ? '<img src="img/' + r.img + '" alt="' + esc(r.name) + '">' : '<span class="ph">Not built.<br>A concept.</span>') + '<span class="row" style="justify-content:space-between"><b>' + esc(r.name) + '</b><span class="tag ' + (r.built ? "work" : "idea") + '">' + (r.built ? "Built" : "Idea") + "</span></span><small>" + (r.own ? "Yours" : "Shared room") + " · " + esc(r.gate) + "</small></button>"; }).join("") + "</div>");
      body.appendChild(lad);
      $$("[data-r]", lad).forEach(function (b) { b.addEventListener("click", function () { S.room = +b.getAttribute("data-r"); draw(); }); });
      var key = M.rungs[S.room], r = RUNG[key], d = draft()[key] || {};
      var real = key.indexOf("hall") === 0 ? { cost: 5000, aura: 300, placements: 1 } : null;
      var det = h('<div class="grid2"><div class="box"><h3>' + esc(r.name) + "</h3><p>" + esc(r.blurb) + '</p><dl class="kv"><dt>What you have</dt><dd>' + esc(r.have) + "</dd><dt>Whose is it</dt><dd>" + (r.own ? "Yours. It saves, and you can change it." : "Shared by the whole server. Your career opens the door.") + "</dd><dt>Getting in</dt><dd>" + esc(r.gate) + "</dd><dt>Visitors</dt><dd>" + (r.own ? "Walk-ins come to you here. Other players by your door setting." : "Everyone who has unlocked it.") + "</dd></dl></div>" +
        '<div class="box"><h3>Draft what it takes to get here</h3><div class="lab"><label>Money<input type="number" data-d="cost" placeholder="' + (real ? real.cost : "e.g. 1500") + '" value="' + (d.cost != null ? d.cost : "") + '" data-store="rooms" data-id="draft"></label><label>Aura<input type="number" data-d="aura" placeholder="' + (real ? real.aura : "0") + '" value="' + (d.aura != null ? d.aura : "") + '" data-store="rooms" data-id="draft"></label><label>Placements<input type="number" data-d="placements" placeholder="' + (real ? real.placements : "0") + '" value="' + (d.placements != null ? d.placements : "") + '" data-store="rooms" data-id="draft"></label></div><p class="small muted">For scale, from the real game: the starter request pays $400 to $600. A normal request pays $250 to $980. Gear runs $250 to $4,000. THE HALL costs $5,000 with a placement and 300 Aura, and the pacing sim reaches it around day 4. Your career run has ' + money(S.run.money) + ", " + num(S.run.aura) + " Aura and " + S.run.placements + " placements.</p><p class=\"small dim\">Saved as a design note. It changes nothing in the game.</p></div></div>");
      body.appendChild(det);
      $$("[data-d]", det).forEach(function (inp) { inp.addEventListener("change", function () { var all = JSON.parse(JSON.stringify(draft())); all[key] = all[key] || {}; if (inp.value === "") delete all[key][inp.getAttribute("data-d")]; else all[key][inp.getAttribute("data-d")] = +inp.value; store.set("rooms", "draft", all); }); });
      body.appendChild(h('<div class="box"><h3>The three versions side by side</h3><div class="tw"><table class="t"><thead><tr><th></th><th>Climb all four</th><th>Two of your own, two shared</th><th>The Nov 4 plan</th></tr></thead><tbody>' + [
        ["Where you start", "Your bedroom", "Your bedroom", "Your Room, in the shared building"],
        ["THE HALL and THE WEST SUITE", "The top two steps. Yours.", "Shared premium rooms your career unlocks", "Unchanged, beside the ladder"],
        ["New rooms to build", "2 (bedroom, home studio)", "2 (bedroom, home studio)", "3 (room, pro room, suite)"],
        ["The hard part", "A private copy of two huge rooms per player, or taking turns. Heavy on phones", "Giving THE WEST SUITE a gate. Small", "Three new builds, and the legends stay disconnected from your climb"],
        ["What saves", "Your tier, plus anything you place in four rooms", "Your tier, plus what you place in two rooms", "Your tier, plus what you place in three rooms"],
        ["Day One story", "Rewritten for a bedroom", "Rewritten for a bedroom", "Stays in the studio"],
        ["Where friends meet", "In each other's rooms", "Your rooms, and the shared legends", "Your rooms, and today's studio"]
      ].map(function (x) { return "<tr><th>" + x[0] + "</th><td>" + x[1] + "</td><td>" + x[2] + "</td><td>" + x[3] + "</td></tr>"; }).join("") + "</tbody></table></div></div>"));
      body.appendChild(h('<div class="grid2"><div class="box"><h3>Today vs the idea</h3><table class="t"><tbody><tr><th>Where you start</th><td class="muted">A shared, finished studio</td><td>Your own bedroom</td></tr><tr><th>What money is for</th><td class="muted">Gear, fits, the door to THE HALL</td><td>The place you live and work</td></tr><tr><th>Where progress shows</th><td class="muted">Menus and a nameplate</td><td>A room you can walk through</td></tr><tr><th>What others see</th><td class="muted">Nameplate, fits, your beats on the speakers</td><td>Your room, when they visit</td></tr></tbody></table></div>' +
        '<div class="box"><h3>How far customizing goes</h3><table class="t"><tbody><tr><td><b>1 · Gear</b></td><td>Kits, voices, neon, nameplates, fits</td><td><span class="tag work">In the game</span></td></tr><tr><td><b>2 · Rooms</b></td><td>Unlock bigger rooms as fixed upgrades</td><td><span class="tag work">THE HALL only</span></td></tr><tr><td><b>3 · Gear shows up</b></td><td>What you buy appears in your room</td><td><span class="tag idea">Idea</span></td></tr><tr><td><b>4 · Build mode</b></td><td>Place furniture anywhere</td><td><span class="tag launch">Nov 4 plan</span></td></tr></tbody></table><p class="small muted">Already in the game to hang on a ladder: ' + C.Gear.length + " gear items, 3 kits, 3 keys voices, 3 fits, 12 firsts, plaques, a discography, 5 fame tiers.</p></div>" +
        '<div class="box"><h3>What it costs</h3><ul class="plain small"><li>Placing furniture is a new system, and saves have to remember every piece.</li><li>The place is at its light limit (61). New rooms need their own budget.</li><li>It has to run on a phone, and no phone has run the game yet.</li><li>Day One (the new opening) is built before the room. A bedroom start changes its story, so this is the call to make first.</li></ul></div></div>'));
      body.appendChild(h('<div class="pnote"><ul><li>Click through the three versions and let them react. The middle one is the cheapest way to get the bedroom story.</li><li>Type draft numbers together. They save as notes and show up under "Our notes".</li><li>On Nov 4 a 12-room phone test was built and removed without running. It gets rebuilt for the room design.</li></ul></div>'));
    }
    draw();
    store.subs.push(function () { var a = document.activeElement; if (!(a && a.getAttribute && a.getAttribute("data-store") === "rooms")) draw(); });
  };

  /* ================= 6. OUR NOTES ================= */
  var DECISIONS = [
    ["start", "Where does a new player start?", "Decides how Day One gets written, so it comes first.", [["bedroom", "Your own bedroom", "Day One written around it"], ["studio", "Today's shared studio", "Build Day One now, room later"], ["bedroom-then-studio", "Bedroom, then the studio", "A short bedroom opening"]]],
    ["legends", "THE HALL and THE WEST SUITE", "See the three versions under The room idea.", [["own", "Top of your own climb", "Yours. Heaviest to build"], ["shared", "Shared premium rooms", "Your career unlocks the door"], ["separate", "Beside the ladder", "As they are today"]]],
    ["custom", "How much can you change your room at launch?", "", [["fixed", "Fixed upgrades", "Cheapest"], ["gear-shows", "Gear shows up in the room", "Personal, no build mode"], ["place", "Place your own furniture", "Most work"]]],
    ["doors", "Who can walk into your room?", "", [["anyone", "Anyone in the server", ""], ["friends", "Friends only", ""], ["choose", "You choose", "Friends-only by default"]]],
    ["depth", "How deep does the career go?", "Every situation is a card or two today.", [["cards", "Quick cards", "Keep the pace"], ["some-systems", "Cards plus a few real systems", "Splits, a contract"], ["full", "A full industry sim", "Much more to build"]]],
    ["beatmaker", "How good does the beat maker need to be?", "", [["launch-pass", "The launch pass", "Two bars, real hat, 808 pitch, volumes"], ["real-tool", "A real tool", "Months of work"], ["simple", "Keep it simple", "The career is the game"]]],
    ["playtest", "When do people outside of us play it?", "", [["soon", "Soon, privately", "After Day One and phone fixes"], ["before-room", "Right before the room", ""], ["after-all", "After the whole list", ""]]],
    ["hooks", "Any of the seven hooks before launch?", "", [["none", "None", ""], ["few", "The ones we mark below", ""], ["all", "All seven", ""]]]
  ];
  var IDEAS = [
    ["split-sheet", "The placement with no split sheet", "Your beat is charting and nothing was signed. Chase it, call it out, or keep the relationship.", "navx_placement"],
    ["advance-publishing", "Advance or keep your publishing", "A big check now for a cut of everything later.", "tier_icon"],
    ["lease-exclusive", "Lease it or sell it exclusive", "Small money from many artists, or more from one.", null],
    ["sample-clearance", "The uncleared sample", "The song takes off, then the sample's owner shows up.", null],
    ["credit-fight", "Someone adds themselves to your credit", "Fight it, share it, or trade it for a favor.", "ghost_gig"],
    ["manager-cut", "A manager who takes a cut", "A percentage of everything, for bigger visitors.", null],
    ["loyalty", "The artist who blew up", "Someone you came up with gets big. Do they bring you along?", "two_sessions"],
    ["sync", "The TV or game placement", "Low pay, huge exposure.", "tier_known"],
    ["jacked", "Your beat got jacked", "A real release on your beat, never paid.", "leaked"],
    ["h-recap", "Hook: a comeback recap", "What happened today, and a teaser for tomorrow.", null],
    ["h-goals", "Hook: three goals always on screen", "Each pays out when done.", null],
    ["h-heat", "Hook: a HOT streak", "Three FIREs in a day: better odds, bigger visitors.", null],
    ["h-risk", "Hook: cards that can really go wrong", "High risk, high reward, rare.", null],
    ["h-fire", "Hook: a bigger FIRE moment", "A banner, and the visitor reacts.", null],
    ["h-rare", "Hook: rare cards that look rare", "Plus a cards-seen count in your story.", null],
    ["h-chart", "Hook: hottest beat in the server today", "A small chart, just for that server.", null]
  ];
  A.views.board = function (root) {
    root.appendChild(h('<div class="vhead"><h2>Our notes</h2><p>What we decide, what we want to change, and what happens next. Notes you leave on cards show up here too.</p></div>'));
    var body = h('<div style="display:grid;gap:18px"></div>'); root.appendChild(body);
    function summaryText() {
      var D = store.data, out = ["PROD LIFE III notes"], dec = [], open = [];
      DECISIONS.forEach(function (d) { var s = D.decisions[d[0]] || {}, o = d[3].filter(function (x) { return x[0] === s.choice; })[0]; if (o) dec.push("- " + d[1] + " " + o[1] + (s.note ? " (" + s.note + ")" : "")); else open.push("- " + d[1] + (s.note ? " " + s.note : "")); });
      if (dec.length) out.push("", "Decided:", dec.join("\n"));
      if (open.length) out.push("", "Still open:", open.join("\n"));
      var cn = Object.keys(D.cardnotes).filter(function (k) { return (D.cardnotes[k].notes || []).length; });
      if (cn.length) out.push("", "Card notes:", cn.map(function (k) { return "- " + k + ": " + D.cardnotes[k].notes.map(function (n) { return n.t; }).join(" | "); }).join("\n"));
      var marks = { yes: [], maybe: [] };
      IDEAS.forEach(function (i) { var m = (D.ideas[i[0]] || {}).mark; if (marks[m]) marks[m].push("- " + i[1]); });
      Object.keys(D.ideas).forEach(function (k) { var x = D.ideas[k]; if (x.custom && x.text) (marks[x.mark] || (marks.maybe)).push("- " + x.text + " (ours)"); });
      if (marks.yes.length) out.push("", "Ideas to build:", marks.yes.join("\n"));
      if (marks.maybe.length) out.push("", "Ideas to think about:", marks.maybe.join("\n"));
      var rd = D.rooms.draft || {}, rk = Object.keys(rd).filter(function (k) { return Object.keys(rd[k]).length; });
      if (rk.length) out.push("", "Room ladder draft:", rk.map(function (k) { return "- " + RUNG[k].name + ": " + Object.keys(rd[k]).map(function (f) { return f + " " + rd[k][f]; }).join(", "); }).join("\n"));
      var mn = (D.meeting.notes || {}).text; if (mn && mn.trim()) out.push("", "Meeting notes:", mn.trim());
      return out.join("\n");
    }
    function draw() {
      var D = store.data; body.innerHTML = "";
      /* decisions */
      var decided = DECISIONS.filter(function (d) { return (D.decisions[d[0]] || {}).choice; }).length;
      var dbox = h('<div style="display:grid;gap:8px"><div class="row" style="justify-content:space-between"><h3>Calls to make</h3><span class="small muted">' + decided + " of " + DECISIONS.length + " made</span></div></div>");
      DECISIONS.forEach(function (d) {
        var s = D.decisions[d[0]] || {};
        var el = h('<div class="decision' + (s.choice ? " done" : "") + '"><header><h4>' + esc(d[1]) + '</h4><span class="small muted">' + esc(d[2]) + '</span></header><div class="opts">' + d[3].map(function (o) { return '<button type="button" class="opt' + (s.choice === o[0] ? " on" : "") + '" data-o="' + o[0] + '"><b>' + esc(o[1]) + "</b>" + (o[2] ? "<span>" + esc(o[2]) + "</span>" : "") + "</button>"; }).join("") + '</div><input class="inp" type="text" placeholder="Note" aria-label="Note on: ' + esc(d[1]) + '" data-store="decisions" data-id="' + d[0] + '"></div>');
        $("input", el).value = s.note || "";
        $$("[data-o]", el).forEach(function (b) { b.addEventListener("click", function () { var cur = store.data.decisions[d[0]] || {}, v = b.getAttribute("data-o"); store.set("decisions", d[0], { choice: cur.choice === v ? null : v, note: cur.note || "", at: new Date().toISOString() }); }); });
        $("input", el).addEventListener("change", function (e) { var cur = store.data.decisions[d[0]] || {}; store.set("decisions", d[0], { choice: cur.choice || null, note: e.target.value, at: new Date().toISOString() }); });
        dbox.appendChild(el);
      });
      body.appendChild(dbox);
      /* card notes */
      var cn = Object.keys(D.cardnotes).filter(function (k) { return (D.cardnotes[k].notes || []).length && E.byId[k]; });
      var cbox = h('<div class="box"><h3>Changes we want on cards</h3>' + (cn.length ? "" : '<p class="small muted">None yet. Open any card under "Every card" and add a note, like "this choice should cost more" or "needs a worse outcome".</p>') + "</div>");
      cn.forEach(function (k) {
        var row = h('<div class="irow"><div><b>' + cardLink(k, A.whoName(E.byId[k].visitor, E.byId[k].sponsor) + " · " + E.byId[k].tag.replace("{sponsor}", "SPONSOR")) + '</b><ul class="plain small" style="margin-top:4px"></ul></div></div>');
        D.cardnotes[k].notes.forEach(function (n) { var li = document.createElement("li"); li.textContent = n.t; $("ul", row).appendChild(li); });
        cbox.appendChild(row);
      });
      body.appendChild(cbox);
      /* ideas */
      var ibox = h('<div class="box"><h3>Ideas on the table</h3><p class="small muted">Real industry situations that could become cards, plus the seven hooks from my Nov 6 play session. None are built.</p><div id="idea-list" style="display:grid;gap:8px"></div><div class="row" style="flex-wrap:nowrap"><input class="inp" id="idea-new" type="text" placeholder="Add an idea of ours" aria-label="Add an idea"><button type="button" class="btn sm hot" id="idea-add">Add</button></div></div>');
      var list = $("#idea-list", ibox);
      function ideaRow(id, title, text, near, custom) {
        var m = (D.ideas[id] || {}).mark || "";
        var el = h('<div class="irow"><div><b></b><span></span>' + (near && E.byId[near] ? '<span class="small">Closest card today: ' + cardLink(near) + "</span>" : "") + '</div><div class="marks">' + [["yes", "Build it"], ["maybe", "Maybe"], ["no", "Skip"]].map(function (x) { return '<button type="button" data-m="' + x[0] + '" class="' + (m === x[0] ? "on" : "") + '">' + x[1] + "</button>"; }).join("") + "</div></div>");
        $("b", el).textContent = title; $("span", el).textContent = text || "";
        $$("[data-m]", el).forEach(function (b) { b.addEventListener("click", function () { var cur = store.data.ideas[id] || {}, v = b.getAttribute("data-m"); var next = { mark: cur.mark === v ? "" : v, at: new Date().toISOString() }; if (custom) { next.custom = true; next.text = cur.text; } store.set("ideas", id, next); }); });
        list.appendChild(el);
      }
      IDEAS.forEach(function (i) { ideaRow(i[0], i[1], i[2], i[3]); });
      Object.keys(D.ideas).filter(function (k) { return D.ideas[k].custom && D.ideas[k].text; }).forEach(function (k) { ideaRow(k, D.ideas[k].text, "Ours, added in the meeting.", null, true); });
      function addIdea() { var inp = $("#idea-new", ibox), t = inp.value.trim(); if (!t) return; inp.value = ""; store.set("ideas", "ours-" + Date.now().toString(36), { custom: true, text: t, mark: "", at: new Date().toISOString() }); }
      $("#idea-add", ibox).addEventListener("click", addIdea);
      $("#idea-new", ibox).addEventListener("keydown", function (e) { if (e.key === "Enter") addIdea(); });
      body.appendChild(ibox);
      /* meeting notes + next */
      var nbox = h('<div class="grid2"><div class="box"><h3>Anything else we said</h3><textarea class="inp" id="meet" style="min-height:130px" placeholder="Names, ideas, who\'s doing what" data-store="meeting" data-id="notes"></textarea><div class="row"><button type="button" class="btn hot" id="copy">Copy everything as text</button></div><textarea class="inp mono" id="copy-fb" hidden readonly aria-label="Summary text"></textarea></div>' +
        '<div class="box"><h3>What happens next</h3><ol class="small" style="margin:0;padding-left:1.2em;display:grid;gap:4px"><li>I fold today\'s calls into the build plan. If the bedroom is a yes, Day One gets written for it.</li><li>Finish the fixes on the six characters who remember you, and rerun the full test suite.</li><li>Build the launch list in order: names and the random first visitor, Day One, phone fixes, server fixes, the visitor look, the beat maker upgrade, the room.</li><li>A final full check.</li></ol><h3>Only we can do these</h3><ul class="plain small"><li>Listen to the new sounds</li><li>Play it on a real phone, and with two people at once</li><li>Rename the experience and check the name is free</li><li>Publish privately first, then the maturity questions, icon and thumbnails</li></ul></div></div>');
      $("#meet", nbox).value = (D.meeting.notes || {}).text || "";
      var mt = null; $("#meet", nbox).addEventListener("input", function (e) { var v = e.target.value; clearTimeout(mt); mt = setTimeout(function () { store.set("meeting", "notes", { text: v, at: new Date().toISOString() }); }, 700); });
      $("#copy", nbox).addEventListener("click", function () {
        var t = summaryText(), btn = $("#copy", nbox), fb = $("#copy-fb", nbox), show = function () { fb.hidden = false; fb.value = t; fb.style.minHeight = "160px"; fb.focus(); fb.select(); };
        try { navigator.clipboard.writeText(t).then(function () { btn.textContent = "Copied"; setTimeout(function () { btn.textContent = "Copy everything as text"; }, 1600); }, show); } catch (e) { show(); }
      });
      body.appendChild(nbox);
      body.appendChild(h('<div class="pnote"><ul><li>After the meeting, tell Claude to read the walkthrough notes. Every pick, card note, idea and draft number is stored with this page.</li><li>Already decided, no need to reopen: made-up names, the random first visitor, Day One, the beat maker pass, visitor look B (OK\'s pick), the light limit at 61, the room on the launch list.</li></ul></div>'));
      wireOpen(body);
    }
    draw();
    store.subs.push(function () { var a = document.activeElement; if (a && /TEXTAREA|INPUT/.test(a.tagName) && a.getAttribute("data-store")) return; draw(); });
  };

  A.boot();
})();
