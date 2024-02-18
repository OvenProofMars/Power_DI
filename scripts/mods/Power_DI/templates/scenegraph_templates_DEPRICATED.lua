local scenegraph_templates = {}

scenegraph_templates.pdi_main_view = {
    screen = {
        scale = "fit",
        size = {
            1920,
            1080,
        },
    },
    anchor = {
        parent = "screen",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = {0,0},
        position = anchor_position,
    },
    test_block = {
        parent = "report_header",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = sizes.block,
        position = {
            0,
            0,
            0,
        },
    },
    session_header = {
        parent = "anchor",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = sizes.block_header,
        position = {
            0,
            0,
            0,
        },
    },
    session_divider_top = {
        parent = "session_header",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = sizes.block_divider,
        position = {
            0,
            sizes.block_header[2],
            0,
        },
    },
    session_dropdown = {
        parent = "session_header",
        horizontal_alignment = "left",
        vertical_alignment = "bottom",
        size = {sizes.block_header[1],sizes.block_header[2]/2},
        position = {
            0,
            sizes.block_divider[2],
            0,
        },
    },
    session_info = {
        parent = "session_divider_top",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = {sizes.block_area[1], sizes.block_area[2]},
        position = {
            0,
            sizes.block_divider[2],
            0,
        },
    },
    session_divider_bottom = {
        parent = "session_info",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = sizes.block_divider,
        position = {
            0,
            sizes.block_area[2],
            0,
        },
    },
    report_header = {
        parent = "session_divider_bottom",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = sizes.block_header,
        position = {
            0,
            sizes.block_divider[2],
            0,
        },
    },
    report_divider_top = {
        parent = "report_header",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = sizes.block_divider,
        position = {
            0,
            sizes.block_header[2],
            0,
        },
    },
    report_area = {
        parent = "report_divider_top",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = {sizes.block_area[1],sizes.block_area[2]-sizes.block_item[2]},
        position = {
            0,
            sizes.block_divider[2],
            0,
        },
    },
    report_scrollbar = {
        parent = "report_area",
        horizontal_alignment = "right",
        vertical_alignment = "center",
        size = {sizes.block_scrollbar[1], sizes.block_area[2]-sizes.block_item[2]},
        position = {
            sizes.block_scrollbar[1],
            0,
            0,
        },
    },
    report_pivot = {
        parent = "report_area",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = {0,0},
        position = {
            0,
            0,
            0,
        },
    },
    report_item = {
        parent = "report_pivot",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = sizes.block_item,
        position = {
            0,
            0,
            0,
        },
    },
    report_new_divider_top = {
        parent = "report_area",
        horizontal_alignment = "left",
        vertical_alignment = "bottom",
        size = sizes.block_divider,
        position = {
            0,
            sizes.block_divider[2],
            0,
        },
    },
    report_new = {
        parent = "report_new_divider_top",
        horizontal_alignment = "left",
        vertical_alignment = "bottom",
        size = {sizes.block_item[1], sizes.block_item[2]},
        position = {
            0,
            sizes.block_item[2],
            0,
        },
    },
}