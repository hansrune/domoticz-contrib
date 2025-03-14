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
debug=uservariables["DebugPIR"]; 
if (not debug ) then debug = 0 end
devdebug=uservariables["DebugDevice"]
--
-- Congfigure to your needs - either via user variables, or the fallback values below
--
switchdevsuffix=uservariables["PIRSwitchDevSuffix"]; 
switchdevprefix=uservariables["PIRSwitchDevPrefix"]; 
--
-- Default / fallback values
--
if not (switchdevsuffix) then switchdevsuffix="Lys" end
if not (switchdevprefix) then switchdevprefix="Dimmer" end

-- for i, v in pairs(otherdevices_svalues) do print("name=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Name=" ..  i .. " otherdevice=" .. v .. "<--") end

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
                if ( endtime > 0 ) then
                    if ( timenow > endtime ) then
                        if ( switchval == "Off" ) then
                            dbg(3, "Device " .. switchdev .. " is already " .. switchval .. " for sensor " .. irdev )
                        else 
                            table.insert(commandArray,{ [switchdev] = 'Off' })
                        end
                    else
                        dbg(3, "'" .. switchdev .. "' has " .. timeleft .. " seconds left before switching off. Ssensor '" .. irdev .. "' changed at " .. otherdevices_lastupdate[irdev])
                    end
                else
                    dbg(5, "'" .. switchdev .. "' has no active timer and state is " .. switchval .. " Ssensor '" .. irdev .. "' changed at " .. otherdevices_lastupdate[irdev])
                end
            else
                print("WARNING: IR sensor '"..irdev.."' has no corresponding uservariable named '"..vardev.."'. Skipping device")
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
