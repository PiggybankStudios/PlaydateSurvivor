-- configFile --
local configData = {}

function initializeConfig()
	print("initializing configuration")
	for i = 1, #CONFIG_REF_ORDER do
		CONFIG_REF[CONFIG_REF_ORDER[i]] = i
		configData[i] = 0
	end
	if check_file_exists("config") == false then
		writeConfigFile()
	end
end

function writeConfigFile()
	playdate.datastore.write(configData, "config")
	print("config data stowritered")
end

function readConfigFile()
	local configData = playdate.datastore.read("config")
	print("config data read")
end

function deleteConfigFile()
	local result = playdate.datastore.delete("config")
	print("save data delete")
end

function setConfigValue(itemNum, value)
	configData[itemNum] = value
	print("set config")
end

function getConfigValue(itemNum)
	print("get config")
	return configData[itemNum]
end

-- savefile --
local saveData = {}

function initializeSave()
	print("initializing save file")
	for i = 1, #SAVE_REF_ORDER do
		SAVE_REF[SAVE_REF_ORDER[i]] = i
		saveData[i] = 0
	end
end

function writeSaveFile(filename)
	playdate.datastore.write(saveData, filename)
	print("save data write")
end

function readSaveFile(filename)
	saveData = playdate.datastore.read(filename)
	print("save data read")
end

function deleteSaveFile(filename)
	local result = playdate.datastore.delete(filename)
	print("save data delete")
end

function setSaveValue(itemNum, value)
	saveData[itemNum] = value
end

function getSaveValue(itemNum)
	return saveData[itemNum]
end

function check_file_exists(name)
   local f=playdate.datastore.read(name)
   if f~=nil then return true else return false end
end