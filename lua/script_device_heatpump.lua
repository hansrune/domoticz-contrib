--
-- $Id$
--
-- Logging and debugging defaults - change as needed
--
logging = true
logswitch = true
debug = false
--
-- // Power state
-- #define POWER_OFF   0
-- #define POWER_ON    1

-- // Operating modes
-- #define MODE_AUTO   1
-- #define MODE_HEAT   2
-- #define MODE_COOL   3
-- #define MODE_DRY    4
-- #define MODE_FAN    5
-- #define MODE_MAINT  6

-- // Fan speeds. Note that some heatpumps have less than 5 fan speeds
-- #define FAN_AUTO    0
-- #define FAN_1       1
-- #define FAN_2       2
-- #define FAN_3       3
-- #define FAN_4       4
-- #define FAN_5       5

-- // Vertical air directions. Note that these cannot be set on all heat pumps
-- #define VDIR_AUTO   0
-- #define VDIR_MANUAL 0
-- #define VDIR_SWING  1
-- #define VDIR_UP     2
-- #define VDIR_MUP    3
-- #define VDIR_MIDDLE 4
-- #define VDIR_MDOWN  5
-- #define VDIR_DOWN   6

-- // Horizontal air directions. Note that these cannot be set on all heat pumps
-- #define HDIR_AUTO   0
-- #define HDIR_MANUAL 0
-- #define HDIR_SWING  1
-- #define HDIR_MIDDLE 2
-- #define HDIR_LEFT   3
-- #define HDIR_MLEFT  4
-- #define HDIR_MRIGHT 5
-- #define HDIR_RIGHT  6
--
-- Translate and change via user variables or below default values as needed. 
--
-- debug=uservoariables["HeatpumpDebug"]; 
--
-- http://192.168.0.19/control?cmd=heatpumpir,mitsubishi_fd,1,1,0,23,0,0
espdevices=uservariables["IRHeatPumpDevices"]; 
if not (espdevices) then espdevices="192.168.101.119 192.168.101.117" end

heatpumpmodel="mitsubishi_kj"

heatpumpmodeswitchdev="Varmepumpe Modus"
heatpumpthermostatdev="Varmepumpe Temp"
heatpumpvdirdev="Varmepumpe Retning"
heatpumpfandev="Varmepumpe Vifte"
heatpumpflowdev="Varmepumpe Spjeld"
--
heatpumpsetpower=1
heatpumpsetmode=1
heatpumpsettemp=23
heatpumpsetfanspeed=0
heatpumpsetvdir=0
heatpumpsethdir=1
--

