-- Perun for DCS World https://github.com/szporwolik/perun -> DCS Hook component

-- Initial init
local Perun = {}
package.path  = package.path..";"..lfs.currentdir().."/LuaSocket/?.lua"
package.cpath = package.cpath..";"..lfs.currentdir().."/LuaSocket/?.dll"

-- ###################### SETTINGS - DO NOT MODIFY OUTSIDE THIS SECTION #############################

Perun.RefreshStatus = 15 																-- (int) [default: 60] Base refresh rate in seconds to send status update
Perun.RefreshMission = 60 																-- (int) [default: 120] Refresh rate in seconds to send mission information
Perun.TCPTargetPort = 48622																-- (int) [default: 48621] TCP port to send data to
Perun.TCPPerunHost = "localhost"														-- (string) [default: "localhost"] IP adress of the Perun instance or "localhost"
Perun.Instance = 2																		-- (int) [default: 1] Id number of instance (if multiple DCS instances are to run at the same PC)
Perun.JsonStatusLocation = "Scripts\\Json\\" 											-- (string) [default: "Scripts\\Json\\"] Folder relative do user's SaveGames DCS folder -> status file updated each RefreshMission
Perun.MissionStartNoDeathWindow = 300													-- (int) [default: 300] Number of secounds after mission start when death of the pilot will not go to statistics, shall avoid death penalty during spawning DCS bugs
Perun.DebugMode = 2																		-- (int) [0 (default),1,2] Value greater than 0 will display Perun information in DCS log file, values: 1 - minimal verbose, 2 - all log information will be logged
Perun.LogServerMessages = 1																-- (int) [0,1 (default)] Set to 1 if you want to log also the chat messages send by server
Perun.MOTD_L1 = "Witamy na serwerze Gildia.org !"										-- (string) Message send to players connecting the server - Line 1
Perun.MOTD_L2 = "Wymagamy obecnosci DCS SRS oraz TeamSpeak - szczegoly na forum"		-- (string) Message send to players connecting the server - Line 2

-- ###################### END OF SETTINGS - DO NOT MODIFY OUTSIDE THIS SECTION ######################

-- Variable init
Perun.Version = "v0.9.0"
Perun.StatusData = {}
Perun.SlotsData = {}
Perun.MissionData = {}
Perun.ServerData = {}
Perun.StatData = {}
Perun.StatDataLastType = {}
Perun.MissionHash=""
Perun.lastSentStatus = 0
Perun.lastSentMission = 0
Perun.lastSentKeepAlive = 0
Perun.lastReconnect = 0
Perun.SendRetries = 3
Perun.RefreshKeepAlive = 3
Perun.JsonStatusLocation = lfs.writedir() .. Perun.JsonStatusLocation
Perun.socket  = require("socket")
Perun.IsServer = true --DCS.isServer( )								-- TBD looks like DCS API error, always returning True

-- ################################ Helper function definitions ################################
function stripChars(str)
    -- Hellper functions removes accents characters from string
    -- via https://stackoverflow.com/questions/50459102/replace-accented-characters-in-string-to-standard-with-lua
    local _tableAccents = {}
    _tableAccents["à"] = "a"
    _tableAccents["á"] = "a"
    _tableAccents["â"] = "a"
    _tableAccents["ã"] = "a"
    _tableAccents["ä"] = "a"
    _tableAccents["ç"] = "c"
    _tableAccents["è"] = "e"
    _tableAccents["é"] = "e"
    _tableAccents["ê"] = "e"
    _tableAccents["ë"] = "e"
    _tableAccents["ì"] = "i"
    _tableAccents["í"] = "i"
    _tableAccents["î"] = "i"
    _tableAccents["ï"] = "i"
    _tableAccents["ñ"] = "n"
    _tableAccents["ò"] = "o"
    _tableAccents["ó"] = "o"
    _tableAccents["ô"] = "o"
    _tableAccents["õ"] = "o"
    _tableAccents["ö"] = "o"
    _tableAccents["ù"] = "u"
    _tableAccents["ú"] = "u"
    _tableAccents["û"] = "u"
    _tableAccents["ü"] = "u"
    _tableAccents["ý"] = "y"
    _tableAccents["ÿ"] = "y"
    _tableAccents["À"] = "A"
    _tableAccents["Á"] = "A"
    _tableAccents["Â"] = "A"
    _tableAccents["Ã"] = "A"
    _tableAccents["Ä"] = "A"
    _tableAccents["Ç"] = "C"
    _tableAccents["È"] = "E"
    _tableAccents["É"] = "E"
    _tableAccents["Ê"] = "E"
    _tableAccents["Ë"] = "E"
    _tableAccents["Ì"] = "I"
    _tableAccents["Í"] = "I"
    _tableAccents["Î"] = "I"
    _tableAccents["Ï"] = "I"
    _tableAccents["Ñ"] = "N"
    _tableAccents["Ò"] = "O"
    _tableAccents["Ó"] = "O"
    _tableAccents["Ô"] = "O"
    _tableAccents["Õ"] = "O"
    _tableAccents["Ö"] = "O"
    _tableAccents["Ù"] = "U"
    _tableAccents["Ú"] = "U"
    _tableAccents["Û"] = "U"
    _tableAccents["Ü"] = "U"
    _tableAccents["Ý"] = "Y"

    -- Polish accents
    _tableAccents["ę"] = "e"
    _tableAccents["Ę"] = "Ę"
    _tableAccents["ó"] = "o"
    _tableAccents["Ó"] = "O"
    _tableAccents["ą"] = "a"
    _tableAccents["Ą"] = "A"
    _tableAccents["ś"] = "s"
    _tableAccents["Ś"] = "S"
    _tableAccents["ć"] = "c"
    _tableAccents["Ć"] = "C"
    _tableAccents["ż"] = "z"
    _tableAccents["Ż"] = "Z"
    _tableAccents["ź"] = "z"
    _tableAccents["Ź"] = "Z"
    _tableAccents["ł"] = "l"
    _tableAccents["Ł"] = "L"

    -- TBD additonal characters for other languages

	-- Check string and replace special chars via replacement table
    local _normalizedString = ''
    for _strChar in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
        if _tableAccents[_strChar] ~= nil then
			-- Replace char
            _normalizedString = _normalizedString.._tableAccents[_strChar]
        else
			-- No need to replace
            _normalizedString = _normalizedString.._strChar
        end
    end
    return _normalizedString
