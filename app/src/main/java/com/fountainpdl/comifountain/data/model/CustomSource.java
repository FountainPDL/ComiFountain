package com.fountainpdl.comifountain.data.model;

import androidx.annotation.NonNull;
import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

/**
 * A user-added source defined by a base URL.
 * The app will attempt to scrape it generically or use known patterns.
 */
@Entity(tableName = "custom_sources")
public class CustomSource {

    @PrimaryKey
    @NonNull
    @ColumnInfo(name = "id")
    public String id = "";              // UUID

    @ColumnInfo(name = "name")          public String  name;
    @ColumnInfo(name = "base_url")      public String  baseUrl;
    @ColumnInfo(name = "search_path")   public String  searchPath;   // e.g. "/?s={query}"
    @ColumnInfo(name = "lang")          public String  lang = "en";
    @ColumnInfo(name = "enabled")       public boolean enabled = true;
    @ColumnInfo(name = "nsfw")          public boolean nsfw = false;
    @ColumnInfo(name = "icon_url")      public String  iconUrl;
    @ColumnInfo(name = "created_at")    public long    createdAt;
    @ColumnInfo(name = "notes")         public String  notes;        // e.g. "switched domain 2025-05"

    public CustomSource() {}

    @Ignore
    public CustomSource(@NonNull String id, String name, String baseUrl, String searchPath) {
        this.id         = id;
        this.name       = name;
        this.baseUrl    = baseUrl;
        this.searchPath = searchPath;
        this.createdAt  = System.currentTimeMillis();
    }
}
