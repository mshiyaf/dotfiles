-- Personal input overrides loaded after Omarchy's defaults.
hl.config({
  input = {
    kb_layout = "us",
    kb_model = "macintosh",
    kb_variant = "mac",
    repeat_rate = 40,
    repeat_delay = 600,
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
})

-- Change workspaces with a three-finger horizontal swipe.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
