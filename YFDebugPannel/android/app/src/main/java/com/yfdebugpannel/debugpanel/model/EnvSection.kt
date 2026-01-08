package com.yfdebugpannel.debugpanel.model

data class EnvSection(
    val title: String,
    val items: List<CellItem>
)

sealed class CellItem(open val label: String) {
    data class SwitchItem(override val label: String, val enabled: Boolean) : CellItem(label)
    data class StepperItem(override val label: String, val value: Int, val min: Int, val max: Int) : CellItem(label)
    data class SegmentItem(override val label: String, val options: List<String>, val selectedIndex: Int) : CellItem(label)
}
