package com.fountainpdl.comifountain.ui.reader;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.sources.*;
import java.util.List;
import java.util.concurrent.*;

public class ReaderViewModel extends AndroidViewModel {
    public final MutableLiveData<List<Page>> pages       = new MutableLiveData<>();
    public final MutableLiveData<Integer>    currentPage = new MutableLiveData<>(0);
    public final MutableLiveData<Boolean>    loading     = new MutableLiveData<>(false);
    public final MutableLiveData<String>     error       = new MutableLiveData<>();

    private final MangaRepository repo;
    private final ExecutorService exec = Executors.newSingleThreadExecutor();
    private String chapterId;

    public ReaderViewModel(@NonNull Application app) {
        super(app);
        repo = ((ComiFountainApp) app).getRepository();
    }

    public void load(String mangaId, String chapterId) {
        this.chapterId = chapterId;
        loading.setValue(true);
        exec.execute(() -> {
            try {
                String sourceId = mangaId.substring(0, mangaId.indexOf(':'));
                String rawManga = mangaId.substring(mangaId.indexOf(':') + 1);
                String rawChap  = chapterId.substring(chapterId.indexOf(':') + 1);
                Source source   = SourceRegistry.getInstance(getApplication()).getById(sourceId);
                if (source == null) throw new Exception("Unknown source: " + sourceId);
                List<Page> p = source.getPageList(rawManga, rawChap);
                pages.postValue(p);
                loading.postValue(false);
                repo.markChapterRead(chapterId, mangaId);
            } catch (Exception e) {
                error.postValue("Failed to load pages: " + e.getMessage());
                loading.postValue(false);
            }
        });
    }

    public void updatePage(int index) {
        currentPage.setValue(index);
        repo.updateLastPageRead(chapterId, index);
    }

    public int getTotalPages() {
        List<Page> p = pages.getValue();
        return p != null ? p.size() : 0;
    }
}
