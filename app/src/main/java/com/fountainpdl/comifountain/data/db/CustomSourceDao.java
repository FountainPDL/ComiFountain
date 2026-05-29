package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.CustomSource;
import java.util.List;

@Dao
public interface CustomSourceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insert(CustomSource s);
    @Update void update(CustomSource s);
    @Delete void delete(CustomSource s);
    @Query("SELECT * FROM custom_sources ORDER BY name ASC")
    LiveData<List<CustomSource>> getAll();
    @Query("SELECT * FROM custom_sources WHERE enabled = 1 ORDER BY name ASC")
    List<CustomSource> getAllEnabledSync();
    @Query("SELECT * FROM custom_sources WHERE id = :id LIMIT 1")
    CustomSource getById(String id);
    @Query("UPDATE custom_sources SET enabled = :enabled WHERE id = :id")
    void setEnabled(String id, boolean enabled);
    @Query("UPDATE custom_sources SET base_url = :url WHERE id = :id")
    void updateUrl(String id, String url);
}
