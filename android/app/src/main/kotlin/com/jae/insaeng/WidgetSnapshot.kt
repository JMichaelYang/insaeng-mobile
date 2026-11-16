package com.jae.insaeng

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject

data class WidgetSnapshot(val pageId: String, val root: WidgetNode) {
    companion object {
        fun decode(json: String): WidgetSnapshot? =
            runCatching {
                val obj = Json.parseToJsonElement(json).jsonObject
                WidgetSnapshot(
                    pageId = obj.requireString("pageId"),
                    root = WidgetNode.fromJson(obj.getValue("root")),
                )
            }.getOrNull()
    }
}

data class WidgetNode(
    val type: String,
    val id: String,
    val props: JsonObject = JsonObject(emptyMap()),
    val children: List<WidgetNode> = emptyList(),
    val tap: WidgetTap? = null,
) {
    fun string(key: String): String? = (props[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

    fun int(key: String): Int? = (props[key] as? JsonPrimitive)?.takeUnless { it.isString }?.intOrNull

    companion object {
        fun fromJson(element: JsonElement): WidgetNode {
            val obj = element.jsonObject
            return WidgetNode(
                type = obj.requireString("type"),
                id = obj.requireString("id"),
                props = obj["props"]?.jsonObject ?: JsonObject(emptyMap()),
                children = (obj["children"]?.jsonArray ?: JsonArray(emptyList())).map(::fromJson),
                tap = obj["tap"]?.let(WidgetTap::fromJson),
            )
        }
    }
}

sealed interface WidgetTap {
    data object OpenApp : WidgetTap

    data class Event(val nodeId: String, val event: String) : WidgetTap

    companion object {
        fun fromJson(element: JsonElement): WidgetTap? {
            val obj = element as? JsonObject ?: return null
            return when (obj.optString("type")) {
                "openApp" -> OpenApp
                "event" -> Event(nodeId = obj.requireString("nodeId"), event = obj.requireString("event"))
                else -> null
            }
        }
    }
}

private fun JsonObject.optString(key: String): String? =
    (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

private fun JsonObject.requireString(key: String): String =
    requireNotNull(optString(key)) { "Missing string \"$key\"" }
