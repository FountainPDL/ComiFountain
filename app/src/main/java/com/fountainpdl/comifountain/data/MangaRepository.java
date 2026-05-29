package com.fountainpdl.comifountain.data;

import android.content.Context;
import androidx.lifecycle.LiveData;
import com.fountainpdl.comifountain.data.db.*;
import com.fountainpdl.comifountain.data.model.*;
import com.google.gson.Gson;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MangaRepository {

    private final MangaDao    mangaDao;
    private final ChapterDao  chapterDao;
    private final CategoryDao categoryDao;
    private final HistoryDao  historyDao;
    private final ExecutorService exec = Executors.newFixedThreadPool(4);
    private static final Gson GSON = new Gson();

    public MangaRepository(Context context) {
        AppDatabase db = AppDatabase.getInstance(context);
        mangaDao    = db.mangaDao();
        chapterDao  = db.chapterDao();
        categoryDao = db.categoryDao();
        historyDao  = db.historyDao();
    }

    // ── Library ───────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> getLibraryManga()                      { return mangaDao.getLibraryManga(); }
    public LiveData<List<Manga>> getLibraryMangaByCategory(String cat) { return mangaDao.getLibraryByCategory(cat); }
    public LiveData<List<Manga>> getMangaWithUpdates()                  { return mangaDao.getMangaWithUpdates(); }
    public LiveData<Integer>     getUpdatesBadgeCount()                 { return mangaDao.getUpdatesBadgeCount(); }
    public LiveData<Manga>       observeManga(String id)                { return mangaDao.observeMangaById(id); }

    // ── Manga CRUD ────────────────────────────────────────────────────────────

    public void saveManga(Manga m)              { exec.execute(() -> mangaDao.insertManga(m)); }
    public void saveMangaList(List<Manga> list) { exec.execute(() -> mangaDao.insertAll(list)); }
    public void updateManga(Manga m)            { exec.execute(() -> mangaDao.updateManga(m)); }

    // ── Library management ────────────────────────────────────────────────────

    public void addToLibrary(String id) {
        exec.execute(() -> mangaDao.addToLibrary(id, System.currentTimeMillis()));
    }
    public void removeFromLibrary(String id) {
        exec.execute(() -> mangaDao.removeFromLibrary(id));
    }
    public void checkIsInLibrary(String id, Callback<Boolean> cb) {
        exec.execute(() -> cb.onResult(mangaDao.isInLibrary(id)));
    }
    public void updateLastRead(String id) {
        exec.execute(() -> mangaDao.updateLastRead(id, System.currentTimeMillis()));
    }
    public void updateCategories(String id, List<String> cats) {
        exec.execute(() -> mangaDao.updateCategories(id, GSON.toJson(cats)));
    }

    // ── Chapters ──────────────────────────────────────────────────────────────

    public LiveData<List<Chapter>> getChaptersForManga(String id) {
        return chapterDao.getChaptersForManga(id);
    }
    public void saveChapters(List<Chapter> chapters) {
        exec.execute(() -> {
            chapterDao.insertChapters(chapters);
            if (!chapters.isEmpty()) syncChapterStats(chapters.get(0).mangaId);
        });
    }
    public void getFirstUnreadChapter(String mangaId, Callback<Chapter> cb) {
        exec.execute(() -> cb.onResult(chapterDao.getFirstUnreadChapter(mangaId)));
    }
    public void getResumeChapter(String mangaId, Callback<Chapter> cb) {
        exec.execute(() -> {
            Chapter c = chapterDao.getResumeChapter(mangaId);
            if (c == null) c = chapterDao.getFirstUnreadChapter(mangaId);
            cb.onResult(c);
        });
    }

    // ── Read state ────────────────────────────────────────────────────────────

    public void markChapterRead(String chapId, String mangaId) {
        exec.execute(() -> { chapterDao.markRead(chapId); syncChapterStats(mangaId); });
    }
    public void markChapterUnread(String chapId, String mangaId) {
        exec.execute(() -> { chapterDao.markUnread(chapId); syncChapterStats(mangaId); });
    }
    public void markAllRead(String mangaId) {
        exec.execute(() -> { chapterDao.markAllRead(mangaId); syncChapterStats(mangaId); });
    }
    public void markAllUnread(String mangaId) {
        exec.execute(() -> { chapterDao.markAllUnread(mangaId); syncChapterStats(mangaId); });
    }
    public void updateLastPageRead(String chapId, int page) {
        exec.execute(() -> chapterDao.updateLastPageRead(chapId, page));
    }

    // ── Bookmarks ─────────────────────────────────────────────────────────────

    public void setBookmark(String chapId, boolean b)          { exec.execute(() -> chapterDao.setBookmark(chapId, b)); }
    public LiveData<List<Chapter>> getBookmarkedChapters(String id) { return chapterDao.getBookmarkedChapters(id); }

    // ── Downloads ─────────────────────────────────────────────────────────────

    public void markDownloaded(String chapId, String path) {
        exec.execute(() -> chapterDao.markDownloaded(chapId, System.currentTimeMillis(), path));
    }
    public void clearDownload(String chapId) { exec.execute(() -> chapterDao.clearDownload(chapId)); }

    // ── Categories ────────────────────────────────────────────────────────────

    public LiveData<List<Category>> getCategories() { return categoryDao.getAll(); }

    public void addCategory(String name) {
        exec.execute(() -> {
            int pos = categoryDao.count();
            categoryDao.insert(new Category(name, pos));
        });
    }
    public void deleteCategory(Category c) { exec.execute(() -> categoryDao.delete(c)); }
    public void updateCategoryPosition(int id, int pos) {
        exec.execute(() -> categoryDao.updatePosition(id, pos));
    }

    // ── History ───────────────────────────────────────────────────────────────

    public LiveData<List<HistoryEntry>> getRecentHistory() { return historyDao.getRecent(); }

    public void recordHistory(String mangaId, String chapterId) {
        exec.execute(() -> historyDao.insert(new HistoryEntry(mangaId, chapterId)));
    }
    public void clearHistory() { exec.execute(() -> historyDao.clearAll()); }
    public void clearHistoryForManga(String mangaId) {
        exec.execute(() -> historyDao.clearForManga(mangaId));
    }

    // ── Search ────────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> searchLibrary(String q) { return mangaDao.searchLibrary(q); }

    // ── Internal ─────────────────────────────────────────────────────────────

    private void syncChapterStats(String mangaId) {
        int total  = chapterDao.getTotalCount(mangaId);
        int unread = chapterDao.getUnreadCount(mangaId);
        List<Chapter> chapters = chapterDao.getChaptersForMangaSync(mangaId);
        long latest = 0;
        for (Chapter c : chapters) if (c.date > latest) latest = c.date;
        mangaDao.updateChapterStats(mangaId, total, unread, latest);
    }

    public interface Callback<T> { void onResult(T result); }
}
