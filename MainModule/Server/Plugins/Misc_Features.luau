--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!

return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	-- // Remove legacy trello board
	local epix_board_index = type(Settings.Trello_Secondary) == "table" and table.find(Settings.Trello_Secondary, "9HH6BEX2")
	
	if epix_board_index then
		table.remove(Settings.Trello_Secondary, epix_board_index)
		Logs:AddLog("Script", "Removed legacy trello board")
	end

	--// AutoClean
	if Settings.AutoClean then
		service.StartLoop("AUTO_CLEAN", Settings.AutoCleanDelay, Functions.CleanWorkspace, true)
		Logs:AddLog("Script", `Started autoclean with {Settings.AutoCleanDelay}s delay`)
	end

	-- // Backwards compatibility
	local Pcall = server.Pcall
	local function cPcall(func, ...)
		return Pcall(function(...)
			return coroutine.resume(coroutine.create(func), ...)
		end, ...)
	end
	server.cPcall, service.cPcall = cPcall, cPcall
	service.AltUnpack = function(args, shift) -- TODO: Remove. This is not used in Adonis at all and is easily replicatable so you can safely remove it withour fear
		return table.unpack(args, 1 + (shift and shift - 1 or 0), 10 + (shift and shift - 1 or 0))
	end
	service.CloneTable = function(tbl)
		return getmetatable(tbl) and setmetatable(table.clone(tbl), {__index = function(_, k) return tbl[k] end}) or table.clone(tbl)
	end
	service.GoodSignal = service.Signal
	service.Yield = function()
		local event = service.Signal.new()
		return {
			Release = function(...) event:Fire(...) end;
			Wait = function(...) return event:Wait(...) end;
			Destroy = function() event:Destroy() end;
			Event = event;
		}
	end
	Remote.UnEncrypted = setmetatable({}, {
		__newindex = function(_, ind, val)
			warn("Unencrypted remote commands are deprecated; moving", ind, "to Remote.Commands. Replace `Remote.Unencrypted` with `Remote.Commands`!")
			Remote.Commands[ind] = val
			Logs:AddLog("Script", `Attempted to add {ind} to legacy Remote.Unencrypted. Moving to Remote.Commands`)
		end
	})
	Functions.GetRandom = function(pLen)
		local random = math.random
		local format = string.format

		local Len = (type(pLen) == "number" and pLen) or random(5,10) --// reru
		local Res = {}
		for Idx = 1, Len do
			Res[Idx] = format("%02x", random(255))
		end
		return table.concat(Res)
	end
	if HTTP.Trello.API then
		HTTP.Trello.API.GenerateRequestID = Functions.GetRandom
	end
	--// Old settings/plugins backwards compatibility. Do not remove this because many games use old loader ranks!
	for _, rank in {"Owners", "HeadAdmins", "Admins", "Moderators", "Creators"} do
		if Settings[rank] and not Settings.CustomRanks[rank] then
			Settings.Ranks[if rank == "Owners" then "HeadAdmins" else rank].Users = Settings[rank]
		end
	end
	for k, v in {-- Legacy aliases
		[":giveppoints <player> <amount>"] = ":script local Players = game:GetService(\"Players\") for _, v in ipairs(_G.Adonis.GetPlayers(Players:GetPlayers()[math.random(1, #Players:GetPlayers())], \"<player>\")) do game:GetService(\"PointsService\"):AwardPoints(v.UserId, <amount>) end",
		[":giveplayerpoints <player> <amount>"] = ":script local Players = game:GetService(\"Players\") for _, v in ipairs(_G.Adonis.GetPlayers(Players:GetPlayers()[math.random(1, #Players:GetPlayers())], \"<player>\")) do game:GetService(\"PointsService\"):AwardPoints(v.UserId, <amount>) end",
		[":sendplayerpoints <player> <amount>"] = ":script local Players = game:GetService(\"Players\") for _, v in ipairs(_G.Adonis.GetPlayers(Players:GetPlayers()[math.random(1, #Players:GetPlayers())], \"<player>\")) do game:GetService(\"PointsService\"):AwardPoints(v.UserId, <amount>) end",
		[":flyclip <player>"] = ":fly <player> true";
	} do
		if not Variables.Aliases[k] then
			Variables.Aliases[k] = v
		end
	end
	HTTP.CheckHttp = function()
		return HTTP.HttpEnabled
	end

	Logs:AddLog("Script", "Misc Features Module Loaded")
end