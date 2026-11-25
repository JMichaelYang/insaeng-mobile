package com.jae.insaeng

import android.content.Context
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import kotlin.time.Duration.Companion.seconds

class WidgetEventWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val uri = inputData.getString(URI_KEY) ?: return Result.failure()
        if (runAttemptCount > 0) return Result.failure()
        return if (WidgetEventEngine.dispatch(applicationContext, uri, timeout)) Result.success() else Result.failure()
    }

    override suspend fun getForegroundInfo(): ForegroundInfo = foregroundInfo(applicationContext)

    companion object {
        const val URI_KEY = "uri"
        const val CHANNEL_ID = "widget_event"
        const val NOTIFICATION_ID = 199

        val timeout = 60.seconds

        fun request(uri: String): OneTimeWorkRequest =
            OneTimeWorkRequestBuilder<WidgetEventWorker>()
                .setInputData(workDataOf(URI_KEY to uri))
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                .build()

        fun enqueue(context: Context, uri: String) {
            WorkManager.getInstance(context).enqueue(request(uri))
        }

        fun foregroundInfo(context: Context): ForegroundInfo {
            NotificationManagerCompat.from(context).createNotificationChannel(
                NotificationChannelCompat
                    .Builder(CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_LOW)
                    .setName(context.getString(R.string.widget_event_channel_name))
                    .build(),
            )
            val notification =
                NotificationCompat
                    .Builder(context, CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_refresh)
                    .setContentTitle(context.getString(R.string.widget_event_notification))
                    .setPriority(NotificationCompat.PRIORITY_LOW)
                    .setOngoing(true)
                    .build()
            return ForegroundInfo(NOTIFICATION_ID, notification)
        }
    }
}
