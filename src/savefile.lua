--****************
---- configFile ----
--****************
local configData = {}

function initializeConfig()
	print("initializing configuration")
	--[[
	for i = 1, #CONFIG_REF_ORDER do
		CONFIG_REF[CONFIG_REF_ORDER[i] ] = i
		configData[i] = 0
	end
	if check_file_exists("config") == false then
		writeConfigFile()
	end
	]]--
	configData = CONFIG_REF
	if (check_file_exists("config") == true) then
		readConfigFile()
		if #configData ~= #CONFIG_REF then 
			configData = CONFIG_REF
			writeConfigFile()
		end
	else
		writeConfigFile()
	end
end

function writeConfigFile()
	playdate.datastore.write(configData, "config")
	--print("config data write")
end

function readConfigFile()
	configData = playdate.datastore.read("config")
	--print("config data read")
end

function deleteConfigFile()
	local result = playdate.datastore.delete("config")
	--print("config data delete " .. result)
end

function setConfigValue(itemID, value)
	configData[itemID] = value
	writeConfigFile()
end

function getConfigValue(itemID)
	--print("get config")
	--for i,v in pairs(configData) do
	--	print(i .. " - " .. v)
	--end
	return configData[itemID]
end

function get_file_value_text(name)
   local s = "off"
   if getConfigValue(name) == 1 then s = "on" end
   return s
end

function toggle_config_value(name)
   local f=getConfigValue(name)
   if f == 1 then f = 0 else f = 1 end
   setConfigValue(name, f)
end

--**************
---- savefile ----
--**************
local saveData = {}

function initializeSave()
	print("initializing save file")
	--[[
	for i = 1, #SAVE_REF_ORDER do
		SAVE_REF[SAVE_REF_ORDER[i] ] = i
		saveData[i] = 0
	end
	]]--
	saveData = SAVE_REF
	if (check_file_exists(configData.Default_Save) == true) then
		readSaveFile(configData.Default_Save)
		if #saveData ~= #SAVE_REF then 
			saveData = SAVE_REF
			writeSaveFile(configData.Default_Save) --need to future proof handle better but this will do for now
		end
	else
		writeSaveFile(configData.Default_Save)
	end
	initializeMun()
end

function writeSaveFile(filename)
	playdate.datastore.write(saveData, filename)
	--print("save data write")
end

function readSaveFile(filename)
	saveData = playdate.datastore.read(filename)
	--print("save data read")
end

function deleteSaveFile(filename)
	local result = playdate.datastore.delete(filename)
	--print("save data delete " .. result)
end

function setSaveValue(itemID, value)
	saveData[itemID] = value
end

function getSaveValue(itemID)
	return saveData[itemID]
end

function check_file_exists(name)
   local f=playdate.datastore.read(name)
   if f~=nil then return true else return false end
end