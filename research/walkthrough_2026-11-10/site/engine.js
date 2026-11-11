/* Prod Life III rules, ported to JS from the game's pure Luau modules (WalkInRules, CareerRules, BriefCheck).
   This is a model for the explorer page, not the game engine. Where it simplifies, MODEL_NOTES says so. */
(function (root) {
  "use strict";
  var PL = root.PL;
  var C = PL.config, W = C.WalkIns, O = W.Odds;
  var byId = {}, visitorById = {}, sponsorById = {};
  PL.cards.forEach(function (c) { byId[c.id] = c; });
  PL.visitors.forEach(function (v) { visitorById[v.id] = v; });
  PL.sponsors.forEach(function (s) { sponsorById[s.id] = s; });
  var clamp = function (n, lo, hi) { return Math.max(lo, Math.min(hi, n)); };
  var rint = function (lo, hi) { return lo + Math.floor(Math.random() * (hi - lo + 1)); };

  var MODEL_NOTES = [
    "You press a button for the next visitor or phone message. In the game they arrive on timers (a visitor every 4 to 6 minutes in the studio, a phone message every 2 to 3).",
    "Busy-day bursts, cards timing out, and the per-day limits on how many times a reward can pay are left out.",
    "Delivering here also counts as playing the beat on the speakers. A FIRE needs another player in the real game.",
    "Weekly limits use 7 career days as a week. The game uses calendar weeks.",
    "Everything else (odds, gates, relationships, follow-ups, sponsors, cold streaks, fame tiers) follows the game's own rules and card data."
  ];

  /* ---------- odds (WalkInRules.Chance / Readiness / ChoiceChance / RollChance) ---------- */
  function auraPts(aura) { return clamp(Math.floor((aura || 0) / O.auraPer), -O.auraCap, O.auraCap); }
  function folPts(f) { return Math.min(Math.floor((f || 0) / O.followersPer), O.followersCap); }
  function chance(base, career, tilt) { return clamp(base + auraPts(career.aura) + folPts(career.followers) + (tilt || 0), O.min, O.max); }
  function readiness(career) {
    var part = function (have, mark) { return Math.min(Math.max(have || 0, 0) / mark, 1); };
    var r = O.ready;
    return (part(career.level || 1, r.level) + part(career.placements, r.placements) + part(career.followers, r.followers) + part(career.aura, r.aura)) / 4;
  }
  function beatQuality(e) { return e ? Math.min((e.stars || 0) + ((e.fires || 0) >= 3 ? 1 : 0), 4) : 0; }
  function bestBeat(recent) {
    var best = null, bq = -1;
    (recent || []).forEach(function (e) { var q = beatQuality(e); if (q > bq) { best = e; bq = q; } });
    return best;
  }
  function isPhone(card) { return (card.source || "walkin") === "phone"; }
  function relScore(prof, who) { var e = prof.rel[who]; return e ? (e.score || 0) : 0; }

  /* everything that decides one choice, with each part shown */
  function breakdown(card, choice, prof) {
    var bq = beatQuality(bestBeat(prof.recent));
    var phone = isPhone(card);
    var b = { kind: "roll", rareOdds: choice.rare ? (choice.rareOdds || 0) : 0, beatQ: bq, min: O.min, max: O.max };
    if (choice.beatMin) {
      b.kind = "beatMin"; b.beatMin = choice.beatMin; b.chance = bq >= choice.beatMin ? 100 : 0; return b;
    }
    b.relPts = phone ? 0 : relScore(prof, card.visitor) * O.relPer;
    b.beatPts = choice.beat ? (bq - O.beatCenter) * O.beatPer : 0;
    var tilt = b.relPts + b.beatPts;
    if (choice.sure) { b.kind = "sure"; b.chance = 100; return b; }
    if (choice.ready) {
      b.kind = "ready"; b.readiness = readiness(prof);
      b.base = Math.floor(O.min + (O.max - O.min) * b.readiness + 0.5);
      b.raw = b.base + tilt; b.chance = clamp(b.raw, O.min, O.max); return b;
    }
    b.base = choice.odds == null ? 50 : choice.odds;
    b.auraPts = auraPts(prof.aura); b.folPts = folPts(prof.followers);
    b.raw = b.base + b.auraPts + b.folPts + tilt;
    b.chance = clamp(b.raw, O.min, O.max);
    return b;
  }

  /* WalkInRules.Resolve. force = "good" | "bad" | "rare" picks an outcome without rolling */
  function resolve(card, choice, prof, force) {
    var cost = choice.cost || 0;
    if ((prof.money || 0) < cost) return { ok: false, reason: "afford", cost: cost };
    var b = breakdown(card, choice, prof), outcome, roll;
    if (force) { outcome = choice[force] || choice.good; roll = force === "good" && (choice.sure || b.kind === "beatMin") ? "sure" : force; }
    else if (b.kind === "beatMin") { if (b.chance === 100) { outcome = choice.good; roll = "sure"; } else { outcome = choice.bad || choice.good; roll = "bad"; } }
    else if (choice.rare && rint(1, 100) <= (choice.rareOdds || 0)) { outcome = choice.rare; roll = "rare"; }
    else if (choice.sure) { outcome = choice.good; roll = "sure"; }
    else if (rint(1, 100) <= b.chance) { outcome = choice.good; roll = "good"; }
    else { outcome = choice.bad || choice.good; roll = "bad"; }
    return { ok: true, outcome: outcome, roll: roll, b: b, cost: cost, forced: !!force };
  }

  /* ---------- gates (WalkInRules.GateOk / CapOk / cardEligible) ---------- */
  var CAREER_GATES = { aura: 1, followers: 1, placements: 1, hits: 1, sponsors: 1, money: 1 };
  function gateValue(k, prof) { if (k === "visits") return prof.w.count; return CAREER_GATES[k] ? prof[k] : undefined; }
  function flagSet(prof, id) { var p = id.split("."), e = prof.rel[p[0]]; return !!(e && e.flags && e.flags[p.slice(1).join(".")] != null); }
  /* returns a list of { text, ok } rows so the page can show which conditions hold */
  function gateRows(card, prof) {
    var rows = [], n = card.needs || {}, u = card.under || {};
    var lab = { aura: "Aura", followers: "followers", placements: "placements", hits: "hits", sponsors: "sponsors", money: "money", visits: "walk-ins so far" };
    var fmt = function (k, v) { return k === "money" ? "$" + v.toLocaleString("en-US") : v.toLocaleString("en-US") + " " + lab[k]; };
    Object.keys(n).forEach(function (k) {
      if (k === "flags") n.flags.forEach(function (f) { rows.push({ text: "Remembered: " + f, ok: flagSet(prof, f), kind: "flag", id: f }); });
      else if (k === "rel") { var has = prof.rel[card.visitor]; rows.push({ text: "Relationship with them is " + n.rel + " or more", ok: !!has && relScore(prof, card.visitor) >= n.rel, kind: "rel" }); }
      else { var have = gateValue(k, prof); rows.push({ text: "At least " + fmt(k, n[k]), ok: have != null && have >= n[k], kind: k }); }
    });
    Object.keys(u).forEach(function (k) {
      if (k === "flags") u.flags.forEach(function (f) { rows.push({ text: "Not yet remembered: " + f, ok: !flagSet(prof, f), kind: "flag", id: f }); });
      else if (k === "rel") { var has = prof.rel[card.visitor]; rows.push({ text: "Relationship with them is under " + u.rel, ok: !!has && relScore(prof, card.visitor) < u.rel, kind: "rel" }); }
      else { var have = gateValue(k, prof); rows.push({ text: "Under " + fmt(k, u[k]), ok: have != null && have < u[k], kind: k }); }
    });
    if (card.sponsor) { var fl = sponsorById[card.sponsor].floor; rows.push({ text: "Aura at their bar of " + fl + " or more", ok: (prof.aura || 0) >= fl, kind: "floor" }); }
    if (card.when === "unsponsored") rows.push({ text: "You have no sponsor", ok: !prof.sponsor, kind: "when" });
    if (card.when === "sponsored") rows.push({ text: "You have a sponsor", ok: !!prof.sponsor, kind: "when" });
    if (card.aired) rows.push({ text: "One of your beats played on the speakers this session", ok: !!prof.aired, kind: "aired" });
    return rows;
  }
  function gateOk(card, prof) {
    var n = card.needs, u = card.under, k, have;
    if ((n && (n.flags || n.rel != null)) || (u && (u.flags || u.rel != null))) {
      var e = prof.rel[card.visitor], sc = e ? (e.score || 0) : null, i;
      if (n) {
        if (n.flags) for (i = 0; i < n.flags.length; i++) if (!flagSet(prof, n.flags[i])) return false;
        if (n.rel != null && (sc == null || sc < n.rel)) return false;
      }
      if (u) {
        if (u.flags) for (i = 0; i < u.flags.length; i++) if (flagSet(prof, u.flags[i])) return false;
        if (u.rel != null && (sc == null || sc >= u.rel)) return false;
      }
    }
    for (k in (n || {})) if (k !== "flags" && k !== "rel") { have = gateValue(k, prof); if (have == null || have < n[k]) return false; }
    for (k in (u || {})) if (k !== "flags" && k !== "rel") { have = gateValue(k, prof); if (have == null || have >= u[k]) return false; }
    return true;
  }
  function capKey(cap, prof) { return cap.per === "week" ? Math.floor(prof.day / 7) : prof.day; }
  function capOk(card, prof) {
    var cap = card.cap; if (!cap) return true;
    var c = prof.w.caps[cap.group];
    return !(c && c.key === capKey(cap, prof) && c.n >= cap.max);
  }
  function countCap(card, prof) {
    var cap = card.cap; if (!cap) return;
    var key = capKey(cap, prof), c = prof.w.caps[cap.group];
    if (!c || c.key !== key) { c = { key: key, n: 0 }; prof.w.caps[cap.group] = c; }
    c.n += 1;
  }
  function eligible(card, prof, source, exclude) {
    if (card.fu || card.system) return false;
    var last = prof.w.last[card.visitor];
    if (last != null && prof.w.count - last < W.ArtistCooldown) return false;
    if (card.sponsor && (prof.aura || 0) < sponsorById[card.sponsor].floor) return false;
    if ((card.source || "walkin") !== source) return false;
    if (!gateOk(card, prof)) return false;
    if (!capOk(card, prof)) return false;
    if (card.aired && !prof.aired) return false;
    if (exclude && exclude[card.id]) return false;
    if (card.when === "unsponsored") return !prof.sponsor;
    if (card.when === "sponsored") return !!prof.sponsor;
    return true;
  }
  /* why a card can't come right now, in plain words (for the library) */
  function blockers(card, prof) {
    var out = [];
    if (card.system) out.push("Sent by the game itself, never drawn");
    if (card.fu) out.push("Only comes back after the outcome that plants it");
    var last = prof.w.last[card.visitor];
    if (last != null && prof.w.count - last < W.ArtistCooldown) out.push("They were just here (same visitor waits " + W.ArtistCooldown + " visits)");
    if (!capOk(card, prof)) out.push("Its group already hit this " + card.cap.per + "'s limit");
    gateRows(card, prof).forEach(function (r) { if (!r.ok) out.push(r.text); });
    return out;
  }

  /* ---------- the pick (WalkInRules.Seed + Pick) ---------- */
  function dueEntry(prof, source) {
    var best = null;
    prof.w.queue.forEach(function (q) {
      var f = byId[q.id];
      if (q.at <= prof.w.count + 1 && f && (f.source || "walkin") === source && (!best || q.at < best.at)) best = q;
    });
    return best;
  }
  function stale(prof, entry) {
    if (entry.id !== "sponsor_drop" && entry.id !== "sponsor_warning") return false;
    var want = entry.ctx && entry.ctx.sponsor;
    if (!prof.sponsor || (want && want !== prof.sponsor)) return true;
    return (prof.aura || 0) >= sponsorById[prof.sponsor].floor;
  }
  function pick(prof, source) {
    var entry;
    while ((entry = dueEntry(prof, source))) {
      if (!stale(prof, entry)) return { kind: "followup", entry: entry, card: byId[entry.id], pool: null };
      prof.w.queue = prof.w.queue.filter(function (q) { return q !== entry; });
    }
    var elig = PL.cards.filter(function (c) { return eligible(c, prof, source); });
    if (source === "walkin" && prof.w.count === 0) {
      var first = elig.filter(function (c) { return c.first; })[0];
      if (first) return { kind: "card", card: first, pool: [first], first: true };
    }
    /* Seed: a newly open card joins at the lowest seen count among the open ones */
    var low = null;
    elig.forEach(function (c) { var s = prof.w.seen[c.id]; if (s != null && (low == null || s < low)) low = s; });
    elig.forEach(function (c) { if (prof.w.seen[c.id] == null) prof.w.seen[c.id] = low || 0; });
    var fewest = Infinity, pool = [];
    elig.forEach(function (c) { var s = prof.w.seen[c.id] || 0; if (s < fewest) { pool = []; fewest = s; } if (s === fewest) pool.push(c); });
    if (!pool.length) return null;
    return { kind: "card", card: pool[rint(0, pool.length - 1)], pool: pool, eligible: elig.length };
  }

  /* ---------- applying an outcome ---------- */
  function plant(prof, p, ctx, events, why) {
    if (prof.w.queue.some(function (q) { return q.id === p.id; })) return null;
    var at = p.at || W.FollowupAt;
    var entry = { id: p.id, at: prof.w.count + rint(at[0], at[1]), ctx: ctx || null };
    prof.w.queue.push(entry);
    if (events) events.push({ t: "plant", id: p.id, at: entry.at, inVisits: entry.at - prof.w.count, range: at, why: why || null });
    return entry;
  }
  function tierIndex(f) { var t = C.Life.Tiers, i = 0; for (var k = 0; k < t.length; k++) if (f >= t[k].followers) i = k; return i; }
  function levelFor(xp) { var L = C.Levels, lv = 1; for (var i = 0; i < L.length; i++) if (xp >= L[i]) lv = i + 1; return lv; }
  function addFollowers(prof, n, events) {
    prof.followers = Math.max(0, prof.followers + n);
    var ti = tierIndex(prof.followers), k = 0;
    while (prof.tier < ti) {
      prof.tier += 1; k += 1;
      var id = C.Life.Tiers[prof.tier].id, visit = C.Life.TierVisits[id];
      events.push({ t: "tier", id: id });
      if (visit) { var at = [k, k + 1]; if (prof.w.count === 0) at = [k + 1, k + 2]; plant(prof, { id: visit, at: at }, null, events, "fame tier"); }
    }
  }
  function relWrite(prof, write, own, events) {
    if (write.score == null && write.flag == null && write.clear == null) return;
    var id = write.who || own, e = prof.rel[id];
    if (!e) { e = { score: 0, flags: {} }; prof.rel[id] = e; }
    var before = e.score;
    if (write.score) e.score = clamp(e.score + write.score, -3, 3);
    if (write.flag) e.flags[write.flag] = prof.day;
    if (write.clear) delete e.flags[write.clear];
    events.push({ t: "rel", who: id, before: before, after: e.score, flag: write.flag || null, clear: write.clear || null });
  }
  /* apply one outcome to the profile. Returns { applied, events }. Mirrors Systems/WalkIns apply and Systems/Phone. */
  function apply(prof, card, outcome, cost) {
    var phone = isPhone(card), ev = [], a = { cost: cost || 0, money: 0, aura: 0, followers: 0, placements: 0, hits: 0, sponsors: 0, xp: 0 };
    prof.money -= a.cost;
    var m = outcome.money || 0;
    if (phone && m) { ev.push({ t: "note", text: "Phone messages never pay or take money from an outcome, so the $" + Math.abs(m) + " here isn't applied." }); m = 0; }
    if (m > 0) { prof.money += m; a.money = m; }
    else if (m < 0) { var taken = Math.min(-m, prof.money); prof.money -= taken; a.money = -taken; if (taken < -m) ev.push({ t: "note", text: "Money can't go below $0, so only $" + taken + " was taken." }); }
    if (outcome.aura) { prof.aura += outcome.aura; a.aura = outcome.aura; }
    if (outcome.followers) { var f0 = prof.followers; addFollowers(prof, outcome.followers, ev); a.followers = prof.followers - f0; }
    if (!phone) {
      ["placements", "hits", "sponsors"].forEach(function (k) {
        if (outcome[k]) { var b0 = prof[k]; prof[k] = Math.max(0, prof[k] + outcome[k]); a[k] = prof[k] - b0; }
      });
      if (a.hits > 0 && !prof.hadHit) { prof.hadHit = true; }
    }
    if (outcome.xp) { var xp = phone ? Math.min(outcome.xp, C.XP.Sources.Phone.max) : 0; if (xp) { prof.xp += xp; a.xp = xp; var lv = levelFor(prof.xp); if (lv > prof.level) { prof.level = lv; ev.push({ t: "level", level: lv }); } } }
    if (outcome.sponsor === "drop") { ev.push({ t: "sponsor", drop: true, id: prof.sponsor }); prof.sponsor = null; }
    else if (typeof outcome.sponsor === "string") { prof.sponsor = outcome.sponsor; delete prof.rel.rep; prof.rel.rep = { score: 0, flags: {} }; ev.push({ t: "sponsor", id: outcome.sponsor }); }
    if (outcome.rel) relWrite(prof, outcome.rel, card.visitor, ev);
    if (outcome.plant) plant(prof, outcome.plant, prof.sponsor ? { sponsor: prof.sponsor } : null, ev);
    if (a.hits > 0 && !prof.plaquePlanted) { prof.plaquePlanted = true; plant(prof, { id: "mom_plaque", at: [1, 2] }, null, ev, "first HIT"); }
    if (typeof outcome.cooldown === "number") { prof.w.last[card.visitor] = (prof.w.last[card.visitor] != null ? prof.w.last[card.visitor] : prof.w.count) + outcome.cooldown; ev.push({ t: "cooldown", n: outcome.cooldown, who: card.visitor }); }
    if (outcome.disco) ev.push({ t: "disco", kind: outcome.disco });
    coldCheck(prof, ev);
    return { applied: a, events: ev };
  }

  /* ---------- a visit arrives ---------- */
  function dailyMax(prof) { return prof.cold ? W.Cold.dailyMax : W.DailyMax; }
  function canVisit(prof) { return prof.w.today < dailyMax(prof); }
  function canPhone(prof) { return !prof.cold && prof.w.phone.today < C.Phone.DailyMax; }
  function arrive(prof, p) {
    var card = p.card, ev = [], news = null, phone = isPhone(card);
    if (!phone) { prof.w.count += 1; prof.w.today += 1; prof.w.last[card.visitor] = prof.w.count; }
    else { prof.w.phone.today += 1; if (visitorById[card.visitor].kind === "artist") prof.w.last[card.visitor] = Math.max(prof.w.last[card.visitor] != null ? prof.w.last[card.visitor] : prof.w.count, prof.w.count); }
    var ctx = null;
    if (p.kind === "followup") {
      ctx = p.entry.ctx;
      prof.w.queue = prof.w.queue.filter(function (q) { return q !== p.entry; });
      if (card.resolve) {
        var r = resolve(card, { odds: card.resolve.odds, good: card.resolve.good, bad: card.resolve.bad, _news: true }, prof);
        /* a follow-up's news rolls on Aura and Followers only (WalkInRules.ResolveNews passes no tilt) */
        var ch = chance(card.resolve.odds == null ? 50 : card.resolve.odds, prof, 0);
        var good = rint(1, 100) <= ch;
        var out = good ? card.resolve.good : (card.resolve.bad || card.resolve.good);
        var res = apply(prof, card, out, 0);
        news = { outcome: out, roll: good ? "good" : "bad", chance: ch, applied: res.applied, events: res.events };
        void r;
      }
      if (card.id === "sponsor_warning") plant(prof, { id: "sponsor_drop", at: [2, 3] }, { sponsor: prof.sponsor }, ev, "the warning");
    } else {
      prof.w.seen[card.id] = (prof.w.seen[card.id] || 0) + 1;
      countCap(card, prof);
    }
    if (!phone && prof.sponsor && prof.aura < sponsorById[prof.sponsor].floor) {
      var waiting = prof.w.queue.some(function (q) { return q.id === "sponsor_drop" || q.id === "sponsor_warning"; });
      if (!waiting) plant(prof, { id: relScore(prof, "rep") >= 1 ? "sponsor_warning" : "sponsor_drop", at: W.DropAt }, { sponsor: prof.sponsor }, ev, "Aura under your sponsor's bar");
    }
    return { card: card, news: news, events: ev, ctx: ctx, kind: p.kind };
  }

  /* ---------- cold spell (CareerRules.ColdStep) ---------- */
  function coldStep(cold, rearm, aura, day, lastDay, event) {
    var cfg = W.Cold;
    if (event === "fire" || event === "delivery3") {
      if (!cold) return [cold, rearm, false];
      return [null, rearm === true || cold.reason === "aura" || aura < cfg.aura, true];
    }
    if (event !== "check" || lastDay == null) return [cold, rearm, false];
    var changed = false;
    if (rearm && aura >= cfg.rearmAura) { rearm = false; changed = true; }
    if (cold) return [cold, rearm, changed];
    if (aura < cfg.aura && !rearm) return [{ since: day, reason: "aura" }, rearm, true];
    if (day - lastDay >= cfg.quietDays) return [{ since: day, reason: "quiet" }, rearm, true];
    return [null, rearm, changed];
  }
  function coldCheck(prof, ev, event) {
    var was = prof.cold;
    var r = coldStep(prof.cold, prof.rearm, prof.aura, prof.day, prof.lastDay, event || "check");
    prof.cold = r[0]; prof.rearm = r[1];
    if (!was && prof.cold && ev) ev.push({ t: "cold", reason: prof.cold.reason });
    if (was && !prof.cold) { prof.lastDay = prof.day; if (ev) ev.push({ t: "thaw" }); }
  }

  /* ---------- the music side ---------- */
  function offers(prof) {
    return PL.briefs.filter(function (b) {
      var art = PL.artists.filter(function (a) { return a.id === b.artist; })[0];
      return art.level <= prof.level && !prof.done[b.id];
    });
  }
  function deliver(prof, brief, stars) {
    var ev = [], a = { cost: 0, money: 0, aura: 0, followers: 0, placements: 0, hits: 0, sponsors: 0, xp: 0 };
    var first = !prof.done[brief.id];
    if (first) {
      var mult = function (x) { return stars === 3 ? Math.floor(x * 1.5 + 0.5) : x; };
      a.money = mult(brief.reward.cred); a.xp = mult(brief.reward.xp);
      prof.money += a.money; prof.xp += a.xp;
      var feed = C.Career.DeliveryFeed[String(stars)];
      if (feed) { a.aura = feed.aura; prof.aura += feed.aura; var f0 = prof.followers; addFollowers(prof, feed.followers, ev); a.followers = prof.followers - f0; }
      prof.done[brief.id] = stars;
      var lv = levelFor(prof.xp); if (lv > prof.level) { prof.level = lv; ev.push({ t: "level", level: lv }); }
    }
    prof.recent.unshift({ stars: stars, fires: 0, bpm: brief.bpm || 142, title: brief.title });
    prof.recent = prof.recent.slice(0, W.RecentMax);
    prof.aired = true; prof.lastDay = prof.day;
    if (stars === 3) coldCheck(prof, ev, "delivery3");
    coldCheck(prof, ev);
    return { applied: a, events: ev, first: first };
  }
  function fire(prof) {
    var ev = [], a = { cost: 0, money: C.Cred.Sources.Fire.amount, aura: 0, followers: 0, placements: 0, hits: 0, sponsors: 0, xp: 0 };
    var b = bestBeat(prof.recent);
    if (!b) { b = { stars: 0, fires: 0, bpm: 142, title: "an unsaved beat" }; prof.recent.unshift(b); }
    b.fires += 1; prof.money += a.money; prof.aired = true;
    var f0 = prof.followers; addFollowers(prof, C.Career.Sources.Fire.followers.amount, ev); a.followers = prof.followers - f0;
    coldCheck(prof, ev, "fire"); coldCheck(prof, ev);
    return { applied: a, events: ev };
  }
  function nextDay(prof) {
    var ev = [];
    prof.day += 1; prof.w.today = 0; prof.w.phone.today = 0;
    if (prof.aura < 0) { var h = Math.min(C.Career.Sources.AuraHeal.aura.max, -prof.aura); prof.aura += h; ev.push({ t: "heal", n: h }); }
    coldCheck(prof, ev);
    return { events: ev };
  }
  function gateCheck(gate, prof) {
    var rows = Object.keys(gate.needs || {}).map(function (k) { return { k: k, need: gate.needs[k], have: prof[k] || 0, ok: (prof[k] || 0) >= gate.needs[k] }; });
    var money = { need: gate.cost || 0, have: prof.money, ok: prof.money >= (gate.cost || 0) };
    return { rows: rows, money: money, ok: rows.every(function (r) { return r.ok; }) && money.ok };
  }

  /* ---------- profiles ---------- */
  function fresh() {
    return { money: 0, aura: 0, followers: 0, placements: 0, hits: 0, sponsors: 0, level: 1, xp: 0, sponsor: null,
      recent: [], rel: {}, aired: false, day: 1, lastDay: 1, cold: null, rearm: false, tier: 0, hall: false, done: {}, gear: { "808": true },
      hadHit: false, plaquePlanted: false,
      w: { count: 0, today: 0, queue: [], seen: {}, last: {}, caps: {}, phone: { today: 0 } } };
  }
  var PRESETS = [
    { id: "fresh", name: "Day one", note: "A brand new producer. Nothing yet.", make: function () { return fresh(); } },
    { id: "placed", name: "First placement", note: "Day 3. One placement, a 3-star beat, a little money.", make: function () {
      var p = fresh(); p.money = 1400; p.aura = 90; p.followers = 1800; p.placements = 1; p.level = 3; p.xp = 260; p.day = 3; p.lastDay = 3; p.tier = 1;
      p.recent = [{ stars: 3, fires: 1, bpm: 142, title: "Late Bus Home" }]; p.aired = true; p.done = { j1: 3, j2: 2, t1: 2 }; p.w.count = 9; return p; } },
    { id: "sponsored", name: "Known, with a sponsor", note: "Day 6. 6,000 followers, a sponsor, two placements.", make: function () {
      var p = fresh(); p.money = 4200; p.aura = 320; p.followers = 6200; p.placements = 2; p.sponsors = 1; p.sponsor = "headphones"; p.level = 5; p.xp = 720; p.day = 6; p.lastDay = 6; p.tier = 2;
      p.recent = [{ stars: 3, fires: 3, bpm: 150, title: "Glow Stick" }]; p.aired = true; p.w.count = 24; p.rel = { rep: { score: 1, flags: {} }, rival: { score: -1, flags: { posted: 5 } } }; return p; } },
    { id: "red", name: "In the red", note: "Day 5. Aura at -60 after some bad calls, no delivery in days.", make: function () {
      var p = fresh(); p.money = 300; p.aura = -60; p.followers = 2400; p.placements = 1; p.level = 3; p.xp = 300; p.day = 5; p.lastDay = 2; p.tier = 1;
      p.recent = [{ stars: 2, fires: 0, bpm: 142, title: "Late Bus Home" }]; p.w.count = 14; p.rel = { blogger: { score: -2, flags: {} }, mom: { score: -1, flags: {} } };
      coldCheck(p, null); return p; } }
  ];

  /* ---------- BriefCheck (request grading) ---------- */
  var TRACKS = ["Kick", "Snare", "Clap", "Hat", "808"];
  var DEFAULT_GRID = ["1000001000100000", "0000100000001000", "0000000000001000", "1010101010101010", "0000000000000000"];
  function askText(a) {
    var k = a.k;
    if (k === "bpm") return "BPM " + a.min + "–" + a.max;
    if (k === "backbeat") return "Snare or clap on 2 & 4";
    if (k === "on") {
      if (a.track === "Kick" && a.steps.length === 1 && a.steps[0] === 1) return "Kick on the 1";
      if (a.track === "Snare" && a.steps.length === 1 && a.steps[0] === 9) return "Snare on beat 3";
      if (a.track === "Hat" && a.steps.length === 4 && a.steps[0] === 3) return "Hats on the offbeats";
      return a.track + " on steps " + a.steps.join(", ");
    }
    if (k === "min") return a.n + "+ " + (a.track === "808" ? "808 notes" : a.track.toLowerCase() + "s");
    if (k === "max") return a.n === 0 ? "No " + a.track.toLowerCase() : a.n + " " + a.track.toLowerCase() + "s max";
    if (k === "notes") return "808 uses " + a.n + "+ different notes";
    if (k === "rolls") return a.n + "+ hat rolls";
    if (k === "swing") return "Swing " + a.n + "%+";
    if (k === "melody") return "Keys: " + a.n + "+ notes";
    if (k === "melnotes") return "Keys use " + a.n + "+ different notes";
    if (k === "chord") return "A chord on the keys (2+ notes together)";
    return "?";
  }
  function askNeeds(a) {
    if (a.k === "notes") return "Bass"; if (a.k === "rolls") return "Rolls"; if (a.k === "swing") return "Swing";
    if ((a.k === "min" || a.k === "on") && a.track === "808") return "Bass"; return null;
  }
  /* beat = { grid: [5 strings of 16 chars], bpm, swing, keys: { notes, distinct } } */
  function askOk(a, beat) {
    var seg = function (name) { return beat.grid[TRACKS.indexOf(name)] || ""; };
    var hits = function (s) { return s.replace(/0/g, "").length; };
    var on = function (s, step) { var c = s.charAt(step - 1); return c !== "" && c !== "0"; };
    var k = a.k;
    if (k === "bpm") return beat.bpm >= a.min && beat.bpm <= a.max;
    if (k === "backbeat") { var sn = seg("Snare"), cl = seg("Clap"); return (on(sn, 5) || on(cl, 5)) && (on(sn, 13) || on(cl, 13)); }
    if (k === "on") return a.steps.every(function (s) { return on(seg(a.track), s); });
    if (k === "min") return hits(seg(a.track)) >= a.n;
    if (k === "max") return hits(seg(a.track)) <= a.n;
    if (k === "notes") { var seen = {}; seg("808").replace(/[^0]/g, function (ch) { seen[ch] = 1; return ch; }); return Object.keys(seen).length >= a.n; }
    if (k === "rolls") return seg("Hat").replace(/[^23]/g, "").length >= a.n;
    if (k === "swing") return (beat.swing || 0) >= a.n;
    if (k === "melody") return (beat.keys.notes || 0) >= a.n;
    if (k === "melnotes") return (beat.keys.distinct || 0) >= a.n;
    return false;
  }
  function checkBrief(brief, beat) {
    var res = { asks: brief.asks.map(function (a) { return { text: askText(a), ok: askOk(a, beat), needs: askNeeds(a), keys: /^mel/.test(a.k) }; }) };
    res.met = res.asks.filter(function (r) { return r.ok; }).length; res.total = res.asks.length;
    if (brief.bonus) res.bonus = { text: askText(brief.bonus), ok: askOk(brief.bonus, beat), needs: askNeeds(brief.bonus), keys: /^mel/.test(brief.bonus.k) };
    res.passed = res.met === res.total;
    res.stars = res.passed ? (res.bonus && res.bonus.ok ? 3 : 2) : 0;
    var changed = 0;
    for (var t = 0; t < 5; t++) for (var i = 0; i < 16; i++) if (beat.grid[t].charAt(i) !== DEFAULT_GRID[t].charAt(i)) changed++;
    res.changed = changed + (beat.keys.notes || 0);
    return res;
  }

  root.PLE = { byId: byId, visitorById: visitorById, sponsorById: sponsorById, MODEL_NOTES: MODEL_NOTES, PRESETS: PRESETS,
    chance: chance, readiness: readiness, beatQuality: beatQuality, bestBeat: bestBeat, breakdown: breakdown, resolve: resolve,
    gateRows: gateRows, gateOk: gateOk, capOk: capOk, eligible: eligible, blockers: blockers, pick: pick, arrive: arrive, apply: apply,
    canVisit: canVisit, canPhone: canPhone, dailyMax: dailyMax, coldStep: coldStep, coldCheck: coldCheck,
    offers: offers, deliver: deliver, fire: fire, nextDay: nextDay, gateCheck: gateCheck, fresh: fresh,
    tierIndex: tierIndex, levelFor: levelFor, isPhone: isPhone, relScore: relScore, auraPts: auraPts, folPts: folPts,
    TRACKS: TRACKS, DEFAULT_GRID: DEFAULT_GRID, askText: askText, checkBrief: checkBrief, clone: function (p) { return JSON.parse(JSON.stringify(p)); } };
})(typeof window !== "undefined" ? window : globalThis);
