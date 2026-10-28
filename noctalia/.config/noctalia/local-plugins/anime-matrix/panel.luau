--!nonstrict

local STATE_KEY = "anime_matrix_state"
local COMMAND_KEY = "anime_matrix_command"
local snapshot = noctalia.state.get(STATE_KEY) or { loading = true }

local PRESETS = {
  { id = "rog-static", label = "Static ROG" },
  { id = "rog-glitch", label = "ROG Glitch" },
  { id = "controller", label = "Controller" },
  { id = "clock", label = "Clock" },
}
local BRIGHTNESS = { "off", "low", "med", "high" }

local function send(changes)
  noctalia.state.set(COMMAND_KEY, { changes = changes, id = noctalia.nowMs() })
end

local function section(title, content)
  return ui.column({ gap = 8, align = "stretch" }, {
    ui.label({ text = string.upper(title), fontSize = 11, fontWeight = "bold", color = "on_surface_variant" }),
    content,
  })
end

local function render()
  local state = snapshot.state or {}
  local busy = snapshot.loading == true
  local enabled = state.enabled == true
  local content = {
    ui.row({ gap = 10, align = "center" }, {
      ui.glyph({ name = "sparkles", size = 26, color = enabled and "primary" or "on_surface_variant" }),
      ui.column({ gap = 2 }, {
        ui.label({ text = "AniMe Matrix", fontSize = 18, fontWeight = "bold" }),
        ui.label({ text = enabled and "Display enabled" or "Display disabled", fontSize = 12, color = "on_surface_variant" }),
      }),
      ui.spacer({ flexGrow = 1 }),
      ui.button({
        text = enabled and "Turn off" or "Turn on",
        variant = enabled and "outline" or "primary",
        enabled = not busy,
        onClick = function() send({ enabled = not enabled }) end,
      }),
    }),
    ui.button({
      text = "Open AniMe Studio",
      variant = "outline",
      enabled = not busy,
      onClick = function()
        noctalia.runAsync({ "/usr/bin/gtk-launch", "anime-matrix-studio" })
      end,
    }),
    ui.separator({}),
  }

  local brightness = {}
  for _, value in ipairs(BRIGHTNESS) do
    table.insert(brightness, ui.button({
      text = string.upper(value),
      variant = enabled and state.brightness == value and "primary" or "outline",
      controlSize = "sm",
      enabled = not busy,
      onClick = function() send({ brightness = value }) end,
    }))
  end
  table.insert(content, section("Brightness", ui.row({ gap = 8, align = "center" }, brightness)))

  local presets = {}
  for _, preset in ipairs(PRESETS) do
    table.insert(presets, ui.button({
      text = preset.label,
      variant = enabled and state.preset == preset.id and "primary" or "outline",
      controlSize = "sm",
      enabled = not busy,
      onClick = function() send({ preset = preset.id, enabled = true }) end,
    }))
  end
  table.insert(content, section("Display preset", ui.column({ gap = 6, align = "stretch" }, {
    ui.row({ gap = 8, align = "center" }, { presets[1], presets[2] }),
    ui.row({ gap = 8, align = "center" }, { presets[3], presets[4] }),
  })))

  local power = {}
  for _, item in ipairs({
    { key = "off_when_unplugged", label = "Turn off on battery" },
    { key = "off_when_suspended", label = "Turn off when suspended" },
    { key = "off_when_lid_closed", label = "Turn off with lid closed" },
  }) do
    local active = state[item.key] == true
    table.insert(power, ui.button({
      text = `{item.label}: {active and "yes" or "no"}`,
      variant = active and "primary" or "outline",
      controlSize = "sm",
      enabled = not busy,
      onClick = function() send({ [item.key] = not active }) end,
    }))
  end
  table.insert(content, section("Power saving", ui.column({ gap = 6, align = "stretch" }, power)))

  if snapshot.error and snapshot.error ~= "" then
    table.insert(content, ui.label({ text = snapshot.error, color = "error", fontSize = 12, maxLines = 3 }))
  elseif busy then
    table.insert(content, ui.label({ text = "Applying…", color = "on_surface_variant", fontSize = 12 }))
  else
    table.insert(content, ui.label({ text = "ASUS automatic standby animations are disabled to avoid random dots. Presets can still animate.", color = "on_surface_variant", fontSize = 12, maxLines = 3 }))
  end

  panel.render(ui.column({ gap = 14, padding = 20, align = "stretch" }, content))
end

noctalia.state.watch(STATE_KEY, function(value)
  snapshot = value or snapshot
  render()
end)

render()
