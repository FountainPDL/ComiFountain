package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.HistoryEntry;
import java.util.List;

@Dao
public interface HistoryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insert(HistoryEntry h);
    @Query("DELETE FROM history WHERE manga_id = :mangaId") void clearForManga(String mangaId);
    @Query("DELETE FROM history") void clearAll();
    @Query("SELECT * FROM history ORDER BY read_at DESC LIMIT 200")
    LiveData<List<HistoryEntry>> getRecent();
    @Query("SELECT * FROM history WHERE manga_id = :mangaId ORDER BY read_at DESC")
    List<HistoryEntry> getForManga(String mangaId);
    @Query("SELECT * FROM history WHERE chapter_id = :chapterId ORDER BY read_at DESC LIMIT 1")
    HistoryEntry getForChapter(String chapterId);
}
