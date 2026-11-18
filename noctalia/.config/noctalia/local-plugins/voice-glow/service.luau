--!nonstrict
-- Follows Voxtype's state file and makes the focused niri window glow while it
-- is busy. Reading a one-word file in the runtime dir is cheap, so a short poll
-- keeps the glow in step with the key without a long-lived child process.

local POLL_MS = 120
local RULE_FILE = noctalia.expandPath("~/.config/niri/voice-glow.kdl")
local COLORS_FILE = noctalia.expandPath("~/.config/noctalia/colors.json")

local stateFile = nil
local current = nil

local function read()
  local raw = stateFile and noctalia.readFile(stateFile)
  local word = raw and string.match(raw, "^%s*(%a+)") or "idle"
  return string.lower(word)
end

-- The theme's own colors, read on each change so a theme switch is picked up.
local function themeColor(key, fallback)
  local raw = noctalia.readFile(COLORS_FILE)
  local colors = raw and noctalia.json.decode(raw)
  local value = type(colors) == "table" and colors[key]
  return type(value) == "string" and string.match(value, "^#%x%x%x%x%x%x$") and value or fallback
end

local function rule(color)
  return table.concat({
    "// Written by the voice-glow Noctalia plugin while Voxtype dictates.",
    "window-rule {",
    "    match is-focused=true",
    "    focus-ring {",
    "        on",
    "        width 3",
    `        active-color "{color}"`,
    "    }",
    "    shadow {",
    "        on",
    `        color "{color}cc"`,
    "        softness 40",
    "        spread 8",
    "        offset x=0 y=0",
    "    }",
    "}",
    "",
  }, "\n")
end

local function apply(state)
  if state == current then
    return
  end
  current = state
  local text = ""
  if state == "recording" then
    text = rule(themeColor("mPrimary", "#e6b450"))
  elseif state ~= "idle" and state ~= "stopped" then
    text = rule(themeColor("mSecondary", "#aad94c"))
  end
  noctalia.writeFile(RULE_FILE, text)
end

local runtime = noctalia.getenv("XDG_RUNTIME_DIR")
stateFile = runtime and runtime ~= "" and `{runtime}/voxtype/state` or nil
noctalia.setUpdateInterval(POLL_MS)
apply(read())

function update()
  apply(read())
end

-- Never leave a window glowing after a reload or shutdown.
function onExit()
  noctalia.writeFile(RULE_FILE, "")
end
