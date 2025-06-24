return {
	--Power DI notifications
	mloc_notification_save_files_loaded = {
		en = "PDI: Save files loaded",
		["zh-cn"] = "PDI：已加载存档文件",
		["zh-tw"] = "PDI：已載入存檔文件",
	},
	mloc_notification_data_dup_successful = {
		en = "PDI: Data dump successful",
		["zh-cn"] = "PDI：数据转储成功",
		["zh-tw"] = "PDI：資料匯出成功",
	},
	mloc_notification_user_reports_cleared = {
		en = "PDI: User report templates cleared successfully",
		["zh-cn"] = "PDI：清空用户报告模板成功",
		["zh-tw"] = "PDI：已成功清除使用者報告模板",
	},
	mloc_notification_toggle_force_report_generation = {
		en = "PDI: Force report generation",
		["zh-cn"] = "PDI：强制报告生成",
		["zh-tw"] = "PDI：強制產生報告",
	},
	mloc_enabled = {
		en = "enabled",
		["zh-cn"] = "启用",
		["zh-tw"] = "已啟用",
	},
	mloc_disabled = {
		en = "disabled",
		["zh-cn"] = "禁用",
		["zh-tw"] = "已停用",
	},
	--Mod settings
	mod_description = {
		en = "Framework for collection, transforming, and displaying game statistics",
		["zh-cn"] = "用来收集、转换和显示游戏统计数据的框架",
		["zh-tw"] = "用於收集、轉換並顯示遊戲統計數據的框架",
	},
	open_pdi_view_title = {
		en = "Open Power DI",
		["zh-cn"] = "打开 Power DI",
		["zh-tw"] = "打開 Power DI",
	},
	open_pdi_view_tooltip = {
		en = "Open the main Power DI view",
		["zh-cn"] = "打开 Power DI 主界面",
		["zh-tw"] = "打開 Power DI 主介面",
	},
	debug_dump_title = {
		en = "Dump data",
		["zh-cn"] = "转储数据",
		["zh-tw"] = "匯出資料",
	},
	debug_dump_tooltip = {
		en = "Dump data for debugging",
		["zh-cn"] = "转储用于调试的数据",
		["zh-tw"] = "匯出用於除錯的資料",
	},
	clear_user_reports_title = {
		en = "Clear user report templates",
		["zh-cn"] = "清空用户报告模板",
		["zh-tw"] = "清除使用者報告模板",
	},
	clear_user_reports_tooltip = {
		en = "Will clear all user created and edited reports",
		["zh-cn"] = "将会清空所有由用户创建和编辑的报告",
		["zh-tw"] = "將會清空所有由使用者建立或編輯的報告",
	},
	testing_title = {
		en = "Development testing",
		["zh-cn"] = "开发测试",
		["zh-tw"] = "開發測試",
	},
	testing_tooltip = {
		en = "For development purposes, shouldn't do anything, but don't use just in case I accidentally left some code there ^^",
		["zh-cn"] = "用于开发目的，应该不会执行任何功能，但请勿使用，防止我意外没有清理完这里的代码 ^^",
		["zh-tw"] = "僅供開發測試，理論上不會執行任何功能；為避免尚有遺留程式碼，請勿隨意使用 ^^",
	},
	auto_save_title = {
		en = "Auto save",
		["zh-cn"] = "自动保存",
		["zh-tw"] = "自動儲存",
	},
	auto_save_tooltip = {
		en = "When turned on it will periodically save the recorded session data while in a mission",
		["zh-cn"] = "启用时，将会在任务中定期保存已经录制的会话数据",
		["zh-tw"] = "開啟後，將在任務中定期儲存所記錄的會話數據",
	},
	auto_save_interval_title = {
		en = "Auto save interval",
		["zh-cn"] = "自动保存间隔",
		["zh-tw"] = "自動儲存間隔",
	},
	auto_save_interval_tooltip = {
		en = "Interval between auto saves, in seconds",
		["zh-cn"] = "自动保存操作之间的间隔时间，单位为秒",
		["zh-tw"] = "自動儲存之間的時間間隔（單位：秒）",
	},
	max_cycles_title = {
		en = "Maximum cycles",
		["zh-cn"] = "最大循环次数",
		["zh-tw"] = "最大循環次數",
	},
	max_cycles_tooltip = {
		en = "Maximum coroutine cycles per frame, increasing this number will speed up the data creation, but you risk dropping frames",
		["zh-cn"] = "每帧的最大协程循环次数，增大此值会加快数据创建的速度，但导致掉帧的风险也会增大",
		["zh-tw"] = "每幀可執行的協程最大迴圈次數，調高此值會加快數據處理速度，但可能導致畫面掉幀",
	},
	debug_mode_title = {
		en = "Debug mode",
		["zh-cn"] = "调试模式",
		["zh-tw"] = "除錯模式",
	},
	debug_mode_tooltip = {
		en = "Will print more data to console",
		["zh-cn"] = "将会在控制台输出更多数据",
		["zh-tw"] = "將在控制台輸出更多資訊",
	},
	date_format_title = {
		en = "Date format",
		["zh-cn"] = "日期格式",
		["zh-tw"] = "日期格式",
	},
	date_format_tooltip = {
		en = "Format used when displaying dates",
		["zh-cn"] = "显示日期的格式",
		["zh-tw"] = "顯示日期時所使用的格式",
	},
	DD_MM_YYYY = {
		en = "DD/MM/YYYY",
		["zh-cn"] = "日/月/年",
		["zh-tw"] = "日/月/年",
	},
	MM_DD_YYYY = {
		en = "MM/DD/YYYY",
		["zh-cn"] = "月/日/年",
		["zh-tw"] = "月/日/年",
	},
	YYYY_MM_DD = {
		en = "YYYY/MM/DD",
		["zh-cn"] = "年/月/日",
		["zh-tw"] = "年/月/日",
	},
	toggle_force_report_generation_title = {
		en = "Toggle force report generation",
		["zh-cn"] = "开关强制报告生成",
		["zh-tw"] = "開關強制產生報告",
	},
	toggle_force_report_generation_tooltip = {
		en = "Forces Power DI to generate reports from scratch, bypassing the cache",
		["zh-cn"] = "强制 Power DI 跳过缓存，从零开始生成报告",
		["zh-tw"] = "強制 Power DI 跳過快取，從頭開始生成報告",
	},
	open_ui_on_end_screen_title = {
		en = "Open Power DI on end screen",
		["zh-cn"] = "在结算界面打开 Power DI",
		["zh-tw"] = "在結算畫面開啟 Power DI",
	},
	open_ui_on_end_screen_tooltip = {
		en = "If enabled will automatically open the Power DI ui when entering the end screen.",
		["zh-cn"] = "启用时，将会在进入结算界面时自动打开 Power DI 界面。",
		["zh-tw"] = "啟用時，進入結算畫面時將自動開啟 Power DI 介面。",
	},

	--Static UI
	mloc_sessions = {
		en = "Sessions",
		["zh-cn"] = "会话",
		["zh-tw"] = "會話",
	},
	mloc_session_category = {
		en = "Category: ",
		["zh-cn"] = "类别：",
		["zh-tw"] = "類別：",
	},
	mloc_session_auric = {
		en = "Auric",
		["zh-cn"] = "金级",
		["zh-tw"] = "奧里克級",
	},
	mloc_session_standard = {
		en = "Standard",
		["zh-cn"] = "标准",
		["zh-tw"] = "標準",
	},
	mloc_session_date = {
		en = "Date: ",
		["zh-cn"] = "日期：",
		["zh-tw"] = "日期：",
	},
	mloc_session_start_time = {
		en = "Start time: ",
		["zh-cn"] = "开始时间：",
		["zh-tw"] = "開始時間：",
	},
	mloc_session_duration = {
		en = "Duration: ",
		["zh-cn"] = "时长：",
		["zh-tw"] = "時長：",
	},
	mloc_session_outcome = {
		en = "Outcome: ",
		["zh-cn"] = "结果：",
		["zh-tw"] = "結果：",
	},
	mloc_session_won = {
		en = "Won",
		["zh-cn"] = "成功",
		["zh-tw"] = "成功",
	},
	mloc_session_lost = {
		en = "Lost",
		["zh-cn"] = "失败",
		["zh-tw"] = "失敗",
	},
	mloc_session_resumed = {
		en = "Resumed: ",
		["zh-cn"] = "被恢复：",
		["zh-tw"] = "被恢復：",
	},
	mloc_true = {
		en = "True",
		["zh-cn"] = "是",
		["zh-tw"] = "是",
	},
	mloc_false = {
		en = "False",
		["zh-cn"] = "否",
		["zh-tw"] = "否",
	},
	mloc_n_a = {
		en = "N.a.",
		["zh-cn"] = "无效",
		["zh-tw"] = "不適用",
	},
	mloc_reports = {
		en = "Reports",
		["zh-cn"] = "报告",
		["zh-tw"] = "報告",
	},
	mloc_report_rows = {
		en = "Row order",
		["zh-cn"] = "行排序",
		["zh-tw"] = "行排序",
	},
	mloc_select_session = {
		en = "Sessions",
		["zh-cn"] = "会话",
		["zh-tw"] = "會話",
	},
	mloc_none = {
		en = "None",
		["zh-cn"] = "无",
		["zh-tw"] = "無",
	},
	mloc_edit_report = {
		en = "Edit",
		["zh-cn"] = "编辑",
		["zh-tw"] = "編輯",
	},
	mloc_new_report = {
		en = "New",
		["zh-cn"] = "新建",
		["zh-tw"] = "新增",
	},
	mloc_report_settings = {
		en = "Report settings",
		["zh-cn"] = "报告设置",
		["zh-tw"] = "報告設定",
	},
	mloc_report_name = {
		en = "Name:",
		["zh-cn"] = "名称：",
		["zh-tw"] = "名稱：",
	},
	mloc_template_name = {
		en = "Template:",
		["zh-cn"] = "模板：",
		["zh-tw"] = "模板：",
	},
	mloc_dataset_name = {
		en = "Dataset:",
		["zh-cn"] = "数据集：",
		["zh-tw"] = "資料集：",
	},
	mloc_report_type_name = {
		en = "Report type:",
		["zh-cn"] = "报告类型：",
		["zh-tw"] = "報告類型：",
	},
	mloc_report_type_pivot_table = {
		en = "Pivot table",
		["zh-cn"] = "数据透视表",
		["zh-tw"] = "樞紐分析表",
	},
	mloc_select = {
		en = "Select...",
		["zh-cn"] = "选择...",
		["zh-tw"] = "選擇...",
	},
	mloc_delete_report = {
		en = "Delete report",
		["zh-cn"] = "删除报告",
		["zh-tw"] = "刪除報告",
	},
	mloc_exit_without_saving = {
		en = "Exit without saving",
		["zh-cn"] = "退出而不保存",
		["zh-tw"] = "不儲存直接退出",
	},
	mloc_save_and_exit = {
		en = "Save and exit",
		["zh-cn"] = "保存并退出",
		["zh-tw"] = "儲存並退出",
	},
	mloc_pivot_table_settings = {
		en = "Pivot table settings",
		["zh-cn"] = "数据透视表设置",
		["zh-tw"] = "樞紐分析表設定",
	},
	mloc_expand_first_level = {
		en = "Expand first level:",
		["zh-cn"] = "展开第一层：",
		["zh-tw"] = "展開第一層：",
	},
	mloc_dataset_fields = {
		en = "Dataset fields",
		["zh-cn"] = "数据集字段",
		["zh-tw"] = "資料集欄位",
	},
	mloc_field_type_string = {
		en = "String",
		["zh-cn"] = "字符串",
		["zh-tw"] = "字串",
	},
	mloc_field_type_number = {
		en = "Number",
		["zh-cn"] = "数字",
		["zh-tw"] = "數字",
	},
	mloc_field_type_player = {
		en = "Player",
		["zh-cn"] = "玩家",
		["zh-tw"] = "玩家",
	},
	mloc_edit_item_format_none = {
		en = "None",
		["zh-cn"] = "无",
		["zh-tw"] = "無",
	},
	mloc_edit_item_format_number = {
		en = "Number",
		["zh-cn"] = "数字",
		["zh-tw"] = "數字",
	},
	mloc_edit_item_format_percent = {
		en = "Percent",
		["zh-cn"] = "百分比",
		["zh-tw"] = "百分比",
	},
	mloc_column = {
		en = "Column",
		["zh-cn"] = "列",
		["zh-tw"] = "欄",
	},
	mloc_rows = {
		en = "Rows",
		["zh-cn"] = "行",
		["zh-tw"] = "行",
	},
	mloc_values = {
		en = "Values",
		["zh-cn"] = "值",
		["zh-tw"] = "值",
	},
	mloc_data_filter = {
		en = "Data filter",
		["zh-cn"] = "数据筛选器",
		["zh-tw"] = "資料篩選器",
	},
	mloc_add_calculated_field = {
		en = "Add calculated field",
		["zh-cn"] = "添加计算字段",
		["zh-tw"] = "新增計算欄位",
	},
	mloc_edit_item_label = {
		en = "Label:",
		["zh-cn"] = "标签：",
		["zh-tw"] = "標籤：",
	},
	mloc_edit_item_field = {
		en = "Field:",
		["zh-cn"] = "字段：",
		["zh-tw"] = "欄位：",
	},
	mloc_edit_item_type = {
		en = "Type:",
		["zh-cn"] = "类型：",
		["zh-tw"] = "類型：",
	},
	mloc_edit_item_type_sum = {
		en = "Sum",
		["zh-cn"] = "求和",
		["zh-tw"] = "加總",
	},
	mloc_edit_item_type_count = {
		en = "Count",
		["zh-cn"] = "计数",
		["zh-tw"] = "計數",
	},
	mloc_edit_item_formula = {
		en = "Formula:",
		["zh-cn"] = "公式：",
		["zh-tw"] = "公式：",
	},
	mloc_edit_item_format = {
		en = "Format:",
		["zh-cn"] = "格式：",
		["zh-tw"] = "格式：",
	},
	mloc_edit_item_visible = {
		en = "Visible:",
		["zh-cn"] = "可见：",
		["zh-tw"] = "是否可見：",
	},

	--Report template names
	mloc_attack_report = {
		en = "Attack report",
		["zh-cn"] = "攻击报告",
		["zh-tw"] = "攻擊報告",
	},
	mloc_defense_report = {
		en = "Defense report",
		["zh-cn"] = "防御报告",
		["zh-tw"] = "防禦報告",
	},
	mloc_player_status_report = {
		en = "Player status report",
		["zh-cn"] = "玩家状态报告",
		["zh-tw"] = "玩家狀態報告",
	},
	mloc_player_interactions_report = {
		en = "Player interactions report",
		["zh-cn"] = "玩家交互报告",
		["zh-tw"] = "玩家互動報告",
	},
	mloc_player_tagging_report = {
		en = "Tagging report",
		["zh-cn"] = "标记报告",
		["zh-tw"] = "標記報告",
	},
	mloc_player_suppression_report = {
		en = "Player suppression report",
		["zh-cn"] = "玩家压制报告",
		["zh-tw"] = "玩家壓制報告",
	},
	mloc_player_blocked_report = {
		en = "Player blocked report",
		["zh-cn"] = "玩家格挡报告",
		["zh-tw"] = "玩家格擋報告",
	},
	mloc_player_slots_report = {
		en = "Player slots report",
		["zh-cn"] = "玩家装备栏报告",
		["zh-tw"] = "玩家欄位報告",
	},
	mloc_player_abilities_report = {
		en = "Player abilities report",
		["zh-cn"] = "玩家技能报告",
		["zh-tw"] = "玩家技能報告",
	},
	mloc_player_buffs_report = {
		en = "Player buffs report",
		["zh-cn"] = "玩家状态效果报告",
		["zh-tw"] = "玩家 Buff 報告",
	},
	mloc_player_shots_blocked_report = {
		en = "Player shots blocked report",
		["zh-cn"] = "玩家射击受阻报告",
		["zh-tw"] = "玩家射擊阻擋報告",
	},

	--Dataset template names
	mloc_dataset_attack_reports = {
		en = "Attack reports",
		["zh-cn"] = "攻击报告",
		["zh-tw"] = "攻擊報告",
	},
	mloc_dataset_player_status = {
		en = "Player status",
		["zh-cn"] = "玩家状态",
		["zh-tw"] = "玩家狀態",
	},
	mloc_dataset_player_interactions = {
		en = "Player interactions",
		["zh-cn"] = "玩家交互",
		["zh-tw"] = "玩家互動",
	},
	mloc_dataset_tagging = {
		en = "Tagging",
		["zh-cn"] = "标记",
		["zh-tw"] = "標記",
	},
	mloc_dataset_player_supression = {
		en = "Player suppression",
		["zh-cn"] = "玩家压制",
		["zh-tw"] = "玩家壓制",
	},
	mloc_dataset_blocked_attacks = {
		en = "Blocked attacks",
		["zh-cn"] = "格挡攻击",
		["zh-tw"] = "格擋攻擊",
	},
	mloc_dataset_slot_events = {
		en = "Slots",
		["zh-cn"] = "装备栏",
		["zh-tw"] = "裝備欄",
	},
	mloc_dataset_player_abilities = {
		en = "Player abilities",
		["zh-cn"] = "玩家技能",
		["zh-tw"] = "玩家技能",
	},
	mloc_dataset_player_buffs = {
		en = "Player buffs",
		["zh-cn"] = "玩家状态效果",
		["zh-tw"] = "玩家狀態效果",
	},

	--Custom lookup table values
	mloc_other = {
		en = "Other",
		["zh-cn"] = "其他",
		["zh-tw"] = "其他",
	},
	mloc_1_melee_weapon_damage = {
		en = "Melee weapon damage",
		["zh-cn"] = "近战武器伤害",
		["zh-tw"] = "近戰武器傷害",
	},
	mloc_2_ranged_weapon_damage = {
		en = "Ranged weapon damage",
		["zh-cn"] = "远程武器伤害",
		["zh-tw"] = "遠程武器傷害",
	},
	mloc_3_blitz_damage = {
		en = "Blitz damage",
		["zh-cn"] = "闪击伤害",
		["zh-tw"] = "閃擊傷害",
	},
	mloc_4_combat_ability_damage = {
		en = "Combat ability damage",
		["zh-cn"] = "主动技能伤害",
		["zh-tw"] = "戰鬥技能傷害",
	},
	mloc_5_debuff_damage = {
		--Note: damage from debuffs such as bleeding, burning ect
		en = "Condition damage",
		["zh-cn"] = "状态效果伤害",
		["zh-tw"] = "狀態傷害",
	},
	mloc_6_environmental_damage = {
		en = "Environmental damage",
		["zh-cn"] = "环境伤害",
		["zh-tw"] = "環境傷害",
	},
	mloc_7_other_damage = {
		en = "Other damage",
		["zh-cn"] = "其他伤害",
		["zh-tw"] = "其他傷害",
	},
	mloc_8_minion = {
		en = "Minion",
		["zh-cn"] = "敌人",
		["zh-tw"] = "小兵 / 雜兵",
	},
	mloc_9_companion = {
		en = "Companion",
		--["zh-cn"] = "",
		--["zh-tw"] = "",
	},
	mloc_chaos_faction = {
		en = "Chaos",
		["zh-cn"] = "混沌",
		["zh-tw"] = "混沌魔物",
	},
	mloc_imperium_faction = {
		en = "Imperium",
		["zh-cn"] = "帝国",
		["zh-tw"] = "帝國",
	},
	mloc_player = {
		en = "Player",
		["zh-cn"] = "玩家",
		["zh-tw"] = "玩家",
	},
	mloc_toughness = {
		en = "Toughness",
		["zh-cn"] = "韧性",
		["zh-tw"] = "韌性",
	},
	mloc_elite = {
		en = "Elite",
		["zh-cn"] = "精英",
		["zh-tw"] = "精英",
	},
	mloc_specialist = {
		en = "Specialist",
		["zh-cn"] = "专家",
		["zh-tw"] = "專家",
	},
	mloc_monstrosity = {
		en = "Monstrosity",
		["zh-cn"] = "怪物",
		["zh-tw"] = "巨獸 / 怪物",
	},
	mloc_horde = {
		en = "Horde",
		["zh-cn"] = "群怪",
		["zh-tw"] = "成群小怪",
	},
	mloc_mauler = {
		en = "Mauler",
		["zh-cn"] = "重锤兵",
		["zh-tw"] = "重錘兵",
	},
	mloc_gunner = {
		en = "Gunner",
		["zh-cn"] = "炮手",
		["zh-tw"] = "砲手",
	},
	mloc_hound = {
		en = "Hound",
		["zh-cn"] = "猎犬",
		["zh-tw"] = "瘟疫獵犬",
	},
	mloc_trapper = {
		en = "Trapper",
		["zh-cn"] = "陷阱手",
		["zh-tw"] = "陷阱手",
	},
	mloc_sniper = {
		en = "Sniper",
		["zh-cn"] = "狙击手",
		["zh-tw"] = "狙擊手",
	},
	mloc_rager = {
		en = "Rager",
		["zh-cn"] = "狂暴者",
		["zh-tw"] = "狂暴者",
	},
	mloc_bomber = {
		en = "Bomber",
		["zh-cn"] = "轰炸者",
		["zh-tw"] = "轟炸者",
	},
	mloc_stalker = {
		en = "Stalker",
		["zh-cn"] = "潜行者",
		["zh-tw"] = "潛行者",
	},
	mloc_bruiser = {
		en = "Bruiser",
		["zh-cn"] = "格斗兵",
		["zh-tw"] = "格鬥兵",
	},
	mloc_basic = {
		en = "Basic",
		["zh-cn"] = "基础",
		["zh-tw"] = "基本",
	},
	mloc_flamer = {
		en = "Flamer",
		["zh-cn"] = "火焰兵",
		["zh-tw"] = "火焰兵",
	},
	mloc_burster = {
		en = "Burster",
		["zh-cn"] = "爆破手",
		["zh-tw"] = "爆破手",
	},
	mloc_shooter = {
		en = "Shooter",
		["zh-cn"] = "枪手",
		["zh-tw"] = "槍手",
	},
	mloc_disabled_player_state = {
		en = "Disabled",
		["zh-cn"] = "被控",
		["zh-tw"] = "無法行動",
	},
	mloc_movement_player_state = {
		en = "Movement",
		["zh-cn"] = "移动",
		["zh-tw"] = "移動",
	},
	mloc_combat_ability = {
		en = "Combat ability",
		["zh-cn"] = "主动技能",
		["zh-tw"] = "戰鬥技能",
	},
	mloc_blitz_ability = {
		en = "Blitz ability",
		["zh-cn"] = "闪击技能",
		["zh-tw"] = "閃擊技能",
	},
	mloc_ability_charge_gained = {
		en = "Charge gained",
		["zh-cn"] = "获得使用次数",
		["zh-tw"] = "獲得技能次數",
	},
	mloc_ability_charge_used = {
		en = "Charge used",
		["zh-cn"] = "消耗使用次数",
		["zh-tw"] = "使用技能次數",
	},
	mloc_melee_weapon = {
		en = "Melee weapon",
		["zh-cn"] = "近战武器",
		["zh-tw"] = "近戰武器",
	},
	mloc_ranged_weapon = {
		en = "Ranged weapon",
		["zh-cn"] = "远程武器",
		["zh-tw"] = "遠程武器",
	},
	mloc_curio = {
		en = "Curio",
		["zh-cn"] = "附件",
		["zh-tw"] = "飾品",
	},

	--Report template value labels
	mloc_damage = {
		en = "Damage",
		["zh-cn"] = "伤害",
		["zh-tw"] = "傷害",
	},
	mloc_kills = {
		en = "Kills",
		["zh-cn"] = "击杀",
		["zh-tw"] = "擊殺",
	},
	mloc_crit_percent = {
		en = "Crit percent",
		["zh-cn"] = "暴击百分比",
		["zh-tw"] = "暴擊百分比",
	},
	mloc_weakspot_percent = {
		en = "Weakspot percent",
		["zh-cn"] = "弱点百分比",
		["zh-tw"] = "弱點百分比",
	},
	mloc_damage_received = {
		en = "Damage received",
		["zh-cn"] = "受到伤害",
		["zh-tw"] = "受到的傷害",
	},
	mloc_states = {
		en = "States",
		["zh-cn"] = "状态",
		["zh-tw"] = "狀態",
	},
	mloc_interactions = {
		en = "Interactions",
		["zh-cn"] = "交互",
		["zh-tw"] = "互動",
	},
	mloc_total_tags = {
		en = "Total tags",
		["zh-cn"] = "总标记",
		["zh-tw"] = "總標記次數",
	},
	mloc_suppression = {
		en = "Suppression",
		["zh-cn"] = "压制",
		["zh-tw"] = "壓制",
	},
	mloc_blocked_attacks = {
		en = "Blocked attacks",
		["zh-cn"] = "格挡攻击",
		["zh-tw"] = "格擋攻擊",
	},
	mloc_slot_changes = {
		en = "Slot changes",
		["zh-cn"] = "装备栏切换",
		["zh-tw"] = "裝備欄切換",
	},
	mloc_player_abilities = {
		en = "Player abilities",
		["zh-cn"] = "玩家技能",
		["zh-tw"] = "玩家技能",
	},
	mloc_buff_events = {
		en = "Buff events",
		["zh-cn"] = "状态效果事件",
		["zh-tw"] = "狀態效果事件",
	},
	mloc_player_shots_blocked = {
		en = "Player shots blocked",
		["zh-cn"] = "玩家射击受阻",
		["zh-tw"] = "玩家射擊受阻",
	},
	--Dataset field labels
	attacker_player = {
		en = "Attacking player",
		["zh-cn"] = "攻击者玩家",
		["zh-tw"] = "攻擊者玩家",
	},
	defender_player = {
		en = "Defending player",
		["zh-cn"] = "防御者玩家",
		["zh-tw"] = "防禦者玩家",
	},
	damage_efficiency = {
		en = "Damage efficiency",
		["zh-cn"] = "伤害效率",
		["zh-tw"] = "傷害效率",
	},
	weakspot_hit = {
		en = "Weakspot hit",
		["zh-cn"] = "弱点命中",
		["zh-tw"] = "弱點命中",
	},
	defender_faction = {
		en = "Defender faction",
		["zh-cn"] = "防御者阵营",
		["zh-tw"] = "防禦者陣營",
	},
	attack_result = {
		en = "Attack result",
		["zh-cn"] = "攻击结果",
		["zh-tw"] = "攻擊結果",
	},
	defender_name = {
		en = "Defender name",
		["zh-cn"] = "防御者名称",
		["zh-tw"] = "防禦者名稱",
	},
	attacker_name = {
		en = "Attacker name",
		["zh-cn"] = "攻击者名称",
		["zh-tw"] = "攻擊者名稱",
	},
	damage_category = {
		en = "Damage category",
		["zh-cn"] = "伤害类别",
		["zh-tw"] = "傷害類別",
	},
	time = {
		en = "Time",
		["zh-cn"] = "时间",
		["zh-tw"] = "時間",
	},
	defender_attack_type = {
		en = "Defender attack type",
		["zh-cn"] = "防御者攻击类型",
		["zh-tw"] = "防禦者攻擊類型",
	},
	attacker_armor_type = {
		en = "Attacker armor type",
		["zh-cn"] = "攻击者护甲类型",
		["zh-tw"] = "攻擊者護甲類型",
	},
	defender_armor_type = {
		en = "Defender armor type",
		["zh-cn"] = "防御者护甲类型",
		["zh-tw"] = "防禦者護甲類型",
	},
	defender_type = {
		en = "Defender type",
		["zh-cn"] = "防御者类型",
		["zh-tw"] = "防禦者類型",
	},
	attacker_type = {
		en = "Attacker type",
		["zh-cn"] = "攻击者类型",
		["zh-tw"] = "攻擊者類型",
	},
	critical_hit = {
		en = "Critical hit",
		["zh-cn"] = "暴击命中",
		["zh-tw"] = "暴擊命中",
	},
	attacker_faction = {
		en = "Attacker faction",
		["zh-cn"] = "攻击者阵营",
		["zh-tw"] = "攻擊者陣營",
	},
	damage_profile_name = {
		en = "Damage profile",
		["zh-cn"] = "伤害档案",
		["zh-tw"] = "傷害檔案",
	},
	attacker_attack_type = {
		en = "Attacker attack type",
		["zh-cn"] = "攻击者攻击类型",
		["zh-tw"] = "攻擊者攻擊類型",
	},
	killed = {
		en = "Killed",
		["zh-cn"] = "击杀",
		["zh-tw"] = "擊殺",
	},
	damage = {
		en = "Damage",
		["zh-cn"] = "伤害",
		["zh-tw"] = "傷害",
	},
	attack_type = {
		en = "Attack type",
		["zh-cn"] = "攻击类型",
		["zh-tw"] = "攻擊類型",
	},
	defender_max_health = {
		en = "Defender max health",
		["zh-cn"] = "防御者最大生命值",
		["zh-tw"] = "防禦者最大生命值",
	},
	health_damage = {
		en = "Health damage",
		["zh-cn"] = "生命值伤害",
		["zh-tw"] = "生命值傷害",
	},
	attacker_class = {
		en = "Attacker class",
		["zh-cn"] = "攻击者分类",
		["zh-tw"] = "攻擊者分類",
	},
	defender_class = {
		en = "Defender class",
		["zh-cn"] = "防御者分类",
		["zh-tw"] = "防禦者分類",
	},
	player_name = {
		en = "Player name",
		["zh-cn"] = "玩家名称",
		["zh-tw"] = "玩家名稱",
	},
	player = {
		en = "Player",
		["zh-cn"] = "玩家",
		["zh-tw"] = "玩家",
	},
	state_category = {
		en = "State category",
		["zh-cn"] = "状态类别",
		["zh-tw"] = "狀態類別",
	},
	state_name = {
		en = "State name",
		["zh-cn"] = "状态名称",
		["zh-tw"] = "狀態名稱",
	},
	previous_state_name = {
		en = "Previous state name",
		["zh-cn"] = "上一个状态名称",
		["zh-tw"] = "上一個狀態名稱",
	},
	interactor_name = {
		en = "Interactor name",
		["zh-cn"] = "交互者名称",
		["zh-tw"] = "交互者名稱",
	},
	interactee_name = {
		en = "Interactee name",
		["zh-cn"] = "交互物名称",
		["zh-tw"] = "交互物名稱",
	},
	interactor_player = {
		en = "Interactor player",
		["zh-cn"] = "交互者玩家",
		["zh-tw"] = "交互者玩家",
	},
	interactee_player = {
		en = "Interactee player",
		["zh-cn"] = "交互物玩家",
		["zh-tw"] = "交互物玩家",
	},
	interaction_type = {
		en = "Interaction type",
		["zh-cn"] = "交互类型",
		["zh-tw"] = "交互類型",
	},
	event = {
		en = "Event",
		["zh-cn"] = "事件",
		["zh-tw"] = "事件",
	},
	result = {
		en = "Result",
		["zh-cn"] = "结果",
		["zh-tw"] = "結果",
	},

	target_name = {
		en = "Target name",
		["zh-cn"] = "目标名称",
		["zh-tw"] = "目標名稱",
	},
	target_type = {
		en = "Target type",
		["zh-cn"] = "目标类型",
		["zh-tw"] = "目標類型",
	},
	target_class = {
		en = "Target class",
		["zh-cn"] = "目标分类",
		["zh-tw"] = "目標分類",
	},
	tag_type = {
		en = "Tag type",
		["zh-cn"] = "标记类型",
		["zh-tw"] = "標記類型",
	},
	reason = {
		en = "Reason",
		["zh-cn"] = "原因",
		["zh-tw"] = "原因",
	},
	tag_id = {
		en = "Tag ID",
		["zh-cn"] = "标记 ID",
		["zh-tw"] = "標記 ID",
	},
	suppression_type = {
		en = "Suppression type",
		["zh-cn"] = "压制类型",
		["zh-tw"] = "壓制類型",
	},
	enemy_name = {
		en = "Enemy name",
		["zh-cn"] = "敌人名称",
		["zh-tw"] = "敵人名稱",
	},
	enemy_attack_type = {
		en = "Enemy attack type",
		["zh-cn"] = "敌人攻击类型",
		["zh-tw"] = "敵人攻擊類型",
	},
	enemy_faction = {
		en = "Enemy faction",
		["zh-cn"] = "敌人阵营",
		["zh-tw"] = "敵人陣營",
	},
	enemy_type = {
		en = "Enemy type",
		["zh-cn"] = "敌人类型",
		["zh-tw"] = "敵人類型",
	},
	enemy_class = {
		en = "Enemy class",
		["zh-cn"] = "敌人分类",
		["zh-tw"] = "敵人分類",
	},
	enemy_armor_type = {
		en = "Enemy armor type",
		["zh-cn"] = "敌人护甲类型",
		["zh-tw"] = "敵人護甲類型",
	},
	weapon_template_name = {
		en = "Weapon template name",
		["zh-cn"] = "武器模板名称",
		["zh-tw"] = "武器模板名稱",
	},
	slot_name = {
		en = "Slot name",
		["zh-cn"] = "装备栏名称",
		["zh-tw"] = "裝備欄名稱",
	},
	ability_type = {
		en = "Ability type",
		["zh-cn"] = "技能类型",
		["zh-tw"] = "技能類型",
	},
	charge_delta = {
		en = "Charge delta",
		["zh-cn"] = "使用次数差值",
		["zh-tw"] = "使用次數差值",
	},
	event_type = {
		en = "Event type",
		["zh-cn"] = "事件类型",
		["zh-tw"] = "事件類型",
	},
	template_name = {
		en = "Template name",
		["zh-cn"] = "模板名称",
		["zh-tw"] = "模板名稱",
	},
	buff_category = {
		en = "Buff category",
		["zh-cn"] = "状态效果类别",
		["zh-tw"] = "狀態效果類別",
	},
	class_name = {
		en = "Class name",
		["zh-cn"] = "分类名",
		["zh-tw"] = "分類名",
	},
	icon = {
		en = "Icon",
		["zh-cn"] = "图标",
		["zh-tw"] = "圖標",
	},
	parent_template_name = {
		en = "Parent template name",
		["zh-cn"] = "父模板名称",
		["zh-tw"] = "父模板名稱",
	},
	parent_buff_category = {
		en = "Parent buff category",
		["zh-cn"] = "父状态效果类别",
		["zh-tw"] = "父狀態效果類別",
	},
	parent_class_name = {
		en = "Parent class name",
		["zh-cn"] = "父分类名称",
		["zh-tw"] = "父分類名稱",
	},
	parent_icon = {
		en = "Parent icon",
		["zh-cn"] = "父图标",
		["zh-tw"] = "父圖標",
	},
	source_category = {
		en = "Source category",
		["zh-cn"] = "来源类别",
		["zh-tw"] = "來源類別",
	},
	source_sub_category = {
		en = "Source subcategory",
		["zh-cn"] = "来源子类别",
		["zh-tw"] = "來源子類別",
	},
	source_item_name = {
		en = "Source item name",
		["zh-cn"] = "来源物品名称",
		["zh-tw"] = "來源物品名稱",
	},
	source_icon = {
		en = "Source icon",
		["zh-cn"] = "来源图标",
		["zh-tw"] = "來源圖標",
	},
	source_name = {
		en = "Source name",
		["zh-cn"] = "来源名称",
		["zh-tw"] = "來源名稱",
	},
}
