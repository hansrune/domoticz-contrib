--
-- $Id: script_time_thermostat.lua,v 1.7 2016/04/23 12:25:59 pi Exp $
--
-- Logging and debugging defaults - change as needed
--
logging = true
debug = false
--
-- Translate and change via user variables or below default values as needed. 
--
-- Temp sensor, heater switch, and thermostat must have a common prefix
-- Any temp sensor, thermostat and switch are associated based on this naming convention:
--	a temperature sensor ("Prefix Temp")
--	a thermostat device ("Prefix Thermostat"), a real or virtual device
--	a heater switch ("Prefix Oven"), i.e. a real On/Off switch
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
	-- if (debug) then print("Device " .. device .. " not changed in " .. difftime .. " seconds") end
	return difftime
end

commandArray = {}
for device, value in pairs(otherdevices_svalues) 
do
	if (debug) then print("Device=" ..  device .. " value=" .. value) end
	idx=string.find(device,thermostatsuffix,1,true) 
	if (idx)
	then
		-- this includes a space after the prefix
		commonprefix=string.sub(device,1,idx-1)
		--
		-- Check that there is a thermostat device
		--
		thermostatvalue=otherdevices_svalues[commonprefix .. thermostatsuffix]
        if (not thermostatvalue) then 
            print("ERROR: " .. commonprefix .. temperaturesuffix .. " has no corresponding " .. commonprefix .. thermostatsuffix .. " device")
            break
        end
		thermostatvalue=tonumber(thermostatvalue)
		--
        -- Set to 0 is interpreted as "disabled", i.e. no on/off actions will be taken
		--
        if ( thermostatvalue == 0 ) then
            if (debug) then print("Thermostat " .. commonprefix .. thermostatsuffix .. " is disabled (set to 0)") end
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
				print("ERROR: " .. commonprefix .. thermostatsuffix .. " has no corresponding " .. commonprefix .. temperaturesuffix .. " device")
				break
			end
			tempsensorvalue=tonumber(tempsensorvalue)
		end

		ovendev=commonprefix .. heaterswitchsuffix
		ovenstate=otherdevices[ovendev]
		coolerdev=commonprefix .. coolerswitchsuffix
		coolerstate=otherdevices[coolerdev]
		if ( ovenstate ) then
			if (debug) then print(commonprefix .. "sensor=" .. tempsensorvalue .. " thermostat=" .. thermostatvalue .. " oven=" .. ovenstate) end
			switchdev   = ovendev
			switchstate = ovenstate
			switchheat  = 'On'
			switchcool  = 'Off'
		elseif ( coolerstate ) then
			if (debug) then print(commonprefix .. "sensor=" .. tempsensorvalue .. " thermostat=" .. thermostatvalue .. " cooler=" .. coolerstate) end
			switchdev   = coolerdev
			switchstate = coolerstate
			switchheat  = 'Off'
			switchcool  = 'On'
		else
			print("ERROR: " .. commonprefix .. thermostatsuffix .. " has no corresponding " .. commonprefix .. heaterswitchsuffix .. " nor " .. commonprefix .. coolerswitchsuffix .. " device")
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
return commandArray
--
-- vim:ts=4:sw=4
--
