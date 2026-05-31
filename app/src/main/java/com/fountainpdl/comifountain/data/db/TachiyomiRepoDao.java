package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.TachiyomiRepo;
import java.util.List;

@Dao
public interface TachiyomiRepoDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insert(TachiyomiRepo r);
    @Delete void delete(TachiyomiRepo r);
    @Query("SELECT * FROM tachiyomi_repos ORDER BY added_at DESC")
    LiveData<List<TachiyomiRepo>> getAll();
    @Query("SELECT * FROM tachiyomi_repos ORDER BY added_at DESC")
    List<TachiyomiRepo> getAllSync();
}
