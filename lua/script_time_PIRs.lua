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
-- Congfigure to your needs - either via user variables, or the fallback values below
--
debug=uservariables["PIRDebug"]; 
switchdevsuffix=uservariables["PIRSwitchDevSuffix"]; 
switchdevprefix=uservariables["PIRSwitchDevPrefix"]; 
--
-- Default / fallback values
--
if (debug and debug > 0 ) then debug = true else debug=false end
if not (switchdevsuffix) then switchdevsuffix="Lys" end
if not (switchdevprefix) then switchdevprefix="Dimmer" end

-- for i, v in pairs(otherdevices_svalues) do print("name=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Name=" ..  i .. " otherdevice=" .. v .. "<--") end

function dbg(s)
    if (debug) then 
        print("PIRDebugTime: " .. s)
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
 
 
commandArray = {}
 
for irdev,irstate in pairs(otherdevices) do
    iir=string.find(irdev,"IR(",1,true) 
    if (iir) then
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
        if (switchval) then
            vardev = 'PIRoff' .. basedev
            endtime = uservariables[vardev]
            if ( endtime ) then 
                timenow  = os.time()
                timeleft = endtime - timenow
                if ( timenow > endtime ) then
                    if ( switchval == "Off" ) then
                        dbg( "PIRTimeDebug: Device " .. switchdev .. " is already " .. switchval )
                    else 
                        commandArray[switchdev] = 'Off'
                    end
                else
                    dbg( "'" .. switchdev .. "' has " .. timeleft .. " seconds left before switched off. Ssensor '" .. irdev .. "' changed at " .. otherdevices_lastupdate[irdev])
                end
            else
                print("INFO: IR sensor '"..irdev.."' has no corresponding uservariable named '"..vardev.."'. Skipping device")
            end
        else
            print("ERROR: IR sensor '"..irdev.."' has no corresponding light switch/group named '"..switchdev.."'")
        end
    end
end
 
return commandArray
--
-- vim:tabstop=4:shiftwidth=4:softtabstop=4:expandtab
--
