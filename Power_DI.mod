return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Power_DI` encountered an error loading the Darktide Mod Framework.")

		new_mod("Power_DI", {
			mod_script       = "Power_DI/scripts/mods/Power_DI/Power_DI",
			mod_data         = "Power_DI/scripts/mods/Power_DI/Power_DI_data",
			mod_localization = "Power_DI/scripts/mods/Power_DI/Power_DI_localization",
		})
	end,
	packages = {},
}