end

Perun.GetCategory = function(id)
    -- Helper function returns object category basing on I via  https://pastebin.com/GUAXrd2U TBD: rewrite
    local _killed_target_category = DCS.getUnitTypeAttribute(id, "category")
    
	-- Below, simple hack to get the propper category when DCS API is not returning correct value
	if _killed_target_category == nil then
        local _killed_target_cat_check_ship = DCS.getUnitTypeAttribute(id, "DeckLevel")
        local _killed_target_cat_check_plane = DCS.getUnitTypeAttribute(id, "WingSpan")
        if _killed_target_cat_check_ship ~= nil and _killed_target_cat_check_plane == nil then
            _killed_target_category = "Ships"
        elseif _killed_target_cat_check_ship == nil and _killed_target_cat_check_plane ~= nil then
            _killed_target_category = "Planes"
        else
            _killed_target_category = "Helicopters"
        end
    end
    return _killed_target_category
end

Perun.SideID2Name = function(id)
    -- Helper function returns side name per side (coalition) id
    local _sides = {
        [0] = 'SPECTATOR',
        [1] = 'RED',
        [2] = 'BLUE',
		[3] = 'NEUTRAL',	-- TBD check once this is released in DCS
    }
    return _sides[id]
end

Perun.AddLog = function(text,LogLevel)
    -- Adds logs to DCS.log file
	LogLevel = LogLevel or 1
	if Perun.DebugMode == LogLevel then
		net.log("Perun : ".. text)
	end
end

Perun.GenerateMissionHash = function()
	-- Generates unique simulation mission hash
	return DCS.getMissionName( ).."@".. Perun.Instance .. "@" .. Perun.Version .. "@".. os.date('%Y%m%d_%H%M%S') 
end

Perun.GetMulticrewAllParameters = function (PlayerId)
	-- Gets all multicrew parameters
	local _result = ""
	local _player_slot=net.get_player_info(PlayerId, 'slot')
	local _master_type= "?"
	local _master_slot = nil
	local _sub_slot = nil

	if _player_slot and _player_slot ~= '' and not (string.find(_player_slot, 'red') or string.find(_player_slot, 'blue')) then
		-- Player took model
		_master_slot = _player_slot
		_sub_slot =0

		if (not tonumber(_player_slot)) then 
			-- If this is multiseat slot parse master slot and look for seat number
			_t_start, _t_end = string.find(_player_slot, '_%d+')
		
			if _t_start then
				-- This is co-player
				_master_slot = string.sub(_player_slot, 0 , _t_start -1 )
				_sub_slot = string.sub(_player_slot, _t_start + 1, _t_end )
			end
		end
		_master_type = DCS.getUnitType(_master_slot)

	elseif string.find(_player_slot, 'red') or string.find(_player_slot, 'blue') then
		-- Deal with the special slots addded by Combined Arms and Spectators
		if string.find(_player_slot, 'artillery_commander') then
			_master_type = "artillery_commander"
		elseif string.find(_player_slot, 'instructor') then
			_master_type = "instructor"
		elseif string.find(_player_slot, 'forward_observer') then
			_master_type = "forward_observer"
		elseif string.find(_player_slot, 'observer') then
			_master_type = "observer"
		end
		_master_slot = -1
		_sub_slot = 0
	end
	return _master_type,_master_slot,_sub_slot
end

Perun.GetMulticrewParameter = function (PlayerId,Parameter)
	-- Get specific multicrew Parameter
	_master_type,_master_slot,_sub_slot = Perun.GetMulticrewAllParameters(PlayerId)

	if Parameter == "mastertype" then
		return _master_type
	elseif Parameter == "masterslot" then
		return _master_slot
	elseif Parameter == "subslot" then
		return _sub_slot
	elseif Parameter == "subtype" then
		if _sub_slot == 0 then
			return _master_type
		else
			return _master_type .. "_" .. _sub_slot
		end
	else
		return nil
	end
