--
-- ~/domoticz/scripts/lua/script_device_pirs.lua
--
-- $Id: script_device_PIRs.lua,v 1.2 2015/12/13 18:54:02 pi Exp $
--
-- Each of the motion sensors in Domoticz follow this name convention:
-- SwitchName IR(gmNN)
-- PIRxrzSwitchName or PIRxgzGroupName
--   g specifies what the PIR is controlling -
--     r = room (single Domoticz) switch and g = group
--   m specifies when the PIR controls 
--     a=all day
--     n=nighttime
--     d=daytime
--     1=custom timer 1 set to 22:00 to 07:30
--   NN specifies how long the ligth will stay on for in minutes, 
--   NN = 5 turns the switch or the group on for 5 minutes
--
-- N.B. be carefully as currently there is little error checking so wrongly
--      named PIRs in Domoticz may cause an error
-- N.B. one wrongly named PIR may stop the script, check log for any issues
--
-- $Id: script_device_PIRs.lua,v 1.2 2015/12/13 18:54:02 pi Exp $
--
logging = true
--
-- Congfigure to your needs - either via user variables, or the fallback values below
--
debug=uservariables["PIRDebug"]; 
switchdevsuffix=uservariables["PIRSwitchDev"]; 
luxdevsuffix=uservariables["PIRLuxDev"]; 
nightdevice=uservariables["PIRNightSwitch"]; 
luxlimit=uservariables["PIRLuxLimit"]; 
--
-- Default / fallback values
--
if not (debug)           then debug=false           end
if not (switchdevsuffix) then switchdevsuffix="Lys" end
if not (luxdevsuffix)    then luxdevsuffix="Lux"    end
if not (nightdevice)     then nightdevice="Natt"    end
if not (luxlimit)        then luxlimit=10           end

-- for i, v in pairs(otherdevices_svalues) do print("name=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("name='" ..  i .. "' otherdevice=" .. v .. "<--") end
-- for i, v in pairs(devicechanged) do print("Device changed="..i.." value="..v) end


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
 
function timetest(opertime,stem)
    if ( opertime == "a" or opertime == "A" ) then
        return true
    end
    if ( opertime == "l" or opertime == "L" ) then
		luxdev=stem .. luxdevsuffix
		l=otherdevices[luxdev]
		if (not l) then
            -- Try a base lux device as a fallback
            luxdev=luxdevsuffix
            l=otherdevices[luxdev]
        end
		if (not l) then
			print("ERROR: Thers is no light sensor named" .. luxdev .. " or " .. luxdevsuffix)
        else
            if (debug) then print("PIRDebug: Light sensor " .. luxdev .. " is now at " .. l .. " (threshold to trigger from stem " .. stem .. " device is " .. luxlimit .. ")") end
            if ( tonumber(l) < luxlimit ) then return true end
		end
        return false
    end
    if opertime == "N" then
		if ( otherdevices[nightdevice] == "On" ) then
            return true
        else
            return false
        end
    end
    if opertime == "D" then
		if ( otherdevices[nightdevice] == "Off" ) then
            return true
        else
            return false
        end
    end
    if opertime == "n" then
        if timeofday['Nighttime'] then
            return true
        else
            return false
        end
    end
    if opertime == "d" then
        if timeofday['Daytime'] then
            return true
        else
            return false
        end
    end
    if opertime == "s" then
        if (otherdevices['Dummy-'..stem] == 'On') then
            return true
        else
            return false
        end
    end
    return false
end
 
commandArray = {}
 
device=next(devicechanged)
iir=string.find(device,"IR(",1,true) 
s=devicechanged[device]
if (iir and ( s == "On" or s == "Group On" )) then
	basedev=string.sub(device,1,iir-1)
	if device:sub(iir+3,iir+3) == "g" then
		group="Group:"
		imode=iir+4
		onoffdev=basedev
	else
		group=""
		imode=iir+3
		onoffdev=basedev .. switchdevsuffix
		v=otherdevices[onoffdev]
		if (not v) then
			print("ERROR: "..device.." has no corresponding '"..onoffdev.."' device val=", v)
			return commandArray
		end
	end
    d = group..onoffdev
    v = otherdevices[d]
    -- Avoid sending repetetive On commands
    -- ...or some dimmers change level
    if ( v == "Off" or v == "Group Off" ) then
        onmode = device:sub(imode,imode)
        if (timetest(onmode,basedev)) then
            commandArray[onoffdev] = 'On'
            msg = "IR device "..device.." now in state "..s.." triggered "..onoffdev.." (mode="..onmode.." group="..group..")"
            if (logging) then print(msg) end
        end
    else
        if (debug) then print("PIRDebug: Device " .. d .. " is already " .. v) end
    end
end

return commandArray
--
-- vi:ts=4:sw=4:sts=4:et:
--
