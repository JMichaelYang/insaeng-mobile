package com.jae.insaeng.views

import androidx.glance.Emittable
import androidx.glance.EmittableWithChildren
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.testing.unit.runGlanceAppWidgetUnitTest
import androidx.glance.layout.EmittableRow
import androidx.glance.layout.WidthModifier
import androidx.glance.testing.GlanceNodeMatcher
import androidx.glance.testing.unit.MappedNode
import androidx.glance.unit.Dimension
import com.jae.insaeng.WidgetNode
import com.jae.insaeng.WidgetSnapshot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RowViewTest {
    private fun footer(): WidgetNode {
        val fixture =
            requireNotNull(javaClass.classLoader?.getResource("widget_snapshots/my_day.json")) { "Missing fixture" }
                .readText()
        return requireNotNull(WidgetSnapshot.decode(fixture)).root.children.last()
    }

    private fun renderRow(node: WidgetNode): EmittableRow {
        var row: EmittableRow? = null
        runGlanceAppWidgetUnitTest {
            provideComposable { RowView(node, GlanceModifier) }
            onNode(GlanceNodeMatcher<MappedNode>("is the row") { it.value.emittable is EmittableRow })
                .assert(
                    GlanceNodeMatcher("captures the row") {
                        row = it.value.emittable as EmittableRow
                        true
                    },
                )
        }
        return requireNotNull(row)
    }

    private val Emittable.width: Dimension?
        get() = modifier.foldIn<Dimension?>(null) { width, element -> (element as? WidthModifier)?.width ?: width }

    private fun Emittable.descendants(): List<Emittable> =
        if (this is EmittableWithChildren) children.flatMap { listOf(it) + it.descendants() } else emptyList()

    @Test
    fun laysOutTheFooterEdgeToEdge() {
        val footer = footer()
        assertEquals("footer", footer.id)
        assertEquals(listOf("footerStart", "openClaude"), footer.renderedChildren().map { it.id })

        val row = renderRow(footer.copy(children = footer.children.map { it.copy(tap = null) }))

        assertEquals(2, row.children.size)
        val (slot, button) = row.children
        assertEquals(Dimension.Expand, slot.width)
        assertTrue(slot.descendants().none { it.width == Dimension.Expand })
        assertTrue(button.width != Dimension.Expand && button.width != Dimension.Fill)
    }
}
