package com.jae.insaeng

import androidx.annotation.DrawableRes
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.layout.Alignment
import androidx.glance.text.FontWeight

enum class WidgetSpacing(val size: Dp) {
    NONE(0.dp),
    XS(4.dp),
    SM(8.dp),
    MD(16.dp),
    LG(24.dp),
    XL(32.dp),
    ;

    companion object {
        fun of(name: String?, default: WidgetSpacing = NONE): WidgetSpacing =
            entries.firstOrNull { it.name.equals(name, ignoreCase = true) } ?: default
    }
}

enum class WidgetTextStyle(val token: String, val size: TextUnit, val weight: FontWeight) {
    DISPLAY_LARGE("displayLarge", 57.sp, FontWeight.Normal),
    DISPLAY_MEDIUM("displayMedium", 45.sp, FontWeight.Normal),
    DISPLAY_SMALL("displaySmall", 36.sp, FontWeight.Normal),
    HEADLINE_LARGE("headlineLarge", 32.sp, FontWeight.Normal),
    HEADLINE_MEDIUM("headlineMedium", 28.sp, FontWeight.Normal),
    HEADLINE_SMALL("headlineSmall", 24.sp, FontWeight.Normal),
    TITLE_LARGE("titleLarge", 22.sp, FontWeight.Normal),
    TITLE_MEDIUM("titleMedium", 16.sp, FontWeight.Medium),
    TITLE_SMALL("titleSmall", 14.sp, FontWeight.Medium),
    BODY_LARGE("bodyLarge", 16.sp, FontWeight.Normal),
    BODY_MEDIUM("bodyMedium", 14.sp, FontWeight.Normal),
    BODY_SMALL("bodySmall", 12.sp, FontWeight.Normal),
    LABEL_LARGE("labelLarge", 14.sp, FontWeight.Medium),
    LABEL_MEDIUM("labelMedium", 12.sp, FontWeight.Medium),
    LABEL_SMALL("labelSmall", 11.sp, FontWeight.Medium),
    ;

    companion object {
        fun of(name: String?): WidgetTextStyle = entries.firstOrNull { it.token == name } ?: BODY_MEDIUM
    }
}

enum class WidgetAlignment(
    val horizontal: Alignment.Horizontal,
    val vertical: Alignment.Vertical,
) {
    START(Alignment.Horizontal.Start, Alignment.Vertical.Top),
    CENTER(Alignment.Horizontal.CenterHorizontally, Alignment.Vertical.CenterVertically),
    END(Alignment.Horizontal.End, Alignment.Vertical.Bottom),
    STRETCH(Alignment.Horizontal.Start, Alignment.Vertical.Top),
    ;

    companion object {
        fun of(name: String?): WidgetAlignment =
            entries.firstOrNull { it.name.equals(name, ignoreCase = true) } ?: START
    }
}

enum class WidgetButtonVariant {
    PRIMARY,
    SECONDARY,
    TEXT,
    ;

    companion object {
        fun of(name: String?): WidgetButtonVariant =
            entries.firstOrNull { it.name.equals(name, ignoreCase = true) } ?: PRIMARY
    }
}

enum class WidgetIcon(val token: String, @DrawableRes val drawable: Int) {
    EDIT("edit", R.drawable.ic_edit),
    CHEVRON_LEFT("chevronLeft", R.drawable.ic_chevron_left),
    CHEVRON_RIGHT("chevronRight", R.drawable.ic_chevron_right),
    REFRESH("refresh", R.drawable.ic_refresh),
    ;

    companion object {
        fun of(name: String?): WidgetIcon? = entries.firstOrNull { it.token == name }
    }
}
