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
-- $Id: script_device_PIRs.lua,v 1.2 2015/12/13 18:54:02 pi Exp $
--
logging = true
debug=uservariables["DebugPIR"]; 
if (not debug ) then debug = 0 end
devdebug=uservariables["DebugDevice"]
--
-- Congfigure to your needs - either via user variables, or the fallback values below
--
switchdevsuffix=uservariables["PIRSwitchDevSuffix"]; 
switchdevprefix=uservariables["PIRSwitchDevPrefix"]; 
luxdevsuffix=uservariables["PIRLuxDev"]; 
nightdevice=uservariables["PIRNightSwitch"]; 
luxlimiton=uservariables["PIRLuxLimitOn"]; 
luxlimitoff=uservariables["PIRLuxLimitOff"]; 
onretrans=uservariables["PIRRetrans"]; 
--
-- Default / fallback values
--
if not (switchdevsuffix) then switchdevsuffix="Lys"         end
if not (switchdevprefix) then switchdevprefix="Dimmer"      end
if not (luxdevsuffix)    then luxdevsuffix="Lux"            end
if not (nightdevice)     then nightdevice="Natt"            end
if not (luxlimiton)      then luxlimiton=10                 end
if not (luxlimitoff)     then luxlimitoff=20                end
if not (onretrans)       then onretrans=20                    end

-- for i, v in pairs(otherdevices_svalues) do print("name=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("name='" ..  i .. "' otherdevice=" .. v .. "<--") end
-- for i, v in pairs(devicechanged) do print("Device changed="..i.." value="..v) end
-- for i, v un pairs(otherdevices_scenesgroups) do print("Group name=" ..  i .. " svalue=" .. v .. "<--") end

function dbg(lvl,s)
    local msg, p
    if (lvl <= debug) then 
        msg = "DebugPIR " .. lvl .. "/" .. debug ..": " .. s
        if ( devdebug ) then
            p = string.find(msg, devdebug, 1, true)
            if (p) then print(msg .. " (debugdevice " .. devdebug .. ")") end
        else
            print(msg)
        end
    end
end

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
	return math.floor(difference)
end
 
function timetest(opertime,stem)
    if ( opertime == "a" or opertime == "A" ) then
        return true
    end
    if ( opertime == "l" or opertime == "L" ) then
		luxdev=stem .. " " .. luxdevsuffix
		luxval=otherdevices[luxdev]
		if (not luxval) then
            -- Try a base lux device as a fallback
            luxdev=luxdevsuffix
            luxval=otherdevices[luxdev]
        end
		if (not luxval) then
			print("ERROR: Thers is no light sensor named" .. luxdev .. " or " .. luxdevsuffix)
        else
            dbg(3, "Light sensor '" .. luxdev .. "' is now '" .. luxval .. "' Threshold is < " .. luxlimiton) 
            if ( tonumber(luxval) < luxlimiton ) then
                return true
            end
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
 
irdev=next(devicechanged)
iir=string.find(irdev,"IR(",1,true) 
irstate=devicechanged[irdev]
if (iir and ( irstate == "On" ))  then
	basedev=string.sub(irdev,1,iir-2)
	if irdev:sub(iir+3,iir+3) == "g" then
		group="Group:"
		imode=iir+4
		onmode = irdev:sub(imode,imode)
		switchdev=basedev .. " " .. switchdevsuffix
		switchval=otherdevices_scenesgroups[switchdev]
		switchdev=group..basedev .. " " .. switchdevsuffix
	else
		group=""
		imode=iir+3
		onmode = irdev:sub(imode,imode)
		switchdev=basedev .. " " .. switchdevsuffix
		switchval=otherdevices[switchdev]
	end
    if (not switchval) then
        print("ERROR: IR sensor '"..irdev.."' has no corresponding light switch/group named '"..switchdev.."'")
        return commandArray
    end
    vardev = 'PIRoff'..basedev
    if ( not uservariables[vardev]) then
        print("INFO: IR sensor '"..irdev.."' has no corresponding uservariable named '"..vardev.."'. Creating variable ...")
        --
        -- comment / correct if automatic variable creation is not desired or your server URL is not http://127.0.0.1:8080
        -- Note that no URL encode is done - devices with blanks in basename will not work
        --
        openurl='http://127.0.0.1:8080/json.htm?type=command&param=adduservariable&vname='..vardev..'&vtype=0&vvalue=-1'
        dbg(3, "Create variable: " .. openurl)
        table.insert(commandArray,{ ['OpenURL'] = openurl })
        -- return now, the user variable creation need to take effect before the below code works
        return commandArray
    end

    inumend=string.find(irdev,')',iir+4,true) 
    if not (inumend) then
        print("ERROR: IR sensor '"..irdev.."' has no closing ')' after string position "..iir+4)
        return commandArray
    end
    onduration= tonumber(irdev:sub(imode+1, inumend-1))
    timenow   = os.time()
    timeoff   = timenow + onduration * 60

    if ( group == "" ) then
        dt = timedifference(otherdevices_lastupdate[switchdev])
    else
        -- no retransmit for groups / scenes
        dt = 0
    end
    tt = timetest(onmode,basedev,switchval)
    dbg(5,"TimeTest="..tostring(tt).." irdev='"..irdev.."' switchdev="..switchdev.." switchval="..switchval.." onmode="..onmode.." onduration="..onduration.." dt="..dt)
    if (tt) then
        -- if set, then done by PIR controls - else leave a manual switch alone
        endtime = uservariables[vardev]
        if ( not endtime ) then endtime = 0 end

        if ( switchval == "Off" or switchval == "Mixed" ) then
            table.insert(commandArray,{ ['Variable:' .. vardev] = tostring(timeoff) })
            table.insert(commandArray,{ [switchdev] = 'On' })
            dbg(1,"IR device "..irdev.." state "..irstate.." triggered "..group..switchdev.." from "..switchval.." to On")
        elseif ( endtime > 0 and onretrans > 0 and dt > onretrans ) then
            table.insert(commandArray,{ ['Variable:' .. vardev] = tostring(timeoff) })
            table.insert(commandArray,{ [switchdev] = 'On' })
            dbg(1,"IR device "..irdev.." state "..irstate.." - Repeat trigger ("..dt..">"..onretrans..") for "..switchdev.." from "..switchval.." to On (mode="..onmode..")")
        elseif ( endtime > 0 ) then
            table.insert(commandArray,{ ['Variable:' .. vardev] = tostring(timeoff) })
            dbg(1,"IR device "..irdev.." state "..irstate.." - No repeat trigger so close to last trigger ("..dt.."<="..onretrans..") for "..switchdev.." from "..switchval.." to On (mode="..onmode..")")
        else 
            dbg(1,"IR device "..irdev.." state "..irstate.." - assumed manual control for "..switchdev.." state " .. switchval)
        end
    end
end

return commandArray
--
-- vi:ts=4:sw=4:sts=4:et:
--
