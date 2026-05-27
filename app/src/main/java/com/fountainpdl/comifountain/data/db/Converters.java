package com.fountainpdl.comifountain.data.db;

import androidx.room.TypeConverter;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;

/** Lets Room store List<String> as a JSON column (used by Manga.genres, Manga.categories). */
public class Converters {

    private static final Gson GSON = new Gson();
    private static final Type LIST_TYPE = new TypeToken<List<String>>() {}.getType();

    @TypeConverter
    public static String fromList(List<String> list) {
        if (list == null || list.isEmpty()) return "[]";
        return GSON.toJson(list);
    }

    @TypeConverter
    public static List<String> toList(String value) {
        if (value == null || value.isEmpty()) return new ArrayList<>();
        try { return GSON.fromJson(value, LIST_TYPE); }
        catch (Exception e) { return new ArrayList<>(); }
    }
}
