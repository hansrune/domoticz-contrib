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
sensorsalerted=uservariables["SensorsAlerted"];
devicetimeout=uservariables["SensorTimeOut"]; 
--
-- Fallback values
--
if not ( monitordevices ) then monitordevices = "Temp,CPU" end
if not ( excludeddevices ) then excludeddevices = "egulator" end
if not ( devicetimeout ) then devicetimeout = 600 end

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
	difftime=(os.difftime(t1,t2))
	-- if (debug) then print("Device " .. device .. " not changed in " .. difftime .. " seconds") end
	return math.floor(difftime)
end

commandArray = {}
for device, value in pairs(otherdevices_svalues) 
do
	pos = nil
	exclpos = nil
	for matchname in string.gmatch(monitordevices, "[^,]+")
	do
		pos = string.find(device,matchname,1,true)
		if ( pos ) then 
			for exname in string.gmatch(excludeddevices, "[^,]+")
			do
				exclpos = string.find(device,exname,1,true)
				if ( exclpos ) then 
					if (debug) then print("Excluded device " ..  device .. "  matching " .. exname) end
					break 
				end
			end
			if ( exclpos ) then break end
			if (debug) then print("Included device " ..  device .. " matching " .. matchname .. " value=" .. value) end
			deltatime =  changedsince(device)
			devstored = "[" .. device .. "]"
			if ( deltatime > devicetimeout ) then
				if (logging) then print("Timeout for " .. device .. ". Not seen for " .. deltatime .. " seconds" ) end
				if ( sensorsalerted ) then
					pos = string.find(sensorsalerted,devstored,1,true)
					if not ( pos ) then
						sensorsalerted = sensorsalerted .. devstored
						if (logging) then print("sensorsalterted addition: " .. device .. " added to " .. sensorsalerted) end
						commandArray['Variable:SensorsAlerted']=sensorsalerted
						commandArray['SendNotification']="Sensor " .. device .. " inactive for " .. deltatime .. " seconds"
					end
				end
			else
				if ( sensorsalerted ) then
					pos = string.find(sensorsalerted,devstored,1,true)
					if ( pos ) then
						len = string.len(devstored) 
						sensorsalerted = string.sub(sensorsalerted, 1, pos - 1) .. string.sub(sensorsalerted, pos + len)
						if (logging) then print("sensorsalterted removal: " .. device .. " removed from " .. sensorsalerted) end
						commandArray['Variable:SensorsAlerted']=sensorsalerted
						commandArray['SendNotification']="Sensor " .. device .. " active again"
					end
				end
			end
		else
			if (debug) then print("No match device " ..  device .. " no match for " .. matchname) end
		end
	end
end
if (timing) then print("Script elapsed time: " .. os.clock()-nClock) end
return commandArray
--
-- vim:ts=4:sw=4
--
