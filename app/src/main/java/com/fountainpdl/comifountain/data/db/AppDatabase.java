package com.fountainpdl.comifountain.data.db;

import android.content.Context;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.*;

/**
 * Room database singleton — version 1.
 * Access via AppDatabase.getInstance(context).
 *
 * Schema version history:
 *   v1 — manga, chapters, categories, history tables
 */
@Database(
    entities = {
        Manga.class,
        Chapter.class,
        Category.class,
        HistoryEntry.class
    },
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters.class)
public abstract class AppDatabase extends RoomDatabase {

    private static final String DB_NAME = "comifountain.db";

    public abstract MangaDao   mangaDao();
    public abstract ChapterDao chapterDao();

    private static volatile AppDatabase INSTANCE;

    public static AppDatabase getInstance(Context context) {
        if (INSTANCE == null) {
            synchronized (AppDatabase.class) {
                if (INSTANCE == null) {
                    INSTANCE = Room.databaseBuilder(
                            context.getApplicationContext(),
                            AppDatabase.class,
                            DB_NAME)
                        // Add migrations here when schema changes:
                        // .addMigrations(MIGRATION_1_2)
                        .fallbackToDestructiveMigration()  // remove before production release
                        .build();
                }
            }
        }
        return INSTANCE;
    }

    // Template for future migrations:
    // static final Migration MIGRATION_1_2 = new Migration(1, 2) {
    //     @Override public void migrate(SupportSQLiteDatabase db) {
    //         db.execSQL("ALTER TABLE manga ADD COLUMN new_col TEXT");
    //     }
    // };
}
