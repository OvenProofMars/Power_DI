local UIRenderer = require("scripts/managers/ui/ui_renderer")
local _math_max = math.max
local _math_min = math.min
local _math_clamp = math.clamp
local _math_floor = math.floor
local _ui_renderer_text_size = UIRenderer.text_size
local _ui_renderer_text_height = UIRenderer.text_height
local _ui_renderer_word_wrap = UIRenderer.word_wrap
local _utf8_string_length = Utf8.string_length
local _utf8_sub_string = Utf8.sub_string

local input_service = Managers.input:get_input_service("View")

local font_color = Color.terminal_text_body(200, true)

local function _find_next_word(text, caret_position)
	caret_position = Utf8.find(text, "%s", caret_position)
	caret_position = caret_position or _utf8_string_length(text)

	return caret_position + 1
end

local function _find_prev_word(text, caret_position)
	local pos = 0
	local result = 1
	local text_length = _utf8_string_length(text)

	if text_length < caret_position then
		caret_position = text_length
	end

	while pos and pos < caret_position - 1 do
		pos = pos + 1
		result = pos
		pos = Utf8.find(text, "%s", pos)
	end

	return result
end

local function _insert_text(target, caret_position, text_to_insert, max_length)
	local text_length = _utf8_string_length(text_to_insert)

	if max_length then
		local target_length = _utf8_string_length(target)

		if max_length < target_length + text_length then
			text_length = max_length - target_length
			text_to_insert = Utf8.sub_string(text_to_insert, 1, _math_max(text_length, 0))
		end
	end

	if text_length > 0 then
		target = Utf8.string_insert(target, caret_position, text_to_insert)
		caret_position = caret_position + text_length
	end

	return target, caret_position
end

local function _remove_text(input_text, selection_start, selection_end, caret_position)
	local selection_length = selection_end - selection_start
	input_text = Utf8.string_remove(input_text, selection_start, selection_length)

	if caret_position then
		if selection_end <= caret_position then
			caret_position = caret_position - selection_length
		elseif selection_start <= caret_position then
			caret_position = selection_start
		end
	end

	return input_text, caret_position
end

local function _input_active_visibility_function(content, style)
	return content.is_writing
end

local function _selection_visibility_function(content, style)
	local selected_text = content.selected_text

	return selected_text and selected_text ~= ""
end

