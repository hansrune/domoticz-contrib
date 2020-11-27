--
-- $Id: script_time_aggregatesensors.lua,v 1.4 2019/05/15 08:32:21 pi Exp $
--
logging = true
dbg = false

-- Extra debugging in included / excluded devices
exdbg = false

-- For timing
timingdbg = false
-- Also used to time out in case things loop
nClock = os.clock()

--
-- User variables from Domoticz setup
--
incldevices=uservariables["AggregateDevices"]; 
excldevices=uservariables["AggregateExcluded"]; 
devicetimeout=uservariables["AggregateDeviceTimeOut"]; 
dbg=uservariables["AggregateDebug"]; 
maxdiff=uservariables["AggregateMaxDiff"]; 
--
-- Fallback values
--
if not ( incldevices ) then incldevices = "Temp$,Lux$" end
if not ( excldevices ) then excldevices = "egulator" end
if not ( devicetimeout ) then devicetimeout = 300 end
if not ( maxdiff ) then maxdiff = "30%" end
if not ( dbg ) or ( dbg == 0 ) then dbg = false end

commandArray = {}

if ( string.sub(maxdiff, -1) == "%" )
then
	maxdiffval  = tonumber(string.sub(maxdiff,1,string.len(maxdiff)-1))
	maxdiffunit = "%"
else
	maxdiffunit = ""
	maxdiffval  = tonumber(maxdiff)
end

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

devicevalues = {}

function updatedevice(d)
	local i = otherdevices_idx[d]
    local cmd, v, s, k
	if ( #devicevalues == 0 ) then
		if (exdbg) then print("Main device " .. d .. " not updated (idx " .. i .. ", " .. #devicevalues .. " subsensors in use)") end
		return
	end
	
	s = 0
	for k, v in pairs(devicevalues) do s = s + v end
	s = s / #devicevalues
	
	v   = string.format("%.1f", s)
    cmd = i .. "|0|" .. v
	if (logging) then print("Main device " .. d .. " value " .. v .. ", idx " .. i .. ", " .. devicesincluded .. " subsensors used, included ".. #devicevalues .. " value(s)") end
    table.insert (commandArray, { ['UpdateDevice'] = cmd } )
end

function collectdata(d, v)
	local p, i
	
	v = tonumber(v)
    i = #devicevalues
	devicesincluded = devicesincluded + 1

	if ( i == 0 ) then 
		devicevalues[i+1] = v
		return 
	end

    --- examine last 5 characters for (min) or (max)
	p = string.sub(d, -5)

	if ( p == "(min)" ) then
		-- compare to / update last value only
		if ( v < devicevalues[i] ) then devicevalues[i] = v end
	elseif ( p == "(max)" ) then
		-- compare to / update last value only
		if ( v > devicevalues[i] ) then devicevalues[i] = v end
	else
		devicevalues[i+1] = v
	end
end

for maindev, mainval in pairs(otherdevices_svalues) 
do
	pos = nil
	exclpos = nil
	if os.clock()-nClock > 1 then
		print("ERROR: Running for > 1 second - match loop now on device " .. maindev)
		return commandArray
	end
	for matchname in string.gmatch(incldevices, "[^,]+")
	do
		pos = string.find(maindev,matchname)
		if ( pos ) then 
			for exname in string.gmatch(excldevices, "[^,]+")
			do
				exclpos = string.find(maindev,exname)
				if ( exclpos ) then 
					if (exdbg) then print("Excluded device " ..  maindev .. "  matching " .. exname) end
					break 
				end
			end
			if (exclpos) then break end
			if (exdbg) then print("Included device " ..  maindev .. " matching " .. matchname .. " value=" .. mainval) end
			maindtime = changedsince(maindev)
			devicevalues = {}
			devicesincluded = 0 
			for subdev, subval in pairs(otherdevices_svalues)
			do
				if os.clock()-nClock > 1 then
					print("ERROR: Running for > 1 second - inner loop now on device " .. maindev)
					return commandArray
				end
				p = 1
				-- in case of a hidden device, exclude the initial $
				if (string.sub(subdev,1,1) == '$') then p = 2 end
				-- examine all devices where main device is a plain substring from start of string (excluding itself)
				p = string.find(subdev, maindev, p, true)
				if ( p ) and ( subdev ~= maindev ) then
					-- Strip off everything after first ; in case of a multisensor - assuming main value is first
					p = string.find(subval, ";", 1, true)
					if (p) then subval = string.sub( subval, 1, p - 1 ) end
					subdtime = changedsince(subdev)
					if (subdtime <= devicetimeout) then
						if ((string.sub(subdev, -1) == "+" ) and (subdtime <= devicetimeout)) then
							-- Subdevice ends in +, so include as long as it has not timed out
							collectdata(string.sub(subdev, 1, -2), subval)
							if (dbg) then print("Subdevice " .. string.sub(subdev, 1, -2) .. "+ value " .. subval .. " inluded as name ends in +") end
						elseif ( maindtime > devicetimeout ) and (subdtime <= devicetimeout) then
							-- If main device is not updated, collect all subdevice values that are not timed out
							collectdata(subdev, subval)
							print("Subdevice " ..  subdev .. " value " .. subval .. " included due to main device timeout")
						else
							-- ... else, collect only those within tolerable deviations
							-- For new sensors, the initial value is 0, so make sure we treat that as OK 
							diff = 0
                            if ( mainval ~= 0 ) then
								if ( maxdiffunit == "" )
								then
									diff = math.abs(subval - mainval)
								else
									diff = math.ceil(100 * math.abs( 1 - subval / mainval ))
								end
                            end
							inc = "excluded"
							if ( diff <= maxdiffval ) then
								collectdata(subdev, subval)
								inc = "included"
							end
							if (dbg) then print("Subdevice " ..  subdev .. " value " .. subval .. " " .. inc .. ", main device " .. mainval .. ", difference " .. diff .. maxdiffunit .. ", maximum " .. maxdiffval .. maxdiffunit) end
						end
					else
						if (dbg) then print("Subdevice " .. subdev .. " value " .. subval .. " excluded. Not seen for " .. subdtime .. " seconds" ) end
					end
				end
			end
			updatedevice(maindev)
		else
			if (exdbg) then print("No match device " ..  maindev .. " no match for " .. matchname) end
		end
	end
end
if (timingdbg) then print("Script elapsed time: " .. os.clock()-nClock) end

return commandArray
--
-- vim:ts=4:sw=4
--
