package com.fountainpdl.comifountain.ui.common;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;

public class ToastManager {
    private static Toast current;
    private static final Handler H = new Handler(Looper.getMainLooper());

    public static void show(Context c, String msg) {
        H.post(() -> { if (current != null) current.cancel();
            current = Toast.makeText(c.getApplicationContext(), msg, Toast.LENGTH_SHORT);
            current.show(); });
    }

    public static void showLong(Context c, String msg) {
        H.post(() -> { if (current != null) current.cancel();
            current = Toast.makeText(c.getApplicationContext(), msg, Toast.LENGTH_LONG);
            current.show(); });
    }
}
