package com.fountainpdl.comifountain.sources;

import android.content.Context;
import com.fountainpdl.comifountain.data.db.AppDatabase;
import com.fountainpdl.comifountain.data.model.CustomSource;
import java.util.*;
import java.util.concurrent.Executors;

/**
 * Central registry for all sources — built-in and user-added.
 * Use this everywhere instead of SourceRegistry.
 */
public class SourceManager {

    private static SourceManager instance;
    private final Context context;
    private final Map<String, Source> sources = new LinkedHashMap<>();

    private SourceManager(Context context) {
        this.context = context.getApplicationContext();
        registerBuiltIn();
        loadCustomSources();
    }

    public static SourceManager getInstance(Context context) {
        if (instance == null) synchronized (SourceManager.class) {
            if (instance == null) instance = new SourceManager(context.getApplicationContext());
        }
        return instance;
    }

    private void registerBuiltIn() {
        register(new AllMangaSource());
        register(new MangaPumaSource());
        register(new RavenScansSource());
        register(new LocalSource(context));
    }

    /** Load user-saved custom sources from DB on background thread. */
    public void loadCustomSources() {
        Executors.newSingleThreadExecutor().execute(() -> {
            List<CustomSource> customs = AppDatabase.getInstance(context)
                .customSourceDao().getAllEnabledSync();
            for (CustomSource cs : customs) {
                sources.put("custom_" + cs.id, new CustomUrlSource(cs));
            }
        });
    }

    public void register(Source s)           { sources.put(s.getId(), s); }
    public Source getById(String id)         { return sources.get(id); }
    public List<Source> getAll()             { return new ArrayList<>(sources.values()); }
    public List<Source> getBuiltIn() {
        List<Source> list = new ArrayList<>();
        for (Source s : sources.values())
            if (!s.getId().startsWith("custom_")) list.add(s);
        return list;
    }
    public List<Source> getCustom() {
        List<Source> list = new ArrayList<>();
        for (Source s : sources.values())
            if (s.getId().startsWith("custom_")) list.add(s);
        return list;
    }
    public Source getDefault() { return sources.values().iterator().next(); }

    public void addCustomSource(CustomSource cs) {
        AppDatabase.getInstance(context).customSourceDao().insert(cs);
        sources.put("custom_" + cs.id, new CustomUrlSource(cs));
    }

    public void removeCustomSource(String sourceId) {
        String dbId = sourceId.replace("custom_", "");
        Executors.newSingleThreadExecutor().execute(() -> {
            CustomSource cs = AppDatabase.getInstance(context).customSourceDao().getById(dbId);
            if (cs != null) AppDatabase.getInstance(context).customSourceDao().delete(cs);
        });
        sources.remove(sourceId);
    }

    public void updateCustomSourceUrl(String sourceId, String newUrl) {
        String dbId = sourceId.replace("custom_", "");
        Executors.newSingleThreadExecutor().execute(() ->
            AppDatabase.getInstance(context).customSourceDao().updateUrl(dbId, newUrl));
        Source s = sources.get(sourceId);
        if (s instanceof CustomUrlSource) {
            // Reload from DB
            loadCustomSources();
        }
    }
}