end

Perun.GetMulticrewCrew = function (owner_playerID)
	-- Get all multicrew crew
	_master_type,_master_slot,_sub_slot = Perun.GetMulticrewAllParameters(owner_playerID)

	local _crew = {}
	table.insert(_crew, owner_playerID)
	if _master_type == "F-14B" or _master_type == "Yak-52" or _master_type == "L-39C" or _master_type == "SA342M" or _master_type =="SA342Minigun" or _master_type == "SA342Mistral" or _master_type == "SA342L" then -- TBD add additional multicrew model types
		local _owner_side=net.get_player_info(owner_playerID, 'side')
		
		if _master_slot and _master_slot ~= "" then
			-- Search for all players from crew
			local _all_players = net.get_player_list()
			for PlayerIDIndex, _playerID in ipairs(_all_players) do
				 local _playerDetails = net.get_player_info( _playerID )
				 
				 if _playerDetails.side == _owner_side and (_playerDetails.slot == _master_slot  or _playerDetails.slot == _master_slot .. "_1" or _playerDetails.slot == _master_slot .. "_2" or _playerDetails.slot == _master_slot .. "_3" or _playerDetails.slot == _master_slot .. "_4") and _playerID ~= owner_playerID then
					-- Add to crew list
					table.insert(_crew, _playerID)
				 else
					-- Do nothing
				 end
			end
		end
	end

	Perun.AddLog("Multicrew check completed: " .. net.lua2json(_crew),2)
	return _crew
end

Perun.GetMulticrewCrewNames = function (owner_playerID)
	-- Get all crew names and return as string (needed for logging purposes)
	local _pilots_accounted = Perun.GetMulticrewCrew(owner_playerID)
	local _result_text = ""
	for _, pilotID in ipairs(_pilots_accounted) do
		_result_text= _result_text .. net.get_player_info(pilotID, "name") .. ", "
	end
	return _result_text
end

-- ################################ TCP Connection ################################

Perun.ConnectToPerun = function ()
	-- Connects to Perun server
	Perun.AddLog("Connecting to TCP server",2)
	Perun.TCP = assert(Perun.socket.tcp())
	Perun.TCP:settimeout(5000)
	
	_, _err = Perun.TCP:connect(Perun.TCPPerunHost, Perun.TCPTargetPort)
	if _err then
		-- Could not connect
		Perun.AddLog("ERROR - TCP connection error : " .. _err)
	else
		-- Connected
		Perun.AddLog("Sucess - connected to TCP server",2)
		Perun.lastReconnect = _now
	end
end

Perun.SendToPerun = function(data_id, data_package)
    -- Prepares and sends data package
    local _TempData={}
    _TempData["type"]=data_id
    _TempData["payload"]=data_package
    _TempData["timestamp"]=os.date('%Y-%m-%d %H:%M:%S')
	_TempData["instance"]=Perun.Instance
	
	-- Build TCP frame
    local _TCPFrame="<SOT>" .. stripChars(net.lua2json(_TempData)) .. "<EOT>"

    -- TCP Part - sending
	local _intStatus = nil
	local _intTries =0
	local _err=nil

	-- Try to send a few times (defind in settings section)
	while _intStatus == nil and _intTries < Perun.SendRetries do
		_intStatus, _err = Perun.TCP:send(_TCPFrame) 
		if _err then
			-- Failure, packet was not send
			Perun.AddLog("Packed not send : " .. data_id .. " , error: " .. _err .. ", tries: " .. _intTries,2)
			Perun.ConnectToPerun()
		else
			-- Succes, packet was send
			Perun.AddLog("Packet send : " .. data_id .. " , tries:" .. _intTries,2)
		end
		_intTries=_intTries+1
		_err = nil
	end
	if _err then
		-- Add information to log file
		Perun.AddLog("ERROR - packed dropped : " .. data_id)
	end 
end

-- ################################ Log functions ################################

Perun.LogChat = function(playerID,msg,all)
    -- Logs chat messages
    local _TempData={}
    _TempData['player']= net.get_player_info(playerID, "name")
    _TempData['msg']=stripChars(msg)
    _TempData['all']=all
    _TempData['ucid']=net.get_player_info(playerID, 'ucid')
    _TempData['datetime']=os.date('%Y-%m-%d %H:%M:%S')
    _TempData['missionhash']=Perun.MissionHash

	Perun.AddLog("Sending chat message",2)
    Perun.SendToPerun(50,_TempData)
end

Perun.LogEvent = function(log_type,log_content,log_arg_1,log_arg_2)
    -- Logs events messages
    local _TempData={}
    _TempData['log_type']= log_type
	_TempData['log_arg_1']= log_arg_1
	_TempData['log_arg_2']= log_arg_2
    _TempData['log_content']=log_content
    _TempData['log_datetime']=os.date('%Y-%m-%d %H:%M:%S')
    _TempData['log_missionhash']=Perun.MissionHash
	
	if log_arg_1 == nil then
		log_arg_1 = "null"
	end
	if log_arg_2 == nil then
		log_arg_2 = "null"
	end

	Perun.AddLog("Sending event data, event: " .. log_type .. ", arg1:" .. log_arg_1 .. ", arg2:" .. log_arg_2 .. ", content: " .. log_content,2)
    Perun.SendToPerun(51,_TempData)
