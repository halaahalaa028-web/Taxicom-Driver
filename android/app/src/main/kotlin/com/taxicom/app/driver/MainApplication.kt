package com.taxicom.app.driver

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (manager.getNotificationChannel("sumer_taxi_gps_monitor") == null) {
                val channel = NotificationChannel(
                    "sumer_taxi_gps_monitor",
                    "تتبع موقع السائق",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "إشعار يعمل في الخلفية لتتبع موقع السائق"
                    setSound(null, null)
                    enableVibration(false)
                }
                manager.createNotificationChannel(channel)
            }
        }
    }
}
