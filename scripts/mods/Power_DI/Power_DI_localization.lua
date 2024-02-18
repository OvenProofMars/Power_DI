return {
	--Power DI notifications
	mloc_notification_save_files_loaded = {
		en = "PDI: Save files loaded",
		--["zh-cn"] = "",
	},
	mloc_notification_data_dup_successful = {
		en = "PDI: Data dump successful",
		--["zh-cn"] = "",
	},
	mloc_notification_user_reports_cleared = {
		en = "PDI: User report templates cleared successfully",
		--["zh-cn"] = "",
	},
	mloc_notification_toggle_force_report_generation = {
		en = "PDI: Force report generation",
		--["zh-cn"] = "",
	},
	mloc_enabled = {
		en = "enabled",
		--["zh-cn"] = "",
	},
	mloc_disabled = {
		en = "disabled",
		--["zh-cn"] = "",
	},
	--Mod settings
	mod_description = {
		en = "Framework for collection, transforming, and displaying game statistics",
		["zh-cn"] = "收集、转换和显示游戏统计数据的框架",
	},
	open_pdi_view_title = {
		en = "Open Power DI",
		["zh-cn"] = "打开 Power DI",
	},
	open_pdi_view_tooltip = {
		en = "Open the main Power DI view",
		["zh-cn"] = "打开 Power DI 主界面",
	},
	debug_dump_title = {
		en = "Dump data",
		["zh-cn"] = "转储数据",
	},
	debug_dump_tooltip = {
		en = "Dump data for debugging",
		["zh-cn"] = "转储用于调试的数据",
	},
	clear_user_reports_title = {
		en = "Clear user report templates",
		["zh-cn"] = "清空用户报告模板",
	},
	clear_user_reports_tooltip = {
		en = "Will clear all user created and edited reports, will require restart for them to disapear from the ui",
		["zh-cn"] = "将会清空所有由用户创建和编辑的报告，需要重启使它们从界面上消失",
	},
	testing_title = {
		en = "Development testing",
		["zh-cn"] = "开发测试",
	},
	testing_tooltip = {
		en = "For development purposes, shouldn't do anything, but don't use just in case I accidentally left some code there ^^",
		["zh-cn"] = "用于开发目的，应该不会执行任何功能，但请勿使用，防止我意外没有清理完这里的代码 ^^",
	},
	auto_save_title = {
		en = "Auto save",
		["zh-cn"] = "自动保存",
	},
	auto_save_tooltip = {
		en = "When turned on it will periodically save the recorded session data while in a mission",
		["zh-cn"] = "启用时，将会在任务中定期保存已经录制的会话数据",
	},
	auto_save_interval_title = {
		en = "Auto save interval",
		["zh-cn"] = "自动保存间隔",
	},
	auto_save_interval_tooltip = {
		en = "Interval between auto saves, in seconds",
		["zh-cn"] = "自动保存操作之间的间隔时间，单位为秒",
	},
	max_cycles_title = {
		en = "Maximum cycles",
		["zh-cn"] = "最大循环次数",
	},
	max_cycles_tooltip = {
		en = "Maximum coroutine cycles per frame, increasing this number will speed up the data creation, but you risk dropping frames",
		["zh-cn"] = "每帧的最大协程循环次数，增大此值会加快数据创建的速度，但导致掉帧的风险也会增大",
	},
	debug_mode_title = {
		en = "Debug mode",
		["zh-cn"] = "调试模式",
	},
	debug_mode_tooltip = {
		en = "Will print more data to console",
		["zh-cn"] = "将会在控制台输出更多数据",
	},
	date_format_title = {
		en = "Date format",
		["zh-cn"] = "日期格式",
	},
	date_format_tooltip = {
		en = "Format used when displaying dates",
		["zh-cn"] = "显示日期的格式",
	},
	DD_MM_YYYY = {
		en = "DD/MM/YYYY",
		["zh-cn"] = "日/月/年",
	},
	MM_DD_YYYY = {
		en = "MM/DD/YYYY",
		["zh-cn"] = "月/日/年",
	},
	YYYY_MM_DD = {
		en = "YYYY/MM/DD",
		["zh-cn"] = "年/月/日",
	},
	toggle_force_report_generation_title = {
		en = "Toggle force report generation",
		--["zh-cn"] = "",
	},
	toggle_force_report_generation_tooltip = {
		en = "Forces Power DI to generate reports from scratch, bypassing the cache",
		--["zh-cn"] = "",
	},

	--Static UI
	mloc_sessions = {
		en = "Sessions",
		["zh-cn"] = "会话",
	},
	mloc_session_category = {
		en = "Category: ",
		["zh-cn"] = "类别：",
	},
	mloc_session_auric = {
		en = "Auric",
		["zh-cn"] = "金级",
	},
	mloc_session_standard = {
		en = "Standard",
		["zh-cn"] = "标准",
	},
	mloc_session_date = {
		en = "Date: ",
		["zh-cn"] = "日期：",
	},
	mloc_session_start_time = {
		en = "Start time: ",
		["zh-cn"] = "开始时间：",
	},
	mloc_session_duration = {
		en = "Duration: ",
		["zh-cn"] = "时长：",
	},
	mloc_session_outcome = {
		en = "Outcome: ",
		["zh-cn"] = "结果：",
	},
	mloc_session_won = {
		en = "Won",
		["zh-cn"] = "成功",
	},
	mloc_session_lost = {
		en = "Lost",
		["zh-cn"] = "失败",
	},
	mloc_session_resumed = {
		en = "Resumed: ",
		["zh-cn"] = "已恢复：",
	},
	mloc_true = {
		en = "True",
		["zh-cn"] = "是",
	},
	mloc_false = {
		en = "False",
		["zh-cn"] = "否",
	},
	mloc_n_a = {
		en = "N.a.",
		["zh-cn"] = "无效",
	},
	mloc_reports = {
		en = "Reports",
		["zh-cn"] = "报告",
	},
	mloc_report_rows = {
		en = "Row order",
		["zh-cn"] = "行排序",
	},
	mloc_select_session = {
		en = "Sessions",
		["zh-cn"] = "会话",
	},
	mloc_none = {
		en = "None",
		["zh-cn"] = "无",
	},
	mloc_edit_report = {
		en = "Edit",
		["zh-cn"] = "编辑",
	},
	mloc_new_report = {
		en = "New",
		["zh-cn"] = "新建",
	},
	mloc_report_settings = {
		en = "Report settings",
		["zh-cn"] = "报告设置",
	},
	mloc_report_name = {
		en = "Name:",
		["zh-cn"] = "名称：",
	},
	mloc_template_name = {
		en = "Template:",
		["zh-cn"] = "模板：",
	},
	mloc_dataset_name = {
		en = "Dataset:",
		["zh-cn"] = "数据集：",
	},
	mloc_report_type_name = {
		en = "Report type:",
		["zh-cn"] = "报告类型：",
	},
	mloc_report_type_pivot_table = {
		en = "Pivot table",
		["zh-cn"] = "数据透视表",
	},
	mloc_select = {
		en = "Select...",
		["zh-cn"] = "选择...",
	},
	mloc_delete_report = {
		en = "Delete report",
		["zh-cn"] = "删除报告",
	},
	mloc_exit_without_saving = {
		en = "Exit without saving",
		["zh-cn"] = "退出而不保存",
	},
	mloc_save_and_exit = {
		en = "Save and exit",
		["zh-cn"] = "保存并退出",
	},
	mloc_pivot_table_settings = {
		en = "Pivot table settings",
		["zh-cn"] = "数据透视表设置",
	},
	mloc_expand_first_level = {
		en = "Expand first level:",
		["zh-cn"] = "展开第一层",
	},
	mloc_dataset_fields = {
		en = "Dataset fields",
		["zh-cn"] = "数据集字段",
	},
	mloc_field_type_string = {
		en = "String",
		["zh-cn"] = "字符串",
	},
	mloc_field_type_number= {
		en = "Number",
		["zh-cn"] = "数字",
	},
	mloc_field_type_player= {
		en = "Player",
		["zh-cn"] = "玩家",
	},
	mloc_edit_item_format_none= {
		en = "None",
		["zh-cn"] = "无",
	},
	mloc_edit_item_format_number= {
		en = "Number",
		["zh-cn"] = "数字",
	},
	mloc_edit_item_format_percent= {
		en = "Percent",
		["zh-cn"] = "百分比",
	},
	mloc_column = {
		en = "Column",
		["zh-cn"] = "列",
	},
	mloc_rows = {
		en = "Rows",
		["zh-cn"] = "行",
	},
	mloc_values = {
		en = "Values",
		["zh-cn"] = "值",
	},
	mloc_data_filter = {
		en = "Data filter",
		["zh-cn"] = "数据筛选器",
	},
	mloc_add_calculated_field = {
		en = "Add calculated field",
		["zh-cn"] = "添加计算字段 calculated field",
	},
	mloc_edit_item_label = {
		en = "Label:",
		["zh-cn"] = "标签：",
	},
	mloc_edit_item_field = {
		en = "Field:",
		["zh-cn"] = "字段：",
	},
	mloc_edit_item_type = {
		en = "Type:",
		["zh-cn"] = "类型：",
	},
	mloc_edit_item_type_sum = {
		en = "Sum",
		["zh-cn"] = "求和",
	},
	mloc_edit_item_type_count = {
		en = "Count",
		["zh-cn"] = "计数",
	},
	mloc_edit_item_formula = {
		en = "Formula:",
		["zh-cn"] = "公式：",
	},
	mloc_edit_item_format = {
		en = "Format:",
		["zh-cn"] = "格式：",
	},
	mloc_edit_item_visible = {
		en = "Visible:",
		["zh-cn"] = "可见：",
	},

	--Report template names
	mloc_attack_report = {
		en = "Attack report",
		["zh-cn"] = "攻击报告",
	},
	mloc_defense_report = {
		en = "Defense report",
		["zh-cn"] = "防御报告",
	},
	mloc_player_status_report = {
		en = "Player status report",
		["zh-cn"] = "玩家状态报告",
	},
	mloc_player_interactions_report = {
		en = "Player interactions report",
		["zh-cn"] = "玩家交互报告",
	},
	mloc_player_tagging_report = {
		en = "Tagging report",
		["zh-cn"] = "标记报告",
	},
	mloc_player_suppression_report = {
		en = "Player suppression report",
		["zh-cn"] = "玩家压制报告",
	},
	mloc_player_blocked_report = {
		en = "Player blocked report",
		["zh-cn"] = "玩家格挡报告",
	},
	mloc_player_slots_report = {
		en = "Player slots report",
		["zh-cn"] = "玩家装备栏报告",
	},
	mloc_player_abilities_report = {
		en = "Player abilities report",
		["zh-cn"] = "玩家技能报告",
	},
	mloc_player_buffs_report = {
		en = "Player buffs report",
		["zh-cn"] = "玩家状态效果报告",
	},

	--Dataset template names
	mloc_dataset_attack_reports = {
		en = "Attack reports",
		["zh-cn"] = "攻击报告",
	},
	mloc_dataset_player_status = {
		en = "Player status",
		["zh-cn"] = "玩家状态",
	},
	mloc_dataset_player_interactions = {
		en = "Player interactions",
		["zh-cn"] = "玩家交互",
	},
	mloc_dataset_tagging = {
		en = "Tagging",
		["zh-cn"] = "标记",
	},
	mloc_dataset_player_supression = {
		en = "Player suppression",
		["zh-cn"] = "玩家压制",
	},
	mloc_dataset_blocked_attacks = {
		en = "Blocked attacks",
		["zh-cn"] = "格挡攻击",
	},
	mloc_dataset_slot_events = {
		en = "Slots",
		["zh-cn"] = "装备栏",
	},
	mloc_dataset_player_abilities = {
		en = "Player abilities",
		["zh-cn"] = "玩家技能",
	},
	mloc_dataset_player_buffs = {
		en = "Player buffs",
		["zh-cn"] = "玩家状态效果",
	},

	--Custom lookup table values
	mloc_other = {
		en = "Other",
		--["zh-cn"] = "",
	},
	mloc_1_melee_weapon_damage = {
		en = "Melee weapon damage",
		--["zh-cn"] = "",
	},
	mloc_2_ranged_weapon_damage = {
		en = "Ranged weapon damage",
		--["zh-cn"] = "",
	},
	mloc_3_blitz_damage = {
		en = "Blitz damage",
		--["zh-cn"] = "",
	},
	mloc_4_combat_ability_damage = {
		en = "Combat ability damage",
		--["zh-cn"] = "",
	},
	mloc_5_debuff_damage = {
		--Note: damage from debuffs such as bleeding, burning ect
		en = "Condition damage",
		--["zh-cn"] = "",
	},
	mloc_6_environmental_damage = {
		en = "Environmental damage",
		--["zh-cn"] = "",
	},
	mloc_7_other_damage = {
		en = "Other damage",
		--["zh-cn"] = "",
	},
	mloc_8_minion = {
		en = "Minion",
		--["zh-cn"] = "",
	},
	mloc_chaos_faction = {
		en = "Chaos",
		--["zh-cn"] = "",
	},
	mloc_imperium_faction = {
		en = "Imperium",
		--["zh-cn"] = "",
	},
	mloc_player = {
		en = "Player",
		["zh-cn"] = "玩家",
	},
	mloc_toughness = {
		en = "Toughness",
		--["zh-cn"] = "",
	},
	mloc_elite = {
		en = "Elite",
		--["zh-cn"] = "",
	},
	mloc_specialist = {
		en = "Specialist",
		--["zh-cn"] = "",
	},
	mloc_monstrosity = {
		en = "Monstrosity",
		--["zh-cn"] = "",
	},
	mloc_horde = {
		en = "Horde",
		--["zh-cn"] = "",
	},
	mloc_mauler = {
		en = "Mauler",
		--["zh-cn"] = "",
	},
	mloc_gunner = {
		en = "Gunner",
		--["zh-cn"] = "",
	},
	mloc_hound = {
		en = "Hound",
		--["zh-cn"] = "",
	},
	mloc_trapper = {
		en = "Trapper",
		--["zh-cn"] = "",
	},
	mloc_sniper = {
		en = "Sniper",
		--["zh-cn"] = "",
	},
	mloc_rager = {
		en = "Rager",
		--["zh-cn"] = "",
	},
	mloc_bomber = {
		en = "Bomber",
		--["zh-cn"] = "",
	},
	mloc_stalker = {
		en = "Stalker",
		--["zh-cn"] = "",
	},
	mloc_bruiser = {
		en = "Bruiser",
		--["zh-cn"] = "",
	},
	mloc_basic = {
		en = "Basic",
		--["zh-cn"] = "",
	},
	mloc_flamer = {
		en = "Flamer",
		--["zh-cn"] = "",
	},
	mloc_burster = {
		en = "Burster",
		--["zh-cn"] = "",
	},
	mloc_shooter = {
		en = "Shooter",
		--["zh-cn"] = "",
	},
	mloc_disabled_player_state = {
		en = "Disabled",
		--["zh-cn"] = "",
	},
	mloc_movement_player_state = {
		en = "Movement",
		--["zh-cn"] = "",
	},
	mloc_combat_ability = {
		en = "Combat ability",
		--["zh-cn"] = "",
	},
	mloc_blitz_ability = {
		en = "Blitz ability",
		--["zh-cn"] = "",
	},
	mloc_ability_charge_gained = {
		en = "Charge gained",
		--["zh-cn"] = "",
	},
	mloc_ability_charge_used = {
		en = "Charge used",
		--["zh-cn"] = "",
	},
	mloc_melee_weapon = {
		en = "Melee weapon",
		--["zh-cn"] = "",
	},
	mloc_ranged_weapon = {
		en = "Ranged weapon",
		--["zh-cn"] = "",
	},
	mloc_curio = {
		en = "Curio",
		--["zh-cn"] = "",
	},

	--Report template value labels
	mloc_damage = {
		en = "Damage",
		--["zh-cn"] = "",
	},
	mloc_kills = {
		en = "Kills",
		--["zh-cn"] = "",
	},
	mloc_crit_percent = {
		en = "Crit percent",
		--["zh-cn"] = "",
	},
	mloc_weakspot_percent = {
		en = "Weakspot percent",
		--["zh-cn"] = "",
	},
	mloc_damage_received = {
		en = "Damage received",
		--["zh-cn"] = "",
	},
	mloc_states = {
		en = "States",
		--["zh-cn"] = "",
	},
	mloc_interactions = {
		en = "Interactions",
		--["zh-cn"] = "",
	},
	mloc_total_tags = {
		en = "Total tags",
		--["zh-cn"] = "",
	},
	mloc_suppression = {
		en = "Suppression",
		--["zh-cn"] = "",
	},
	mloc_blocked_attacks = {
		en = "Blocked attacks",
		--["zh-cn"] = "",
	},
	mloc_slot_changes = {
		en = "Slot changes",
		--["zh-cn"] = "",
	},
	mloc_player_abilities = {
		en = "Player abilities",
		--["zh-cn"] = "",
	},
	mloc_buff_events = {
		en = "Buff events",
		--["zh-cn"] = "",
	},
	--Dataset field labels
	attacker_player = {
		en = "Attacking player",
		--["zh-cn"] = "",
	},
	defender_player = {
		en = "Defending player",
		--["zh-cn"] = "",
	},
	damage_efficiency = {
		en = "Damage efficiency",
		--["zh-cn"] = "",
	},
	weakspot_hit = {
		en = "Weakspot hit",
		--["zh-cn"] = "",
	},
	defender_faction = {
		en = "Defender faction",
		--["zh-cn"] = "",
	},
	attack_result = {
		en = "Attack result",
		--["zh-cn"] = "",
	},
	defender_name = {
		en = "Defender name",
		--["zh-cn"] = "",
	},
	attacker_name = {
		en = "Attacker_name",
		--["zh-cn"] = "",
	},
	damage_category = {
		en = "Damage category",
		--["zh-cn"] = "",
	},
	time = {
		en = "Time",
		--["zh-cn"] = "",
	},
	defender_attack_type = {
		en = "Defender attack type",
		--["zh-cn"] = "",
	},
	attacker_armor_type = {
		en = "Attacker armor type",
		--["zh-cn"] = "",
	},
	defender_armor_type = {
		en = "Defender armor type",
		--["zh-cn"] = "",
	},
	defender_type = {
		en = "Defender type",
		--["zh-cn"] = "",
	},
	attacker_type = {
		en = "Attacker type",
		--["zh-cn"] = "",
	},
	critical_hit = {
		en = "Critical hit",
		--["zh-cn"] = "",
	},
	attacker_faction = {
		en = "Attacker faction",
		--["zh-cn"] = "",
	},
	damage_profile_name = {
		en = "Damage profile",
		--["zh-cn"] = "",
	},
	attacker_attack_type = {
		en = "Attacker attack type",
		--["zh-cn"] = "",
	},
	killed = {
		en = "Killed",
		--["zh-cn"] = "",
	},
	damage = {
		en = "Damage",
		--["zh-cn"] = "",
	},
	attack_type = {
		en = "Attack type",
		--["zh-cn"] = "",
	},
	defender_max_health = {
		en = "Defender max health",
		--["zh-cn"] = "",
	},
	health_damage = {
		en = "Health damage",
		--["zh-cn"] = "",
	},
	attacker_class = {
		en = "Attacker class",
		--["zh-cn"] = "",
	},
	defender_class = {
		en = "Defender class",
		--["zh-cn"] = "",
	},
	player_name = {
		en = "Player name",
		--["zh-cn"] = "",
	},
	player = {
		en = "Player",
		--["zh-cn"] = "",
	},
	state_category = {
		en = "State category",
		--["zh-cn"] = "",
	},
	state_name = {
		en = "State name",
		--["zh-cn"] = "",
	},
	previous_state_name = {
		en = "Previous state name",
		--["zh-cn"] = "",
	},
	interactor_name = {
		en = "Interactor name",
		--["zh-cn"] = "",
	},
	interactee_name = {
		en = "Interactee name",
		--["zh-cn"] = "",
	},
	interactor_player = {
		en = "Interactor player",
		--["zh-cn"] = "",
	},
	interactee_player = {
		en = "Interactee player",
		--["zh-cn"] = "",
	},
	interaction_type = {
		en = "Interaction type",
		--["zh-cn"] = "",
	},
	event = {
		en = "Event",
		--["zh-cn"] = "",
	},
	result = {
		en = "Result",
		--["zh-cn"] = "",
	},

	target_name = {
		en = "Target name",
		--["zh-cn"] = "",
	},
	target_type = {
		en = "Target type",
		--["zh-cn"] = "",
	},
	target_class = {
		en = "Target class",
		--["zh-cn"] = "",
	},
	tag_type = {
		en = "Tagg type",
		--["zh-cn"] = "",
	},
	reason = {
		en = "Reason",
		--["zh-cn"] = "",
	},
	tag_id = {
		en = "Tag ID",
		--["zh-cn"] = "",
	},
	suppression_type = {
		en = "Suppression type",
		--["zh-cn"] = "",
	},
	enemy_name = {
		en = "Enemy name",
		--["zh-cn"] = "",
	},
	enemy_attack_type = {
		en = "Enemy attack type",
		--["zh-cn"] = "",
	},
	enemy_faction = {
		en = "Enemy faction",
		--["zh-cn"] = "",
	},
	enemy_type = {
		en = "Enemy type",
		--["zh-cn"] = "",
	},
	enemy_class = {
		en = "Enemy class",
		--["zh-cn"] = "",
	},
	enemy_armor_type = {
		en = "Enemy armor type",
		--["zh-cn"] = "",
	},
	weapon_template_name = {
		en = "Weapon template name",
		--["zh-cn"] = "",
	},
	slot_name = {
		en = "Slot name",
		--["zh-cn"] = "",
	},
	ability_type = {
		en = "Ability type",
		--["zh-cn"] = "",
	},
	charge_delta = {
		en = "Charge delta",
		--["zh-cn"] = "",
	},
	event_type = {
		en = "Event type",
		--["zh-cn"] = "",
	},
	template_name = {
		en = "Template name",
		--["zh-cn"] = "",
	},
	buff_category = {
		en = "Buff category",
		--["zh-cn"] = "",
	},
	class_name = {
		en = "Class name",
		--["zh-cn"] = "",
	},
	icon = {
		en = "Icon",
		--["zh-cn"] = "",
	},
	parent_template_name = {
		en = "Parent template name",
		--["zh-cn"] = "",
	},
	parent_buff_category = {
		en = "Parent buff category",
		--["zh-cn"] = "",
	},
	parent_class_name = {
		en = "Parent class name",
		--["zh-cn"] = "",
	},
	parent_icon = {
		en = "Parent icon",
		--["zh-cn"] = "",
	},
	source_category = {
		en = "Source category",
		--["zh-cn"] = "",
	},
	source_sub_category = {
		en = "Source subcategory",
		--["zh-cn"] = "",
	},
	source_item_name = {
		en = "Source item name",
		--["zh-cn"] = "",
	},
	source_icon = {
		en = "Source icon",
		--["zh-cn"] = "",
	},
	source_name = {
		en = "Source name",
		--["zh-cn"] = "",
	},
}