commandArray = {}
for devname, devvalue in pairs(devicechanged) 
do
    if (debug) then print(devname .. " changed - value " .. devvalue) end
    if (devname == heatpumpmodeswitchdev) then
		if (logswitch) then print(devname .. " changed - value " .. devvalue) end
        heatpumpmodevalue=devvalue
        heatpumpfanvalue=otherdevices[heatpumpfandev]
        heatpumpvdirvalue=otherdevices[heatpumpvdirdev]
        heatpumpflowvalue=otherdevices[heatpumpflowdev]
        heatpumpsettemp=otherdevices[heatpumpthermostatdev]
    elseif (devname == heatpumpvdirdev) then
		if (logswitch) then print(devname .. " changed - value " .. devvalue) end
        heatpumpmodevalue=otherdevices[heatpumpmodeswitchdev]
        heatpumpfanvalue=otherdevices[heatpumpfandev]
        heatpumpvdirvalue=devvalue
        heatpumpflowvalue=otherdevices[heatpumpflowdev]
        heatpumpsettemp=otherdevices[heatpumpthermostatdev]
    elseif (devname == heatpumpfandev) then
		if (logswitch) then print(devname .. " changed - value " .. devvalue) end
        heatpumpmodevalue=otherdevices[heatpumpmodeswitchdev]
        heatpumpfanvalue=devvalue
        heatpumpvdirvalue=otherdevices[heatpumpvdirdev]
        heatpumpflowvalue=otherdevices[heatpumpflowdev]
        heatpumpsettemp=otherdevices[heatpumpthermostatdev]
    elseif (devname == heatpumpthermostatdev) then
		if (logswitch) then print(devname .. " changed - value " .. devvalue) end
        heatpumpmodevalue=otherdevices[heatpumpmodeswitchdev]
        heatpumpfanvalue=otherdevices[heatpumpfandev]
        heatpumpvdirvalue=otherdevices[heatpumpvdirdev]
        heatpumpflowvalue=otherdevices[heatpumpflowdev]
        heatpumpsettemp=devvalue
    elseif (devname == heatpumpthermostatdev .. "_Utility") then
		if (logswitch) then print(devname .. " changed - value " .. devvalue) end
        heatpumpmodevalue=otherdevices[heatpumpmodeswitchdev]
        heatpumpfanvalue=otherdevices[heatpumpfandev]
        heatpumpvdirvalue=otherdevices[heatpumpvdirdev]
        heatpumpflowvalue=otherdevices[heatpumpflowdev]
        heatpumpsettemp=devvalue
    elseif (devname == heatpumpflowdev) then
		if (logswitch) then print(devname .. " changed - value " .. devvalue) end
        heatpumpmodevalue=otherdevices[heatpumpmodeswitchdev]
        heatpumpfanvalue=otherdevices[heatpumpfandev]
        heatpumpvdirvalue=otherdevices[heatpumpvdirdev]
        heatpumpflowvalue=devvalue
        heatpumpsettemp=otherdevices[heatpumpthermostatdev]
    else
        break
    end


    heatpumpsettemp=math.floor(tonumber(heatpumpsettemp))

    if (heatpumpmodevalue == "Off") then
        heatpumpsetpower=0
    elseif (heatpumpmodevalue == "Frostsikring") then
        heatpumpsetmode=6
        heatpumpsettemp=10
    elseif (heatpumpmodevalue == "Varme") then
        heatpumpsetmode=2
    elseif (heatpumpmodevalue == "Kjøle") then
        heatpumpsetmode=3
    elseif (heatpumpmodevalue == "Auto") then
        heatpumpsetmode=1
    end
    
	-- if ( not heatpumpvdirvalue ) then heatpumpvdirvalue="" end;
    if (heatpumpvdirvalue == "Auto") then
        heatpumpsetvdir=0
    elseif (heatpumpvdirvalue == "Sving") then
        heatpumpsetvdir=1
    elseif (heatpumpvdirvalue == "Oppover") then
        heatpumpsetvdir=2
    elseif (heatpumpvdirvalue == "Halvvegs oppover") then
        heatpumpsetvdir=3
    elseif (heatpumpvdirvalue == "Midtstilt") then
        heatpumpsetvdir=4
    elseif (heatpumpvdirvalue == "Midten") then
        heatpumpsetvdir=4
    elseif (heatpumpvdirvalue == "Halvvegs nedover") then
        heatpumpsetvdir=5
    elseif (heatpumpvdirvalue == "Nedover") then
        heatpumpsetvdir=6
    end

    if (heatpumpfanvalue == "Auto") then
        heatpumpsetfanspeed=0
    elseif (heatpumpfanvalue == "H1") then
        heatpumpsetfanspeed=1
    elseif (heatpumpfanvalue == "H2") then
        heatpumpsetfanspeed=2
    elseif (heatpumpfanvalue == "H3") then
        heatpumpsetfanspeed=3
    elseif (heatpumpfanvalue == "H4") then
        heatpumpsetfanspeed=4
    elseif (heatpumpfanvalue == "Stille") then
        heatpumpsetfanspeed=5
	end

    if (heatpumpflowvalue == "2flow") then
      heatpumpsethdir=0
    end

    if (debug) then 
        print(devname .. " changed: heatpumpsettemp=" .. heatpumpsettemp .. " heatpumpmodevalue=" .. heatpumpmodevalue)
    end

    -- http://192.168.0.19/control?cmd=heatpumpir,mitsubishi_fd,1,1,0,23,0,0
	for espeasyip in espdevices:gmatch("%S+") do
		espeasyprefix=espeasyip .. "/control?cmd=heatpumpir," .. heatpumpmodel .. ","
		urlcommand=espeasyprefix .. heatpumpsetpower .. "," .. heatpumpsetmode .. "," .. heatpumpsetfanspeed .. ","
		urlcommand=urlcommand .. heatpumpsettemp .. "," .. heatpumpsetvdir .. "," .. heatpumpsethdir
		if (logging) then 
			print("heatpump: " .. devname .. " set to " .. devvalue .. " --> http://" .. urlcommand)
		end
		-- commandArray['OpenURL']=urlcommand
		table.insert (commandArray, { ['OpenURL'] = urlcommand } )
    end
    return commandArray
end
--
-- vim:ts=4:sw=4
--
