/* Prod Life III explorer: core, notes store, the card component, the card library and the career run. */
(function () {
  "use strict";
  var PL = window.PL, E = window.PLE, C = PL.config;
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var esc = function (s) { return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]; }); };
  var h = function (html) { var t = document.createElement("template"); t.innerHTML = html.trim(); return t.content.firstElementChild; };
  var num = function (n) { return Math.round(n).toLocaleString("en-US"); };
  var money = function (n) { return (n < 0 ? "−$" : "$") + num(Math.abs(n)); };
  var signed = function (n) { return (n > 0 ? "+" : "−") + num(Math.abs(n)); };
  function local(key, val) { try { if (val === undefined) return JSON.parse(localStorage.getItem("pl3x." + key) || "null"); localStorage.setItem("pl3x." + key, JSON.stringify(val)); } catch (e) { return null; } }

  var S = { dev: false, roster: "parody", lab: E.PRESETS[1].make(), labPreset: "placed", run: E.PRESETS[0].make(), runPreset: "fresh", runLog: [], runCur: null,
    sel: "navx_placement", q: "", type: "all", who: "", mech: {}, onlyOpen: false, sys: "beat", room: 0, roomModel: "own" };

  /* ---------- names and text ---------- */
  function sponsorName(id) { var s = E.sponsorById[id]; return s ? s.names[S.roster] : null; }
  function whoName(vid, sp) {
    var v = E.visitorById[vid]; if (!v) return vid;
    return v.names[S.roster].replace("{sponsor}", sp ? sponsorName(sp) : "YOUR SPONSOR");
  }
  function fill(text, card, prof, ctxSp) {
    var sp = card.sponsor || ctxSp || (prof && prof.sponsor);
    var bb = prof ? E.bestBeat(prof.recent) : null;
    return String(text || "").replace(/\{name:([^}]+)\}/g, function (_, id) { return whoName(id, sp); })
      .replace(/\{sponsor\}/g, sp ? sponsorName(sp) : "your sponsor")
      .replace(/\{beat\}/g, bb && !E.isPhone(card) ? "the one at " + (bb.bpm || 142) : "something");
  }
  var STAT = { money: "Money", aura: "Aura", followers: "Followers", placements: "Placements", hits: "Hits", sponsors: "Sponsors", xp: "XP" };
  function chips(a, extra) {
    var out = [];
    if (a.cost) out.push('<span class="chip neg">' + money(-a.cost) + " paid</span>");
    ["money", "aura", "followers", "placements", "hits", "sponsors", "xp"].forEach(function (k) {
      if (!a[k]) return;
      out.push('<span class="chip ' + (a[k] > 0 ? "pos" : "neg") + '">' + (k === "money" ? (a[k] > 0 ? "+" : "") + money(a[k]) : signed(a[k]) + " " + STAT[k]) + "</span>");
    });
    if (!out.length && !extra) out.push('<span class="chip zero">No stat change</span>');
    return out.join("") + (extra || "");
  }
  function outcomeDeltas(o) { return { cost: 0, money: o.money || 0, aura: o.aura || 0, followers: o.followers || 0, placements: o.placements || 0, hits: o.hits || 0, sponsors: o.sponsors || 0, xp: o.xp || 0 }; }
  function pips(score) {
    var out = '<span class="pips" title="' + score + '">';
    for (var i = -3; i <= 3; i++) { if (i === 0) { out += '<i class="mid"></i>'; continue; } out += '<i class="' + (i < 0 && score <= i ? "neg" : i > 0 && score >= i ? "pos" : "") + '"></i>'; }
    return out + "</span>";
  }
  function stars(n, fires) { var s = ""; for (var i = 1; i <= 3; i++) s += i <= n ? "★" : "<s>★</s>"; return '<span class="stars" style="font-size:1em">' + s + "</span>" + (fires ? " · 🔥 " + fires : ""); }
  function typeOf(c) { if (c.fu) return "followup"; if (E.isPhone(c)) return c.news ? "news" : "phone"; return "walkin"; }
  var TYPE = { walkin: "Walk-in", phone: "Phone", news: "News", followup: "Follow-up" };
  function allOutcomes(c) {
    var o = [];
    (c.choices || []).forEach(function (ch) { ["good", "bad", "rare"].forEach(function (k) { if (ch[k]) o.push(ch[k]); }); });
    if (c.resolve) ["good", "bad"].forEach(function (k) { if (c.resolve[k]) o.push(c.resolve[k]); });
    return o;
  }
  var MECH = [
    ["beat", "Uses your beat", function (c) { return (c.choices || []).some(function (x) { return x.beat || x.beatMin; }); }],
    ["cost", "Costs money", function (c) { return (c.choices || []).some(function (x) { return x.cost; }); }],
    ["gate", "Has requirements", function (c) { return !!(c.needs || c.under || c.when || c.sponsor || c.aired); }],
    ["plant", "Comes back later", function (c) { return allOutcomes(c).some(function (o) { return o.plant; }); }],
    ["rel", "They remember", function (c) { return allOutcomes(c).some(function (o) { return o.rel; }) || !!((c.needs && (c.needs.flags || c.needs.rel != null)) || (c.under && (c.under.flags || c.under.rel != null))); }],
    ["placement", "Placement", function (c) { return allOutcomes(c).some(function (o) { return o.placements > 0; }); }],
    ["hit", "Hit", function (c) { return allOutcomes(c).some(function (o) { return o.hits > 0; }); }],
    ["deal", "Sponsor deal", function (c) { return allOutcomes(c).some(function (o) { return o.sponsor; }); }],
    ["rare", "Rare outcome", function (c) { return (c.choices || []).some(function (x) { return x.rare; }); }],
    ["cap", "Limited per day or week", function (c) { return !!c.cap; }],
    ["safe", "No way to lose", function (c) { return !c.resolve && (c.choices || []).every(function (x) { return x.sure && !x.rare; }) && allOutcomes(c).every(function (o) { return o.tone !== "loss"; }); }]
  ];
  PL.cards.forEach(function (c) {
    c._type = typeOf(c); c._mech = {};
    MECH.forEach(function (m) { if (m[2](c)) c._mech[m[0]] = true; });
    c._text = [c.id, c.tag, c.line, E.visitorById[c.visitor].names.parody, E.visitorById[c.visitor].names.fiction].concat((c.choices || []).map(function (x) { return x.text; }), allOutcomes(c).map(function (o) { return o.headline + " " + o.text + " " + o.line; })).join(" ").toLowerCase();
  });

  /* ---------- notes store (shared db, with a this-browser fallback) ---------- */
  var store = { data: { decisions: {}, ideas: {}, cardnotes: {}, meeting: {}, rooms: {} }, mode: "loading", db: null, subs: [], queues: {} };
  function say(msg) { var el = $("#save-line"); if (el) el.textContent = msg; }
  store.changed = function () { store.subs.forEach(function (f) { try { f(); } catch (e) { /* a view that is gone */ } }); };
  store.set = function (coll, id, body) {
    store.data[coll][id] = body;
    store.changed();
    if (store.mode === "readonly") return;
    if (store.mode !== "live") { local("store", store.data); return; }
    var path = coll + "/" + id, q = store.queues[path] || Promise.resolve();
    store.queues[path] = q.then(function () { say("Saving…"); return store.db.doc(path).set(body); }).then(function () { say("Saved."); }, function (e) {
      if (e && e.code === "invalid_argument") { store.mode = "readonly"; say("You can read the notes here but not change them."); }
      else say("That change didn't save (" + ((e && e.code) || "error") + "). Try it again.");
    });
  };
  store.start = function () {
    function goLocal(msg) { store.mode = "local"; var s = local("store"); if (s) Object.keys(store.data).forEach(function (k) { store.data[k] = s[k] || {}; }); say(msg); store.changed(); }
    say("Connecting to the notes…");
    if (!(window.claude && window.claude.use)) return goLocal("Notes save in this browser only.");
    Promise.resolve(window.claude.use("db")).then(function (db) {
      if (!db) return goLocal("Notes save in this browser only.");
      store.db = db; store.mode = "live";
      var got = 0, timer = setTimeout(function () { say("The notes store isn't answering yet."); }, 10000);
      Object.keys(store.data).forEach(function (coll) {
        db.collection(coll).onSnapshot(function (snap) {
          var typing = document.activeElement && /TEXTAREA|INPUT/.test(document.activeElement.tagName) && document.activeElement.getAttribute("data-store") === coll;
          var next = {}; snap.docs.forEach(function (d) { next[d.id] = d.data() || {}; });
          if (typing) { var keep = document.activeElement.getAttribute("data-id"); if (keep && store.data[coll][keep]) next[keep] = store.data[coll][keep]; }
          store.data[coll] = next;
          if (!snap.metadata.fromCache) { got++; if (got >= 5) { clearTimeout(timer); say("Notes save for everyone with this page."); } }
          if (!typing) store.changed();
        }, function (e) { clearTimeout(timer); say("The notes store stopped answering (" + e.code + ")."); });
      });
    }, function () { goLocal("Notes save in this browser only."); });
  };

  /* ---------- router and chrome ---------- */
  var views = {};
  var APP = window.APP = { S: S, E: E, PL: PL, $: $, $$: $$, esc: esc, h: h, num: num, money: money, signed: signed, chips: chips, pips: pips, stars: stars,
    whoName: whoName, sponsorName: sponsorName, fill: fill, store: store, views: views, local: local, TYPE: TYPE, MECH: MECH };
  function current() { var v = (location.hash || "#game").slice(1); return views[v] ? v : "game"; }
  function render() {
    var v = current(), root = $("#view");
    store.subs = [];
    root.innerHTML = ""; root.className = "view v-" + v;
    $$("#nav a").forEach(function (a) { a.classList.toggle("on", a.getAttribute("href") === "#" + v); });
    views[v](root);
    wireShots(root);
  }
  APP.render = render;
  APP.go = function (v) { if (current() === v) render(); else location.hash = v; };
  APP.openCard = function (id) { S.sel = id; S.q = ""; S.type = "all"; S.who = ""; S.mech = {}; S.onlyOpen = false; APP.go("cards"); window.scrollTo(0, 0); };
  function wireShots(root) {
    $$("img.shot", root).forEach(function (img) {
      img.addEventListener("click", function () { var z = $("#zoom"); $("img", z).src = img.src; $("p", z).textContent = img.getAttribute("data-cap") || img.alt; z.hidden = false; });
    });
  }
  APP.wireShots = wireShots;
  function seg(id, key, after) {
    $$("#" + id + " button").forEach(function (b) {
      b.addEventListener("click", function () {
        $$("#" + id + " button").forEach(function (x) { x.classList.toggle("on", x === b); });
        after(b.getAttribute("data-v"));
      });
    });
  }
  function setDev(on) { S.dev = on; document.documentElement.classList.toggle("dev", on); $$("#seg-view button").forEach(function (x) { x.classList.toggle("on", (x.getAttribute("data-v") === "dev") === on); }); }
  function setNotes(on) { document.documentElement.classList.toggle("notes-on", on); $("#toggle-notes").setAttribute("aria-pressed", on ? "true" : "false"); }
  var ROUTE = [["Before you start", "Studio in Edit, press Play (not Run), wait about 10 s. Check 🔊 top left. Keep the window wide."], ["1 · Look around", "The tour tracker at the top, the HUD, the OS button."], ["2 · First visitor", "Within about 30 s. Read the card out loud and pick one."], ["3 · Studio PC", "Press F on \"Make a beat\"."], ["4 · JUNO's request", "Take it, tick every ask, KEYS for a few notes, DELIVER."], ["5 · ON MONITORS", "The whole room hears it."], ["6 · The OS", "Career, then Story (firsts), then Credits."], ["7 · Phone", "Tap it when it pulses, 1.5 to 2.5 min after the tour."], ["8 · The lounge", "Gear rack, cypher board (don't start one alone), credits wall, TV."], ["9 · THE HALL door", "\"Enter · The Hall\". Locked unless demo prep ran."], ["10 · THE WEST SUITE", "No gate. Show the scale of it."]];
  function boot() {
    $("#nav-count").textContent = PL.cards.length + " cards, all playable";
    seg("seg-view", "dev", function (v) { setDev(v === "dev"); });
    seg("seg-names", "roster", function (v) { S.roster = v; render(); });
    $("#toggle-notes").addEventListener("click", function () { setNotes(!document.documentElement.classList.contains("notes-on")); });
    var route = $("#route"), ticks = local("route") || {};
    $("#route-list").innerHTML = ROUTE.map(function (r, i) { return '<label><input type="checkbox" id="rt' + i + '"' + (ticks[i] ? " checked" : "") + "><div><b>" + esc(r[0]) + "</b><span>" + esc(r[1]) + "</span></div></label>"; }).join("");
    $$("#route-list input").forEach(function (cb, i) { cb.addEventListener("change", function () { ticks[i] = cb.checked; local("route", ticks); }); });
    $("#toggle-route").addEventListener("click", function () { route.hidden = !route.hidden; });
    $("#route-close").addEventListener("click", function () { route.hidden = true; });
    $("#zoom").addEventListener("click", function () { $("#zoom").hidden = true; });
    document.addEventListener("keydown", function (e) {
      var a = document.activeElement;
      if ((a && /TEXTAREA|INPUT|SELECT/.test(a.tagName)) || e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.key === "n" || e.key === "N") setNotes(!document.documentElement.classList.contains("notes-on"));
      else if (e.key === "l" || e.key === "L") route.hidden = !route.hidden;
      else if (e.key === "d" || e.key === "D") setDev(!S.dev);
      else if (e.key === "Escape") { route.hidden = true; $("#zoom").hidden = true; }
      else if (/^[1-6]$/.test(e.key)) APP.go(["game", "play", "cards", "systems", "rooms", "board"][+e.key - 1]);
    });
    window.addEventListener("hashchange", function () { render(); window.scrollTo(0, 0); });
    render();
    store.start();
  }

  /* ---------- the card, as the game shows it ---------- */
  function auraFooter(a) { return a < 0 ? "Your Aura's in the red. People hesitate. Odds stay hidden." : a >= 300 ? "Your Aura's loud. People lean in. Odds stay hidden." : "Your Aura and Followers tilt the odds. You never see them."; }
  function oddsBadge(card, ch, prof) {
    var b = E.breakdown(card, ch, prof), t;
    if (b.kind === "sure") t = "always";
    else if (b.kind === "beatMin") t = b.chance === 100 ? "your beat wins it" : "needs a " + ch.beatMin + "-star beat";
    else t = b.chance + "%";
    if (b.rareOdds) t += " · " + b.rareOdds + "% rare";
    return '<span class="odds devonly inl">' + t + "</span>";
  }
  function portrait(card) { var c = E.visitorById[card.visitor].color || [120, 90, 70]; return '<span class="portrait" style="background:rgb(' + c.join(",") + ')"></span>'; }
  function newsStrip(card, news, prof, ctxSp) {
    var o = news.outcome;
    return '<div class="gnews ' + esc(o.tone) + '"><b>' + esc(fill(o.headline, card, prof, ctxSp)) + "</b><span>" + esc(fill(o.text, card, prof, ctxSp)) + '</span><div class="hudrow">' + chips(news.applied, "") + "</div>" +
      (o.note ? '<span class="gnote">' + esc(o.note) + "</span>" : "") + "</div>";
  }
  /* face = the card before you choose. handlers: choose(i), walk() */
  function cardFace(card, prof, o) {
    var phone = E.isPhone(card), sp = o.ctxSp, isNews = !!card.news, hasChoices = (card.choices || []).length > 0;
    var beatCard = (card.choices || []).some(function (x) { return x.beat || x.beatMin; }), bb = E.bestBeat(prof.recent);
    var html = '<div class="gcard' + (phone ? " phone" : "") + '"><div class="ghead">' + portrait(card) + "<div><b>" + esc(whoName(card.visitor, card.sponsor || sp || prof.sponsor)) + "</b><span>" +
      esc(phone ? (card.app || "MESSAGES") : fill(card.tag, card, prof, sp)) + "</span></div><em>" + esc(o.count || "") + "</em></div>";
    if (o.news) html += newsStrip(card, o.news, prof, sp);
    html += '<p class="gline">' + esc(fill(card.line, card, prof, sp)) + "</p>";
    if (hasChoices) {
      html += '<div class="gchoices">' + card.choices.map(function (ch, i) {
        var cant = (ch.cost || 0) > prof.money;
        return '<button type="button" class="gchoice" data-i="' + i + '"' + (cant ? ' disabled title="You can\'t afford this"' : "") + "><span>" + esc(fill(ch.text, card, prof, sp)) + "</span><span>" + (ch.cost ? '<span class="cost">' + money(ch.cost) + "</span>" : "") + oddsBadge(card, ch, prof) + "</span></button>";
      }).join("") + "</div>";
      html += '<div class="gfootrow"><div class="gfoot"><span>' + auraFooter(prof.aura) + "</span>" + (beatCard ? "<span>" + (bb ? "Your best beat: " + "★".repeat(bb.stars || 0) + (bb.fires ? " · 🔥 " + bb.fires : "") : "No beat delivered yet. Your odds are lower.") + "</span>" : "") + "</div>" +
        (isNews ? "" : '<button type="button" class="gwalk">' + (phone ? "Dismiss" : "Walk away") + "</button>") + "</div>";
    } else if (o.onContinue) html += '<div class="gfootrow"><span></span><button type="button" class="gwalk">Nice</button></div>';
    html += "</div>";
    var el = h(html);
    $$(".gchoice", el).forEach(function (b) { b.addEventListener("click", function () { o.choose(+b.getAttribute("data-i")); }); });
    var w = $(".gwalk", el); if (w) w.addEventListener("click", function () { (hasChoices ? o.walk : o.onContinue)(); });
    return el;
  }
  function resultFace(card, r, res, prof, o) {
    var out = r.outcome, sp = o.ctxSp;
    var el = h('<div class="gcard' + (E.isPhone(card) ? " phone" : "") + '"><div class="ghead">' + portrait(card) + "<div><b>" + esc(whoName(card.visitor, card.sponsor || sp || prof.sponsor || (res.events.filter(function (e) { return e.t === "sponsor"; })[0] || {}).id)) + "</b><span>" + esc(fill(card.tag, card, prof, sp)) + '</span></div><em></em></div><div class="gres ' + esc(out.tone) + '"><b>' + esc(fill(out.headline, card, prof, sp)) + "</b><p>" + esc(fill(out.text, card, prof, sp)) + '</p><div class="gbubble">' + esc(fill(out.line, card, prof, sp)) + '</div><div class="hudrow">' + chips(res.applied, "") + "</div>" +
      (out.note ? '<p class="gnote">' + esc(out.note) + "</p>" : "") + '</div><div class="gfootrow"><span></span><button type="button" class="gwalk">' + esc(o.doneLabel || "Nice") + "</button></div></div>");
    $(".gwalk", el).addEventListener("click", o.done);
    return el;
  }

  /* ---------- what changed ---------- */
  function evHtml(ev, card) {
    var link = function (id) { return '<button type="button" class="linkish" data-open="' + esc(id) + '">' + esc(E.byId[id] ? E.byId[id].tag : id) + "</button>"; };
    if (ev.t === "plant") return ["↻", '<span class="playeronly">Something comes back from this in a few visits.</span><span class="devonly">Plants ' + link(ev.id) + " <code>" + esc(ev.id) + "</code>, due in " + ev.inVisits + (ev.inVisits === 1 ? " visit" : " visits") + " (range " + ev.range[0] + " to " + ev.range[1] + ")" + (ev.why ? ", because of " + esc(ev.why) : "") + ".</span>"];
    if (ev.t === "rel") {
      var parts = [];
      if (ev.before !== ev.after) parts.push(pips(ev.before) + " → " + pips(ev.after) + " <b>" + (ev.after > ev.before ? "They like you more." : "They like you less.") + "</b> Their rolls move " + (ev.after * C.WalkIns.Odds.relPer >= 0 ? "+" : "−") + Math.abs(ev.after * C.WalkIns.Odds.relPer) + " points.");
      if (ev.flag) parts.push("They'll remember this" + '<span class="devonly"> (<code>' + esc(ev.who + "." + ev.flag) + "</code>)</span>. " + flagEffects(ev.who + "." + ev.flag));
      if (ev.clear) parts.push("That's settled now" + '<span class="devonly"> (clears <code>' + esc(ev.who + "." + ev.clear) + "</code>)</span>. " + flagEffects(ev.who + "." + ev.clear, true));
      return ["♥", "<b>" + esc(whoName(ev.who)) + "</b><br>" + parts.join("<br>")];
    }
    if (ev.t === "tier") return ["▲", "New fame tier: <b>" + esc(ev.id) + "</b>."];
    if (ev.t === "sponsor") return ["$", ev.drop ? "<b>" + esc(sponsorName(ev.id) || "Your sponsor") + "</b> dropped you." : "Signed with <b>" + esc(sponsorName(ev.id)) + "</b>. Keep your Aura at " + E.sponsorById[ev.id].floor + " or they pull the deal."];
    if (ev.t === "cooldown") return ["⏸", esc(whoName(ev.who)) + " stays away for " + ev.n + " extra visits."];
    if (ev.t === "cold") return ["❄", "<b>You went cold</b> (" + (ev.reason === "aura" ? "Aura under " + C.WalkIns.Cold.aura : C.WalkIns.Cold.quietDays + " days with no delivery") + "). Two visitors a day, phone silent."];
    if (ev.t === "thaw") return ["☀", "<b>You're back.</b> People are calling again."];
    if (ev.t === "heal") return ["+", "The internet forgot. +" + ev.n + " Aura."];
    if (ev.t === "level") return ["▲", "Level " + ev.level + ": " + esc(C.Ranks[ev.level - 1]) + (C.Unlocks[String(ev.level)] ? ". " + esc(C.Unlocks[String(ev.level)]) : "") + "."];
    if (ev.t === "disco") return ["♪", "Added to your discography."];
    if (ev.t === "note") return ["i", esc(ev.text)];
    return ["·", esc(JSON.stringify(ev))];
  }
  function flagEffects(id, cleared) {
    var opens = [], closes = [];
    PL.cards.forEach(function (c) {
      if (c.needs && c.needs.flags && c.needs.flags.indexOf(id) >= 0) opens.push(c.id);
      if (c.under && c.under.flags && c.under.flags.indexOf(id) >= 0) closes.push(c.id);
    });
    var link = function (x) { return '<button type="button" class="linkish" data-open="' + esc(x) + '">' + esc(E.byId[x].tag) + "</button>"; };
    var out = [];
    if (cleared) { if (closes.length) out.push("Can show up again: " + closes.map(link).join(", ") + "."); if (opens.length) out.push("No longer possible: " + opens.map(link).join(", ") + "."); }
    else { if (opens.length) out.push("Opens: " + opens.map(link).join(", ") + "."); if (closes.length) out.push("Closes: " + closes.map(link).join(", ") + "."); }
    return out.join(" ");
  }
  function whyHtml(r, card) {
    var b = r.b, m;
    if (r.roll === "rare") return "<span>The rare outcome rolls first, at " + b.rareOdds + "%. " + (r.forced ? "You picked it to look at it." : "It hit.") + "</span>";
    if (b.kind === "sure") return "<span>No roll. This choice always goes this way." + (b.rareOdds ? " (Unless the " + b.rareOdds + "% rare outcome hits first.)" : "") + "</span>";
    if (b.kind === "beatMin") return "<span>No roll. It checks your best recent beat. It needs quality " + b.beatMin + " (three stars, or two stars with 3 FIREs). Yours is " + b.beatQ + ".</span>";
    m = '<div class="math">';
    if (b.kind === "ready") m += "<span>" + b.base + "</span><span class=\"t\">from how ready you are (" + Math.round(b.readiness * 100) + "%: level, placements, followers and Aura)</span>";
    else {
      m += "<span>" + b.base + "</span><span class=\"t\">base</span>";
      if (b.auraPts) m += "<span>" + signed(b.auraPts) + "</span><span class=\"t\">Aura</span>";
      if (b.folPts) m += "<span>" + signed(b.folPts) + "</span><span class=\"t\">followers</span>";
    }
    if (b.beatPts) m += "<span>" + signed(b.beatPts) + "</span><span class=\"t\">your beat</span>";
    if (b.relPts) m += "<span>" + signed(b.relPts) + "</span><span class=\"t\">how they feel about you</span>";
    m += '<span class="t">=</span><span class="res">' + b.chance + "%</span>" + (b.raw !== b.chance ? '<span class="t">(kept between ' + b.min + " and " + b.max + ")</span>" : "") + "</div>";
    return m + "<span>" + (r.forced ? "You picked this outcome to look at it." : "It rolled " + (r.roll === "good" ? "your way." : "against you.")) + (E.isPhone(card) ? " Phone choices never use the relationship." : "") + "</span>";
  }
  function deltaRow(label, b, a, fmt, bar) { return '<div class="delta"><span class="lbl">' + label + "</span>" + (bar || "<span></span>") + '<span class="ba"><s>' + fmt(b) + "</s> → <b>" + fmt(a) + "</b></span></div>"; }
  function auraBar(b, a) {
    var lo = -150, hi = 600, x = function (v) { return Math.max(0, Math.min(100, (v - lo) / (hi - lo) * 100)); };
    return '<div class="bar" title="scale −150 to 600; marks at 0 and 300"><i style="left:' + Math.min(x(b), x(a)) + "%;width:" + Math.max(1.5, Math.abs(x(a) - x(b))) + "%;background:" + (a >= b ? "var(--green)" : "var(--red)") + '"></i><i style="left:' + x(0) + '%;width:1px;background:var(--ink3)"></i><i style="left:' + x(300) + '%;width:1px;background:var(--ink3)"></i></div>';
  }
  function tierBar(b, a) {
    var t = C.Life.Tiers, i = Math.min(E.tierIndex(a), t.length - 2), lo = t[i].followers, hi = t[i + 1].followers, x = function (v) { return Math.max(0, Math.min(100, (v - lo) / (hi - lo) * 100)); };
    return '<div class="bar" title="toward ' + t[i + 1].id + '"><i style="left:0;width:' + x(Math.min(a, b)) + '%;background:var(--blue);opacity:.45"></i><i style="left:' + x(Math.min(a, b)) + "%;width:" + Math.max(1.5, Math.abs(x(a) - x(b))) + "%;background:" + (a >= b ? "var(--green)" : "var(--red)") + '"></i></div>';
  }
  function changes(before, after, events, r, card, host) {
    var rows = [];
    if (before.money !== after.money) rows.push(deltaRow("Money", before.money, after.money, money));
    if (before.aura !== after.aura) rows.push(deltaRow("Aura", before.aura, after.aura, num, auraBar(before.aura, after.aura)));
    if (before.followers !== after.followers) rows.push(deltaRow("Followers", before.followers, after.followers, num, tierBar(before.followers, after.followers)));
    ["placements", "hits", "sponsors"].forEach(function (k) { if (before[k] !== after[k]) rows.push(deltaRow(STAT[k], before[k], after[k], num)); });
    if (before.xp !== after.xp) rows.push(deltaRow("XP", before.xp, after.xp, num));
    var evs = (events || []).map(function (ev) { var x = evHtml(ev, card); return '<div class="event"><span class="ic">' + x[0] + "</span><div>" + x[1] + "</div></div>"; });
    var html = '<div class="box changes"><h3>What changed</h3>' + (rows.length ? rows.join("") : '<p class="muted small">No stats moved.</p>') + evs.join("");
    if (r) html += '<button type="button" class="btn sm ghost playeronly whybtn" style="justify-self:start">Why did that happen?</button><div class="why devonly grid">' + whyHtml(r, card) + "</div>";
    html += "</div>";
    var el = h(html);
    var wb = $(".whybtn", el); if (wb) wb.addEventListener("click", function () { wb.remove(); $(".why", el).classList.remove("devonly"); });
    $$("[data-open]", el).forEach(function (b) { b.addEventListener("click", function () { APP.openCard(b.getAttribute("data-open")); }); });
    host.appendChild(el);
  }
  APP.changes = changes; APP.evHtml = evHtml;

  /* ---------- the library ---------- */
  function noteCount(id) { var n = store.data.cardnotes[id]; return n && n.notes ? n.notes.length : 0; }
  function matches(c) {
    if (S.type !== "all" && c._type !== S.type) return false;
    if (S.who && c.visitor !== S.who) return false;
    for (var k in S.mech) if (S.mech[k] && !c._mech[k]) return false;
    if (S.onlyOpen && !E.eligible(c, S.lab, E.isPhone(c) ? "phone" : "walkin")) return false;
    if (S.q) { var words = S.q.toLowerCase().split(/\s+/); for (var i = 0; i < words.length; i++) if (c._text.indexOf(words[i]) < 0) return false; }
    return true;
  }
  views.cards = function (root) {
    var counts = { all: PL.cards.length }; PL.cards.forEach(function (c) { counts[c._type] = (counts[c._type] || 0) + 1; });
    var whoCounts = {}; PL.cards.forEach(function (c) { whoCounts[c.visitor] = (whoCounts[c.visitor] || 0) + 1; });
    root.appendChild(h('<div class="vhead"><h2>Every card in the game</h2><p><b>' + PL.cards.length + " cards</b>, pulled straight from the game's data file: " + PL.meta.cards + " cards that can be drawn and " + PL.meta.followups + " follow-ups that come back later. Open one and play it. Switch to Developer on the left to see the odds and wiring.</p></div>"));
    var bar = h('<div class="libbar"><input class="search" id="lib-q" type="search" placeholder="Search names, lines, choices, outcomes" value="' + esc(S.q) + '" aria-label="Search cards"><div class="filters" id="f-type"></div><div class="filters" id="f-mech"></div></div>');
    root.appendChild(bar);
    $("#f-type", bar).innerHTML = ["all", "walkin", "phone", "news", "followup"].map(function (t) { return '<button type="button" class="fchip' + (S.type === t ? " on" : "") + '" data-t="' + t + '">' + (t === "all" ? "All" : TYPE[t]) + "<b>" + (counts[t] || 0) + "</b></button>"; }).join("") +
      '<select id="f-who" aria-label="Who"><option value="">Anyone</option>' + PL.visitors.filter(function (v) { return whoCounts[v.id]; }).map(function (v) { return '<option value="' + v.id + '"' + (S.who === v.id ? " selected" : "") + ">" + esc(whoName(v.id)) + " (" + whoCounts[v.id] + ")</option>"; }).join("") + "</select>" +
      '<button type="button" class="fchip' + (S.onlyOpen ? " on" : "") + '" id="f-open" title="Only cards the test producer below could draw right now">Can show up now</button>';
    $("#f-mech", bar).innerHTML = MECH.map(function (m) { var n = PL.cards.filter(function (c) { return c._mech[m[0]]; }).length; return '<button type="button" class="fchip' + (S.mech[m[0]] ? " on" : "") + '" data-m="' + m[0] + '">' + m[1] + "<b>" + n + "</b></button>"; }).join("");
    var lib = h('<div class="lib"><div><p class="small muted" id="lib-n" style="margin-bottom:6px"></p><div class="liblist" id="lib-list"></div></div><div class="detail" id="lib-detail"></div></div>');
    root.appendChild(lib);
    function list() {
      var shown = PL.cards.filter(matches);
      $("#lib-n", lib).textContent = shown.length === PL.cards.length ? "Showing all " + shown.length : "Showing " + shown.length + " of " + PL.cards.length;
      var box = $("#lib-list", lib); box.innerHTML = "";
      if (!shown.length) box.appendChild(h('<p class="muted small">Nothing matches. Clear a filter or the search.</p>'));
      shown.forEach(function (c) {
        var nn = noteCount(c.id);
        var b = h('<button type="button" class="litem' + (c.id === S.sel ? " on" : "") + '"><span class="who"><span>' + esc(whoName(c.visitor, c.sponsor)) + "</span><em>" + TYPE[c._type] + '</em></span><span class="ln">' + esc(fill(c.line, c, null)) + '</span><span class="mt"><span>' + esc(c.tag.replace("{sponsor}", c.sponsor ? sponsorName(c.sponsor) : "SPONSOR")) + "</span>" + (nn ? '<span class="n">' + nn + (nn === 1 ? " note" : " notes") + "</span>" : "") + "</span></button>");
        b.addEventListener("click", function () { S.sel = c.id; $$(".litem", box).forEach(function (x) { x.classList.remove("on"); }); b.classList.add("on"); detail(); if (window.innerWidth < 860) $("#lib-detail", lib).scrollIntoView(); });
        box.appendChild(b);
      });
    }
    function detail() { cardDetail($("#lib-detail", lib), E.byId[S.sel] || PL.cards[0], function () { list(); }); }
    $("#lib-q", bar).addEventListener("input", function (e) { S.q = e.target.value; list(); });
    $$("[data-t]", bar).forEach(function (b) { b.addEventListener("click", function () { S.type = b.getAttribute("data-t"); $$("[data-t]", bar).forEach(function (x) { x.classList.toggle("on", x === b); }); list(); }); });
    $$("[data-m]", bar).forEach(function (b) { b.addEventListener("click", function () { var k = b.getAttribute("data-m"); S.mech[k] = !S.mech[k]; b.classList.toggle("on", S.mech[k]); list(); }); });
    $("#f-who", bar).addEventListener("change", function (e) { S.who = e.target.value; list(); });
    $("#f-open", bar).addEventListener("click", function (e) { S.onlyOpen = !S.onlyOpen; e.currentTarget.classList.toggle("on", S.onlyOpen); list(); });
    list(); detail();
    store.subs.push(function () { list(); var n = $("#card-notes", lib); if (n && n._draw) n._draw(); });
  };

  function gateList(card, prof) {
    var rows = E.gateRows(card, prof), out = [];
    rows.forEach(function (r) { out.push('<div class="gate"><span class="' + (r.ok ? "ok" : "no") + '">' + (r.ok ? "✓" : "✗") + "</span><span>" + esc(r.text) + "</span></div>"); });
    if (card.cap) out.push('<div class="gate"><span class="' + (E.capOk(card, prof) ? "ok" : "no") + '">' + (E.capOk(card, prof) ? "✓" : "✗") + "</span><span>At most " + card.cap.max + " a " + card.cap.per + " from the “" + esc(card.cap.group) + "” group</span></div>");
    if (card.first) out.push('<div class="gate"><span class="ok">★</span><span>Always the very first walk-in of a new career</span></div>');
    if (card.sys) out.push('<div class="gate"><span class="ok">⚙</span><span>' + esc(card.sys) + "</span></div>");
    if (card.fu && card.from) out.push('<div class="gate"><span class="ok">↻</span><span>Comes back after: ' + card.from.map(function (f) { var src = E.byId[f.card]; return '<button type="button" class="linkish" data-open="' + f.card + '">' + esc(src.tag) + "</button> (" + (f.choice >= 0 ? "choice " + (f.choice + 1) + ", " : "its news, ") + f.out + ")"; }).join("; ") + "</span></div>");
    if (!out.length) out.push('<p class="muted small">No requirements. It can come any time' + (E.isPhone(card) ? " on the phone." : " a visitor walks in.") + "</p>");
    if (!card.fu && !card.system) out.push('<p class="small ' + (E.eligible(card, prof, E.isPhone(card) ? "phone" : "walkin") ? "" : "muted") + '">' + (E.eligible(card, prof, E.isPhone(card) ? "phone" : "walkin") ? "The test producer could draw this card right now." : "The test producer can't draw this right now.") + "</p>");
    return out.join("");
  }
  function outcomeBlock(card, ch, key, o, prof, pct) {
    var extras = [];
    if (o.rel) {
      var who = o.rel.who || card.visitor, bits = [];
      if (o.rel.score) bits.push("relationship " + signed(o.rel.score));
      if (o.rel.flag) bits.push("remembers <code>" + esc(who + "." + o.rel.flag) + "</code>");
      if (o.rel.clear) bits.push("clears <code>" + esc(who + "." + o.rel.clear) + "</code>");
      extras.push("♥ " + esc(whoName(who)) + ": " + bits.join(", "));
    }
    if (o.plant) { var at = o.plant.at || C.WalkIns.FollowupAt; extras.push('↻ Plants <button type="button" class="linkish" data-open="' + esc(o.plant.id) + '">' + esc(o.plant.id) + "</button> in " + at[0] + " to " + at[1] + " visits"); }
    if (o.sponsor) extras.push(o.sponsor === "drop" ? "$ Ends your sponsor deal" : "$ Signs you with " + esc(sponsorName(o.sponsor)));
    if (o.cooldown) extras.push("⏸ They stay away " + o.cooldown + " extra visits");
    if (o.disco) extras.push("♪ Discography entry: " + esc(o.disco));
    if (E.isPhone(card) && o.money) extras.push("Phone outcomes never apply money");
    return '<div class="out ' + (key === "rare" ? "rare" : esc(o.tone)) + '"><div class="oh"><b>' + esc(fill(o.headline, card, prof)) + "</b><em>" + pct + '</em></div><div class="hudrow">' + chips(outcomeDeltas(o), "") + "</div><p>" + esc(fill(o.text, card, prof)) + '</p><p class="q">“' + esc(fill(o.line, card, prof)) + "”</p>" +
      (o.note ? '<p class="small">Note on the card: ' + esc(o.note) + "</p>" : "") + (extras.length ? '<div class="ex">' + extras.map(function (x) { return "<span>" + x + "</span>"; }).join("") + "</div>" : "") +
      '<div class="row"><span class="mono dim">' + key + " · " + esc(o.key) + "</span>" + (ch ? '<button type="button" class="btn sm" data-force="' + key + '">See it happen</button>' : "") + "</div></div>";
  }
  function pctOf(b, key, ch) {
    var rare = b.rareOdds || 0, rest = (100 - rare) / 100, good = b.chance;
    if (key === "rare") return rare + "%";
    var p = key === "good" ? good : 100 - good;
    if (!ch.bad && key === "good") p = 100;
    p = p * rest;
    return (Math.round(p * 10) / 10) + "%";
  }
  function cardDetail(host, card, onNotes) {
    var sim, news, stage, ctxSp;
    function reset(forceNews) {
      sim = E.clone(S.lab); news = null; ctxSp = card.sponsor || sim.sponsor || (card.visitor === "rep" ? "headphones" : null);
      if (card.visitor === "rep" && !sim.sponsor && !card.sponsor && card.fu) sim.sponsor = ctxSp;
      if (card.resolve) {
        var ch = E.chance(card.resolve.odds == null ? 50 : card.resolve.odds, sim, 0);
        var good = forceNews ? forceNews === "good" : Math.random() * 100 < ch;
        var out = good ? card.resolve.good : (card.resolve.bad || card.resolve.good), before = E.clone(sim);
        var res = E.apply(sim, card, out, 0);
        news = { outcome: out, roll: good ? "good" : "bad", chance: ch, applied: res.applied, events: res.events, before: before, forced: !!forceNews };
      }
      stage = "face"; draw();
    }
    function draw(result) {
      host.innerHTML = "";
      var meta = h('<div class="row" style="justify-content:space-between"><div class="row"><span class="tag ' + (card.fu ? "fix" : "work") + '">' + TYPE[card._type] + '</span><span class="mono dim devonly inl">' + esc(card.id) + " · " + esc(PL.meta.file.split("/").pop()) + ":" + card.src + '</span></div><div class="row"><button type="button" class="btn sm" id="cd-reset">Reset the card</button></div></div>');
      host.appendChild(meta);
      $("#cd-reset", meta).addEventListener("click", function () { reset(); });
      var cols = h('<div class="dcols"><div id="cd-left"></div><div id="cd-right"></div></div>'); host.appendChild(cols);
      var left = $("#cd-left", cols), right = $("#cd-right", cols);
      if (!result) {
        left.appendChild(cardFace(card, sim, { news: news, ctxSp: ctxSp, count: E.isPhone(card) ? "" : "3 OF 8 TODAY",
          choose: function (i) { play(i); }, walk: function () { left.appendChild(h('<p class="small muted">' + (E.isPhone(card) ? "Dismissed." : "You walked away.") + " Nothing changes, and the visit still counts for today.</p>")); } }));
        if (news) { changes(news.before, sim, news.events, null, card, left); $("h3", left.lastChild).textContent = "What the news changed"; left.lastChild.insertBefore(h('<p class="small muted devonly">The news rolled at ' + news.chance + "% for the good version (base " + (card.resolve.odds == null ? 50 : card.resolve.odds) + ", moved by Aura and followers only)." + (news.forced ? " You picked this version." : "") + "</p>"), left.lastChild.children[1] || null); }
        if (!(card.choices || []).length && !news) left.appendChild(h('<p class="muted small">This card has no choices.</p>'));
      } else {
        left.appendChild(resultFace(card, result.r, result.res, sim, { ctxSp: ctxSp, doneLabel: "Back to the choices", done: function () { reset(news && news.forced ? news.roll : (news ? news.roll : null)); } }));
        var again = h('<div class="row"><button type="button" class="btn sm">Roll this choice again</button><span class="small muted">Each try starts from the same producer.</span></div>');
        $("button", again).addEventListener("click", function () { var i = result.i; reset(news ? news.roll : null); play(i); });
        left.appendChild(again);
        changes(result.before, sim, result.res.events, result.r, card, left);
      }
      /* right: test producer, wiring, notes */
      right.appendChild(labBox(card, function () { reset(); }));
      var wiring = h('<div class="box devonly grid"><h3>When it can show up</h3>' + gateList(card, S.lab) + "</div>");
      right.appendChild(wiring);
      var dev = h('<div class="box devonly grid"><h3>Every choice and outcome</h3></div>');
      if (card.resolve) {
        var nb = { chance: E.chance(card.resolve.odds == null ? 50 : card.resolve.odds, S.lab, 0), rareOdds: 0 };
        var blk = h('<div class="choiceblock"><div class="ctitle">News when it arrives <small>rolls ' + nb.chance + "% good (base " + (card.resolve.odds == null ? 50 : card.resolve.odds) + ')</small></div><div class="outs">' + ["good", "bad"].map(function (k) { return card.resolve[k] ? outcomeBlock(card, { bad: card.resolve.bad }, k, card.resolve[k], S.lab, pctOf(nb, k, { bad: card.resolve.bad })) : ""; }).join("") + "</div></div>");
        $$("[data-force]", blk).forEach(function (b) { b.addEventListener("click", function () { reset(b.getAttribute("data-force")); }); });
        dev.appendChild(blk);
      }
      (card.choices || []).forEach(function (ch, i) {
        var b = E.breakdown(card, ch, sim), kind = b.kind === "sure" ? "always" : b.kind === "beatMin" ? "decided by your beat (needs quality " + ch.beatMin + ")" : b.kind === "ready" ? "rolls on how ready you are, now " + b.chance + "%" : "rolls, base " + b.base + "%, now " + b.chance + "%";
        var blk2 = h('<div class="choiceblock"><div class="ctitle">' + (i + 1) + ". " + esc(fill(ch.text, card, sim, ctxSp)) + " <small>" + (ch.cost ? "costs " + money(ch.cost) + " · " : "") + kind + (ch.beat ? " · your beat tilts it" : "") + '</small></div><div class="outs">' + ["good", "bad", "rare"].map(function (k) { return ch[k] ? outcomeBlock(card, ch, k, ch[k], sim, pctOf(b, k, ch)) : ""; }).join("") + "</div></div>");
        $$("[data-force]", blk2).forEach(function (btn) { btn.addEventListener("click", function () { reset(news ? news.roll : null); play(i, btn.getAttribute("data-force")); window.scrollTo({ top: host.getBoundingClientRect().top + window.scrollY - 10 }); }); });
        dev.appendChild(blk2);
      });
      right.appendChild(dev);
      right.appendChild(notesBox(card, onNotes));
      $$("[data-open]", host).forEach(function (b) { if (!b._w) { b._w = 1; b.addEventListener("click", function () { APP.openCard(b.getAttribute("data-open")); }); } });
    }
    function play(i, force) {
      var ch = card.choices[i], before = E.clone(sim), r = E.resolve(card, ch, sim, force);
      if (!r.ok) return;
      var res = E.apply(sim, card, r.outcome, r.cost);
      draw({ i: i, r: r, res: res, before: before });
    }
    reset();
  }
  APP.cardDetail = cardDetail;

  function labBox(card, onChange) {
    var p = S.lab, bb = E.bestBeat(p.recent), bv = !bb ? "none" : (bb.stars || 0) + "-" + ((bb.fires || 0) >= 3 ? 3 : 0);
    var who = card && E.visitorById[card.visitor], showRel = card && !E.isPhone(card);
    var el = h('<div class="box"><div class="row" style="justify-content:space-between"><h3>The producer you\'re testing with</h3><select id="lab-preset" class="inp" style="width:auto" aria-label="Starting point">' + E.PRESETS.map(function (x) { return '<option value="' + x.id + '"' + (S.labPreset === x.id ? " selected" : "") + ">" + esc(x.name) + "</option>"; }).join("") + '<option value="run">My career run</option></select></div><div class="lab">' +
      ["aura", "followers", "money", "placements", "level"].map(function (k) { return "<label>" + (STAT[k] || "Level") + '<input type="number" data-k="' + k + '" value="' + p[k] + '"></label>'; }).join("") +
      '<label>Best recent beat<select data-k="beat"><option value="none">None</option><option value="2-0">★★</option><option value="3-0">★★★</option><option value="3-3">★★★ + 3 FIRE</option></select></label>' +
      (showRel ? '<label>How they feel about you<select data-k="rel">' + [-3, -2, -1, 0, 1, 2, 3].map(function (n) { return '<option value="' + n + '"' + (E.relScore(p, card.visitor) === n ? " selected" : "") + ">" + (n > 0 ? "+" : "") + n + "</option>"; }).join("") + "</select></label>" : "") +
      '<label>Sponsor<select data-k="sponsor"><option value="">None</option>' + PL.sponsors.map(function (s) { return '<option value="' + s.id + '"' + (p.sponsor === s.id ? " selected" : "") + ">" + esc(s.names[S.roster]) + "</option>"; }).join("") + "</select></label></div>" +
      '<p class="small muted">Change anything and the card re-reads it: the odds, what\'s affordable, which cards can show up.</p></div>');
    $('[data-k="beat"]', el).value = bv === "2-3" ? "2-0" : (/^(2-0|3-0|3-3)$/.test(bv) ? bv : (bb ? "2-0" : "none"));
    void who;
    $("#lab-preset", el).addEventListener("change", function (e) {
      var v = e.target.value; S.labPreset = v;
      S.lab = v === "run" ? E.clone(S.run) : E.PRESETS.filter(function (x) { return x.id === v; })[0].make(); onChange();
    });
    $$("[data-k]", el).forEach(function (inp) {
      inp.addEventListener("change", function () {
        var k = inp.getAttribute("data-k"), v = inp.value;
        if (k === "beat") { p.recent = v === "none" ? [] : [{ stars: +v.split("-")[0], fires: +v.split("-")[1], bpm: 142 }]; }
        else if (k === "rel") { p.rel[card.visitor] = p.rel[card.visitor] || { score: 0, flags: {} }; p.rel[card.visitor].score = +v; }
        else if (k === "sponsor") { p.sponsor = v || null; p.sponsors = v ? Math.max(1, p.sponsors) : 0; }
        else { p[k] = Math.round(+v || 0); if (k === "followers") p.tier = E.tierIndex(p.followers); if (k === "level") p.level = Math.max(1, Math.min(10, p.level)); }
        onChange();
      });
    });
    return el;
  }
  APP.labBox = labBox;

  function notesBox(card, onNotes) {
    var el = h('<div class="box" id="card-notes"><h3>Our notes on this card</h3><div class="notelist"></div><div class="row" style="flex-wrap:nowrap"><input class="inp" type="text" placeholder="e.g. this choice should cost more" aria-label="Add a note" data-store="cardnotes" data-id="' + esc(card.id) + '"><button type="button" class="btn sm hot">Add</button></div><p class="small dim">Design notes only. They never touch the game.</p></div>');
    function cur() { var d = store.data.cardnotes[card.id]; return d && d.notes ? d.notes.slice() : []; }
    function drawNotes() {
      var box = $(".notelist", el); box.innerHTML = "";
      cur().forEach(function (n, i) {
        var row = h('<div class="noteitem"><span></span><button type="button" title="Remove" aria-label="Remove note">×</button></div>');
        $("span", row).textContent = n.t;
        $("button", row).addEventListener("click", function () { var a = cur(); a.splice(i, 1); store.set("cardnotes", card.id, { notes: a, tag: card.tag }); if (onNotes) onNotes(); });
        box.appendChild(row);
      });
    }
    function add() { var inp = $("input", el), t = inp.value.trim(); if (!t) return; var a = cur(); a.push({ t: t, at: new Date().toISOString() }); inp.value = ""; store.set("cardnotes", card.id, { notes: a, tag: card.tag }); if (onNotes) onNotes(); }
    $("button.hot", el).addEventListener("click", add);
    $("input", el).addEventListener("keydown", function (e) { if (e.key === "Enter") add(); });
    el._draw = drawNotes; drawNotes();
    return el;
  }

  /* ---------- play a career ---------- */
  var REC = ["rival", "mom", "homekid", "navx", "rep", "blogger"];
  function logAdd(title, sub, applied, events) { S.runLog.unshift({ day: S.run.day, title: title, sub: sub || "", applied: applied || null, events: events || [] }); }
  views.play = function (root) {
    var p = S.run;
    root.appendChild(h('<div class="vhead"><div class="row" style="justify-content:space-between"><h2>Play a career</h2><div class="row"><select id="run-preset" class="inp" style="width:auto" aria-label="Start from">' + E.PRESETS.map(function (x) { return '<option value="' + x.id + '"' + (S.runPreset === x.id ? " selected" : "") + ">Start: " + esc(x.name) + "</option>"; }).join("") + '</select><button type="button" class="btn" id="run-reset">Start over</button></div></div><p>Real cards, drawn the way the game draws them, with the game\'s own odds and rules. <span class="tag model">A model, not the game</span> You press the buttons; the game uses timers.</p></div>'));
    var grid = h('<div class="play"><div id="pl-prof"></div><div id="pl-stage"></div><div class="logcol" id="pl-log"></div></div>');
    root.appendChild(grid);
    function restart() { S.run = E.PRESETS.filter(function (x) { return x.id === S.runPreset; })[0].make(); S.runLog = []; S.runCur = null; render(); }
    $("#run-preset", root).addEventListener("change", function (e) { S.runPreset = e.target.value; restart(); });
    $("#run-reset", root).addEventListener("click", restart);

    function prof() {
      var el = $("#pl-prof", grid), bb = E.bestBeat(p.recent), t = C.Life.Tiers, hall = E.gateCheck(C.Career.Gates[0], p);
      var html = '<div class="box"><h3>Your producer</h3><div class="hudrow"><span class="chip pink">LV ' + p.level + '</span><span class="chip">' + esc(C.Ranks[p.level - 1]) + "</span>" + (p.cold ? '<span class="chip cold">❄ COLD</span>' : "") + '</div><div class="hudrow"><span class="chip"><b class="m">' + money(p.money) + '</b></span><span class="chip"><b class="a">' + num(p.aura) + '</b> Aura</span><span class="chip"><b class="f">' + num(p.followers) + "</b> followers</span></div>" +
        '<div class="hudrow"><span class="chip">' + p.placements + ' placements</span><span class="chip">' + p.hits + ' hits</span><span class="chip">' + (p.sponsor ? esc(sponsorName(p.sponsor)) : "no sponsor") + "</span></div>" +
        '<div class="tiers">' + t.map(function (x, i) { return '<div class="' + (i === p.tier ? "on" : i < p.tier ? "past" : "") + '"><b>' + x.id + "</b>" + (x.followers >= 1000 ? x.followers / 1000 + "K" : "start") + "</div>"; }).join("") + "</div>" +
        '<p class="small">Best recent beat: ' + (bb ? stars(bb.stars, bb.fires) : '<span class="muted">none yet</span>') + "</p>" +
        '<p class="small muted">Day ' + p.day + " · visitors today " + p.w.today + " of " + E.dailyMax(p) + " · phone " + p.w.phone.today + " of " + (p.cold ? 0 : C.Phone.DailyMax) + "</p></div>";
      html += '<div class="box"><h3>Who remembers you</h3>' + REC.map(function (id) {
        var e = p.rel[id], fl = e ? Object.keys(e.flags || {}) : [];
        return '<div class="relrow"><span>' + esc(whoName(id, p.sponsor)) + "</span>" + pips(e ? e.score : 0) + (fl.length ? "<small>remembers: " + fl.map(esc).join(", ") + "</small>" : "") + "</div>";
      }).join("") + '<p class="small dim">Each step moves their rolls 4 points.</p></div>';
      html += '<div class="box"><h3>Coming back</h3>' + (p.w.queue.length ? p.w.queue.slice().sort(function (a, b) { return a.at - b.at; }).map(function (q) {
        var c = E.byId[q.id], inN = q.at - p.w.count;
        return '<div class="qitem"><span class="playeronly">Something from ' + esc(whoName(c.visitor, p.sponsor)) + '</span><span class="devonly"><button type="button" class="linkish" data-open="' + q.id + '">' + esc(c.tag) + "</button></span><small>" + (E.isPhone(c) ? "on the phone" : inN <= 1 ? "next visit" : "in about " + inN + " visits") + "</small></div>";
      }).join("") : '<p class="small muted">Nothing waiting.</p>') + "</div>";
      html += '<div class="box"><h3>THE HALL</h3>' + (p.hall ? '<p class="small">Unlocked. The door opens for you.</p>' : hall.rows.map(function (r) { return '<div class="req"><span style="color:' + (r.ok ? "var(--green)" : "var(--red)") + '">' + (r.ok ? "✓" : "✗") + "</span><span>" + num(r.need) + " " + STAT[r.k] + '</span><span class="dim">' + num(r.have) + "</span></div>"; }).join("") +
        '<div class="req"><span style="color:' + (hall.money.ok ? "var(--green)" : "var(--red)") + '">' + (hall.money.ok ? "✓" : "✗") + "</span><span>" + money(hall.money.need) + '</span><span class="dim">' + money(hall.money.have) + '</span></div><button type="button" class="btn sm hot" id="hall-btn"' + (hall.ok ? "" : " disabled") + ">Unlock THE HALL</button>") +
        '<details><summary class="small muted" style="cursor:pointer">Gear rack (' + Object.keys(p.gear).length + " of " + C.Gear.length + ")</summary><div style=\"display:grid;gap:6px;margin-top:8px\">" + C.Gear.map(function (g) {
          var own = p.gear[g.id], needs = Object.keys(g.needs || {}).map(function (k) { return num(g.needs[k]) + " " + STAT[k].toLowerCase(); });
          var ok = p.level >= g.level && Object.keys(g.needs || {}).every(function (k) { return p[k] >= g.needs[k]; }) && p.money >= g.price;
          return '<div class="req"><span>' + (own ? "✓" : "") + "</span><span>" + esc(g.name) + '<br><small class="dim">' + (g.level > 1 ? "level " + g.level + " · " : "") + (needs.length ? needs.join(", ") + " · " : "") + money(g.price) + "</small></span>" + (own ? "" : '<button type="button" class="btn sm" data-gear="' + g.id + '"' + (ok ? "" : " disabled") + ">Buy</button>") + "</div>";
        }).join("") + "</div></details></div>";
      el.innerHTML = html;
      var hb = $("#hall-btn", el); if (hb) hb.addEventListener("click", function () { var b = E.clone(p); p.money -= C.Career.Gates[0].cost; p.hall = true; logAdd("Unlocked THE HALL", "", { cost: C.Career.Gates[0].cost }, []); S.runCur = { kind: "info", before: b, title: "THE HALL is open for you", text: "A placement, 300 Aura and $5,000. It's the first of the twelve firsts most players chase.", events: [] }; draw(); });
      $$("[data-gear]", el).forEach(function (b) { b.addEventListener("click", function () { var g = C.Gear.filter(function (x) { return x.id === b.getAttribute("data-gear"); })[0]; p.money -= g.price; p.gear[g.id] = true; logAdd("Bought " + g.name, g.desc, { cost: g.price }, []); draw(); }); });
      $$("[data-open]", el).forEach(function (b) { b.addEventListener("click", function () { APP.openCard(b.getAttribute("data-open")); }); });
    }
    function log() {
      var el = $("#pl-log", grid);
      el.innerHTML = '<div class="box"><h3>This career so far</h3><div class="log">' + (S.runLog.length ? S.runLog.map(function (l) { return '<div class="logitem"><span class="d">DAY ' + l.day + "</span><b>" + esc(l.title) + "</b>" + (l.sub ? "<span class=\"muted\">" + esc(l.sub) + "</span>" : "") + (l.applied ? '<div class="hudrow">' + chips(l.applied, "") + "</div>" : "") + "</div>"; }).join("") : '<p class="small muted">Nothing yet. Bring in the first visitor.</p>') + '</div></div><div class="box"><h3>What this model leaves out</h3><ul class="plain small muted">' + E.MODEL_NOTES.map(function (n) { return "<li>" + esc(n) + "</li>"; }).join("") + "</ul></div>";
    }
    function stage() {
      var el = $("#pl-stage", grid), cur = S.runCur; el.innerHTML = "";
      if (!cur) {
        var offers = E.offers(p), canV = E.canVisit(p), coldMsg = !!(p.cold && !p.cold.news), canP = E.canPhone(p) || coldMsg;
        var acts = h('<div class="actions"><button type="button" class="act" id="a-visit"' + (canV ? "" : " disabled") + "><b>Next visitor</b><span>" + (canV ? (p.w.count === 0 ? "Your first ever walk-in" : "Someone walks in from the hallway") : "That's everyone for today (" + E.dailyMax(p) + (p.cold ? ", you're cold" : "") + ")") + '</span></button><button type="button" class="act" id="a-phone"' + (canP ? "" : " disabled") + "><b>Check your phone</b><span>" + (coldMsg ? "One new message" : p.cold ? "Silent while you're cold" : canP ? "A DM or the news" : "Quiet for the rest of today") + '</span></button><button type="button" class="act" id="a-fire"><b>Someone FIREs your beat</b><span>+$30, +10 followers, and it ends a cold streak</span></button><button type="button" class="act" id="a-day"><b>Next day</b><span>Resets the day\'s visitors and phone</span></button></div>');
        el.appendChild(acts);
        var del = h('<div class="box"><h3>Deliver a beat</h3>' + (offers.length ? '<div class="row"><select id="d-brief" class="inp" style="width:auto;max-width:100%">' + offers.slice(0, 8).map(function (b) { var a = PL.artists.filter(function (x) { return x.id === b.artist; })[0]; return '<option value="' + b.id + '">' + esc(a.name) + " · “" + esc(b.title) + "” · " + money(b.reward.cred) + "</option>"; }).join("") + '</select><button type="button" class="btn" data-stars="2">Deliver ★★</button><button type="button" class="btn hot" data-stars="3">Deliver ★★★</button></div><p class="small muted">Two stars means every ask is met. Three means the bonus too, and pays 1.5×. Your best of the last three beats is what visitors judge you by.</p>' : '<p class="small muted">Every request open at your level is done. Level up for the next artist.</p>') + "</div>");
        el.appendChild(del);
        if (S.dev && S.lastPick) el.appendChild(h('<p class="small muted">Last draw: ' + esc(S.lastPick) + "</p>"));
        $("#a-visit", acts).addEventListener("click", function () { open("walkin"); });
        $("#a-phone", acts).addEventListener("click", function () { open("phone"); });
        $("#a-fire", acts).addEventListener("click", function () { var b = E.clone(p), r = E.fire(p); logAdd("A FIRE on your beat", "", r.applied, r.events); S.runCur = { kind: "info", before: b, title: "🔥 FIRE", text: "Someone in the room liked your beat. Three FIREs on one beat lift its quality a step.", events: r.events }; draw(); });
        $("#a-day", acts).addEventListener("click", function () { var b = E.clone(p), r = E.nextDay(p); logAdd("Day " + p.day, "", null, r.events); S.runCur = { kind: "info", before: b, title: "Day " + p.day + (p.day > 7 ? " · Year " + (Math.floor((p.day - 1) / 7) + 1) : ""), text: "A new career day. In the game, only days you actually play count.", events: r.events }; draw(); });
        $$("[data-stars]", del).forEach(function (btn) { btn.addEventListener("click", function () {
          var brief = PL.briefs.filter(function (x) { return x.id === $("#d-brief", del).value; })[0], st = +btn.getAttribute("data-stars"), a = PL.artists.filter(function (x) { return x.id === brief.artist; })[0];
          var b = E.clone(p), r = E.deliver(p, brief, st);
          logAdd("Delivered “" + brief.title + "” to " + a.name, "★".repeat(st), r.applied, r.events);
          S.runCur = { kind: "info", before: b, title: "“" + brief.title + "” · " + "★".repeat(st), text: a.name + ": “" + a.quotes[String(st)] + "”", events: r.events }; draw();
        }); });
        return;
      }
      if (cur.kind === "info") {
        el.appendChild(h('<div class="box"><h2 style="font-size:1.1rem">' + esc(cur.title) + '</h2><p class="muted">' + esc(cur.text) + "</p></div>"));
        changes(cur.before, p, cur.events, null, null, el);
        var ok = h('<button type="button" class="btn hot" style="justify-self:start">Keep going</button>'); ok.addEventListener("click", function () { S.runCur = null; draw(); }); el.appendChild(ok);
        return;
      }
      var card = cur.arr.card, sp = (cur.arr.ctx && cur.arr.ctx.sponsor) || cur.sp;
      if (cur.result) {
        el.appendChild(resultFace(card, cur.result.r, cur.result.res, p, { ctxSp: sp, done: function () { S.runCur = null; draw(); } }));
        changes(cur.result.before, p, cur.result.res.events.concat(cur.arr.events), cur.result.r, card, el);
      } else {
        var newsOnly = !(card.choices || []).length;
        el.appendChild(cardFace(card, p, { news: cur.arr.news, ctxSp: sp, count: E.isPhone(card) ? "" : p.w.today + " OF " + E.dailyMax(p) + " TODAY",
          choose: function (i) {
            var ch = card.choices[i], before = E.clone(p), r = E.resolve(card, ch, p); if (!r.ok) return;
            var res = E.apply(p, card, r.outcome, r.cost);
            logAdd(whoName(card.visitor, sp || p.sponsor) + ": " + fill(r.outcome.headline, card, p, sp), fill(ch.text, card, p, sp), res.applied, res.events);
            cur.result = { r: r, res: res, before: before }; draw();
          },
          walk: function () { logAdd(whoName(card.visitor, sp || p.sponsor) + ": walked away", "", null, []); S.runCur = null; draw(); },
          onContinue: newsOnly ? function () { S.runCur = null; draw(); } : null }));
        if (cur.arr.news) { changes(cur.newsBefore, cur.afterNews, cur.arr.news.events.concat(newsOnly ? cur.arr.events : []), null, card, el); $("h3", el.lastChild).textContent = "What the news changed"; el.lastChild.appendChild(h('<p class="small muted devonly">Rolled at ' + cur.arr.news.chance + "% for the good version.</p>")); }
      }
      el.appendChild(h('<p class="small muted devonly">' + esc(cur.pickNote) + ' · <button type="button" class="linkish" data-open="' + card.id + '">open in the library</button></p>'));
      $$("[data-open]", el).forEach(function (b) { if (!b._w) { b._w = 1; b.addEventListener("click", function () { APP.openCard(b.getAttribute("data-open")); }); } });
    }
    function open(source) {
      var pk = (source === "phone" && p.cold && !p.cold.news) ? { kind: "card", card: E.byId.cold_news, pool: [E.byId.cold_news], eligible: 1, system: true } : E.pick(p, source);
      if (pk && pk.system) p.cold.news = true;
      if (!pk) { S.runCur = { kind: "info", before: E.clone(p), title: source === "phone" ? "No new messages" : "Nobody's at the door", text: "No card is open to this producer right now.", events: [] }; draw(); return; }
      var before = E.clone(p), spBefore = p.sponsor, arr = E.arrive(p, pk);
      var note = pk.kind === "followup" ? "A follow-up that was due (" + pk.card.id + ")" : pk.system ? "Sent by the game because you went cold" : pk.first ? "The first card of every career" : "Drawn from the " + pk.pool.length + " least-seen of " + pk.eligible + " open cards (" + pk.card.id + ")";
      S.lastPick = note;
      S.runCur = { kind: "card", arr: arr, newsBefore: before, afterNews: E.clone(p), pickNote: note, sp: spBefore };
      if (arr.news) logAdd(whoName(pk.card.visitor, spBefore) + ": " + fill(arr.news.outcome.headline, pk.card, p, spBefore), "news", arr.news.applied, arr.news.events);
      if (pk.card.news && pk.card.choices && pk.card.choices.length === 1) { /* a NEWS item applies when you open it */
        var b2 = E.clone(p), r = E.resolve(pk.card, pk.card.choices[0], p), res = E.apply(p, pk.card, r.outcome, 0);
        logAdd(whoName(pk.card.visitor) + ": " + r.outcome.headline, pk.card.line, res.applied, res.events);
        S.runCur.result = { r: r, res: res, before: b2 };
      }
      draw();
    }
    function draw() { p = S.run; prof(); stage(); log(); }
    draw();
  };

  APP.boot = boot;
})();
