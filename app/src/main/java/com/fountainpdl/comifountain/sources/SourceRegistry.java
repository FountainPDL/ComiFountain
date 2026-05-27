package com.fountainpdl.comifountain.sources;

import android.content.Context;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class SourceRegistry {
    private static SourceRegistry instance;
    private final Map<String, Source> sources = new LinkedHashMap<>();

    private SourceRegistry(Context context) {
        register(new AllMangaSource());
        register(new MangaPumaSource());
        register(new RavenScansSource());
        register(new LocalSource(context));
    }

    public static SourceRegistry getInstance(Context context) {
        if (instance == null)
            synchronized (SourceRegistry.class) {
                if (instance == null)
                    instance = new SourceRegistry(context.getApplicationContext());
            }
        return instance;
    }

    private void register(Source s) { sources.put(s.getId(), s); }
    public Source       getById(String id) { return sources.get(id); }
    public List<Source> getAll()           { return new ArrayList<>(sources.values()); }
    public Source       getDefault()       { return sources.values().iterator().next(); }
}
