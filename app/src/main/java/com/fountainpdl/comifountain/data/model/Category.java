package com.fountainpdl.comifountain.data.model;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

/** User-created library category (e.g. "Favourites", "Reading"). */
@Entity(tableName = "categories")
public class Category {

    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")       public int    id;
    @ColumnInfo(name = "name")     public String name;
    @ColumnInfo(name = "position") public int    position;

    public Category() {}

    @Ignore
    public Category(String name, int position) {
        this.name     = name;
        this.position = position;
    }
}
