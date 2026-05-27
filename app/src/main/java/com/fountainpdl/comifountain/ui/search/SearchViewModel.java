package com.fountainpdl.comifountain.ui.search;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.sources.*;
import java.util.*;
import java.util.concurrent.*;

public class SearchViewModel extends AndroidViewModel {
    public enum State { IDLE, LOADING, RESULTS, ERROR }

    public final MutableLiveData<List<Manga>> results  = new MutableLiveData<>(new ArrayList<>());
    public final MutableLiveData<State>       state    = new MutableLiveData<>(State.IDLE);
    public final MutableLiveData<String>      errorMsg = new MutableLiveData<>();
    public final MutableLiveData<String>      query    = new MutableLiveData<>("");
    public final MutableLiveData<String>      sourceId = new MutableLiveData<>();

    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    public SearchViewModel(@NonNull Application app) {
        super(app);
        Source def = SourceRegistry.getInstance(app).getDefault();
        sourceId.setValue(def != null ? def.getId() : "allanime");
    }

    public void search(String q, int page) {
        query.setValue(q);
        state.setValue(State.LOADING);
        executor.execute(() -> {
            try {
                SourceRegistry reg = SourceRegistry.getInstance(getApplication());
                Source source = reg.getById(sourceId.getValue());
                if (source == null) source = reg.getDefault();
                List<Manga> found = (q == null || q.isEmpty())
                    ? source.browse(page) : source.search(q, page);
                results.postValue(found);
                state.postValue(State.RESULTS);
            } catch (Exception e) {
                errorMsg.postValue(e.getMessage());
                state.postValue(State.ERROR);
            }
        });
    }

    public void setSource(String id) {
        sourceId.setValue(id);
        search(query.getValue(), 1);
    }
}
