package com.fountainpdl.comifountain.ui.library;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.Manga;
import java.util.List;

public class LibraryViewModel extends AndroidViewModel {
    private final MangaRepository repo;
    public final MutableLiveData<String> activeCategory = new MutableLiveData<>("All");

    public LibraryViewModel(@NonNull Application app) {
        super(app);
        repo = ((ComiFountainApp) app).getRepository();
    }

    public LiveData<List<Manga>> getLibraryManga()               { return repo.getLibraryManga(); }
    public LiveData<List<Manga>> getLibraryByCategory(String c)  { return repo.getLibraryMangaByCategory(c); }
    public LiveData<List<Manga>> getMangaWithUpdates()           { return repo.getMangaWithUpdates(); }
    public LiveData<Integer>     getUpdatesBadge()               { return repo.getUpdatesBadgeCount(); }
    public void removeFromLibrary(String mangaId)                { repo.removeFromLibrary(mangaId); }
    public void markAllRead(String mangaId)                      { repo.markAllRead(mangaId); }
}
