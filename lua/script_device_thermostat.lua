--
-- $Id: script_device_thermostat.lua,v 1.1 2014/11/06 20:11:59 pi Exp $
--
logging = true
debug = false
--
-- Translate as needed, but the "Basename" must be before everything else
-- These names link together the any list of sensors and devices named as follows:
--	a real room temperature sensor ("Basename Temp")
--	a virtual room temp sensor as a thermostat ("Basename Thermostat")
--	a thermostat up switch ("Basename Temp Up"), i.e. a virtual push on button w 10 sec or so off delay
--	a thermostat down switch ("Basename Temp Down"), i.e. a virtual push on button w 10 sec or so off delay
--
temperatureword = "Temp"
thermostatword = "Termostat"
tempupword = "Temp Opp"
tempdownword = "Temp Ned"
tempregword = "Temp Regulator"
--
-- Change limits as needed. 
-- 0 is interpreted as thermostat disabled in the thermostat logic, i.e. no on/off actions will be taken
--
tempmax = 25;
tempmin = 0;
--
-- These are the limits and steps for the slider setting
--
tempregmax=25
tempregmin=5
tempsteps=31
--
-- You will need to look up the "Basename Thermostat" device indexes from Domoticz and insert them here
--
termodevidx = {
 	-- Device Kjøkken T
	["Kj\xC3\xB8kken " .. thermostatword] = 125,
	["Hovedstue " .. thermostatword] = 57,
	["Kjellerstue " .. thermostatword] = 59,
	["Sstue " .. thermostatword] = 69
}

--
-- No changes should be needed below here unless you use port numbers other than 8080 for domoticz
--
function printf(format, ...)
	print(string.format(format, ...))
end

--
-- for i, v in pairs(devicechanged) do print("Changed Device=" ..  i .. " Value=" .. v .. "<--") end 
-- for i, v in pairs(termodevidx) do print("Idx=" ..  i .. " Value=" .. v .. "<--") end
-- for i, v in pairs(otherdevices_temperature) do print("Idx=" ..  i .. " temperature=" .. v .. "<--") end
-- for i, v in pairs(otherdevices_svalues) do print("Idx=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Idx=" ..  i .. " otherdevice=" .. v .. "<--") end
--
device = ""
for i, v in pairs(devicechanged) do
	if (#device == 0 or #i < #device) then device = i end
end
if (debug) then print("Triggered by " .. device .. " now " .. otherdevices_svalues[device] .. "/" .. otherdevices[device] ) end

commandArray = {}
if ( otherdevices[device] == "On" or otherdevices[device] == "Set Level" )
then
    --
    -- Plain text searches
    --
	idxup=string.find(device,tempupword,1,true) 
	idxdown=string.find(device,tempdownword,1,true) 
	idxreg=string.find(device,tempregword,1,true) 

	deltatemp=0
	idx=0
	if ( idxup )
	then 
		idx=idxup
		deltatemp=1
	elseif ( idxdown )
	then
		idx=idxdown
		deltatemp=-1
	elseif ( idxreg )
	then
		idx=idxreg
	else
		return commandArray
	end

	-- this typically includes a space after the Basename
	basedev=string.sub(device,1,idx-1)
	thermostatdev=basedev .. thermostatword
	thermostatvalue=otherdevices_temperature[thermostatdev]
	tempsensorvalue=otherdevices_temperature[basedev .. temperatureword]
	devidx=termodevidx[basedev .. thermostatword];
	if (debug)
	then
		print("Basedev is >" ..  basedev .. "<")
		print("thermostatdev is >" ..  thermostatdev .. "<")
		-- print("thermostatvalue is >" ..  thermostatvalue .. "<")
		print("tempsensorvalue is >" ..  tempsensorvalue .. "<")
		print("devidx is >" ..  devidx .. "<")
	end
	
	-- This fails before virtual device is set for the first time
	-- if ( thermostatvalue ) and ( devidx ) 
	if ( devidx ) 
	then
		if ( idxreg )
		then
			-- no thermostat temperature device found, so test if there is a slider value
			tempregvalue = otherdevices_svalues[basedev .. tempregword]
			if ( tempregvalue )
			then
				thermostatvalue = math.floor(tempregmin + (tempregmax - tempregmin)*tempregvalue/tempsteps)
				if (logging) then print("Regulator for " ..  basedev .. " set to " .. tempregvalue .. " --> " .. thermostatvalue) end
			else
				print("ERROR: Bug ? No Regulator device for " .. basedev)
			end
		else
			thermostatvalue=math.floor(thermostatvalue + deltatemp);
		end

		if ( thermostatvalue > tempmax ) then thermostatvalue = tempmax end
		if ( thermostatvalue < tempmin ) then thermostatvalue = tempmin end

		--
		-- Cannot make this work, so the OpenURL is a workaround
		-- commandArray['UpdateDevice']=devidx .. "|0|" .. thermostatvalue
		commandArray['OpenURL']='http://127.0.0.1:8080/json.htm?type=command&param=udevice&idx=' .. devidx .. '&nvalue=0&svalue=' .. thermostatvalue
		if (logging) then printf("Device %s (%s), thermostat %s set to %s, delta %s, current temp %s\n", device, devidx, thermostatdev, thermostatvalue, deltatemp, tempsensorvalue) end
	else
		print("Error: Device " .. device .. " has no corresponding thermostatdev or thermostatvalue")
	end
	-- Not needed. Add a 10sec off delay to the virtual on-switch instead to make it a push button
	-- commandArray[device]='Off'
end

return commandArray
