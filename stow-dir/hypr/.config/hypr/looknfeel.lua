-- Group (tabbed/stacked window) styling.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

-- Reversed Rosé Pine: accent (rose) is the primary fill, dark base is the text.
hl.config({
  group = {
    col = {
      border_active = "rgba(ebbcbaff)",
      border_inactive = "rgba(484456ff)",
    },

    groupbar = {
      font_family = "FiraCode Nerd Font SemiBold",
      font_size = 11,
      height = 18,
      text_color = "rgba(26233aff)",
      col = {
        active = "rgba(ebbcbaff)",
        inactive = "rgba(7c7b88ff)",
      },
    },
  },
})
