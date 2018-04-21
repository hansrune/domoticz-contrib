--
-- $Id: script_time_energy.lua,v 1.1 2014/11/06 20:12:00 pi Exp $
--
logging = true
debug = true
--

countfile="isrcounter1"
ratefile="isrcounter2"
meteridx0=117
-- meteridx1=350
-- meteridx2=362
meteridx3=363

--
-- No changes should be needed below here
--
countfile = "/var/log/" .. countfile
ratefile = "/var/log/" .. ratefile

--
-- for i, v in pairs(devicechanged) do print("Changed Device=" ..  i .. " Value=" .. v .. "<--") end 
-- for i, v in pairs(termodevidx) do print("Idx=" ..  i .. " Value=" .. v .. "<--") end
-- for i, v in pairs(otherdevices_svalues) do print("Idx=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Idx=" ..  i .. " otherdevice=" .. v .. "<--") end
--

commandArray = {}
local countfh = io.open(countfile, "r")
if (countfh)
then
	count = countfh:read()
	countfh:close()
else
	if (logging) then print("Cannot open meterfile " .. countfile) end
end

local ratefh = io.open(ratefile, "r")
if (ratefh)
then
	rate = ratefh:read()
	ratefh:close()
else
	if (logging) then print("Cannot open ratefile " .. ratefile) end
end

if (count and rate and tonumber(count) > 0) 
then
    if (debug) then print(countfile .. " update to " .. count .. " " .. ratefile .. " update to " .. rate ) end
    commandArray[0] = {['UpdateDevice']=meteridx0 .. "|0|" .. count }
    commandArray[1] = {['UpdateDevice']=meteridx3 .. "|0|" .. rate .. ";" .. count }
    -- commandArray[1] = {['UpdateDevice']=meteridx1 .. "|0|" .. count .. ";0;0;0;" .. rate .. ";0"}
    -- commandArray[2] = {['UpdateDevice']=meteridx2 .. "|0|" .. rate }
else
    if (debug) then print("No data. Check " .. countfile .. " and " .. ratefile) end
end
return commandArray
