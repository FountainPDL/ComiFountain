package com.fountainpdl.comifountain.utils;

import android.content.ContentValues;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.view.View;
import androidx.recyclerview.widget.RecyclerView;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class ScreenshotManager {

    /** Save the current page view as a PNG to the Pictures/ComiFountain folder. */
    public static void saveCurrentPage(Context context, View pageView, SaveCallback callback) {
        new Thread(() -> {
            try {
                Bitmap bitmap = viewToBitmap(pageView);
                Uri uri = saveBitmapToGallery(context, bitmap, "ComiFountain_page");
                callback.onSaved(uri);
            } catch (Exception e) {
                callback.onError(e.getMessage());
            }
        }).start();
    }

    /** Extended screenshot — stitch all visible pages into one tall image. */
    public static void saveExtendedScreenshot(Context context, RecyclerView recycler, SaveCallback callback) {
        new Thread(() -> {
            try {
                // Measure total content height
                int totalHeight = 0;
                int width = recycler.getWidth();
                List<Bitmap> bitmaps = new ArrayList<>();

                for (int i = 0; i < recycler.getChildCount(); i++) {
                    View child = recycler.getChildAt(i);
                    Bitmap b = viewToBitmap(child);
                    bitmaps.add(b);
                    totalHeight += b.getHeight();
                }

                if (bitmaps.isEmpty()) { callback.onError("No pages visible"); return; }

                Bitmap combined = Bitmap.createBitmap(width, totalHeight, Bitmap.Config.ARGB_8888);
                Canvas canvas = new Canvas(combined);
                int y = 0;
                for (Bitmap b : bitmaps) {
                    canvas.drawBitmap(b, 0, y, null);
                    y += b.getHeight();
                    b.recycle();
                }

                Uri uri = saveBitmapToGallery(context, combined, "ComiFountain_extended");
                combined.recycle();
                callback.onSaved(uri);
            } catch (Exception e) {
                callback.onError(e.getMessage());
            }
        }).start();
    }

    private static Bitmap viewToBitmap(View view) {
        Bitmap bitmap = Bitmap.createBitmap(view.getWidth(), view.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        view.draw(canvas);
        return bitmap;
    }

    private static Uri saveBitmapToGallery(Context context, Bitmap bitmap, String baseName) throws IOException {
        String name = baseName + "_" +
            new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date()) + ".png";

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, name);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/png");
            values.put(MediaStore.Images.Media.RELATIVE_PATH,
                Environment.DIRECTORY_PICTURES + "/ComiFountain");
            Uri uri = context.getContentResolver()
                .insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            if (uri == null) throw new IOException("Failed to create MediaStore entry");
            try (OutputStream os = context.getContentResolver().openOutputStream(uri)) {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, os);
            }
            return uri;
        } else {
            File dir = new File(Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES), "ComiFountain");
            if (!dir.exists()) dir.mkdirs();
            File file = new File(dir, name);
            try (FileOutputStream fos = new FileOutputStream(file)) {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);
            }
            return Uri.fromFile(file);
        }
    }

    public interface SaveCallback {
        void onSaved(Uri uri);
        void onError(String error);
    }
}