end

Perun.LogStats = function(playerID)
    -- Log player status
	local _PlayerStatsTable=Perun.LogStatsGet(playerID)
    local _TempData={}
	_TempData['stat_data_perun']=_PlayerStatsTable
	_TempData['stat_data_type']= _PlayerStatsTable['ps_type'];
	_TempData['stat_data_masterslot'] = _PlayerStatsTable['ps_masterslot'];
    _TempData['stat_data_subslot'] = _PlayerStatsTable['ps_subslot'];
	_TempData['stat_ucid']=net.get_player_info(playerID, 'ucid')
	_TempData['stat_name']=net.get_player_info(playerID, 'name')
    _TempData['stat_datetime']=os.date('%Y-%m-%d %H:%M:%S')
    _TempData['stat_missionhash']=Perun.MissionHash

	Perun.AddLog("Sending stats data",2)
    Perun.SendToPerun(52,_TempData)
end

Perun.LogLogin = function(playerID)
    -- Player logged in
    local _TempData={}
    _TempData['login_ucid']=net.get_player_info(playerID, 'ucid')
    _TempData['login_ipaddr']=net.get_player_info(playerID, 'ipaddr')
    _TempData['login_name']=net.get_player_info(playerID, 'name')
    _TempData['login_datetime']=os.date('%Y-%m-%d %H:%M:%S')

	Perun.AddLog("Sending login event",2)
    Perun.SendToPerun(53,_TempData)
end

--- ################################ Calculate stats ################################
		
