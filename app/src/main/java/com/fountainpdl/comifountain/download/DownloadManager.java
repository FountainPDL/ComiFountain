package com.fountainpdl.comifountain.download;

import android.content.Context;
import android.net.Uri;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.sources.Source;
import com.fountainpdl.comifountain.sources.SourceManager;
import com.fountainpdl.comifountain.ui.common.ToastManager;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import java.io.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * Handles chapter downloads with quality control and location control.
 * Quality modes: original / high (90%) / medium (75%) / low (50%)
 */
public class DownloadManager {

    private static DownloadManager instance;
    private final Context context;
    private final MangaRepository repo;
    private final ExecutorService executor = Executors.newFixedThreadPool(2);
    private final Set<String> activeDownloads = Collections.synchronizedSet(new HashSet<>());

    private DownloadManager(Context context) {
        this.context = context.getApplicationContext();
        this.repo    = new MangaRepository(context);
    }

    public static DownloadManager getInstance(Context context) {
        if (instance == null) synchronized (DownloadManager.class) {
            if (instance == null) instance = new DownloadManager(context);
        }
        return instance;
    }

    /** Queue a chapter for download. */
    public void download(String mangaId, Chapter chapter, DownloadCallback callback) {
        if (activeDownloads.contains(chapter.id)) {
            ToastManager.show(context, "Already downloading: " + chapter.displayName());
            return;
        }
        activeDownloads.add(chapter.id);
        executor.execute(() -> {
            try {
                String sourceId = mangaId.substring(0, mangaId.indexOf(':'));
                String rawManga = mangaId.substring(mangaId.indexOf(':') + 1);
                String rawChap  = chapter.id.substring(chapter.id.indexOf(':') + 1);

                Source source = SourceManager.getInstance(context).getById(sourceId);
                if (source == null) throw new Exception("Source not found: " + sourceId);

                List<Page> pages = source.getPageList(rawManga, rawChap);
                if (pages.isEmpty()) throw new Exception("No pages found");

                File chapDir = getChapterDir(mangaId, chapter);
                chapDir.mkdirs();

                int total = pages.size();
                for (int i = 0; i < total; i++) {
                    Page page = pages.get(i);
                    File imgFile = new File(chapDir, String.format("%03d.jpg", page.index));
                    downloadImage(page.url, imgFile);
                    if (callback != null) callback.onProgress(i + 1, total);
                }

                repo.markDownloaded(chapter.id, chapDir.getAbsolutePath());
                activeDownloads.remove(chapter.id);
                if (callback != null) callback.onComplete(chapter);
            } catch (Exception e) {
                activeDownloads.remove(chapter.id);
                if (callback != null) callback.onError(chapter, e.getMessage());
            }
        });
    }

    /** Delete downloaded chapter files. */
    public void deleteDownload(Chapter chapter) {
        executor.execute(() -> {
            if (chapter.downloadPath != null) {
                deleteDir(new File(chapter.downloadPath));
            }
            repo.clearDownload(chapter.id);
        });
    }

    /** Get resolved download directory for a chapter. */
    private File getChapterDir(String mangaId, Chapter chapter) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        String location = prefs.getDownloadLocation();
        File root = location != null
            ? new File(location)
            : new File(context.getExternalFilesDir(null), "ComiFountain/downloads");
        // Sanitize names for file system
        String mangaName = sanitize(mangaId.substring(mangaId.indexOf(':') + 1));
        String chapName  = sanitize(chapter.displayName());
        return new File(root, mangaName + "/" + chapName);
    }

    private void downloadImage(String url, File outFile) throws Exception {
        if (outFile.exists()) return; // Already downloaded
        AppPreferences prefs = AppPreferences.getInstance(context);
        String quality = prefs.getDownloadQuality();

        Request req = new Request.Builder().url(url)
            .header("User-Agent", "Mozilla/5.0 (Android)").build();
        try (Response resp = new OkHttpClient().newCall(req).execute()) {
            if (!resp.isSuccessful() || resp.body() == null)
                throw new Exception("Download failed: HTTP " + resp.code());
            byte[] bytes = resp.body().bytes();

            // Quality compression (skip for original)
            if (!"original".equals(quality)) {
                int q = "high".equals(quality) ? 90 : "medium".equals(quality) ? 75 : 50;
                android.graphics.Bitmap bmp = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                if (bmp != null) {
                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    bmp.compress(android.graphics.Bitmap.CompressFormat.JPEG, q, bos);
                    bytes = bos.toByteArray();
                    bmp.recycle();
                }
            }
            try (FileOutputStream fos = new FileOutputStream(outFile)) {
                fos.write(bytes);
            }
        }
    }

    private void deleteDir(File dir) {
        if (dir == null || !dir.exists()) return;
        File[] files = dir.listFiles();
        if (files != null) for (File f : files) {
            if (f.isDirectory()) deleteDir(f); else f.delete();
        }
        dir.delete();
    }

    private String sanitize(String name) {
        return name.replaceAll("[^a-zA-Z0-9._\\-]", "_").replaceAll("_{2,}", "_");
    }

    public boolean isDownloading(String chapterId) { return activeDownloads.contains(chapterId); }

    public interface DownloadCallback {
        void onProgress(int downloaded, int total);
        void onComplete(Chapter chapter);
        void onError(Chapter chapter, String error);
    }
}
