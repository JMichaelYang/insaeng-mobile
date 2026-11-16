package com.jae.insaeng

import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.layout.Alignment
import androidx.glance.text.FontWeight
import com.jae.insaeng.views.itemId
import com.jae.insaeng.views.scrollItems
import com.jae.insaeng.views.toAction
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
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
        assertEquals(listOf("expanded"), root.children.map { it.type })

        val body = root.children.single()
        assertEquals("body", body.id)
        assertEquals(1, body.int("flex"))

        val scroll = body.children.single()
        assertEquals("scroll", scroll.type)
        val tasks = scroll.children.single()
        assertEquals("column", tasks.type)
        assertEquals(
            listOf("task-gym", "task-meeting", "task-lunch"),
            tasks.children.map { it.id },
        )
        assertEquals(
            listOf("checkboxTile", "checkboxTile", "checkboxTile"),
            tasks.children.map { it.type },
        )

        val gym = tasks.children[0]
        assertEquals("Gym", gym.string("title"))
        assertNull(gym.string("subtitle"))
        assertEquals("✅", gym.string("emoji"))
        assertEquals(false, gym.boolean("checked"))
        assertEquals(false, gym.boolean("busy"))

        val meeting = tasks.children[1]
        assertEquals("Team meeting", meeting.string("title"))
        assertEquals("9:00 – 10:30 AM", meeting.string("subtitle"))
        assertEquals("✅", meeting.string("emoji"))
        assertEquals(true, meeting.boolean("checked"))
        assertEquals(false, meeting.boolean("busy"))
        assertEquals(WidgetTap.Event(nodeId = "task-meeting", event = "onChanged"), meeting.tap)
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
    fun readsTypedProps() {
        val node =
            WidgetNode.fromJson(
                Json.parseToJsonElement(
                    """{"type":"checkboxTile","id":"t","props":{"checked":true,"busy":"true","title":"T","flex":2}}""",
                ),
            )

        assertEquals(true, node.boolean("checked"))
        assertNull(node.boolean("busy"))
        assertNull(node.boolean("title"))
        assertNull(node.boolean("flex"))
        assertNull(node.boolean("missing"))
    }

    @Test
    fun decodesButtonProps() {
        val button =
            WidgetNode.fromJson(
                Json.parseToJsonElement(
                    """
                    {"type":"button","id":"connectPrompt","tap":{"type":"openApp"},
                     "props":{"label":"Connect Notion in the app","variant":"secondary","loading":true}}
                    """.trimIndent(),
                ),
            )

        assertEquals("Connect Notion in the app", button.string("label"))
        assertEquals(WidgetButtonVariant.SECONDARY, WidgetButtonVariant.of(button.string("variant")))
        assertEquals(true, button.boolean("loading"))
        assertEquals(WidgetTap.OpenApp, button.tap)
    }

    @Test
    fun flattensScrollColumnIntoStableItems() {
        val scroll = requireNotNull(WidgetSnapshot.decode(fixture("my_day.json"))).root.children.single().children.single()
        val items = scroll.scrollItems()

        assertEquals(
            listOf("task-gym", "task-meeting", "task-lunch"),
            items.map { it.id },
        )
        val ids = items.map { it.itemId }
        assertEquals(ids.size, ids.toSet().size)
        assertTrue(ids.all { it >= 0 })
        val again = requireNotNull(WidgetSnapshot.decode(fixture("my_day.json"))).root.children.single().children.single()
        assertEquals(ids, again.scrollItems().map { it.itemId })
        assertNotEquals(WidgetNode(type = "text", id = "a").itemId, WidgetNode(type = "text", id = "b").itemId)
    }

    @Test
    fun scrollsNonColumnChildAsSingleItem() {
        fun node(type: String, id: String, vararg children: WidgetNode) =
            WidgetNode(type = type, id = id, children = children.toList())

        fun itemIds(child: WidgetNode?) =
            (if (child == null) node("scroll", "s") else node("scroll", "s", child)).scrollItems().map { it.id }

        assertEquals(listOf("empty"), itemIds(node("container", "empty", node("text", "emptyText"))))
        assertEquals(emptyList<String>(), itemIds(null))
        assertEquals(emptyList<String>(), itemIds(node("textField", "f")))
        assertEquals(listOf("t"), itemIds(node("column", "c", node("appBar", "bar"), node("checkboxTile", "t"))))
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

    @Test
    fun mapsButtonVariantTokens() {
        assertEquals(WidgetButtonVariant.PRIMARY, WidgetButtonVariant.of("primary"))
        assertEquals(WidgetButtonVariant.SECONDARY, WidgetButtonVariant.of("secondary"))
        assertEquals(WidgetButtonVariant.TEXT, WidgetButtonVariant.of("text"))
        assertEquals(WidgetButtonVariant.PRIMARY, WidgetButtonVariant.of(null))
        assertEquals(WidgetButtonVariant.PRIMARY, WidgetButtonVariant.of("unknown"))
    }

    @Test
    fun mapsOnlyOpenAppTapsToActions() {
        assertNotNull(WidgetTap.OpenApp.toAction())
        assertNull(WidgetTap.Event(nodeId = "task-gym", event = "onChanged").toAction())
        assertNull(null.toAction())
    }
}
