package com.fountainpdl.comifountain.data.model;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.ForeignKey;
import androidx.room.Ignore;
import androidx.room.Index;
import androidx.room.PrimaryKey;

/** Tracks when a chapter was last read. */
@Entity(
    tableName = "history",
    foreignKeys = {
        @ForeignKey(entity = Manga.class,   parentColumns = "id", childColumns = "manga_id",   onDelete = ForeignKey.CASCADE),
        @ForeignKey(entity = Chapter.class, parentColumns = "id", childColumns = "chapter_id", onDelete = ForeignKey.CASCADE)
    },
    indices = { @Index("manga_id"), @Index("chapter_id") }
)
public class HistoryEntry {

    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")          public int    id;
    @ColumnInfo(name = "manga_id")    public String mangaId;
    @ColumnInfo(name = "chapter_id")  public String chapterId;
    @ColumnInfo(name = "read_at")     public long   readAt;
    @ColumnInfo(name = "time_spent_ms") public long timeSpentMs;

    public HistoryEntry() {}

    @Ignore
    public HistoryEntry(String mangaId, String chapterId) {
        this.mangaId   = mangaId;
        this.chapterId = chapterId;
        this.readAt    = System.currentTimeMillis();
    }
}
