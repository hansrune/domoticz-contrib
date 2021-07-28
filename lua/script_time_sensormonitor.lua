--
-- $Id: script_time_sensormonitor.lua,v 1.3 2015/11/01 18:48:39 pi Exp $
--
logging = true
debug = false

-- For timing
timing = false
if (timing) then nClock = os.clock() end

--
-- User variables from Domoticz setup
--	SensorTimeOut (integer) is useful to change for debugging, or undefined for defaults
--	SensorsAlerted (string) - blank / undefined for no alerts, set to "None" as initial value for alterts
--	SensorMonitorDevices (string) - comma separated list of substrings to match for device names
--	SensorMonitorExcluded (string) - comma separated list of substrings out of the matched devices to exclude
--
monitordevices=uservariables["SensorMonitorDevices"]; 
excludeddevices=uservariables["SensorMonitorExcluded"]; 
devicetimeout=uservariables["SensorTimeOut"]; 
alertedvariable="SensorsAlerted";
--
-- Fallback values
--
if not ( monitordevices ) then monitordevices = "Temp,CPU" end
if not ( excludeddevices ) then excludeddevices = "egulator" end
if not ( devicetimeout ) then devicetimeout = 600 end

--
-- Adapt messaging as preferred
--
function sendmsg(msg)
	table.insert(commandArray, { ['SendNotification'] = msg } )
    -- I use my own pushover for urgent messages (pushover is not enabled in my Domoticz setup)
	-- os.execute("/usr/local/bin/pushover '" .. msg .. "' &")
end

--
-- No changes should be needed below here
--
function changedsince(device)
	t1 = os.time()
	ts = otherdevices_lastupdate[device]
	year = string.sub(ts, 1, 4)
	month = string.sub(ts, 6, 7)
	day = string.sub(ts, 9, 10)
	hour = string.sub(ts, 12, 13)
	minutes = string.sub(ts, 15, 16)
	seconds = string.sub(ts, 18, 19)
	t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
	difftime=math.floor(os.difftime(t1,t2))
	-- if (debug) then print("Device " .. device .. " not changed in " .. difftime .. " seconds") end
	return difftime
end

function setuservar(name, value)
	table.insert(commandArray, { ['Variable:' .. name] = value } )
end

function addtouservar(name, value)
	local addvalue = "[" .. value .. "]"
	local currvalue = uservariables[name]

	if ( currvalue ) then
		pos = string.find(currvalue,addvalue,1,true)
		if not ( pos ) then
			currvalue = currvalue .. addvalue
			setuservar(name, currvalue)			
			return true
		end
	else
		sendmsg(msg .. ". Please add user string variable '" .. name .. "' to prevent duplicate alerts")
	end
	return false
end	

function rmfromuservar(name, value)
	local rmvalue = "[" .. value .. "]"
	local currvalue = uservariables[name]
	local pos, len

	if ( currvalue ) then
		pos = string.find(currvalue,rmvalue,1,true)
		if ( pos ) then
			len = string.len(rmvalue) 
			currvalue = string.sub(currvalue, 1, pos - 1) .. string.sub(currvalue, pos + len)
			setuservar(name, currvalue)			
			return true
		end
	else
		sendmsg(msg .. ". Please add user string variable '" .. name .. "' to prevent duplicate alerts")
	end
	return false
end	

function monitored(device)
	local pos = nil
	local exclpos = nil
	for matchname in string.gmatch(monitordevices, "[^,]+")
	do
		pos = string.find(device,matchname,1,true)
		if ( pos ) then 
			for exname in string.gmatch(excludeddevices, "[^,]+")
			do
				exclpos = string.find(device,exname,1,true)
				if ( exclpos ) then 
					if (debug) then print("Excluded device " ..  device .. "  matching " .. exname) end
					return false
				end
			end
			if (debug) then print("Included device " ..  device .. " matching " .. matchname) end
			return true
		end
	end
	if (debug) then print("No match for device " ..  device .. " matching " .. monitordevices) end
	return false
end


commandArray = {}
for device, value in pairs(otherdevices_svalues) 
do
	if ( monitored(device) ) then
		deltatime =  changedsince(device)
		if ( deltatime > devicetimeout ) then
			if (logging) then print("Timeout for " .. device .. ". Not seen for " .. deltatime .. " seconds" ) end
			if (addtouservar(alertedvariable, device)) then
				sendmsg("Sensor " .. device .. " inactive for " .. deltatime .. " seconds")
			end			
		else
			if (rmfromuservar(alertedvariable, device)) then
				if (logging) then print(device .. " removed from SensorsAlerted") end
				sendmsg("Sensor " .. device .. " active again")
			end
		end
	end
end
if (timing) then print("Script elapsed time: " .. os.clock()-nClock) end
return commandArray
--
-- vim:ts=4:sw=4
--
