package com.fountainpdl.comifountain.ui.library;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.*;
import java.util.List;

public class LibraryViewModel extends AndroidViewModel {
    private final MangaRepository repo;

    public LibraryViewModel(@NonNull Application app) {
        super(app);
        repo = ((ComiFountainApp) app).getRepository();
    }

    public LiveData<List<Manga>>    getLibraryManga()              { return repo.getLibraryManga(); }
    public LiveData<List<Manga>>    getLibraryByCategory(String c) { return repo.getLibraryMangaByCategory(c); }
    public LiveData<List<Manga>>    getMangaWithUpdates()          { return repo.getMangaWithUpdates(); }
    public LiveData<Integer>        getUpdatesBadge()              { return repo.getUpdatesBadgeCount(); }
    public LiveData<List<Category>> getCategories()                { return repo.getCategories(); }

    public void removeFromLibrary(String id)                       { repo.removeFromLibrary(id); }
    public void markAllRead(String id)                             { repo.markAllRead(id); }
    public void markAllUnread(String id)                           { repo.markAllUnread(id); }
    public void updateCategories(String id, List<String> cats)     { repo.updateCategories(id, cats); }
    public void addCategory(String name)                           { repo.addCategory(name); }
    public void deleteCategory(Category c)                         { repo.deleteCategory(c); }
}