Perun.LogStatsCount = function(argPlayerID,argAction)
	-- Creates or updates Perun statistics array
	local _player_hash=net.get_player_info(argPlayerID, 'ucid')..Perun.GetMulticrewParameter(argPlayerID,"subtype")
	
	if Perun.StatData[_player_hash] == nil then
		-- Create empty element
		 local _TempData={}
		_TempData['ps_type'] = Perun.GetMulticrewParameter(argPlayerID,"subtype")
		_TempData['ps_masterslot'] = Perun.GetMulticrewParameter(argPlayerID,"masterslot")
		_TempData['ps_subslot'] = Perun.GetMulticrewParameter(argPlayerID,"subslot")
		_TempData['ps_pvp'] = 0
		_TempData['ps_deaths'] = 0
		_TempData['ps_ejections'] = 0
		_TempData['ps_crashes'] = 0
		_TempData['ps_teamkills'] = 0
		_TempData['ps_kills_planes'] = 0
		_TempData['ps_kills_helicopters'] = 0
		_TempData['ps_kills_air_defense'] = 0
		_TempData['ps_kills_armor'] = 0
		_TempData['ps_kills_unarmed'] = 0
		_TempData['ps_kills_infantry'] = 0
		_TempData['ps_kills_ships'] = 0
		_TempData['ps_kills_fortification'] = 0
		_TempData['ps_kills_other'] = 0
		_TempData['ps_airfield_takeoffs'] = 0
		_TempData['ps_airfield_landings'] = 0
		_TempData['ps_ship_takeoffs'] = 0
		_TempData['ps_ship_landings'] = 0
		_TempData['ps_farp_takeoffs'] = 0
		_TempData['ps_farp_landings'] = 0
		_TempData['ps_other_takeoffs'] = 0
		_TempData['ps_other_landings'] = 0

		Perun.StatData[_player_hash]=_TempData
	end
	
	-- TBD BELLOW SEEMS TO BE OBSOLETE, CHECK AND DELETE
	if argType ~= nil then
		Perun.StatData[_player_hash]['ps_type']=Perun.GetMulticrewParameter(argPlayerID,"subtype");
		Perun.StatDataLastType[net.get_player_info(argPlayerID, 'ucid')]=_player_hash
	else
		-- Do nothing
	end 
	-- TBD ABOVE SEEMS TO BE OBSOLETE, CHECK AND DELETE

	if argAction == "eject" then
		Perun.StatData[_player_hash]['ps_ejections']=Perun.StatData[_player_hash]['ps_ejections']+1
	elseif  argAction == "pilot_death" then
		if DCS.getModelTime() > Perun.MissionStartNoDeathWindow then
			-- we do not track deaths during mission startup due to spawning issues
			Perun.StatData[_player_hash]['ps_deaths']=Perun.StatData[_player_hash]['ps_deaths']+1
		end
	elseif  argAction == "friendly_fire" then
		Perun.StatData[_player_hash]['ps_teamkills']=Perun.StatData[_player_hash]['ps_teamkills']+1
	elseif  argAction == "crash" then
		Perun.StatData[_player_hash]['ps_crashes']=Perun.StatData[_player_hash]['ps_crashes']+1
	elseif  argAction == "landing_FARP" then
		Perun.StatData[_player_hash]['ps_farp_landings']=Perun.StatData[_player_hash]['ps_farp_landings']+1
	elseif  argAction == "landing_SHIP" then
		Perun.StatData[_player_hash]['ps_ship_landings']=Perun.StatData[_player_hash]['ps_ship_landings']+1
	elseif  argAction == "landing_AIRFIELD" then
		Perun.StatData[_player_hash]['ps_airfield_landings']=Perun.StatData[_player_hash]['ps_airfield_landings']+1
	elseif  argAction == "tookoff_FARP" then
		Perun.StatData[_player_hash]['ps_farp_takeoffs']=Perun.StatData[_player_hash]['ps_farp_takeoffs']+1
	elseif  argAction == "tookoff_SHIP" then
		Perun.StatData[_player_hash]['ps_ship_takeoffs']=Perun.StatData[_player_hash]['ps_ship_takeoffs']+1
	elseif  argAction == "tookoff_AIRFIELD" then
		Perun.StatData[_player_hash]['ps_airfield_takeoffs']=Perun.StatData[_player_hash]['ps_airfield_takeoffs']+1
	elseif  argAction == "kill_Planes" then
		Perun.StatData[_player_hash]['ps_kills_planes']=Perun.StatData[_player_hash]['ps_kills_planes']+1
	elseif  argAction == "kill_Helicopters" then
		Perun.StatData[_player_hash]['ps_kills_helicopters']=Perun.StatData[_player_hash]['ps_kills_helicopters']+1
	elseif  argAction == "kill_Ships" then
		Perun.StatData[_player_hash]['ps_kills_ships']=Perun.StatData[_player_hash]['ps_kills_ships']+1
	elseif  argAction == "kill_Air_Defence" then
		Perun.StatData[_player_hash]['ps_kills_air_defense']=Perun.StatData[_player_hash]['ps_kills_air_defense']+1
	elseif  argAction == "kill_Unarmed" then
		Perun.StatData[_player_hash]['ps_kills_unarmed']=Perun.StatData[_player_hash]['ps_kills_unarmed']+1
	elseif  argAction == "kill_Armor" then
		Perun.StatData[_player_hash]['ps_kills_armor']=Perun.StatData[_player_hash]['ps_kills_armor']+1
	elseif  argAction == "kill_Infantry" then
		Perun.StatData[_player_hash]['ps_kills_infantry']=Perun.StatData[_player_hash]['ps_kills_infantry']+1
	elseif  argAction == "kill_Fortification" then
		Perun.StatData[_player_hash]['ps_kills_fortification']=Perun.StatData[_player_hash]['ps_kills_fortification']+1
	elseif  argAction == "kill_Other" then
		Perun.StatData[_player_hash]['ps_kills_other']=Perun.StatData[_player_hash]['ps_kills_other']+1
	elseif  argAction == "kill_PvP" then
		Perun.StatData[_player_hash]['ps_pvp']=Perun.StatData[_player_hash]['ps_pvp']+1
	elseif  argAction == "landing_OTHER" then
		Perun.StatData[_player_hash]['ps_other_landings']=Perun.StatData[_player_hash]['ps_other_landings']+1
	elseif  argAction == "tookoff_OTHER" then
		Perun.StatData[_player_hash]['ps_other_takeoffs']=Perun.StatData[_player_hash]['ps_other_takeoffs']+1
	end

	-- Always update slots
	Perun.StatData[_player_hash]['ps_masterslot'] = Perun.GetMulticrewParameter(argPlayerID,"masterslot")
	Perun.StatData[_player_hash]['ps_subslot'] = Perun.GetMulticrewParameter(argPlayerID,"subslot")
	
	Perun.AddLog("Stats data prepared",2)
	Perun.LogStats(argPlayerID);
end

Perun.LogStatsCountCrew = function (MasterPilotID,ActionType)
	-- Change stats for the whole crew
	local _pilots_accounted = Perun.GetMulticrewCrew(MasterPilotID)
	for _, pilotID in ipairs(_pilots_accounted) do
		Perun.LogStatsCount(pilotID,ActionType)
	end
end
-- ################################ Data preparation ################################

Perun.LogStatsGet = function(playerID)
	-- Gets Perun statistics array per player TBD rewrite
	local next = next -- Make next function local - this improves performance TBD
	local _player_hash = nil

	if next(Perun.StatDataLastType) == nil then
		-- Array is empty
		_player_hash=net.get_player_info(playerID, 'ucid')..Perun.GetMulticrewParameter(playerID,"subtype")
	elseif Perun.StatDataLastType[net.get_player_info(playerID, 'ucid')]== nil then
		-- Last type entry is empty
		_player_hash=net.get_player_info(playerID, 'ucid')..Perun.GetMulticrewParameter(playerID,"subtype")
	else
		-- Return last type entry
		_player_hash=Perun.StatDataLastType[net.get_player_info(playerID, 'ucid')]
	end
	
	local next = next -- Make next function local - this improves performance TBD
	if  next(Perun.StatData) == nil then
		-- Array is empty
		Perun.LogStatsCount(playerID,'init') -- Init statistics
	end
	if Perun.StatData[_player_hash]== nil then
		-- Stats for player are empty
		Perun.LogStatsCount(playerID,'init') -- Init statistics
	end

	Perun.AddLog("Getting stats data",2)
	return Perun.StatData[_player_hash];
