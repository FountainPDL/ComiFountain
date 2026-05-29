package com.fountainpdl.comifountain.backup;

import android.content.Context;
import android.net.Uri;
import com.fountainpdl.comifountain.data.db.AppDatabase;
import com.fountainpdl.comifountain.data.model.*;
import com.google.gson.*;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Tachiyomi-style JSON backup and restore.
 *
 * Backup format:
 * {
 *   "version": 2,
 *   "backupManga": [ { manga fields + chapters + categories } ],
 *   "backupCategories": [ { name, order } ]
 * }
 */
public class BackupManager {

    private static final int BACKUP_VERSION = 2;
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    private final Context context;
    private final AppDatabase db;

    public BackupManager(Context context) {
        this.context = context.getApplicationContext();
        this.db      = AppDatabase.getInstance(context);
    }

    // ── Create backup ─────────────────────────────────────────────────────────

    public void createBackup(Uri outputUri, BackupCallback callback) {
        new Thread(() -> {
            try {
                JsonObject root = new JsonObject();
                root.addProperty("version", BACKUP_VERSION);
                root.addProperty("createdAt", System.currentTimeMillis());
                root.addProperty("app", "ComiFountain");

                // Categories
                JsonArray cats = new JsonArray();
                for (Category c : db.categoryDao().getAllSync()) {
                    JsonObject co = new JsonObject();
                    co.addProperty("name", c.name);
                    co.addProperty("position", c.position);
                    cats.add(co);
                }
                root.add("backupCategories", cats);

                // Library manga + chapters
                JsonArray mangaArray = new JsonArray();
                List<Manga> library = db.mangaDao().getLibraryManga().getValue();
                // getLibraryManga() returns LiveData — query synchronously for backup
                // Use a blocking approach via the executor
                List<Manga> allManga = getLibrarySync();
                for (Manga m : allManga) {
                    JsonObject mo = GSON.toJsonTree(m).getAsJsonObject();
                    JsonArray chapArr = new JsonArray();
                    for (Chapter c : db.chapterDao().getChaptersForMangaSync(m.id)) {
                        chapArr.add(GSON.toJsonTree(c));
                    }
                    mo.add("chapters", chapArr);
                    mangaArray.add(mo);
                }
                root.add("backupManga", mangaArray);

                // Write to file
                try (OutputStream os = context.getContentResolver().openOutputStream(outputUri);
                     OutputStreamWriter writer = new OutputStreamWriter(os)) {
                    writer.write(GSON.toJson(root));
                    writer.flush();
                }
                callback.onSuccess("Backup created: " + allManga.size() + " manga");
            } catch (Exception e) {
                callback.onError("Backup failed: " + e.getMessage());
            }
        }).start();
    }

    // ── Restore backup ────────────────────────────────────────────────────────

    public void restoreBackup(Uri inputUri, BackupCallback callback) {
        new Thread(() -> {
            try {
                StringBuilder sb = new StringBuilder();
                try (InputStream is = context.getContentResolver().openInputStream(inputUri);
                     BufferedReader reader = new BufferedReader(new InputStreamReader(is))) {
                    String line;
                    while ((line = reader.readLine()) != null) sb.append(line);
                }

                JsonObject root = JsonParser.parseString(sb.toString()).getAsJsonObject();

                // Restore categories
                if (root.has("backupCategories")) {
                    int pos = 0;
                    for (JsonElement ce : root.getAsJsonArray("backupCategories")) {
                        JsonObject co = ce.getAsJsonObject();
                        Category cat = new Category(co.get("name").getAsString(), pos++);
                        db.categoryDao().insert(cat);
                    }
                }

                // Restore manga + chapters
                int count = 0;
                if (root.has("backupManga")) {
                    for (JsonElement me : root.getAsJsonArray("backupManga")) {
                        Manga m = GSON.fromJson(me, Manga.class);
                        m.inLibrary = true;
                        db.mangaDao().insertManga(m);
                        JsonObject mo = me.getAsJsonObject();
                        if (mo.has("chapters")) {
                            List<Chapter> chapters = new ArrayList<>();
                            for (JsonElement ce : mo.getAsJsonArray("chapters")) {
                                chapters.add(GSON.fromJson(ce, Chapter.class));
                            }
                            db.chapterDao().insertChapters(chapters);
                        }
                        count++;
                    }
                }
                callback.onSuccess("Restored " + count + " manga");
            } catch (Exception e) {
                callback.onError("Restore failed: " + e.getMessage());
            }
        }).start();
    }

    /** Suggested backup file name. */
    public static String suggestFileName() {
        String date = new SimpleDateFormat("yyyy-MM-dd_HHmm", Locale.US).format(new Date());
        return "ComiFountain_backup_" + date + ".json";
    }

    /** Synchronous library query for backup thread. */
    private List<Manga> getLibrarySync() {
        // Raw query since we're already off main thread
        return db.mangaDao().getLibraryMangaSync();
    }

    public interface BackupCallback {
        void onSuccess(String message);
        void onError(String error);
    }
}
