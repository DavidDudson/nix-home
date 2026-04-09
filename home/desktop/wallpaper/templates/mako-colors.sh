#!/usr/bin/env bash
# Apply matugen-generated colors to mako
makoctl set-option background-color="{{colors.surface.default.hex}}"
makoctl set-option text-color="{{colors.on_surface.default.hex}}"
makoctl set-option border-color="{{colors.primary.default.hex}}"
makoctl set-option progress-color="over {{colors.surface_container.default.hex}}"
makoctl reload
