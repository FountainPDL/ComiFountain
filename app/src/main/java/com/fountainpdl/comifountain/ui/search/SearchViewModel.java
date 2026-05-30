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
    private Future<?> pendingSearch = null;

    public SearchViewModel(@NonNull Application app) {
        super(app);
        Source def = SourceManager.getInstance(app).getDefault();
        sourceId.setValue(def != null ? def.getId() : "allanime");
    }

    public void search(String q, int page) {
        // Cancel any pending search
        if (pendingSearch != null && !pendingSearch.isDone())
            pendingSearch.cancel(true);

        query.setValue(q);
        state.setValue(State.LOADING);

        pendingSearch = executor.submit(() -> {
            try {
                SourceManager mgr    = SourceManager.getInstance(getApplication());
                Source        source = mgr.getById(sourceId.getValue());
                if (source == null) source = mgr.getDefault();

                List<Manga> found = (q == null || q.trim().isEmpty())
                    ? source.browse(page)
                    : source.search(q.trim(), page);

                results.postValue(found != null ? found : new ArrayList<>());
                state.postValue(found != null && !found.isEmpty()
                    ? State.RESULTS : State.RESULTS);
            } catch (Exception e) {
                errorMsg.postValue(e.getMessage());
                state.postValue(State.ERROR);
            }
        });
    }

    /** Switch source and immediately re-run the current query. */
    public void setSource(String id) {
        sourceId.setValue(id);
        results.setValue(new ArrayList<>()); // clear old results instantly
        String q = query.getValue();
        search(q != null ? q : "", 1);
    }

    public String getCurrentQuery() {
        return query.getValue() != null ? query.getValue() : "";
    }
}
