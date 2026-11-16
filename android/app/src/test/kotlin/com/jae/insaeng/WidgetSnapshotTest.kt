package com.jae.insaeng

import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.layout.Alignment
import androidx.glance.text.FontWeight
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetSnapshotTest {
    private fun fixture(name: String): String =
        requireNotNull(javaClass.classLoader?.getResource("widget_snapshots/$name")) { "Missing fixture $name" }
            .readText()

    @Test
    fun decodesMyDayFixture() {
        val snapshot = requireNotNull(WidgetSnapshot.decode(fixture("my_day.json")))

        assertEquals("myDayWidget", snapshot.pageId)
        val root = snapshot.root
        assertEquals("column", root.type)
        assertEquals("root", root.id)
        assertEquals("start", root.string("alignment"))
        assertEquals("none", root.string("spacing"))
        assertNull(root.tap)
        assertEquals(listOf("button", "expanded"), root.children.map { it.type })

        val title = root.children[0]
        assertEquals("title", title.id)
        assertEquals("My Day", title.string("label"))
        assertEquals(WidgetTap.OpenApp, title.tap)
        assertEquals(emptyList<WidgetNode>(), title.children)

        val body = root.children[1]
        assertEquals("body", body.id)
        assertEquals(1, body.int("flex"))

        val scroll = body.children.single()
        assertEquals("scroll", scroll.type)
        val tasks = scroll.children.single()
        assertEquals("column", tasks.type)
        assertEquals(
            listOf("task-gym", "divider-gym", "task-meeting", "divider-meeting", "task-lunch"),
            tasks.children.map { it.id },
        )
        assertEquals(
            listOf("checkboxTile", "divider", "checkboxTile", "divider", "checkboxTile"),
            tasks.children.map { it.type },
        )

        val meeting = tasks.children[2]
        assertEquals("Team meeting", meeting.string("title"))
        assertEquals("9:00 – 10:30 AM", meeting.string("subtitle"))
        assertEquals(WidgetTap.Event(nodeId = "task-meeting", event = "onChanged"), meeting.tap)

        assertNull(tasks.children[1].tap)
        assertEquals(0, tasks.children[1].props.size)
    }

    @Test
    fun decodesLayoutNodesWithDefaults() {
        val snapshot =
            requireNotNull(
                WidgetSnapshot.decode(
                    """
                    {"pageId":"p","root":{"type":"row","id":"r","children":[
                      {"type":"text","id":"t","props":{"text":"Hi","style":"titleMedium"}},
                      {"type":"spacer","id":"s"},
                      {"type":"container","id":"c","props":{"padding":"md"},"tap":{"type":"unknown"}}
                    ]}}
                    """.trimIndent(),
                ),
            )

        assertEquals(emptyMap<String, Any>(), snapshot.root.props)
        assertEquals(listOf("t", "s", "c"), snapshot.root.children.map { it.id })
        assertEquals("Hi", snapshot.root.children[0].string("text"))
        assertNull(snapshot.root.children[0].int("text"))
        assertNull(snapshot.root.children[2].tap)
    }

    @Test
    fun returnsNullForInvalidSnapshots() {
        assertNull(WidgetSnapshot.decode(""))
        assertNull(WidgetSnapshot.decode("not json"))
        assertNull(WidgetSnapshot.decode("[]"))
        assertNull(WidgetSnapshot.decode("""{"pageId":"p"}"""))
        assertNull(WidgetSnapshot.decode("""{"pageId":"p","root":{"type":"column"}}"""))
        assertNull(WidgetSnapshot.decode("""{"pageId":"p","root":{"type":"column","id":"r","children":[1]}}"""))
    }

    @Test
    fun mapsSpacingTokens() {
        assertEquals(
            listOf(0.dp, 4.dp, 8.dp, 16.dp, 24.dp, 32.dp),
            listOf("none", "xs", "sm", "md", "lg", "xl").map { WidgetSpacing.of(it).size },
        )
        assertEquals(WidgetSpacing.NONE, WidgetSpacing.of(null))
        assertEquals(WidgetSpacing.MD, WidgetSpacing.of("huge", WidgetSpacing.MD))
    }

    @Test
    fun mapsTextStyleTokens() {
        assertEquals(57.sp, WidgetTextStyle.of("displayLarge").size)
        assertEquals(FontWeight.Medium, WidgetTextStyle.of("titleMedium").weight)
        assertEquals(16.sp, WidgetTextStyle.of("titleMedium").size)
        assertEquals(WidgetTextStyle.LABEL_SMALL, WidgetTextStyle.of("labelSmall"))
        assertEquals(WidgetTextStyle.BODY_MEDIUM, WidgetTextStyle.of(null))
        assertEquals(WidgetTextStyle.BODY_MEDIUM, WidgetTextStyle.of("unknown"))
    }

    @Test
    fun mapsAlignmentTokens() {
        assertEquals(Alignment.Horizontal.Start, WidgetAlignment.of("start").horizontal)
        assertEquals(Alignment.Horizontal.CenterHorizontally, WidgetAlignment.of("center").horizontal)
        assertEquals(Alignment.Vertical.Bottom, WidgetAlignment.of("end").vertical)
        assertEquals(WidgetAlignment.STRETCH, WidgetAlignment.of("stretch"))
        assertEquals(WidgetAlignment.START, WidgetAlignment.of(null))
    }
}
