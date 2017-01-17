--
-- $Id: script_time_husalarm.lua,v 1.2 2016/03/13 19:29:50 pi Exp $ 
-- Ping test IP and use gateway as fallback / link test 
--
debug = false
logging = true
device  = "Husalarm"
awayip  = "192.168.1.3"
homeawayip  = "192.168.1.4"
pingtest = '/usr/local/bin/pingtests'
oldstate = otherdevices[device]
secstate = globalvariables["Security"]

-- for i, v in pairs(otherdevices_svalues) do print("Idx=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Idx=" ..  i .. " otherdevice=" .. v .. "<--") end

function lprint(cond, s)
        if (cond) then print(s) end
end

commandArray = {}
if ( oldstate == nil ) then
	lprint(logging, "Giving up: Cannot get security state via device " .. device)
	return commandArray
end
if os.execute(pingtest .. ' ' .. homeawayip) then
	newstate="Disarm"
	lprint(debug, "pingtest success. State for " .. device .. " is " .. oldstate .. "-->" .. newstate) 
elseif os.execute(pingtest .. ' ' .. awayip) then
	newstate="Arm Home"
	lprint(debug, "pingtest success. State for " .. device .. " is " .. oldstate .. "-->" .. newstate) 
else
	newstate="Arm Away"
	lprint(debug, "pingtest failure. State for " .. device .. " is " .. oldstate .. "-->" .. newstate)
end

if ( newstate == "Arm Away" and secstate ~= "Armed Away")
then
	commandArray[device] = newstate
	lprint(logging,"change " .. device .. "=" .. oldstate .. " and  secstate=" .. secstate .. " to " .. newstate ) 
elseif ( newstate == "Arm Home" and secstate ~= "Armed Home" )
then
	commandArray[device] = newstate
	lprint(logging,"change " .. device .. "=" .. oldstate .. " and  secstate=" .. secstate .. " to " .. newstate ) 
elseif ( newstate == "Disarm" and secstate ~= "Disarmed" )
then
	commandArray[device] = newstate
	lprint(logging, "change " .. device .. "=" .. oldstate .. " and  secstate=" .. secstate .. " to " .. newstate ) 
else
	lprint(debug,"No change needed for " .. device .. "=" .. oldstate .. " and secstate=" .. secstate .. " to " .. newstate)
end

return commandArray
