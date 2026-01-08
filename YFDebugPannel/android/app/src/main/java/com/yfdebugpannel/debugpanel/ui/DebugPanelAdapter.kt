package com.yfdebugpannel.debugpanel.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.Spinner
import android.widget.Switch
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.yfdebugpannel.R
import kotlin.math.max
import kotlin.math.min

class DebugPanelAdapter(private val rows: List<PanelRow>) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {
    override fun getItemCount(): Int = rows.size

    override fun getItemViewType(position: Int): Int {
        return when (rows[position]) {
            is PanelRow.Header -> VIEW_HEADER
            is PanelRow.SwitchRow -> VIEW_SWITCH
            is PanelRow.StepperRow -> VIEW_STEPPER
            is PanelRow.SegmentRow -> VIEW_SEGMENT
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val inflater = LayoutInflater.from(parent.context)
        return when (viewType) {
            VIEW_HEADER -> HeaderViewHolder(inflater.inflate(R.layout.item_section_header, parent, false))
            VIEW_SWITCH -> SwitchViewHolder(inflater.inflate(R.layout.item_switch, parent, false))
            VIEW_STEPPER -> StepperViewHolder(inflater.inflate(R.layout.item_stepper, parent, false))
            VIEW_SEGMENT -> SegmentViewHolder(inflater.inflate(R.layout.item_segment, parent, false))
            else -> error("Unknown view type: $viewType")
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (val row = rows[position]) {
            is PanelRow.Header -> (holder as HeaderViewHolder).bind(row)
            is PanelRow.SwitchRow -> (holder as SwitchViewHolder).bind(row)
            is PanelRow.StepperRow -> (holder as StepperViewHolder).bind(row)
            is PanelRow.SegmentRow -> (holder as SegmentViewHolder).bind(row)
        }
    }

    class HeaderViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val title = itemView.findViewById<TextView>(R.id.section_title)

        fun bind(row: PanelRow.Header) {
            title.text = row.title
        }
    }

    class SwitchViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val label = itemView.findViewById<TextView>(R.id.item_label)
        private val toggle = itemView.findViewById<Switch>(R.id.item_switch)

        fun bind(row: PanelRow.SwitchRow) {
            label.text = row.item.label
            toggle.isChecked = row.item.enabled
        }
    }

    class StepperViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val label = itemView.findViewById<TextView>(R.id.item_label)
        private val decrement = itemView.findViewById<Button>(R.id.stepper_decrement)
        private val increment = itemView.findViewById<Button>(R.id.stepper_increment)
        private val valueView = itemView.findViewById<TextView>(R.id.stepper_value)

        fun bind(row: PanelRow.StepperRow) {
            label.text = row.item.label
            var currentValue = row.item.value
            valueView.text = currentValue.toString()

            decrement.setOnClickListener {
                currentValue = max(row.item.min, currentValue - 1)
                valueView.text = currentValue.toString()
            }
            increment.setOnClickListener {
                currentValue = min(row.item.max, currentValue + 1)
                valueView.text = currentValue.toString()
            }
        }
    }

    class SegmentViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val label = itemView.findViewById<TextView>(R.id.item_label)
        private val spinner = itemView.findViewById<Spinner>(R.id.item_spinner)

        fun bind(row: PanelRow.SegmentRow) {
            label.text = row.item.label
            val adapter = ArrayAdapter(itemView.context, android.R.layout.simple_spinner_item, row.item.options)
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
            spinner.adapter = adapter
            spinner.setSelection(row.item.selectedIndex)
        }
    }

    companion object {
        private const val VIEW_HEADER = 0
        private const val VIEW_SWITCH = 1
        private const val VIEW_STEPPER = 2
        private const val VIEW_SEGMENT = 3
    }
}
