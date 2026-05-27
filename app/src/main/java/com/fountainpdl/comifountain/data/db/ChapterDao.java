package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.Chapter;
import java.util.List;

@Dao
public interface ChapterDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE) void insertChapter(Chapter c);
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insertChapters(List<Chapter> list);
    @Update void updateChapter(Chapter c);
    @Delete void deleteChapter(Chapter c);

    @Query("DELETE FROM chapters WHERE manga_id = :mangaId")
    void deleteChaptersForManga(String mangaId);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId ORDER BY number DESC")
    LiveData<List<Chapter>> getChaptersForManga(String mangaId);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId ORDER BY number DESC")
    List<Chapter> getChaptersForMangaSync(String mangaId);

    @Query("SELECT * FROM chapters WHERE id = :id LIMIT 1")
    Chapter getChapterById(String id);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId AND is_read = 0 ORDER BY number ASC LIMIT 1")
    Chapter getFirstUnreadChapter(String mangaId);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId AND is_read = 0 AND last_page_read > 0 ORDER BY number DESC LIMIT 1")
    Chapter getResumeChapter(String mangaId);

    @Query("UPDATE chapters SET is_read = 1 WHERE id = :id")   void markRead(String id);
    @Query("UPDATE chapters SET is_read = 0 WHERE id = :id")   void markUnread(String id);
    @Query("UPDATE chapters SET is_read = 1 WHERE manga_id = :mangaId") void markAllRead(String mangaId);
    @Query("UPDATE chapters SET is_read = 0 WHERE manga_id = :mangaId") void markAllUnread(String mangaId);

    @Query("UPDATE chapters SET last_page_read = :page WHERE id = :id")
    void updateLastPageRead(String id, int page);

    @Query("UPDATE chapters SET bookmarked = :b WHERE id = :id")
    void setBookmark(String id, boolean b);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId AND bookmarked = 1 ORDER BY number DESC")
    LiveData<List<Chapter>> getBookmarkedChapters(String mangaId);

    @Query("UPDATE chapters SET downloaded_date = :ts, download_path = :path WHERE id = :id")
    void markDownloaded(String id, long ts, String path);

    @Query("UPDATE chapters SET downloaded_date = 0, download_path = NULL WHERE id = :id")
    void clearDownload(String id);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId AND downloaded_date > 0")
    List<Chapter> getDownloadedChapters(String mangaId);

    @Query("SELECT COUNT(*) FROM chapters WHERE manga_id = :mangaId")             int getTotalCount(String mangaId);
    @Query("SELECT COUNT(*) FROM chapters WHERE manga_id = :mangaId AND is_read = 0") int getUnreadCount(String mangaId);
    @Query("SELECT COUNT(*) FROM chapters WHERE manga_id = :mangaId AND downloaded_date > 0") int getDownloadedCount(String mangaId);
}
