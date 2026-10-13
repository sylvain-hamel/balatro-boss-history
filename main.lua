--- Boss History - main.lua
--
-- Press the key during a run to list the boss blinds faced so far, ante by
-- ante, with your score vs the target and hands used, plus the next boss.
--
-- The game only counts how often each boss was picked this run
-- (G.GAME.bosses_used), so fights are logged as they end into
-- G.GAME.bh_history, which is saved with the run.

BH = BH or {}
BH.TOGGLE_KEY = "o"

local function num(x)
   if type(x) == "table" and x.to_number then return x:to_number() end
   return x
end

local function fmt(x)
   x = num(x)
   if type(x) ~= "number" then return tostring(x) end
   return number_format(x)
end

--
-- RECORDING
--

local orig_end_round = end_round
function end_round(...)
   local blind = G.GAME and G.GAME.blind
   if blind and blind.boss and blind.config and blind.config.blind and blind.config.blind.key then
      G.GAME.bh_history = G.GAME.bh_history or {}
      local scored, needed = num(G.GAME.chips), num(blind.chips)
      table.insert(G.GAME.bh_history, {
         ante = G.GAME.round_resets.ante,
         key = blind.config.blind.key,
         scored = scored,
         needed = needed,
         hands = G.GAME.current_round.hands_played,
         beaten = scored >= needed,
         disabled = blind.disabled or nil,
      })
   end
   return orig_end_round(...)
end

--
-- DISPLAY
--

local SCALE = 0.32

local function text(s, colour, scale)
   return {n = G.UIT.T, config = {text = s, scale = scale or SCALE, colour = colour or G.C.UI.TEXT_LIGHT}}
end

local function cell(nodes, minw, align)
   return {n = G.UIT.C, config = {align = align or "cl", minw = minw, padding = 0.03}, nodes = nodes}
end

local function row(nodes, colour)
   return {n = G.UIT.R, config = {align = "cm", padding = 0.03, r = 0.08, colour = colour}, nodes = nodes}
end

local function blind_name(key)
   local ok, name = pcall(localize, {type = "name_text", key = key, set = "Blind"})
   return ok and name and name ~= "ERROR" and name or key
end

-- The boss's effect text, one string per line (as on the blind select screen).
local function blind_description(key)
   local blind = G.P_BLINDS[key]
   if not blind then return {} end
   local ok, lines = pcall(function()
      local target = {type = "raw_descriptions", key = key, set = "Blind", vars = blind.vars or {}}
      if blind.name == "The Ox" then
         target.vars = {localize(G.GAME.current_round.most_played_poker_hand, "poker_hands")}
      end
      if type(blind.loc_vars) == "function" then
         local res = blind:loc_vars() or {}
         target.vars = res.vars or target.vars
         target.key = res.key or target.key
      end
      return localize(target)
   end)
   return ok and type(lines) == "table" and lines or {}
end

local function blind_chip(key, size)
   local blind = G.P_BLINDS[key]
   if not blind then return nil end
   local ok, sprite = pcall(SMODS.create_sprite, 0, 0, size, size, SMODS.get_atlas(blind.atlas) or "blind_chips", blind.pos)
   if not ok or not sprite then return nil end
   sprite.states.drag.can = false
   return {n = G.UIT.O, config = {object = sprite}}
end

local function boss_cells(key)
   local desc = {}
   for _, l in ipairs(blind_description(key)) do
      table.insert(desc, {n = G.UIT.R, config = {align = "cl"}, nodes = {text(l, G.C.UI.TEXT_LIGHT, SCALE * 0.85)}})
   end
   local colour = G.P_BLINDS[key] and G.P_BLINDS[key].boss_colour or G.C.UI.TEXT_LIGHT
   return {
      cell({blind_chip(key, 0.5)}, 0.6, "cm"),
      cell({text(blind_name(key), colour)}, 2.6),
      cell({{n = G.UIT.C, config = {align = "cl"}, nodes = desc}}, 5.2),
   }
end

local function header()
   return row({
      cell({text("Ante", G.C.UI.TEXT_INACTIVE)}, 0.8, "cm"),
      cell({}, 0.6),
      cell({text("Boss", G.C.UI.TEXT_INACTIVE)}, 2.6),
      cell({text("Effect", G.C.UI.TEXT_INACTIVE)}, 5.2),
      cell({text("Score / Target", G.C.UI.TEXT_INACTIVE)}, 3.2),
      cell({text("Hands", G.C.UI.TEXT_INACTIVE)}, 0.9, "cm"),
      cell({text("Result", G.C.UI.TEXT_INACTIVE)}, 1.6),
   })
