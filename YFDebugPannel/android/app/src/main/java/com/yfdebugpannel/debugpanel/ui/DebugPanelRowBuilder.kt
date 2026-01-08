package com.yfdebugpannel.debugpanel.ui

import com.yfdebugpannel.debugpanel.model.CellItem
import com.yfdebugpannel.debugpanel.model.DebugPanelInfo
import com.yfdebugpannel.debugpanel.model.EnvSection

class DebugPanelRowBuilder(private val info: DebugPanelInfo) {
    fun build(sections: List<EnvSection>): List<PanelRow> {
        val rows = mutableListOf<PanelRow>()
        rows.add(PanelRow.Header("${info.appName} (Build ${info.buildNumber})"))

        sections.forEach { section ->
            rows.add(PanelRow.Header(section.title))
            section.items.forEach { item ->
                rows.add(
                    when (item) {
                        is CellItem.SwitchItem -> PanelRow.SwitchRow(item)
                        is CellItem.StepperItem -> PanelRow.StepperRow(item)
                        is CellItem.SegmentItem -> PanelRow.SegmentRow(item)
                    }
                )
            }
        }
        return rows
    }
}

sealed class PanelRow {
    data class Header(val title: String) : PanelRow()
    data class SwitchRow(val item: CellItem.SwitchItem) : PanelRow()
    data class StepperRow(val item: CellItem.StepperItem) : PanelRow()
    data class SegmentRow(val item: CellItem.SegmentItem) : PanelRow()
}
