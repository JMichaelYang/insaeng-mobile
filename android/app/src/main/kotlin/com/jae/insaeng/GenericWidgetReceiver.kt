package com.jae.insaeng

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class GenericWidgetReceiver : HomeWidgetGlanceWidgetReceiver<GenericGlanceWidget>() {
    override val glanceAppWidget = GenericGlanceWidget()
}
