package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.Category;
import java.util.List;

@Dao
public interface CategoryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insert(Category c);
    @Update void update(Category c);
    @Delete void delete(Category c);
    @Query("SELECT * FROM categories ORDER BY position ASC")
    LiveData<List<Category>> getAll();
    @Query("SELECT * FROM categories ORDER BY position ASC")
    List<Category> getAllSync();
    @Query("SELECT COUNT(*) FROM categories") int count();
    @Query("UPDATE categories SET position = :pos WHERE id = :id")
    void updatePosition(int id, int pos);
}