end

Perun.UpdateJsonStatus = function()
    -- Updates status json file
    local _TempData={}
    _TempData["1"]=Perun.ServerData
    _TempData["2"]=Perun.StatusData
    _TempData["3"]=Perun.SlotsData
    -- _TempData["4"]=Perun.MissionData -- TBD: hangs for some large missions

	-- Export data to JSON file
    local _perun_export = io.open(Perun.JsonStatusLocation .. "perun_status_data.json", "w")
    _perun_export:write(net.lua2json(_TempData) .. "\n")
    _perun_export:close()
	Perun.AddLog("Updated JSON",2)
end

Perun.UpdateStatus = function()
    -- Main function for status updates

    -- Diagnostic data
		-- Update version data
		Perun.ServerData['v_dcs_hook']=Perun.Version

		-- Update clients data - count connected players
		_playerlist=net.get_player_list()
		_count = 0
		for _ in pairs(_playerlist) do _count = _count + 1 end
		Perun.ServerData['c_players']=_count

		-- Send
		Perun.AddLog("Sending server data",2)
		Perun.SendToPerun(1,Perun.ServerData)

    -- Status data - update all subsections
		-- 1 - Mission data
		local _TempData={}
		_TempData['name']=DCS.getMissionName()
		_TempData['modeltime']=DCS.getModelTime()
		_TempData['realtime']=DCS.getRealTime()
		_TempData['pause']=DCS.getPause()
		_TempData['multiplayer']=DCS.isMultiplayer()
		_TempData['theatre'] = Perun.MissionData['mission']['theatre']
		_TempData['weather'] = Perun.MissionData['mission']['weather']
		Perun.StatusData["mission"] = _TempData

		-- 2 - Players data
		_PlayersTable={}
		for _k, _i in ipairs(_playerlist) do
			_PlayersTable[_k]=net.get_player_info(_i)
		end
		Perun.StatusData["players"] = _PlayersTable

		-- Send
		Perun.AddLog("Sending status data",2)
		Perun.SendToPerun(2,Perun.StatusData)

    -- Update slots data
		Perun.SlotsData['coalitions']=DCS.getAvailableCoalitions()
		Perun.SlotsData['slots']={}

		-- Build up slot table
		for _j, _i in pairs(Perun.SlotsData['coalitions']) do
			Perun.SlotsData['slots'][_j]=DCS.getAvailableSlots(_j)
			
			for _sj, _si in pairs(Perun.SlotsData['slots'][_j]) do
				Perun.SlotsData['slots'][_j][_sj]['countryName']= nil
				Perun.SlotsData['slots'][_j][_sj]['onboard_num']= nil
				Perun.SlotsData['slots'][_j][_sj]['groupSize']= nil
				Perun.SlotsData['slots'][_j][_sj]['groupName']= nil
				Perun.SlotsData['slots'][_j][_sj]['callsign']= nil
				Perun.SlotsData['slots'][_j][_sj]['task']= nil
				Perun.SlotsData['slots'][_j][_sj]['airdromeId']= nil
				Perun.SlotsData['slots'][_j][_sj]['helipadName']= nil
			end
		end

		-- Send
		Perun.AddLog("Sending slots data",2)
		Perun.SendToPerun(3,Perun.SlotsData)
end

Perun.UpdateMission = function()
    -- Main function for mission information updates
	Perun.AddLog("Updating mission data",2)
    Perun.MissionData=DCS.getCurrentMission()
	-- Perun.SendToPerun(4,Perun.MissionData) -- TBD can cause data transmission troubles
	Perun.AddLog("Mission data updated",2)
end

--- ################################ Event callbacks ################################

Perun.onSimulationStart = function()
	-- Simulation was started
    Perun.MissionHash=Perun.GenerateMissionHash()
    Perun.LogEvent("SimStart","Mission " .. Perun.MissionHash .. " started",nil,nil);
	Perun.StatData = {}
	Perun.StatDataLastType = {}
	-- TBD send this to Perun
end

Perun.onSimulationStop = function()
	-- Simulation was stopped
    Perun.LogEvent("SimStop","Mission " .. Perun.MissionHash .. " finished",nil,nil);
	Perun.MissionHash=Perun.GenerateMissionHash();
	Perun.StatData = {}
	Perun.StatDataLastType = {}
	-- TBD send this to Perun
end

Perun.onPlayerDisconnect = function(id, err_code)
	-- Player disconnected - TBD DCS Bug, this is not triggered at this point of time
    Perun.LogEvent("disconnect", "Player " .. net.get_player_info(id, "name") .. " disconnected; " .. err_code,net.get_player_info(id, "name"),err_code);
	-- TBD send this to Perun
end

