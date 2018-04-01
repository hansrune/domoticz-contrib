--
-- ~/domoticz/scripts/lua/script_time_pirs.lua
--
-- $Id: script_time_PIRs.lua,v 1.3 2015/12/13 18:54:02 pi Exp $
--
-- Each of the motion sensors in Domoticz follow this name convention:
-- SwitchName IR(gmNN)
-- PIRxrzSwitchName or PIRxgzGroupName
--   g specifies what the PIR is controlling -
--     r = room (single Domoticz) switch and g = group
--   m specifies when the PIR controls 
--     a=all day
--     n=nighttime
--     N=night device is on
--     d=daytime
--     D=night device is off
--     l=lux limit
--   NN specifies how long the ligth will stay on for in minutes, 
--   NN = 5 turns the switch or the group on for 5 minutes
--
-- N.B. be carefully as currently there is little error checking so wrongly
--      named PIRs in Domoticz may cause an error
-- N.B. one wrongly named PIR may stop the script, check log for any issues
--
-- $Id: script_time_PIRs.lua,v 1.3 2015/12/13 18:54:02 pi Exp $
--
logging = true
--
switchdevsufffix = "Lys"
--
-- Congfigure to your needs - either via user variables, or the fallback values below
--
debug=uservariables["PIRDebug"]; 
switchdevsufffix=uservariables["PIRSwitchDev"]; 
--
-- Default / fallback values
--
if (debug and debug > 0 ) then debug = true else debug=false end
if not (switchdevsufffix) then switchdevsufffix="Lys" end

-- for i, v in pairs(otherdevices_svalues) do print("name=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Name=" ..  i .. " otherdevice=" .. v .. "<--") end


function timedifference(s)
	year = string.sub(s, 1, 4)
	month = string.sub(s, 6, 7)
	day = string.sub(s, 9, 10)
	hour = string.sub(s, 12, 13)
	minutes = string.sub(s, 15, 16)
	seconds = string.sub(s, 18, 19)
	t1 = os.time()
	t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
	difference = os.difftime (t1, t2)
	return difference
end
 
 
commandArray = {}
 
for device,value in pairs(otherdevices) do
    iir=string.find(device,"IR(",1,true) 
    if (iir) then
		basedev=string.sub(device,1,iir-1)
		if device:sub(iir+3,iir+3) == "g" then
			group="Group:"
			imode=iir+4
			onoffdev=basedev
		else
			group=""
			imode=iir+3
			onoffdev=basedev .. switchdevsufffix
			val=otherdevices[onoffdev]
			if (not val) then
				print("ERROR: "..device.." has no corresponding "..onoffdev.." device")
				return commandArray
			end
		end
        onmode = device:sub(imode,imode)
        timeon = device:sub(imode+1, -2)
        timesecon = (tonumber(timeon) * 60) - 1
        onoffstate = otherdevices[group .. onoffdev]
        if ( onoffstate == "Off" or onoffstate == "Group Off" ) then
            if (debug) then print( "PIRTimeDebug: Device " .. group .. onoffdev .. " is already " .. onoffstate ) end
        else
            devdiff = timedifference(otherdevices_lastupdate[device])
            devstate = otherdevices[device]
            timesecoff = timesecon + 199
            if (debug) then 
                msg = "PIRTimeDebug: Device "..device.." last changed to "..devstate.." at "..devdiff.." seconds ago." 
                msg = msg .. " Device off between "..timesecon.." and "..timesecoff
                msg = msg .. " (group="..group.." onmode="..onmode..")"
                print(msg)
            end
            if (devdiff > timesecon and devdiff < timesecoff) then
                d = group..onoffdev
                msg = d.." off after " .. (timesecon+1) .. " seconds. IR device not changed in " .. devdiff .. " seconds"
                if (logging) then print(msg) end
                commandArray[d] = 'Off'
            end
        end
    end
end
 
return commandArray
--
-- vi:ts=4:sw=4:sts=4:et:
--
