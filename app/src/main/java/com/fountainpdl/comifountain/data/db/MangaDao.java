package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.Manga;
import java.util.List;

@Dao
public interface MangaDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE) void insertManga(Manga m);
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insertAll(List<Manga> list);
    @Update void updateManga(Manga m);
    @Delete void deleteManga(Manga m);

    @Query("DELETE FROM manga WHERE id = :id")
    void deleteMangaById(String id);

    @Query("SELECT * FROM manga WHERE in_library = 1 ORDER BY last_read DESC")
    LiveData<List<Manga>> getLibraryManga();

    @Query("SELECT * FROM manga WHERE in_library = 1 AND categories LIKE '%' || :cat || '%' ORDER BY last_read DESC")
    LiveData<List<Manga>> getLibraryByCategory(String cat);

    @Query("SELECT * FROM manga WHERE in_library = 1 AND unread_count > 0 ORDER BY last_chapter_date DESC")
    LiveData<List<Manga>> getMangaWithUpdates();

    @Query("SELECT * FROM manga WHERE id = :id LIMIT 1")
    Manga getMangaById(String id);

    @Query("SELECT * FROM manga WHERE id = :id LIMIT 1")
    LiveData<Manga> observeMangaById(String id);

    @Query("SELECT in_library FROM manga WHERE id = :id LIMIT 1")
    boolean isInLibrary(String id);

    @Query("SELECT * FROM manga WHERE source_id = :sourceId AND in_library = 1")
    List<Manga> getMangaBySource(String sourceId);

    @Query("UPDATE manga SET in_library = 1, added_date = :ts WHERE id = :id")
    void addToLibrary(String id, long ts);

    @Query("UPDATE manga SET in_library = 0 WHERE id = :id")
    void removeFromLibrary(String id);

    @Query("UPDATE manga SET last_read = :ts WHERE id = :id")
    void updateLastRead(String id, long ts);

    @Query("UPDATE manga SET chapter_count = :total, unread_count = :unread, last_chapter_date = :latestDate WHERE id = :id")
    void updateChapterStats(String id, int total, int unread, long latestDate);

    @Query("UPDATE manga SET categories = :json WHERE id = :id")
    void updateCategories(String id, String json);

    @Query("SELECT * FROM manga WHERE in_library = 1 AND title LIKE '%' || :q || '%' ORDER BY title ASC")
    LiveData<List<Manga>> searchLibrary(String q);

    @Query("SELECT COUNT(*) FROM manga WHERE in_library = 1")
    int getLibraryCount();

    @Query("SELECT COUNT(*) FROM manga WHERE in_library = 1 AND unread_count > 0")

    LiveData<Integer> getUpdatesBadgeCount();

    @Query("SELECT * FROM manga WHERE in_library = 1 ORDER BY last_read DESC")
    List<Manga> getLibraryMangaSync();
}
