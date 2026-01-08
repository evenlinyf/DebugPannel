package com.yfdebugpannel.debugpanel.ui

import com.yfdebugpannel.debugpanel.model.CellItem
import com.yfdebugpannel.debugpanel.model.DebugPanelInfo
import com.yfdebugpannel.debugpanel.model.EnvSection

object DebugPanelData {
    fun buildInfo(): DebugPanelInfo {
        return DebugPanelInfo(appName = "YFDebugPannel", buildNumber = "1")
    }

    fun buildSections(): List<EnvSection> {
        return listOf(
            EnvSection(
                title = "Environment",
                items = listOf(
                    CellItem.SegmentItem("API Environment", listOf("Dev", "Staging", "Prod"), 0),
                    CellItem.SwitchItem("Enable Logging", true)
                )
            ),
            EnvSection(
                title = "Experiments",
                items = listOf(
                    CellItem.SwitchItem("New Checkout", false),
                    CellItem.StepperItem("Cache Size (MB)", value = 64, min = 0, max = 256)
                )
            )
        )
    }
}
