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
--
-- Congfigure to your needs - either via user variables, or the fallback values below
--
debug=uservariables["PIRDebug"]; 
switchdevsuffix=uservariables["PIRSwitchDevSuffix"]; 
switchdevprefix=uservariables["PIRSwitchDevPrefix"]; 
luxdevsuffix=uservariables["PIRLuxDev"]; 
nightdevice=uservariables["PIRNightSwitch"]; 
luxlimiton=uservariables["PIRLuxLimitOn"]; 
luxlimitoff=uservariables["PIRLuxLimitOff"]; 
retrans=uservariables["PIRRetrans"]; 
--
-- Default / fallback values
--
if (debug and debug > 0) then debug = true else debug=false end
if not (switchdevsuffix) then switchdevsuffix="Lys"         end
if not (switchdevprefix) then switchdevprefix="Dimmer"      end
if not (luxdevsuffix)    then luxdevsuffix="Lux"            end
if not (nightdevice)     then nightdevice="Natt"            end
if not (luxlimiton)      then luxlimiton=10                 end
if not (luxlimitoff)     then luxlimitoff=20                end
if not (retrans)         then retrans=600                   end

-- for i, v in pairs(otherdevices_svalues) do print("name=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("name='" ..  i .. "' otherdevice=" .. v .. "<--") end
-- for i, v in pairs(devicechanged) do print("Device changed="..i.." value="..v) end


function dbg(s)
    if (debug) then 
        print("PIRDebug: " .. s)
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
 
function timetest(opertime,stem,state)
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
            if ( state == "Off" ) then
                dbg("Light sensor " .. luxdev .. " is now " .. luxval .. " Threshold from state '" .. state .. "' to 'On' is < " .. luxlimiton) 
                if ( tonumber(luxval) < luxlimiton ) then return true end
            else
                dbg("Light sensor " .. luxdev .. " is now " .. luxval .. " Threshold from state '" .. state .. "' to 'Off' is < " .. luxlimitoff)
                if ( tonumber(luxval) < luxlimitoff ) then return true end
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
		switchdev=basedev
	else
		group=""
		imode=iir+3
		onmode = irdev:sub(imode,imode)
		switchdev=basedev .. " " .. switchdevsuffix
		switchval=otherdevices[switchdev]
		if (not switchval) then
			switchdev=switchdevprefix .. " " .. basedev 
			switchval=otherdevices[switchdev]
			if (not switchval) then
				print("ERROR: IR sensor "..irdev.." has no corresponding light switch named '"..basedev.." "..switchdevsuffix.."' nor '"..switchdevprefix.." "..basedev.."' device value=", switchval)
				return commandArray
			end
		end
	end
    vardev = 'PIRoff'..basedev
    if ( not uservariables[vardev]) then
        print("INFO: IR sensor "..irdev.." has no corresponding uservariable named '"..vardev.."'. Creating variable ...")
        --
        -- comment / correct if automatic variable creation is not desired or your server URL is not http://127.0.0.1:8080
        -- Note that no URL encode is done - devices with blanks in basename will not work
        --
        openurl='http://127.0.0.1:8080/json.htm?type=command&param=adduservariable&vname='..vardev..'&vtype=0&vvalue=-1'
        dbg("Create variable: " .. openurl)
        table.insert(commandArray,{ ['OpenURL'] = openurl })
        -- return now, the user variable creation need to take effect before the below code works
        return commandArray
    end
    inumend=string.find(irdev,')',1,true) 
    if not (inumend) then
        print("ERROR: IR sensor "..irdev.." has no closing ')' ")
        return commandArray
    end
    onduration= tonumber(irdev:sub(imode+1, inumend-1))
    timenow   = os.time()
    timeoff   = timenow + onduration * 60
    switchdev = group..switchdev
    switchval = otherdevices[switchdev]
    dt        = timedifference(otherdevices_lastupdate[switchdev])
    tt        = timetest(onmode,basedev,switchval)
    dbg("TimeTest="..tostring(tt).." IRdev="..irdev.." state="..irstate.." dt=" .. dt .. " group= "..group.." basedev="..basedev.." switchdev="..switchdev.." onmode="..onmode.." onduration=" .. onduration .. " switchdev="..switchdev.." switchval="..switchval)
    if (tt) then
        table.insert(commandArray,{ ['Variable:' .. vardev] = tostring(timeoff) })
        if ( switchval == "Off" ) then
            table.insert(commandArray,{ [switchdev] = 'On' })
            dbg("IR device "..irdev.." state "..irstate.." triggered "..switchdev.." from "..switchval.." to On")
        elseif ( dt > retrans ) then
            table.insert(commandArray,{ [switchdev] = 'On' })
            dbg("IR device "..irdev.." state "..irstate.." retransmit after " .. retrans .. " seconds trigger "..switchdev.." from "..switchval.." to On")
        else
            dbg("IR device "..irdev.." state "..irstate.." no-op ("..dt.."<="..retrans..") for "..switchdev.." from "..switchval.." to On (mode="..onmode..")")
        end
    end
end

return commandArray
--
-- vi:ts=4:sw=4:sts=4:et:
--