end

local function fight_row(f)
   local nodes = {cell({text(tostring(f.ante), G.C.FILTER)}, 0.8, "cm")}
   for _, c in ipairs(boss_cells(f.key)) do table.insert(nodes, c) end
   local result, colour
   if f.beaten then
      result, colour = f.disabled and "Beaten (disabled)" or "Beaten", G.C.GREEN
   else
      result, colour = "Lost", G.C.RED
   end
   table.insert(nodes, cell({text(fmt(f.scored), G.C.CHIPS), text(" / " .. fmt(f.needed))}, 3.2))
   table.insert(nodes, cell({text(tostring(f.hands or "?"))}, 0.9, "cm"))
   table.insert(nodes, cell({text(result, colour)}, 1.6))
   return row(nodes, {0, 0, 0, 0.15})
end

-- Bosses picked earlier this run that the log doesn't cover (e.g. before the
-- mod was installed). Rerolled bosses are counted too, so it's "seen".
local function untracked(history, upcoming)
   local used = G.GAME.bosses_used and (G.GAME.bosses_used.boss or G.GAME.bosses_used) or {}
   local logged = {}
   for _, f in ipairs(history) do logged[f.key] = (logged[f.key] or 0) + 1 end
   local list = {}
   for key, count in pairs(used) do
      if type(count) == "number" and G.P_BLINDS[key] then
         local extra = count - (logged[key] or 0) - (key == upcoming and 1 or 0)
         if extra > 0 then table.insert(list, key) end
      end
   end
   table.sort(list)
   return list
end

function BH.build_ui()
   local history = G.GAME.bh_history or {}
   local upcoming = G.GAME.round_resets.blind_choices and G.GAME.round_resets.blind_choices.Boss
   local nodes = {
      {n = G.UIT.R, config = {align = "cl", padding = 0.05}, nodes = {text("Boss blinds this run", G.C.GOLD, 0.45)}},
      header(),
   }

   for _, f in ipairs(history) do table.insert(nodes, fight_row(f)) end
   if #history == 0 then
      table.insert(nodes, row({cell({text("No boss fought yet since Boss History was installed.", G.C.UI.TEXT_INACTIVE)}, 8)}))
   end

   if upcoming and G.P_BLINDS[upcoming] and G.GAME.round_resets.blind_states.Boss ~= "Defeated" then
      local up = {cell({text(tostring(G.GAME.round_resets.ante), G.C.FILTER)}, 0.8, "cm")}
      for _, c in ipairs(boss_cells(upcoming)) do table.insert(up, c) end
      table.insert(up, cell({text("Target " .. fmt(get_blind_amount(G.GAME.round_resets.ante) * G.P_BLINDS[upcoming].mult * G.GAME.starting_params.ante_scaling), G.C.UI.TEXT_INACTIVE)}, 3.2))
      table.insert(up, cell({}, 0.9))
      table.insert(up, cell({text("Up next", G.C.FILTER)}, 1.6))
      table.insert(nodes, row(up, {1, 1, 1, 0.06}))
   end

   local earlier = untracked(history, upcoming)
   if #earlier > 0 then
      local names = {}
      for _, key in ipairs(earlier) do table.insert(names, blind_name(key)) end
      table.insert(nodes, {n = G.UIT.R, config = {align = "cl", padding = 0.05}, nodes = {
         text("Also seen earlier this run (before tracking, order unknown): " .. table.concat(names, ", "), G.C.UI.TEXT_INACTIVE),
      }})
   end

   return create_UIBox_generic_options({contents = {
      {n = G.UIT.R, config = {id = "bh_root", align = "cm", padding = 0.15, r = 0.1, colour = G.C.BLACK}, nodes = {
         {n = G.UIT.C, config = {align = "cm"}, nodes = nodes},
      }},
   }})
end

local orig_key_press_update = Controller.key_press_update
function Controller:key_press_update(key, dt)
   if key == BH.TOGGLE_KEY and not self.text_input_hook and not self.locks.frame then
      if G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("bh_root") then
         G.FUNCS.exit_overlay_menu()
         return
      elseif not G.OVERLAY_MENU and G.STAGE == G.STAGES.RUN and G.GAME and G.GAME.round_resets then
         G.FUNCS.overlay_menu({definition = BH.build_ui()})
         return
      end
   end
   return orig_key_press_update(self, key, dt)
end

sendInfoMessage("Loaded, key: " .. BH.TOGGLE_KEY, "BossHistory")
