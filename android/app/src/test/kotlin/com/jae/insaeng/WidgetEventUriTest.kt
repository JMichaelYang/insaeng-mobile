package com.jae.insaeng

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetEventUriTest {
    @Test
    fun namesTheFlavorPageNodeAndEvent() {
        assertEquals(
            "insaeng://widget/event?flavor=dev&page=myDayWidget&node=task-gym&event=onChanged",
            WidgetEventUri.build("dev", "myDayWidget", WidgetTap.Event(nodeId = "task-gym", event = "onChanged")),
        )
    }

    @Test
    fun encodesReservedCharacters() {
        assertEquals(
            "insaeng://widget/event?flavor=prod&page=a%26b&node=task+1%3D2&event=on%2FTap",
            WidgetEventUri.build("prod", "a&b", WidgetTap.Event(nodeId = "task 1=2", event = "on/Tap")),
        )
    }
}
