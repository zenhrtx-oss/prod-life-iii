-- Edit: SystemLoader starts enabled systems, skips disabled ones and README, and reports load or start failures
-- (quiet here, so the test itself leaves no [OK][ERR] in the output).
local SSS = game:GetService("ServerScriptService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Loader = freshRequire(SSS.OK.Services.SystemLoader)
local folder = Instance.new("Folder"); folder.Name = "_T18Systems"; folder.Parent = game:GetService("ServerStorage")
local function mod(name, src) local m = Instance.new("ModuleScript"); m.Name = name; m.Source = src; m.Parent = folder; return m end
mod("Good", "return { Enabled = true, Init = function(ctx) ctx.started = (ctx.started or 0) + 1 end }")
mod("Off", "return { Enabled = false, Init = function() error('should not start') end }")
mod("BadLoad", "error('boom at load')")
mod("BadInit", "return { Enabled = true, Init = function() error('boom at start') end }")
mod("README", "return 'docs'")
local ctx = {}
local ok, res = pcall(function() local s, f = Loader.Run(folder, ctx, { quiet = true }); return { s = s, f = f } end)
local okList, failList = ok and res.s, ok and res.f
local function check()
  assert(ok, "loader threw: " .. tostring(res))
  assert(#okList == 1 and okList[1] == "Good" and ctx.started == 1, "started list wrong: " .. table.concat(okList, ","))
  assert(#failList == 2 and failList[1] == "BadInit" and failList[2] == "BadLoad", "failed list wrong: " .. table.concat(failList, ","))
  assert(folder:GetAttribute("SystemsFailed") == "BadInit,BadLoad" and folder:GetAttribute("SystemsStarted") == "Good", "folder attributes wrong")
  assert(folder.Good:GetAttribute("InitOK") == true and folder.BadInit:GetAttribute("InitOK") == nil and folder.Off:GetAttribute("InitOK") == nil, "InitOK flags wrong")
end
local cok, cerr = pcall(check)
folder:Destroy()
if not cok then error(cerr) end
-- the test runner treats [OK][ERR] as a failure
assert(SSS.OK.Main.Source:find("SystemLoader", 1, true), "Main does not use the SystemLoader")
return "T18 OK: loader starts enabled systems, skips disabled and README, lists load and start failures, sets InitOK"