local CustomMultiLineTextInput = {
	{
		pass_type = "hotspot",
		content_id = "hotspot",
		change_function = function (hotspot_content, style)
			local content = hotspot_content.parent

			if content.last_frame_left_pressed and hotspot_content.on_pressed then
				local is_writing = not content.is_writing

				if is_writing then
					local input_text = content.input_text
					local text_length = input_text and _utf8_string_length(input_text) or 0

					-- if input_text and text_length > 0 and not content.selected_text then
					-- 	content.input_text = ""
					-- 	content.selected_text = input_text
					-- end
				end

				content.is_writing = true
			elseif content.last_frame_left_pressed then
				content.is_writing = false
			end

			content.last_frame_left_pressed = input_service:get("left_pressed")
		end
	},
	{
		pass_type = "logic",
		value = function (pass, ui_renderer, ui_style, content, position, size)
			if not content.is_writing then
				return
			end

			local input_service = ui_renderer.input_service
			local caret_position = content.caret_position or 1
			local updated_input_text = content.input_text or ""
			local is_selecting = input_service:get("select_text")
			local last_input = nil

			if input_service:get("navigate_left_continuous") then
				if input_service:get("navigate_text_modifier") then
					caret_position = _find_prev_word(updated_input_text, caret_position)
				else
					caret_position = caret_position - 1
				end
			elseif input_service:get("navigate_right_continuous") then
				if input_service:get("navigate_text_modifier") then
					caret_position = _find_next_word(updated_input_text, caret_position)
				else
					caret_position = caret_position + 1
				end
			elseif input_service:get("navigate_beginning") then
				caret_position = 1
			elseif input_service:get("navigate_end") then
				caret_position = _utf8_string_length(updated_input_text) + 1
			elseif input_service:get("clipboard_paste") then
				local clipboard_text = Clipboard.get()

				if clipboard_text then
					local max_length = content.max_length
					updated_input_text, caret_position = _insert_text(updated_input_text, caret_position, clipboard_text, max_length)
					last_input = clipboard_text
				end
			elseif input_service:get("select_all_text") then
				content.selected_text = updated_input_text
				content._selection_start = 1
				local text_length = _utf8_string_length(updated_input_text)+1
				content._selection_end = text_length
				content._selection_changed = true
				content.force_caret_update = true
				is_selecting = true
				caret_position = text_length
				content._caret_position = text_length
				--updated_input_text = ""
			elseif not input_service:is_null_service() then
				local keystrokes = Keyboard.keystrokes()

				for _, keystroke in ipairs(keystrokes) do
					is_selecting = false

					if type(keystroke) == "string" then
						updated_input_text = Utf8.string_insert(updated_input_text, caret_position, keystroke)
						caret_position = caret_position + 1
						last_input = last_input and last_input .. keystroke or keystroke
					elseif type(keystroke) == "number" then
						if keystroke == Keyboard.BACKSPACE then
							if #updated_input_text == 0 and content.close_on_backspace then
								content.is_writing = false
							elseif caret_position > 1 then
								caret_position = _math_max(caret_position - 1, 1)
								updated_input_text = Utf8.string_remove(updated_input_text, caret_position)
							end

							last_input = ""
						elseif keystroke == Keyboard.DELETE then
							if caret_position <= Utf8.string_length(updated_input_text) then
								updated_input_text = Utf8.string_remove(updated_input_text, caret_position)
							end

							last_input = ""
						end
					end
				end
			end

			if caret_position ~= content.caret_position then
				content._blink_time = 0
			end

			content.input_text = updated_input_text
			content.caret_position = caret_position
			content.last_input = last_input
			content._is_selecting = is_selecting
		end
	},
	{
		pass_type = "logic",
		value = function (pass, ui_renderer, ui_style, content, position, size)
			if not content.is_writing then
				return
			end

			local input_service = ui_renderer.input_service
			local input_text = content.input_text or ""
			local old_input_text = content._input_text or input_text
			local selected_text = content.selected_text
			local caret_position = content.caret_position or 1
			local old_caret_position = content._caret_position or caret_position
			local selection_start = content._selection_start
			local selection_end = content._selection_end
			local is_selecting = content._is_selecting
			local has_selection = selection_start and selection_end

			if has_selection and not is_selecting then
				local last_input = content.last_input
				content.last_input = nil
				local deselect = false

				if input_service:get("clipboard_copy") then
					Clipboard.put(selected_text)
				elseif input_service:get("clipboard_cut") then
					if Clipboard.put(selected_text) then
						input_text, caret_position = _remove_text(input_text, selection_start, selection_end, caret_position)
						deselect = true
					end
				elseif last_input and selection_start ~= selection_end then
					input_text, caret_position = _remove_text(old_input_text, selection_start, selection_end, old_caret_position)
					input_text, caret_position = _insert_text(input_text, caret_position, last_input)
					deselect = true
				elseif caret_position ~= old_caret_position then
					deselect = true
				end

				if deselect then
					content.input_text = input_text
					content.caret_position = caret_position
					content.selected_text = nil
					content._selection_start = nil
					content._selection_end = nil
					has_selection = false
					selected_text = nil
				end
			end

			if not has_selection and not is_selecting and not selected_text then
				return
			end

			if not has_selection then
				selection_start = caret_position
				selection_end = caret_position

				if selected_text then
					local input_text_original_length = _utf8_string_length(input_text)

					if caret_position > input_text_original_length + 1 then
						caret_position = input_text_original_length + 1
						selection_start = caret_position
					end

					input_text, caret_position = _insert_text(input_text, caret_position, selected_text)
					content.input_text = input_text
					content.caret_position = caret_position
					selection_end = caret_position
				end
			elseif selection_start == selection_end and input_text ~= old_input_text then
				content.selected_text = nil
				content._selection_start = nil
				content._selection_end = nil

				return
			elseif caret_position == old_caret_position then
				return
			elseif caret_position < selection_start or caret_position <= selection_end and old_caret_position < caret_position then
				selection_start = _math_max(caret_position, 1)
			elseif selection_start < caret_position or caret_position == selection_start and caret_position < old_caret_position then
				selection_end = _math_min(caret_position, _utf8_string_length(input_text) + 1)
			end

			selected_text = _utf8_sub_string(input_text, selection_start, selection_end - 1)
			content.selected_text = selected_text
			content._selection_start = selection_start
			content._selection_end = selection_end
			content._selection_changed = true

			Log.info("TextInputPasses", "Selected text: [%s]", selected_text)
		end
	},
	{
		pass_type = "logic",
		value = function (pass, ui_renderer, ui_style, content, position, size)
			local old_input_text = content._input_text
			local new_input_text = content.input_text
			local old_caret_position = content._caret_position
			local new_caret_position = content.caret_position
			local force_caret_update = content.force_caret_update
			local text_has_changed = new_input_text ~= old_input_text
			local caret_position_has_changed = new_caret_position ~= old_caret_position
			
			if not text_has_changed and not caret_position_has_changed and not force_caret_update then
				return
			end

			local display_text_style = ui_style.parent.display_text
			local font_type = display_text_style.font_type
			local font_size = display_text_style.font_size

			local text_hight = _ui_renderer_text_height(ui_renderer, new_input_text, font_type, font_size)
			local max_text_width = (size[1] * ui_renderer.inverse_scale) - 1

			if display_text_style.size_addition then
				max_text_width = max_text_width + display_text_style.size_addition[1]
			end

			local rows = _ui_renderer_word_wrap(ui_renderer, new_input_text, font_type, font_size, max_text_width)

			local previous_compound_row_length = 0
			local current_row = 1

			for index, row in ipairs(rows) do
				local compound_row_length = previous_compound_row_length + _utf8_string_length(row)
				if new_caret_position-1 <= compound_row_length then
					current_row = index
					break
				end
				previous_compound_row_length = compound_row_length
			end
		
			local relative_caret_position = new_caret_position - previous_compound_row_length - 1
			local row_string = rows[current_row] or ""
			local row_sub_string = _utf8_sub_string(row_string, 1, relative_caret_position)
			local _1, _2, _3, caret_offset_vector = _ui_renderer_text_size(ui_renderer, row_sub_string, font_type, font_size)

			local caret_offset = caret_offset_vector[1]

			content.caret_position = new_caret_position
			content._input_text = new_input_text
			content.display_text = new_input_text
			content._caret_position = new_caret_position
			content.force_caret_update = nil

			local caret_style = ui_style.parent.input_caret
			caret_style.offset[1] = display_text_style.offset[1] + caret_offset
			caret_style.offset[2] = display_text_style.offset[2] + ((current_row-1)*text_hight)
			caret_style.size[2] = display_text_style.font_size
		end
	},
	{
		pass_type = "logic",
		value = function (pass, ui_renderer, ui_style, content, position, size)
			if not content._selection_changed then
				return
			end
	
			content._selection_changed = nil
			local selection_start = content._selection_start
			local selection_end = content._selection_end
			local text = content._input_text
			local display_text = content.display_text
			local display_text_style = ui_style.parent.display_text
	
			local font_type = display_text_style.font_type
			local font_size = display_text_style.font_size
			local base_offset = display_text_style.offset[1]
			local max_text_width = size[1] - base_offset
			
			local total_text_length = _utf8_string_length(text)
	
			local rows = UIRenderer.word_wrap(ui_renderer, text, font_type, font_size, max_text_width)
	
			local previous_compound_row_length = 0
			local start_row, start_row_relative_selection_start, end_row, end_row_relative_selection_end
			for index, row in ipairs(rows) do
				local compound_row_length = previous_compound_row_length + _utf8_string_length(row)
				if not start_row and selection_start <= compound_row_length then
					start_row = index
					start_row_relative_selection_start = selection_start - previous_compound_row_length -1
				end
				if not end_row and selection_end-1 <= compound_row_length then
					end_row = index
					end_row_relative_selection_end = selection_end - previous_compound_row_length -1
				end
				previous_compound_row_length = compound_row_length
			end
			
			local text_hight = UIRenderer.text_height(ui_renderer, text, font_type, font_size)
	
			local start_row_string = rows[start_row] or ""
			local start_row_string_width = _ui_renderer_text_size(ui_renderer, start_row_string, font_type, font_size)
			local start_row_sub_string = _utf8_sub_string(start_row_string, 1, start_row_relative_selection_start)
			local start_row_sub_string_width = _ui_renderer_text_size(ui_renderer, start_row_sub_string, font_type, font_size)
	
			local end_row_string = rows[end_row] or ""
			local end_row_string_width = _ui_renderer_text_size(ui_renderer, end_row_string, font_type, font_size)
			local end_row_sub_string = _utf8_sub_string(end_row_string, 1, end_row_relative_selection_end)
			local end_row_sub_string_width = _ui_renderer_text_size(ui_renderer, end_row_sub_string, font_type, font_size)
	
			local vertical_end_offset = end_row*text_hight*1.25
			
			local selection_1_style = ui_style.parent.selection_1
			local selection_2_style = ui_style.parent.selection_2
			local selection_3_style = ui_style.parent.selection_3
	
			local nil_offset = {0,0,0}
			local nil_size = {0,0}
	
			selection_1_style.offset = nil_offset
			selection_1_style.size = nil_size
			selection_2_style.offset = nil_offset
			selection_2_style.size = nil_size
			selection_3_style.offset = nil_offset
			selection_3_style.size = nil_size
	
			local selection_1_offset = {start_row_sub_string_width+base_offset, text_hight*(start_row-1), 0}
	
			if end_row-start_row == 0 then
				local selection_1_size = {}
				selection_1_size[1] = end_row_sub_string_width - start_row_sub_string_width
				selection_1_size[2] = text_hight
				selection_1_style.offset = selection_1_offset
				selection_1_style.size = selection_1_size
			elseif end_row-start_row == 1 then
				local selection_1_size = {}
				selection_1_size[1] = start_row_string_width - start_row_sub_string_width
				selection_1_size[2] = text_hight
				selection_1_style.offset = selection_1_offset
				selection_1_style.size = selection_1_size
	
				local selection_2_offset = {base_offset, text_hight*(end_row-1), 0}
				local selection_2_size = {}
				selection_2_size[1] = end_row_sub_string_width
				selection_2_size[2] = text_hight
				selection_2_style.offset = selection_2_offset
				selection_2_style.size = selection_2_size
			elseif end_row-start_row >= 2 then
				local selection_1_size = {}
				selection_1_size[1] = start_row_string_width - start_row_sub_string_width
				selection_1_size[2] = text_hight
				selection_1_style.offset = selection_1_offset
				selection_1_style.size = selection_1_size
	
				local selection_2_offset = {base_offset, text_hight*(start_row), 0}
				local selection_2_size = {}
				selection_2_size[1] = max_text_width-(base_offset*2)
				selection_2_size[2] = text_hight*(end_row-start_row-1)
				selection_2_style.offset = selection_2_offset
				selection_2_style.size = selection_2_size
	
				local selection_3_offset = {base_offset, text_hight*(end_row-1), 0}
				local selection_3_size = {}
				selection_3_size[1] = end_row_sub_string_width
				selection_3_size[2] = text_hight
				selection_3_style.offset = selection_3_offset
				selection_3_style.size = selection_3_size
			end
		end,
		visibility_function = _selection_visibility_function
	},
	{
		style_id = "focused",
		pass_type = "rect",
		style = {
			vertical_alignment = "center",
			horizontal_alignment = "center",
			color = Color.ui_terminal(255, true),
			size_addition = {
				4,
				4
			},
			offset = {
				0,
				0,
				-1
			}
		},
		visibility_function = function (content, style)
			local hotspot = content.hotspot

			return hotspot.use_is_focused and hotspot.is_focused or hotspot.is_selected
		end
	},
	{
		style_id = "background",
		pass_type = "rect",
		style = {
			color = Color.terminal_grid_background(50, true)
		}
	},
	{
		value_id = "display_text",
		style_id = "display_text",
		pass_type = "text",
		value = "",
		style = {
			font_type= "proxima_nova_bold" ,
			line_spacing= 1.2,
			text_color= font_color,
			offset= {4,4,1},
			text_vertical_alignment= "top",
			text_hotizontal_alignment = "left",
			font_size = 20,
			disabled_text_color= {255,60,60,60},
			default_text_color= {255,255,255,255},
		  }
	},
	{
		style_id = "input_caret",
		pass_type = "rect",
		style = {

			color = font_color,
			offset = {0,0,2},
			size = {2},
			size_addition = {0,0}
		},
		visibility_function = _input_active_visibility_function,
		change_function = function (pass_content, style_data, animations, dt)
			local blink_time = (pass_content._blink_time or 0) + dt

			while blink_time > 1 do
				blink_time = blink_time - 1
			end

			style_data.color[1] = blink_time < 0.5 and 255 or 0
			pass_content._blink_time = blink_time
		end
	},
	{
		style_id = "selection_1",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
			offset = {
				0,
				0,
				0
			},
			size_addition = {
				0,
				0
			},
			color = Color.terminal_frame_hover(255, true)
		},
		visibility_function = _selection_visibility_function
	},
	{
		style_id = "selection_2",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
			offset = {
				0,
				0,
				0
			},
			size_addition = {
				0,
				0
			},
			color = Color.terminal_frame_hover(255, true)
		},
		visibility_function = _selection_visibility_function
	},
	{
		style_id = "selection_3",
		pass_type = "rect",
		style = {
			vertical_alignment = "top",
			horizontal_alignment = "left",
			offset = {
				0,
				0,
				0
			},
			size_addition = {
				0,
				0
			},
			color = Color.terminal_frame_hover(255, true)
		},
		visibility_function = _selection_visibility_function
	},
}

return CustomMultiLineTextInput