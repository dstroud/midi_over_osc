local mod = require 'core/mods'
-- local nb = require('nbout/lib/nb/lib/nb')

-- local channel_is_set_up = false
local channel_is_set_up = true
local device_id = 7-- todo work on this. was using -1 to set off-limits

local my_midi = {
    name="midi_over_osc",
    connected=true,
}
function my_midi:send(data) end
function my_midi:note_on(note, vel, ch)
  -- print("DEBUG MOD RCVD NOTE_ON")
    if ch == 1 then
        if not channel_is_set_up then
            print("midi_over_osc received note_on before initialization")
            return
        end
        -- local p = params:lookup_param("midi_over_osc_chan_1"):get_player()
        -- some sequencers (e.g. jala) seem to send nil for vel.
        -- assume they want a default velocity
        if vel == nil then
            vel = 80
        end
        -- p:note_on(note, vel/127)
        -- print("SENDING OSC NOTE_ON")
        osc.send({wifi.ip, 10111}, "/midi_over_osc_note_on", {note, vel}) -- sending to self

    end
end
function my_midi:note_off(note, vel, ch)
    if ch == 1 then
        -- if not channel_is_set_up then
        --     print("midi_over_osc received note_on before initialization")
        --     return
        -- end
        -- local p = params:lookup_param("midi_over_osc_chan_1"):get_player()
        -- p:note_off(note)
        osc.send({wifi.ip, 10111}, "/midi_over_osc_note_off", {note}) -- sending to self
    end
end
function my_midi:pitchbend(val, ch)
    -- TODO
end

-- TODO
function my_midi:cc(cc, val, ch)
    -- if ch == 1 and cc == 72 then
    --     if not channel_is_set_up then
    --         print("midi_over_osc received note_on before initialization")
    --         return
    --     end
    --     local p = params:lookup_param("midi_over_osc_chan_1"):get_player()
    --     p:modulate(val/127)
    -- end
end
function my_midi:key_pressure(note, val, ch) end
function my_midi:channel_pressure(val, ch) end
function my_midi:program_change(val, ch) end
function my_midi:stop()	end
function my_midi:continue()	end
function my_midi:clock() end

-- function my_midi:event(data) 
--   print("MIDI OVER OSC MIDI DATA RECEIVED")  
-- end


local fake_midi = {
    real_midi = midi,
}

local meta_fake_midi = {}

setmetatable(fake_midi, meta_fake_midi)

meta_fake_midi.__index = function(t, key)
    if key == 'vports' then
        local ret = {}
        for _, v in ipairs(t.real_midi.vports) do
            table.insert(ret, v)
        end
        table.insert(ret, my_midi)
        return ret
    end
    if key == 'devices' then
        local ret = {}
        -- local device_id = 7-- todo work on this. was using -1 to set off-limits
        for k, d in pairs(t.real_midi.devices) do
            ret[k] = d
        end
        -- ret[-1] = {  -- index -1 makes this unavailable
        ret[device_id] = {
            name="midi_over_osc",
            port=17,  -- midi.devices[device_id].port
            id=device_id,
        }
        return ret
    end
    if key == 'connect' then
        return function(idx)
            if idx == nil then
                idx = 1
            end
            if idx <= 16 then
                if t.real_midi.vports[idx].name == "midi_over_osc" then
                  print("Connecting to midi_over_osc")
                  return my_midi
                end
                return t.real_midi.connect(idx)
            end
            if idx == #t.real_midi.vports + 1 then
                return my_midi
            end
            return nil
        end
    end
    return t.real_midi[key]
end

mod.hook.register("script_pre_init", "midi_over_osc pre init", function()
-- mod.hook.register("system_post_startup", "midi_over_osc pre init", function()
    midi = fake_midi
    -- local old_init = init
    -- nb:init()
    -- init = function()
        -- old_init()
        -- params:add_separator("midi_over_osc")
        -- nb:add_param("midi_over_osc_chan_1", "midi-over-osc ch 1")
        -- nb:add_player_params()
        -- channel_is_set_up = true
    -- end
    
    function osc.event(path,args,from)
      if type(midi.vports[device_id].event) == "function" then -- necessary?
        -- print("OSC RCVD")
        if path == "/midi_over_osc_note_on" then
          -- print("external IP "..from[1])
          -- external_osc_IP = from[1]
          -- print("midi_on", args[1], args[2])
          -- midi_event(midi.to_data({type = "note_on", note = args[1], ch = 1, vel = args[2]}))
          
          -- midi.vports[device_id].event(midi.to_data({type = "note_on", note = args[1], ch = 1, vel = args[2]}))
          midi.vports[device_id].event(midi.to_data({type = "note_on", note = args[1], ch = 1, vel = args[2]}))
          
          -- local msg = midi.to_data({type = "note_on", note = args[1], ch = 1, vel = args[2]})
          -- midi.vports[device_id]:event(msg)
          
        elseif path == "/midi_over_osc_note_off" then
          -- print("midi_off", args[1])
          -- midi_event(midi.to_data({type = "note_off", note = args[1], ch = 1, vel = 0}))
          midi.vports[device_id].event(midi.to_data({type = "note_off", note = args[1], ch = 1, vel = 0}))
        end
      end
    end
            -- midi_event(midi.to_data({type = "note_on", note = 60, ch = 1, vel = 100})) -- direct to function
    -- midi.vports[7].event(midi.to_data({type = "note_on", note = 40, ch = 1, vel = 100})) -- get fn of port
    
          
end)

mod.hook.register("script_post_cleanup", "midi_over_osc post cleanup", function()
-- mod.hook.register("system_pre_shutdown", "midi_over_osc post cleanup", function()
    -- channel_is_set_up = false
    midi = fake_midi.real_midi
    osc.event = nil -- some sort of cleanup probably needed
end)