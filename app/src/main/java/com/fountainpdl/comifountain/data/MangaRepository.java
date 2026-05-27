package com.fountainpdl.comifountain.data;

import android.content.Context;
import androidx.lifecycle.LiveData;
import com.fountainpdl.comifountain.data.db.AppDatabase;
import com.fountainpdl.comifountain.data.db.ChapterDao;
import com.fountainpdl.comifountain.data.db.MangaDao;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Manga;
import com.google.gson.Gson;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * MangaRepository — single source of truth between UI/ViewModel and the data layer.
 *
 * Threading rules:
 *  - LiveData queries: Room posts to main thread automatically.
 *  - One-shot queries: run on executor, post results via Callback<T>.
 *  - All write ops: run on executor.
 */
public class MangaRepository {

    private final MangaDao   mangaDao;
    private final ChapterDao chapterDao;
    private final ExecutorService exec = Executors.newFixedThreadPool(4);
    private static final Gson GSON = new Gson();

    public MangaRepository(Context context) {
        AppDatabase db = AppDatabase.getInstance(context);
        mangaDao   = db.mangaDao();
        chapterDao = db.chapterDao();
    }

    // ── Library ───────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> getLibraryManga()                        { return mangaDao.getLibraryManga(); }
    public LiveData<List<Manga>> getLibraryMangaByCategory(String cat)   { return mangaDao.getLibraryByCategory(cat); }
    public LiveData<List<Manga>> getMangaWithUpdates()                   { return mangaDao.getMangaWithUpdates(); }
    public LiveData<Integer>     getUpdatesBadgeCount()                  { return mangaDao.getUpdatesBadgeCount(); }
    public LiveData<Manga>       observeManga(String mangaId)            { return mangaDao.observeMangaById(mangaId); }

    // ── Save / Update ─────────────────────────────────────────────────────────

    public void saveManga(Manga m)              { exec.execute(() -> mangaDao.insertManga(m)); }
    public void saveMangaList(List<Manga> list) { exec.execute(() -> mangaDao.insertAll(list)); }
    public void updateManga(Manga m)            { exec.execute(() -> mangaDao.updateManga(m)); }

    // ── Library management ────────────────────────────────────────────────────

    public void addToLibrary(String mangaId) {
        exec.execute(() -> mangaDao.addToLibrary(mangaId, System.currentTimeMillis()));
    }

    public void removeFromLibrary(String mangaId) {
        exec.execute(() -> mangaDao.removeFromLibrary(mangaId));
    }

    public void checkIsInLibrary(String mangaId, Callback<Boolean> cb) {
        exec.execute(() -> cb.onResult(mangaDao.isInLibrary(mangaId)));
    }

    public void updateLastRead(String mangaId) {
        exec.execute(() -> mangaDao.updateLastRead(mangaId, System.currentTimeMillis()));
    }

    public void updateCategories(String mangaId, List<String> cats) {
        exec.execute(() -> mangaDao.updateCategories(mangaId, GSON.toJson(cats)));
    }

    // ── Chapters ──────────────────────────────────────────────────────────────

    public LiveData<List<Chapter>> getChaptersForManga(String mangaId) {
        return chapterDao.getChaptersForManga(mangaId);
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

    public void markChapterRead(String chapterId, String mangaId) {
        exec.execute(() -> { chapterDao.markRead(chapterId); syncChapterStats(mangaId); });
    }

    public void markChapterUnread(String chapterId, String mangaId) {
        exec.execute(() -> { chapterDao.markUnread(chapterId); syncChapterStats(mangaId); });
    }

    public void markAllRead(String mangaId) {
        exec.execute(() -> { chapterDao.markAllRead(mangaId); syncChapterStats(mangaId); });
    }

    public void updateLastPageRead(String chapterId, int page) {
        exec.execute(() -> chapterDao.updateLastPageRead(chapterId, page));
    }

    // ── Bookmarks ─────────────────────────────────────────────────────────────

    public void setBookmark(String chapterId, boolean b)           { exec.execute(() -> chapterDao.setBookmark(chapterId, b)); }
    public LiveData<List<Chapter>> getBookmarkedChapters(String m) { return chapterDao.getBookmarkedChapters(m); }

    // ── Downloads ─────────────────────────────────────────────────────────────

    public void markDownloaded(String chapterId, String path) {
        exec.execute(() -> chapterDao.markDownloaded(chapterId, System.currentTimeMillis(), path));
    }

    public void clearDownload(String chapterId) { exec.execute(() -> chapterDao.clearDownload(chapterId)); }

    // ── Search ────────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> searchLibrary(String query) { return mangaDao.searchLibrary(query); }

    // ── Internal ─────────────────────────────────────────────────────────────

    /** Recompute and persist chapter stats (total, unread, latest date) for a manga. */
    private void syncChapterStats(String mangaId) {
        int    total   = chapterDao.getTotalCount(mangaId);
        int    unread  = chapterDao.getUnreadCount(mangaId);
        List<Chapter> chapters = chapterDao.getChaptersForMangaSync(mangaId);
        long   latest  = 0;
        for (Chapter c : chapters) if (c.date > latest) latest = c.date;
        mangaDao.updateChapterStats(mangaId, total, unread, latest);
    }

    /** Simple async callback for one-shot DB results. */
    public interface Callback<T> {
        void onResult(T result);
    }
}
