package com.fountainpdl.comifountain;

import android.app.Application;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.db.AppDatabase;

/**
 * ComiFountainApp — global Application class.
 * Declared in AndroidManifest as android:name=".ComiFountainApp"
 */
public class ComiFountainApp extends Application {

    private static ComiFountainApp instance;
    private MangaRepository repository;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        // Warm up DB on background thread so first query isn't cold
        new Thread(() -> AppDatabase.getInstance(this)).start();
    }

    public static ComiFountainApp getInstance() { return instance; }

    /** App-scoped repository — shared across all ViewModels via their factory. */
    public MangaRepository getRepository() {
        if (repository == null) repository = new MangaRepository(this);
        return repository;
    }
}
