--
-- $Id$
--
logging = true
debug = false

-- For timing
timing = false
if (timing) then nClock = os.clock() end

--
-- User variables from Domoticz setup
--	DoorTimeOut (integer) is useful to change for debugging, or undefined for defaults
--	DoorsAlerted (string) - blank / undefined for no alerts, set to "None" as initial value for alterts
--	DoorMonitorDevices (string) - comma separated list of substrings to match for device names
--	DoorMonitorExcluded (string) - comma separated list of substrings out of the matched devices to exclude
--
alertedvariable="DoorsAlerted"
monitordevices=uservariables["DoorMonitorDevices"]; 
excludeddevices=uservariables["DoorMonitorExcluded"]; 
sensorsalerted=uservariables[alertedvariable];
devicetimeout=uservariables["DoorTimeOut"]; 
--
-- Fallback values
--
if not ( monitordevices ) then monitordevices = "Door" end
if not ( excludeddevices ) then excludeddevices = "Garage" end
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
	difftime=math.floor(os.difftime(t1,t2))
	-- if (debug) then print("Device " .. device .. " not changed in " .. difftime .. " seconds") end
	return difftime
end

function monitored(device)
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
					return false
				end
			end
			if (debug) then print("Included device " ..  device .. " matching " .. matchname) end
			return true
		end
	end
	if (debug) then print("No match for device " ..  device .. " matching " .. matchname) end
	return false
end

commandArray = {}
-- for device, value in pairs(otherdevices_svalues) 
for device, value in pairs(otherdevices) 
do
	if ( value == 'Open' ) then
		if (debug) then print("Device " .. device .. " is Open") end
		deltatime = changedsince(device)
		devstored = "[" .. device .. "]"
		if ( deltatime > devicetimeout ) then
			if ( monitored(device) ) then
				if (logging) then print("Timeout for " .. device .. "=" .. value .. " after " .. deltatime .. " seconds" ) end
				msg="Door " .. device .. " being " .. value .. " for " .. deltatime .. " or more seconds"
				if ( sensorsalerted ) then
					pos = string.find(sensorsalerted,devstored,1,true)
					if not ( pos ) then
						sensorsalerted = sensorsalerted .. devstored
						if (logging) then print("sensorsalterted addition: " .. device .. " added to " .. sensorsalerted) end
						commandArray['Variable:' .. alertedvariable]=sensorsalerted
						commandArray['SendNotification']=msg
					end
				else
					commandArray['SendNotification']=msg .. ". Please add user variable " .. alertedvariable .. " set to value " .. "None to prevent duplicate alerts"
				end
			end
		end
	elseif ( value == 'Closed' ) then
		if (debug) then print("Device " .. device .. " is Closed") end
		if ( sensorsalerted ) then
			devstored = "[" .. device .. "]"
			pos = string.find(sensorsalerted,devstored,1,true)
			if ( pos ) then
				len = string.len(devstored) 
				sensorsalerted = string.sub(sensorsalerted, 1, pos - 1) .. string.sub(sensorsalerted, pos + len)
				if (logging) then print("DoorsAlerted removal: " .. device .. " removed from " .. sensorsalerted) end
				commandArray['Variable:' .. alertedvariable]=sensorsalerted
				commandArray['SendNotification']="Door " .. device .. " is now " .. value
			end
		end
	end
end
if (timing) then print("Script elapsed time: " .. os.clock()-nClock) end
return commandArray
--
-- vim:ts=4:sw=4
--
