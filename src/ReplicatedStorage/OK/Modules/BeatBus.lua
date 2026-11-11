-- Client-side beat signal shared by every LocalScript in one client (modules are cached per client).
-- Fire(step, hitTracks, source): hitTracks is a set keyed by track NAME ({Kick = true}); source is "local", "monitors" or "audition".
-- (Names, not indices: a BindableEvent turns sparse numeric keys into strings.)
local B = {}
local ev = Instance.new("BindableEvent")
B.Step = ev.Event
B.LastAt = 0
function B.Fire(step, hitTracks, source)
	B.LastAt = os.clock()
	B.LastSource = source
	ev:Fire(step, hitTracks or {}, source)
end
return B