Perun.onSimulationFrame = function()
	-- Repeat for each simulator frame
    local _now = DCS.getRealTime()

    -- First run
    if Perun.lastSentMission ==0 and Perun.lastSentStatus ==0 then
        Perun.UpdateMission()
    end

    -- Send mission update and update JSON
    if _now > Perun.lastSentMission + Perun.RefreshMission then
        Perun.lastSentMission = _now

        Perun.UpdateMission()
        Perun.UpdateJsonStatus()
    end

    -- Send status update
    if _now > Perun.lastSentStatus + Perun.RefreshStatus then
        Perun.lastSentStatus = _now

        Perun.UpdateStatus()
    end
	
	-- Send keepalive
	if _now > Perun.lastSentKeepAlive + Perun.SendRetries then
		Perun.lastSentKeepAlive = _now
		Perun.SendToPerun(0,nil)
	end
end

Perun.onPlayerStart = function (id)
	-- Player entered cocpit
    net.send_chat_to(Perun.MOTD_L1, id);
    net.send_chat_to(Perun.MOTD_L2, id);
end

Perun.onPlayerTrySendChat = function (playerID, msg, all)
	-- Somebody tries to send chat message
    if msg~=Perun.MOTD_L1 and msg~=Perun.MOTD_L2 then
        Perun.LogChat(playerID,msg,all)
    end

    return msg
end

