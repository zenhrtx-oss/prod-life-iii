const fs=require("fs"); global.window=globalThis; eval(fs.readFileSync(process.argv[2]+"/site/data.js","utf8").replace("window.PL","globalThis.PL")); require(process.argv[2]+"/site/engine.js");
const E=globalThis.PLE, PL=globalThis.PL; let seen=new Set(), fuSeen=new Set(), visits=0, phone=0, colds=0, thaws=0, drops=0, tiers=0, errs=0;
for (let run=0; run<400; run++) { const p=E.PRESETS[run%4].make();
  for (let d=0; d<30; d++) {
    for (let k=0;k<12;k++){ const src=Math.random()<0.65?"walkin":"phone"; if(src==="walkin"?!E.canVisit(p):!E.canPhone(p)) continue; const pk=E.pick(p,src); if(!pk) continue; const arr=E.arrive(p,pk); (pk.kind==="followup"?fuSeen:seen).add(pk.card.id); src==="walkin"?visits++:phone++;
      const ch=pk.card.choices||[]; if(ch.length && Math.random()<0.93){ const c=ch[Math.floor(Math.random()*ch.length)]; const r=E.resolve(pk.card,c,p); if(r.ok){ const res=E.apply(p,pk.card,r.outcome,r.cost); res.events.forEach(e=>{ if(e.t==="cold")colds++; if(e.t==="thaw")thaws++; if(e.t==="sponsor"&&e.drop)drops++; if(e.t==="tier")tiers++; }); } }
      if (p.money<0||p.followers<0||isNaN(p.aura)) { errs++; } }
    if (Math.random()<0.5){ const o=E.offers(p); if(o.length) E.deliver(p,o[0],Math.random()<0.5?3:2); }
    if (Math.random()<0.2) E.fire(p);
    E.nextDay(p); } }
console.log({cardsDrawn:seen.size, followupsDrawn:fuSeen.size, visits, phone, colds, thaws, drops, tiers, errs});
const never=PL.cards.filter(c=>!seen.has(c.id)&&!fuSeen.has(c.id)).map(c=>c.id); console.log("never drawn:", never.join(", "));
