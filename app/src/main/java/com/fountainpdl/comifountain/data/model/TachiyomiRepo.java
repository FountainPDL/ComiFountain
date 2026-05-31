package com.fountainpdl.comifountain.data.model;

import androidx.annotation.NonNull;
import androidx.room.*;

/**
 * A Tachiyomi-compatible extension repository URL.
 * Format: https://raw.githubusercontent.com/user/repo/repo/index.min.json
 */
@Entity(tableName = "tachiyomi_repos")
public class TachiyomiRepo {

    @PrimaryKey
    @NonNull
    @ColumnInfo(name = "url")
    public String url = "";

    @ColumnInfo(name = "name")
    public String name;

    @ColumnInfo(name = "added_at")
    public long addedAt;

    public TachiyomiRepo() {}

    public TachiyomiRepo(@NonNull String url, String name) {
        this.url     = url;
        this.name    = name != null ? name : extractName(url);
        this.addedAt = System.currentTimeMillis();
    }

    private String extractName(String url) {
        // Extract "user/repo" from GitHub raw URL
        try {
            String[] parts = url.split("/");
            for (int i = 0; i < parts.length - 1; i++) {
                if ("githubusercontent.com".equals(parts[i]))
                    return parts[i+1] + "/" + parts[i+2];
            }
        } catch (Exception ignored) {}
        return url;
    }
}
