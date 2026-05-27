package com.fountainpdl.comifountain.data.model;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.ForeignKey;
import androidx.room.Ignore;
import androidx.room.Index;
import androidx.room.PrimaryKey;

// ─────────────────────────────────────────────────────────────────────────────
// Category — user-created library categories (e.g. "Favourites", "Reading")
// ─────────────────────────────────────────────────────────────────────────────

@Entity(tableName = "categories")
class Category {

    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    public int id;

    @ColumnInfo(name = "name")
    public String name;

    @ColumnInfo(name = "position")
    public int position;        // For drag-to-reorder

    public Category() {}

    @Ignore
    public Category(String name, int position) {
        this.name = name;
        this.position = position;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// HistoryEntry — tracks when a chapter was last read
// ─────────────────────────────────────────────────────────────────────────────

@Entity(
    tableName = "history",
    foreignKeys = {
        @ForeignKey(
            entity = Manga.class,
            parentColumns = "id",
            childColumns = "manga_id",
            onDelete = ForeignKey.CASCADE
        ),
        @ForeignKey(
            entity = Chapter.class,
            parentColumns = "id",
            childColumns = "chapter_id",
            onDelete = ForeignKey.CASCADE
        )
    },
    indices = {
        @Index("manga_id"),
        @Index("chapter_id")
    }
)
class HistoryEntry {

    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    public int id;

    @ColumnInfo(name = "manga_id")
    public String mangaId;

    @ColumnInfo(name = "chapter_id")
    public String chapterId;

    @ColumnInfo(name = "read_at")
    public long readAt;         // Epoch ms

    @ColumnInfo(name = "time_spent_ms")
    public long timeSpentMs;    // How long spent reading (optional tracking)

    public HistoryEntry() {}

    @Ignore
    public HistoryEntry(String mangaId, String chapterId) {
        this.mangaId = mangaId;
        this.chapterId = chapterId;
        this.readAt = System.currentTimeMillis();
    }
}
