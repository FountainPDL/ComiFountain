package com.fountainpdl.comifountain.services;

import android.app.*;
import android.content.Intent;
import android.os.IBinder;
import androidx.core.app.NotificationCompat;
import com.fountainpdl.comifountain.R;

public class DownloadService extends Service {
    private static final String CH = "cf_downloads";
    @Override public void onCreate() { super.onCreate(); makeChannel(); }
    @Override public int onStartCommand(Intent i, int f, int id) {
        startForeground(1, new NotificationCompat.Builder(this, CH)
            .setSmallIcon(R.drawable.ic_updates).setContentTitle("ComiFountain")
            .setContentText("Downloading…").build());
        return START_NOT_STICKY;
    }
    @Override public IBinder onBind(Intent i) { return null; }
    private void makeChannel() {
        getSystemService(NotificationManager.class).createNotificationChannel(
            new NotificationChannel(CH, "Downloads", NotificationManager.IMPORTANCE_LOW));
    }
}
