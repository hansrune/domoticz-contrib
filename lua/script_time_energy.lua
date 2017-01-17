--
-- $Id: script_time_energy.lua,v 1.1 2014/11/06 20:12:00 pi Exp $
--
logging = true
debug = false
--

metername="isrcounter1"
meteridx=117

--
-- No changes should be needed below here
--
countfile = "/var/run/shm/" .. metername

--
-- for i, v in pairs(devicechanged) do print("Changed Device=" ..  i .. " Value=" .. v .. "<--") end 
-- for i, v in pairs(termodevidx) do print("Idx=" ..  i .. " Value=" .. v .. "<--") end
-- for i, v in pairs(otherdevices_svalues) do print("Idx=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Idx=" ..  i .. " otherdevice=" .. v .. "<--") end
--

commandArray = {}
local file = io.open(countfile, "r")
if (file)
then
	metercount = file:read()
	file:close()
	if (metercount) 
	then
		if (debug) then print(metername .. " update to " .. metercount ) end
		commandArray['UpdateDevice']=meteridx .. "|0|" .. metercount
	else
		if (debug) then print("No metercount from file " .. countfile) end
	end
else
	if (logging) then print("Cannot open meterfile " .. countfile) end
end
return commandArray
