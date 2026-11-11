--[[ OK Studio systems folder.
Each ModuleScript here is a system stub: `return {Enabled=false, Version=0, Init=function(ctx) end}`.
ServerScriptService.OK.Main requires every stub and calls Init(ctx) only when Enabled is true.
ctx = { Data = DataService, Lighting = LightingService, Interaction = InteractionService }.
Add a system: create the module, implement Init, register interaction kinds via ctx.Interaction.Register(kind, handler),
add prompts to world parts with CollectionService tag "OK_Interactable" and attribute Kind, extend Modules.Interactions with the prompt copy,
and extend the client panel (Modules.PanelUI) with a renderer. Never put scripts inside Workspace.OKStudio models.
]]
return {}
