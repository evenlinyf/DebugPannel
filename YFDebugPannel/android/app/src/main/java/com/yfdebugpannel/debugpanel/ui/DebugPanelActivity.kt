package com.yfdebugpannel.debugpanel.ui

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.yfdebugpannel.R

class DebugPanelActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_debug_panel)

        val list = findViewById<RecyclerView>(R.id.debug_panel_list)
        val rows = DebugPanelRowBuilder(DebugPanelData.buildInfo()).build(DebugPanelData.buildSections())

        list.layoutManager = LinearLayoutManager(this)
        list.adapter = DebugPanelAdapter(rows)
    }
}
