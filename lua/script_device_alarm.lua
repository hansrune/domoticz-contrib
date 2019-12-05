--
-- $Id: script_device_alarm.lua,v 1.1 2017/02/23 18:54:57 pi Exp $
--
logging = true
alarmdev  = "Husalarm"
homeswitch  = "Alarm Hjemme"
awayswitch  = "Alarm Borte"

--
-- Congfigure to your needs - either via user variables, or the fallback values below
--
debug=uservariables["AlarmDebug"]; 
alarmdev=uservariables["AlarmDevice"]; 
homeswitch=uservariables["AlarmHomeSwitch"]; 
awayswitch=uservariables["AlarmAwaySwitch"]; 
-- These are the open doors or similar that should be alerted about when 
-- armed home or armed away
alertedvariable="DoorsAlerted"
sensorsalerted=uservariables[alertedvariable];
--
-- Default / fallback values
--
if not (debug)      then debug=false               end
if not (alarmdev)   then alarmdev="Husalarm"       end
if not (homeswitch) then homeswitch="Alarm Hjemme" end
if not (awayswitch) then awayswitch="Alarm Borte"  end

--
-- No changes should be needed below here
--
oldstate = otherdevices[alarmdev]
secstate = globalvariables["Security"]

-- for i, v in pairs(otherdevices_svalues) do print("Idx=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Idx=" ..  i .. " otherdevice=" .. v .. "<--") end

function lprint(cond, s)
        if (cond) then print(s) end
end

commandArray = {}

-- Minimum sanity check for correct config
if ( oldstate == nil ) then
	lprint(logging, "Giving up: Cannot get security state via device " .. alarmdev)
	return commandArray
end

newstate=""
if (devicechanged[awayswitch] == 'On') then
	newstate="Arm Away"
	if ( otherdevices[homeswitch] == 'On' )
	then
		commandArray[homeswitch] = 'Off'
		lprint(debug, "Away switch now on - Home switch was On, so changed to Off")
	end
elseif (devicechanged[homeswitch] == 'On' and otherdevices[awayswitch] == 'Off') then
	newstate="Arm Home"
elseif (devicechanged[homeswitch] == 'Off' and otherdevices[awayswitch] == 'Off') then
	newstate="Disarm"
elseif (otherdevices[homeswitch] == 'Off' and devicechanged[awayswitch] == 'Off') then
	newstate="Disarm"
end

if ( newstate == "" ) then
	return commandArray
end

if ( newstate == "Arm Away" and secstate ~= "Armed Away")
then
	commandArray[alarmdev] = newstate
	lprint(logging,"change " .. alarmdev .. "=" .. oldstate .. " and  secstate=" .. secstate .. " to " .. newstate ) 
elseif ( newstate == "Arm Home" and secstate ~= "Armed Home" )
then
	commandArray[alarmdev] = newstate
	lprint(logging,"change " .. alarmdev .. "=" .. oldstate .. " and  secstate=" .. secstate .. " to " .. newstate ) 
elseif ( newstate == "Disarm" and secstate ~= "Disarmed" )
then
	commandArray[alarmdev] = newstate
	lprint(logging, "change " .. alarmdev .. "=" .. oldstate .. " and  secstate=" .. secstate .. " to " .. newstate ) 
-- else --  extreme amount of debugging ....
--	lprint(debug,"No change needed for " .. alarmdev .. "=" .. oldstate .. " and secstate=" .. secstate .. " to " .. newstate)
end

--
-- Check for sensor alerts to remind about when not disarmed
--
if ( newstate ~= "Disarm" and secstate == "Disarmed" ) then
	if ( sensorsalerted ) then
		if ( string.len(sensorsalerted) > 0 ) then
			-- commandArray[#commandArray + 1] = { SendNotification = 'subject#body#prio#sound#extraData#subSystem1;subSystem2;subSystem3'
			-- table.insert (commandArray, { ['UpdateDevice'] = cmd } )
			commandArray['SendNotification']="Sensor alarms reminder#" .. sensorsalerted
			os.execute('/usr/local/bin/pushover "Active sensor alerts" "Security state is now ' .. newstate .. ' and these alerts are active: ' .. sensorsalerted .. '" &')
		end
	end
end

return commandArray
--
-- vim:ts=4:sw=4
--
