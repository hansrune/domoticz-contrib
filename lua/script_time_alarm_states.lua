--
-- $Id$
--
debug = false
logging = true
alarmdev = "Husalarm"

-- for i, v in pairs(otherdevices_svalues) do print("Idx=" ..  i .. " svalue=" .. v .. "<--") end
-- for i, v in pairs(otherdevices) do print("Idx=" ..  i .. " otherdevice=" .. v .. "<--") end

function lprint(cond, s)
        if (cond) then print(s) end
end

commandArray = {}

secstate = globalvariables["Security"]
minute = tonumber(os.date('%M'))
lprint(debug, "DEBUG: Security state is " .. secstate .. " minute of hour is " .. minute )

-- if ( ( tonumber(os.date('%M')) % 15 == 0 ) and ( secstate ~= "Disarmed" ) ) then
if ( ( tonumber(os.date('%M')) % 15 == 0 ) and ( secstate == "Armed Away" ) ) then
    lprint(logging, "Security state is " .. secstate .. ", and minute of hour is " .. minute .. " --> Trigger scene Leggetid" )
    table.insert (commandArray, { ['Scene:Leggetid'] = 'On' } )
end

return commandArray
