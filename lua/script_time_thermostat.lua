--
-- $Id: script_time_thermostat.lua,v 1.7 2016/04/23 12:25:59 pi Exp $
--
-- Logging and debugging defaults - change as needed
--
logging = true
debug=uservariables["DebugThermostat"]; 
if (not debug ) then debug = 0 end
devdebug=uservariables["DebugDevice"]

-- For timing
if (debug > 0) then nClock = os.clock() end

function dbg(lvl,s)
    local msg, p
    if (lvl <= debug) then 
        msg = "DebugThermostat " .. lvl .. "/" .. debug ..": " .. s
        if ( devdebug ) then
            p = string.find(msg, devdebug, 1, true)
            if (p) then print(msg .. " (debugdevice " .. devdebug .. ")") end
        else
            print(msg)
        end
    end
end

--
-- Translate and change via user variables or below default values as needed. 
--
-- Temp sensor, heater switch, and thermostat must have a common prefix
-- Any temp sensor, thermostat and switch are associated based on this naming convention:
--    a temperature sensor ("Prefix Temp")
--    a thermostat device ("Prefix Thermostat"), a real or virtual device
--    a heater switch ("Prefix Oven"), i.e. a real On/Off switch
--
temperaturesuffix=uservariables["ThermostatTempSuffix"]; 
thermostatsuffix=uservariables["ThermostatThermoSuffix"]; 
heaterswitchsuffix=uservariables["ThermostatHeaterSuffix"];
coolerswitchsuffix=uservariables["ThermostatCoolerSuffix"];
hysteresis=uservariables["ThermostatHysteresis"]; 
--
-- We don't check if a switch is already on or off before sending an on or off command
-- Thus we will repeat the state after the repeat interval. This is to be able to use switches
-- that does not remember it's state after a power outage, or switches that has no 
-- two-way + retransmit on error protocol
--
repeatonoffinterval=uservariables["ThermostatRepeatSetInterval"]; 
--
-- Minimum time between switching an oven state - just in case you have unstable sensor readings
--
minchangeinterval=uservariables["ThermostatMinChangeInterval"]; 
--
-- Default / fallback values
--
if not (temperaturesuffix)   then temperaturesuffix="Temp"       end
if not (thermostatsuffix)    then thermostatsuffix="Termostat"   end
if not (heaterswitchsuffix)  then heaterswitchsuffix="Ovn"       end
if not (coolerswitchsuffix)  then coolerswitchsuffix="Kjøler"    end
if not (hysteresis)          then hysteresis=0.5                 end
if not (repeatonoffinterval) then repeatonoffinterval=300        end
if not (minchangeinterval)   then minchangeinterval=120          end
--
-- No changes should be needed below here
--

function changedsince(device)
    t1 = os.time()
    ts = otherdevices_lastupdate[device]
    year = string.sub(ts, 1, 4)
    month = string.sub(ts, 6, 7)
    day = string.sub(ts, 9, 10)
    hour = string.sub(ts, 12, 13)
    minutes = string.sub(ts, 15, 16)
    seconds = string.sub(ts, 18, 19)
    t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
    difftime=(os.difftime(t1,t2))
    return math.floor(difftime)
end

commandArray = {}
for device, value in pairs(otherdevices_svalues) 
do
    -- if (debug) then print("Device=" ..  device .. " value=" .. value) end
    -- idx=string.find(device,thermostatsuffix .. '$',1,true) 
    idx=string.find(device,thermostatsuffix,1,true) 
    if (idx)
    then
        dbg(1,"Checking thermostat device=" ..  device .. " value=" .. value) 
        -- this includes a space after the prefix
        commonprefix=string.sub(device,1,idx-1)
        --
        -- Check that there is a thermostat device
        --
        thermostatvalue=otherdevices_svalues[commonprefix .. thermostatsuffix]
        if (not thermostatvalue) then 
            print("WARNING: " .. device .. " has no corresponding " .. commonprefix .. thermostatsuffix .. " device. Likely just an unintended device name for " .. device)
            break
        end
        thermostatvalue=tonumber(thermostatvalue)
        --
        -- Set to 0 is interpreted as "disabled", i.e. no on/off actions will be taken
        --
        if ( thermostatvalue == 0 ) then
            dbg(3,"Thermostat " .. device .. "-->" .. commonprefix .. thermostatsuffix .. " is disabled (set to 0)") 
            break
        end

        --
        -- Look for temp sensor + value
        --
        tempsensorvalue=otherdevices_temperature[commonprefix .. temperaturesuffix]
        if (not tempsensorvalue) then 
            --
            -- The svalue is used for the temperatures in case a setpoint device is used for testing
            --
            tempsensorvalue=otherdevices_svalues[commonprefix .. temperaturesuffix]
            if (not tempsensorvalue) then 
                print("ERROR: " .. device .. "-->" .. commonprefix .. thermostatsuffix .. " has no corresponding " .. commonprefix .. temperaturesuffix .. " device")
                break
            end
            tempsensorvalue=tonumber(tempsensorvalue)
        end

        ovendev=commonprefix .. heaterswitchsuffix
        ovenstate=otherdevices[ovendev]
        coolerdev=commonprefix .. coolerswitchsuffix
        coolerstate=otherdevices[coolerdev]
        if ( ovenstate ) then
            dbg(3,device .. "-->" .. commonprefix .. "sensor=" .. tempsensorvalue .. " thermostat=" .. thermostatvalue .. " oven=" .. ovenstate) 
            switchdev   = ovendev
            switchstate = ovenstate
            switchheat  = 'On'
            switchcool  = 'Off'
        elseif ( coolerstate ) then
            dbg(3,device .. "-->" .. commonprefix .. "sensor=" .. tempsensorvalue .. " thermostat=" .. thermostatvalue .. " cooler=" .. coolerstate)
            switchdev   = coolerdev
            switchstate = coolerstate
            switchheat  = 'Off'
            switchcool  = 'On'
        else
            print("ERROR: " .. device .. "-->" .. commonprefix .. thermostatsuffix .. " has no corresponding " .. commonprefix .. heaterswitchsuffix .. " nor " .. commonprefix .. coolerswitchsuffix .. " device")
            break
        end

        switchto=nil
        if (tempsensorvalue > thermostatvalue + hysteresis) then
            switchto = switchcool
        elseif (tempsensorvalue < thermostatvalue - hysteresis) then
            switchto = switchheat
        end
        if (switchto) then
            notchangedsince = changedsince(switchdev)
            if ((switchto ~= switchstate) and (notchangedsince > minchangeinterval)) then
                commandArray[switchdev] = switchto
                if (logging) then
                    print(string.format("%s changed from %s to %s at temperature %.1f (set to %.1f, last update %d seconds ago)", switchdev, switchstate, switchto, tempsensorvalue, thermostatvalue, notchangedsince ))
                end
            elseif ((switchto == switchstate) and(notchangedsince > repeatonoffinterval)) then
                commandArray[switchdev] = switchto
                if (logging) then
                    print(string.format("%s refreshed to %s at temperature %.1f (set to %.1f, last update %d seconds ago)", switchdev, switchstate, tempsensorvalue, thermostatvalue, notchangedsince ))
                end
            end
        end
    end
end
if (debug > 0) then print("Script elapsed time: " .. os.clock()-nClock) end
return commandArray
--
-- vim:ts=4:sw=4
--
