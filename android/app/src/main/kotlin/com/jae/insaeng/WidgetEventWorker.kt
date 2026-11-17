package com.jae.insaeng

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
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

    companion object {
        const val URI_KEY = "uri"

        val timeout = 60.seconds

        fun request(uri: String): OneTimeWorkRequest =
            OneTimeWorkRequestBuilder<WidgetEventWorker>()
                .setInputData(workDataOf(URI_KEY to uri))
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .build()

        fun enqueue(context: Context, uri: String) {
            WorkManager.getInstance(context).enqueue(request(uri))
        }
    }
}
