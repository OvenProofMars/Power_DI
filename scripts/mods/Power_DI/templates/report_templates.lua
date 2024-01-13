local mod = get_mod("Power_DI")

local report_templates

--Report templates--
report_templates = {
    player_attack_report = {
        name = "Attack report",
        label = "Attack report",
        dataset_name = "attack_reports",
        report_type = "pivot_table",
        columns = {"attacker_name"},
        rows = {"defender_type", "defender_class", "damage_category",},
        values = {
            {
                field_name = "health_damage",
                type = "sum",
                label = "Damage",
                visible = true,
                format = "number"
            },
            {
                field_name = "killed",
                type = "sum",
                label = "Kills",
                visible = true,
                format = "number"
            },
            {
                field_name = "critical_hit",
                type = "count",
                label = "critical_hit_count",
                visible = false,
                format = "none"
            },
            {
                field_name = "critical_hit",
                type = "sum",
                label = "critical_hit_sum",
                visible = false,
                format = "none"
            },
            {
                field_name = "weakspot_hit",
                type = "count",
                label = "weakspot_hit_count",
                visible = false,
                format = "none"
            },
            {
                field_name = "weakspot_hit",
                type = "sum",
                label = "weakspot_hit_sum",
                visible = false,
                format = "none"
            },
            {
                --field_name = "crit%",
                type = "calculated_field",
                label = "Crit percent",
                visible = true,
                format = "percentage",
                function_string = "critical_hit_sum/critical_hit_count"
            },
            {
                --field_name = "ws%",
                type = "calculated_field",
                label = "Weakspot percent",
                visible = true,
                format = "percentage",
                function_string = "weakspot_hit_sum/weakspot_hit_count"
            },
        },
        filters = {
            "attacker_type = \"Player\" and damage > 0 and defender_class ~ nil and attacker_name ~ nil"
        },
    },
    player_defense_report = {
        name = "Defense report",
        label = "Defense report",
        dataset_name = "attack_reports",
        report_type = "pivot_table",
        columns = {"defender_name"},
        rows = {"attacker_type", "attacker_class"},
        values = {
            {
                field_name = "health_damage",
                type = "sum",
                label = "Damage",
                visible = true,
                format = "number"
            },
        },
        filters = {
            "defender_type = \"Player\" and damage>0 and attacker_class ~ nil and defender_name ~ nil"
        },
    },
    player_status_report = {
        name = "Status report",
        label = "Status report",
        dataset_name = "player_status",
        report_type = "pivot_table",
        columns = {"player_name"},
        rows = {"state_name",},
        values = {
            {
                field_name = "state_name",
                type = "count",
                label = "States",
                visible = true,
                format = "number"
            },
        },
        filters = {
            "player_name ~ nil"
        },
    },
    player_interactions_report = {
        name = "Interactions report",
        label = "Interactions report",
        dataset_name = "player_interactions",
        report_type = "pivot_table",
        columns = {"interactor_name"},
        rows = {"interaction_type", "interactee_name"},
        values = {
            {
                field_name = "interaction_type",
                type = "count",
                label = "Interactions",
                visible = true,
                format = "number"
            },
        },
        filters = {
            "event = \"interaction_stopped\" and result = \"success\" and interaction_type ~ \"default\""
        },
    },
    player_tagging_report = {
        name = "Tagging report",
        label = "Tagging report",
        dataset_name = "tagging",
        report_type = "pivot_table",
        columns = {"player_name"},
        rows = {"tag_type", "target_name"},
        values = {
            {
                field_name = "target_name",
                type = "count",
                label = "Total tags",
                visible = true,
                format = "number"
            },
        },
        filters = {
            "event = \"set smart tag\" and player_name ~ \"nil\""
        },
    },
    player_suppression_report = {
        name = "Suppression report",
        label = "Suppression report",
        dataset_name = "player_suppression",
        report_type = "pivot_table",
        columns = {"player_name"},
        rows = {"suppression_type"},
        values = {
            {
                field_name = "player_name",
                type = "count",
                label = "Suppression",
                visible = true,
                format = "number"
            },
        },
        filters = {},
    },
    player_blocked_report = {
        name = "Block report",
        label = "Block report",
        dataset_name = "blocked_attacks",
        report_type = "pivot_table",
        columns = {"player_name"},
        rows = {"enemy_name"},
        values = {
            {
                field_name = "player_name",
                type = "count",
                label = "Blocks",
                visible = true,
                format = "number"
            },
        },
        filters = {},
    },
    slots_report = {
        name = "Slots report",
        label = "Slots report",
        dataset_name = "slot_events",
        report_type = "pivot_table",
        columns = {"player_name"},
        rows = {"slot_name", "event"},
        values = {
            {
                field_name = "player_name",
                type = "count",
                label = "Slots",
                visible = true,
                format = "number"
            },
        },
        filters = {},
    },
}

return report_templates