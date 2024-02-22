local function shading_callback(world, shading_env, viewport, default_shading_environment_name)
	local gamma = Application.user_setting("gamma") or 0

	ShadingEnvironment.set_scalar(shading_env, "exposure_compensation", ShadingEnvironment.scalar(shading_env, "exposure_compensation") + gamma)

	local blur_value = World.get_data(world, "fullscreen_blur") or 0

	if blur_value > 0 then
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 1)
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_amount", math.clamp(blur_value, 0, 1))
	else
		World.set_data(world, "fullscreen_blur", nil)
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 0)
	end

	local greyscale_value = World.get_data(world, "greyscale") or 0

	if greyscale_value > 0 then
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 1)
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_amount", math.clamp(greyscale_value, 0, 1))
		ShadingEnvironment.set_vector3(shading_env, "grey_scale_weights", Vector3(0.33, 0.33, 0.33))
	else
		World.set_data(world, "greyscale", nil)
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 0)
	end
end

local world_layer = 500
local viewport_layer = 1
local renderer_templates = {}

renderer_templates.default_renderer = {
    name = "default_renderer",
    world_layer = world_layer + 1,
    viewport_type = "overlay",
    viewport_layer = viewport_layer
}

renderer_templates.background_renderer = {
    name = "background_renderer",
    world_layer = world_layer - 1,
    viewport_type = "overlay",
    viewport_layer = viewport_layer,
    shading_environment = "content/shading_environments/ui/ui_popup_background",
	shading_callback = shading_callback
}

renderer_templates.offscreen_renderer_1 = {
    name = "offscreen_renderer_1",
    world_layer = world_layer,
    viewport_type = "overlay_offscreen",
    viewport_layer = viewport_layer
}

renderer_templates.offscreen_renderer_2 = {
    name = "offscreen_renderer_2",
    world_layer = world_layer,
    viewport_type = "overlay_offscreen_2",
    viewport_layer = viewport_layer
}

renderer_templates.offscreen_renderer_3 = {
    name = "offscreen_renderer_3",
    world_layer = world_layer,
    viewport_type = "overlay_offscreen_3",
    viewport_layer = viewport_layer
}

return renderer_templates