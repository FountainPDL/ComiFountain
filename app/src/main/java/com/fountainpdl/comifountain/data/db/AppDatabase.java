package com.fountainpdl.comifountain.data.db;

import android.content.Context;
import androidx.room.*;
import androidx.room.migration.Migration;
import com.fountainpdl.comifountain.data.model.*;

@Database(
    entities = {
        Manga.class, Chapter.class, Category.class,
        HistoryEntry.class, CustomSource.class, TachiyomiRepo.class
    },
    version = 3,
    exportSchema = true
)
@TypeConverters(Converters.class)
public abstract class AppDatabase extends RoomDatabase {

    private static final String DB_NAME = "comifountain.db";

    public abstract MangaDao         mangaDao();
    public abstract ChapterDao       chapterDao();
    public abstract CategoryDao      categoryDao();
    public abstract HistoryDao       historyDao();
    public abstract CustomSourceDao  customSourceDao();
    public abstract TachiyomiRepoDao tachiyomiRepoDao();

    private static volatile AppDatabase INSTANCE;

    public static AppDatabase getInstance(Context context) {
        if (INSTANCE == null) synchronized (AppDatabase.class) {
            if (INSTANCE == null) {
                INSTANCE = Room.databaseBuilder(
                        context.getApplicationContext(), AppDatabase.class, DB_NAME)
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
                    .fallbackToDestructiveMigration()
                    .build();
            }
        }
        return INSTANCE;
    }

    static final Migration MIGRATION_1_2 = new Migration(1, 2) {
        @Override public void migrate(androidx.sqlite.db.SupportSQLiteDatabase db) {
            db.execSQL("CREATE TABLE IF NOT EXISTS `custom_sources` (" +
                "`id` TEXT NOT NULL PRIMARY KEY, `name` TEXT, `base_url` TEXT, " +
                "`search_path` TEXT, `lang` TEXT, `enabled` INTEGER NOT NULL DEFAULT 1, " +
                "`nsfw` INTEGER NOT NULL DEFAULT 0, `icon_url` TEXT, " +
                "`created_at` INTEGER NOT NULL DEFAULT 0, `notes` TEXT)");
        }
    };

    static final Migration MIGRATION_2_3 = new Migration(2, 3) {
        @Override public void migrate(androidx.sqlite.db.SupportSQLiteDatabase db) {
            db.execSQL("CREATE TABLE IF NOT EXISTS `tachiyomi_repos` (" +
                "`url` TEXT NOT NULL PRIMARY KEY, `name` TEXT, " +
                "`added_at` INTEGER NOT NULL DEFAULT 0)");
        }
    };
}
