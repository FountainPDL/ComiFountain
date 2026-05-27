package com.fountainpdl.comifountain.ui.detail;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.*;
import com.fountainpdl.comifountain.sources.*;
import java.util.List;
import java.util.concurrent.*;

public class MangaDetailViewModel extends AndroidViewModel {
    public enum State { LOADING, READY, ERROR }

    public final MutableLiveData<Manga>         manga     = new MutableLiveData<>();
    public final MutableLiveData<List<Chapter>> chapters  = new MutableLiveData<>();
    public final MutableLiveData<State>         state     = new MutableLiveData<>(State.LOADING);
    public final MutableLiveData<Boolean>       inLibrary = new MutableLiveData<>(false);
    public final MutableLiveData<String>        error     = new MutableLiveData<>();

    private final MangaRepository repo;
    private final ExecutorService exec = Executors.newFixedThreadPool(2);

    public MangaDetailViewModel(@NonNull Application app) {
        super(app);
        repo = ((ComiFountainApp) app).getRepository();
    }

    public void load(String mangaId) {
        exec.execute(() -> {
            try {
                String sourceId = mangaId.substring(0, mangaId.indexOf(':'));
                String rawId    = mangaId.substring(mangaId.indexOf(':') + 1);
                Source source   = SourceRegistry.getInstance(getApplication()).getById(sourceId);
                if (source == null) throw new Exception("Unknown source: " + sourceId);

                Manga detail = source.getMangaDetails(rawId);
                if (detail == null) throw new Exception("Manga not found");
                detail.id = mangaId;
                manga.postValue(detail);
                repo.saveManga(detail);

                List<Chapter> chaps = source.getChapterList(rawId);
                chapters.postValue(chaps);
                if (!chaps.isEmpty()) repo.saveChapters(chaps);

                repo.checkIsInLibrary(mangaId, lib -> inLibrary.postValue(lib));
                state.postValue(State.READY);
            } catch (Exception e) {
                error.postValue(e.getMessage());
                state.postValue(State.ERROR);
            }
        });
    }

    public void toggleLibrary(String mangaId) {
        Boolean lib = inLibrary.getValue();
        if (Boolean.TRUE.equals(lib)) { repo.removeFromLibrary(mangaId); inLibrary.postValue(false); }
        else                          { repo.addToLibrary(mangaId);      inLibrary.postValue(true); }
    }
}