Perun.onGameEvent = function (eventName,arg1,arg2,arg3,arg4,arg5,arg6,arg7)
	-- Game event has occured
	Perun.AddLog("Event handler for ".. eventName .. " started",2)
    if eventName == "friendly_fire" then
        --"friendly_fire", playerID, weaponName, victimPlayerID
		if arg2 == "" then
			arg2 = "Cannon"
		end
		
        Perun.LogEvent(eventName,Perun.SideID2Name( net.get_player_info(arg1, "side")) .. " player " .. net.get_player_info(arg1, "name").." killed friendy " .. net.get_player_info(arg3, "name") .. " using " .. arg2,nil,nil);

    elseif eventName == "mission_end" then
        --"mission_end", winner, msg
        Perun.LogEvent(eventName,"Mission finished, winner " .. arg1 .. " message: " .. arg2,nil,nil);

    elseif eventName == "kill" then
        --"kill", killerPlayerID, killerUnitType, killerSide, victimPlayerID, victimUnitType, victimSide, weaponName
		local _temp_victim=""
		if net.get_player_info(arg4, "name") ~= nil then
            _temp_victim = " player(s) ".. Perun.GetMulticrewCrewNames(arg1) .. " ";
            
			Perun.LogStats(arg4);
        else
            _temp_victim = " AI ";
        end

        if net.get_player_info(arg1, "name") ~= nil then
			_temp_killers = " player(s) ".. Perun.GetMulticrewCrewNames(arg1) .." ";
			
			_temp_event_type=""
			if arg3 ~= arg6 then
				_temp_category=Perun.GetCategory(arg5)
				
				if _temp_category == "Planes" then
					_temp_event_type="kill_Planes"
				elseif _temp_category == "Helicopters" then
					_temp_event_type="kill_Helicopters"
				elseif _temp_category == "Ships" then
					_temp_event_type="kill_Ships"
				elseif _temp_category == "Air Defence" then
					_temp_event_type="kill_Air_Defence"
				elseif _temp_category == "Unarmed" then
					_temp_event_type="kill_Unarmed"
				elseif _temp_category == "Armor" then
					_temp_event_type="kill_Armor"
				elseif _temp_category == "Infantry" then
					_temp_event_type="kill_Infantry"
				elseif _temp_category == "Fortification" then
					_temp_event_type="kill_Fortification"
				else 
					_temp_event_type="kill_Other"
				end
				if net.get_player_info(arg4, "name") ~= nil and arg3 ~= arg6 then
					Perun.LogStatsCountCrew (arg1,"kill_PvP")
				end
			else
				_temp_event_type="friendly_fire"
			end
			
			Perun.LogStatsCountCrew (arg1,_temp_event_type)
			
        else
            _temp_killers = " AI ";
        end
		
		if arg7 == "" then
			arg7 = "Cannon"
		end

		Perun.LogEvent(eventName,Perun.SideID2Name(arg3) .. _temp_killers .. " in " .. arg2 .. " killed " .. Perun.SideID2Name(arg6) .. _temp_victim .. " in " .. arg5  .. " using " .. arg7 .. " [".. Perun.GetCategory(arg5).."]",arg7,Perun.GetCategory(arg5));

    elseif eventName == "self_kill" then
        --"self_kill", playerID
		Perun.LogStats(arg1);
        Perun.LogEvent(eventName,net.get_player_info(arg1, "name") .. " killed himself",nil,nil);

    elseif eventName == "change_slot" then
        --"change_slot", playerID, slotID, prevSide

		Perun.LogStatsCount(arg1,"init")
		_master_type,_master_slot,_sub_slot = Perun.GetMulticrewAllParameters(arg1)
		if _sub_slot == nil then
			_sub_slot =""
		else
			_sub_slot =" (" .. _sub_slot .. ")  "
		end       
	   Perun.LogEvent(eventName,Perun.SideID2Name( net.get_player_info(arg1, "side")) .. " player " .. net.get_player_info(arg1, "name") .. " changed slot to " .. _master_type .. " " .. _sub_slot,nil,nil);
       

    elseif eventName == "connect" then
        --"connect", playerID, name
        Perun.LogLogin(arg1);
        Perun.LogEvent(eventName,"Player "..net.get_player_info(arg1, "name") .. " connected",nil,nil);

    elseif eventName == "disconnect" then
        --"disconnect", playerID, name, playerSide, reason_code
		Perun.LogStats(arg1);
        Perun.LogEvent(eventName, Perun.SideID2Name(arg3) .. " player " ..net.get_player_info(arg1, "name") .. " disconnected",nil,nil);

    elseif eventName == "crash" then
        --"crash", playerID, unit_missionID
		Perun.LogStatsCountCrew (arg1,"crash")
		Perun.LogEvent(eventName, Perun.SideID2Name( net.get_player_info(arg1, "side")) .. " player(s) " .. Perun.GetMulticrewCrewNames(arg1)  .. " crashed in " .. DCS.getUnitType(arg2),nil,nil);

    elseif eventName == "eject" then
        --"eject", playerID, unit_missionID
		Perun.LogStatsCountCrew (arg1,"eject") -- TBD crew or initiator only?
		Perun.LogEvent(eventName, Perun.SideID2Name( net.get_player_info(arg1, "side")) .. " player(s) " .. Perun.GetMulticrewCrewNames(arg1) .. " ejected " .. DCS.getUnitType(arg2),nil,nil);

    elseif eventName == "takeoff" then
        --"takeoff", playerID, unit_missionID, airdromeName
        if arg3 ~= "" then
            _temp_airfield = " from " .. arg3;
        else
            _temp_airfield = "";
        end

		-- TBD below shall be moved to function and arrays of strings - see landings
		_temp_type = ""
		if string.find(arg3, "FARP",1,true) then
			_temp_type="tookoff_FARP"
		elseif string.find(arg3, "CVN-74 John C. Stennis",1,true) or string.find(arg3, "LHA-1 Tarawa",1,true) or string.find(arg3, "SHIP",1,true) then
			_temp_type="tookoff_SHIP"
		elseif arg3 ~= "" then
			_temp_type="tookoff_AIRFIELD"
		else
			_temp_type="tookoff_OTHER"
		end
		
		Perun.LogStatsCountCrew (arg1,_temp_type)
		Perun.LogEvent(eventName, Perun.SideID2Name( net.get_player_info(arg1, "side")) .. " player(s) " .. Perun.GetMulticrewCrewNames(arg1) .. " took off in ".. DCS.getUnitType(arg2) .. _temp_airfield,arg3,nil);

    elseif eventName == "landing" then
        --"landing", playerID, unit_missionID, airdromeName
        if arg3 ~= "" then
            _temp = " at " .. arg3;
        else
            _temp ="";
        end

		-- TBD below shall be moved to function and arrays of strings - see takeoffs
		_temp_type = ""
		if string.find(arg3, "FARP",1,true) then
			_temp_type = "landing_FARP"
		elseif string.find(arg3, "CVN-74 John C. Stennis",1,true) or string.find(arg3, "LHA-1 Tarawa",1,true) or string.find(arg3, "SHIP",1,true) then
			_temp_type = "landing_SHIP"
		elseif arg3 ~= "" then
			_temp_type = "landing_AIRFIELD"
		else
			_temp_type = "landing_OTHER"
		end
		
		Perun.LogStatsCountCrew (arg1,_temp_type)
		Perun.LogEvent(eventName, Perun.SideID2Name( net.get_player_info(arg1, "side")) .. " player(s) " .. Perun.GetMulticrewCrewNames(arg1) .. " landed in " .. DCS.getUnitType(arg2).. _temp_airfield,arg3,nil);

    elseif eventName == "pilot_death" then
        --"pilot_death", playerID, unit_missionID
		Perun.LogStatsCountCrew (arg1,"pilot_death")  -- TBD crew or initiator only?
		Perun.LogEvent(eventName, Perun.SideID2Name( net.get_player_info(arg1, "side")) .. " player(s) " .. Perun.GetMulticrewCrewNames(arg1) .. " in " .. DCS.getUnitType(arg2) .. " died",nil,nil);

    else
        Perun.LogEvent(eventName,"Unknown event type",nil,nil);

    end
	Perun.AddLog("Event handler for " .. eventName .. " finished",2)
end

-- ########### Finalize and set callbacks ###########
if Perun.IsServer then
	-- If this game instance is hosting multiplayer game, start Perun
	Perun.MissionHash=Perun.GenerateMissionHash()														-- Generate initial missionhash
	DCS.setUserCallbacks(Perun)																			-- Set user callbacs,  map DCS event handlers with functions defined above
	net.log("Perun by VladMordock was loaded: " .. Perun.Version )										-- Display perun information in log
	Perun.ConnectToPerun()																				-- Connect to Perun server
end
