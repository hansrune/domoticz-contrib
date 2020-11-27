--
-- $Id: script_time_repeatonoff.lua,v 1.3 2015/03/16 19:20:31 pi Exp $
--
logging = true
debug = false

-- For timing
timing = false
if (timing) then nClock = os.clock() end

--
-- We don't check if a switch is on or off before sending an on or off command
-- rather than repeat this after some time. This is to be able to use switches
-- that does not remember it's state after a power outage
--
-- Note that only one device repeats per run, i.e. this will not cause message floods
-- You can control the rate by the repeatdelay
--
repeatdelay=600
repeatdelta=60
--
-- Devices must match a substring in the included list
-- ... but if it is on the exclude list, it is still not used
--
included = { "Ovn", "Lys", "Brannalarm", "Varmepumpe", "Ventil", "Avfukter", "Garageport", "Fontene", "AudioVideo", "forsyning" };
excluded = { "Sstue", "M3", "IR", "AlarmKey", "Ringe", "klokke", "Brann", "Temp", "ryter", "Jule", "Unknown" };

--
-- No changes should be needed below here
--
function dbg(s)
    if (debug) then 
        print("PIRDebug: " .. s)
    end
end

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

commandArray = {}
for device, value in pairs(otherdevices) 
do
	if ( value == "On" or value == "Off" or value == "Group On" or value == "Group Off" )
	then
		pos = nil
		for idx,name in ipairs(included) 
		do
			pos = string.find(device,name,1,true)
			if ( pos ) then break end
		end
	        if ( pos == nil ) then 
			dbg("Device " ..  device .. " not included in repeat on/off devices") 
		else
			pos = nil
			for idx,name in ipairs(excluded) 
			do
				pos = string.find(device,name,1,true)
				matchname = name
				if ( pos ) then break end
			end
			if ( pos ) then 
				dbg("Device " ..  device .. " excluded on matching " .. matchname) 
			else
				dbg("Device=" ..  device .. " value=" .. value) 
				since = changedsince(device)
				if ( since > repeatdelay ) then
					table.insert(commandArray,{ [device] = value })
					if (logging) then print(device .. " repeat set to value " .. value .. " (last changed " .. since .. " seconds ago)"  ) end
					repeatdelay = repeatdelay + repeatdelta
				end
			end
		end
	end
end
if (timing) then print("Script elapsed time: " .. os.clock()-nClock) end
return commandArray
--
-- vim:ts=4:sw=4
--
