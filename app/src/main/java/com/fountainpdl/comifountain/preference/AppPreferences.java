package com.fountainpdl.comifountain.preference;

import android.content.Context;
import android.content.SharedPreferences;

public class AppPreferences {
    private static final String PREFS = "comifountain_prefs";
    private static AppPreferences instance;
    private final SharedPreferences p;

    public static final String KEY_THEME           = "theme";
    public static final String KEY_SUB_THEME       = "sub_theme";
    public static final String KEY_COLOR_PRIMARY   = "color_primary";
    public static final String KEY_COLOR_SECONDARY = "color_secondary";
    public static final String KEY_SHIFT_COLOR1    = "shift_color1";
    public static final String KEY_SHIFT_COLOR2    = "shift_color2";
    public static final String KEY_SHIFT_SPEED     = "shift_speed";
    public static final String KEY_SHIFT_ANGLE     = "shift_angle";
    public static final String KEY_READING_MODE    = "reading_mode";
    public static final String KEY_GRAYSCALE       = "grayscale";
    public static final String KEY_INVERT          = "invert_colors";
    public static final String KEY_CROP_BORDERS    = "crop_borders";
    public static final String KEY_BG_COLOR        = "bg_color";
    public static final String KEY_PRELOAD         = "preload_chapter";
    public static final String KEY_KEEP_SCREEN     = "keep_screen_on";
    public static final String KEY_DEFAULT_SOURCE  = "default_source";
    public static final String KEY_LOCAL_URI       = "local_source_uri";
    public static final String KEY_LIB_COLS        = "library_columns";

    private AppPreferences(Context c) {
        p = c.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public static AppPreferences getInstance(Context c) {
        if (instance == null) synchronized (AppPreferences.class) {
            if (instance == null) instance = new AppPreferences(c);
        }
        return instance;
    }

    public String  getTheme()          { return p.getString(KEY_THEME,           "dark"); }
    public String  getSubTheme()       { return p.getString(KEY_SUB_THEME,       "solid"); }
    public String  getPrimaryColor()   { return p.getString(KEY_COLOR_PRIMARY,   "#9b30ff"); }
    public String  getSecondaryColor() { return p.getString(KEY_COLOR_SECONDARY, "#e63946"); }
    public String  getShiftColor1()    { return p.getString(KEY_SHIFT_COLOR1,    "#9b30ff"); }
    public String  getShiftColor2()    { return p.getString(KEY_SHIFT_COLOR2,    "#e63946"); }
    public int     getShiftSpeed()     { return p.getInt(KEY_SHIFT_SPEED, 8); }
    public int     getShiftAngle()     { return p.getInt(KEY_SHIFT_ANGLE, 45); }
    public String  getReadingMode()    { return p.getString(KEY_READING_MODE, "ltr"); }
    public boolean isGrayscale()       { return p.getBoolean(KEY_GRAYSCALE,    false); }
    public boolean isInvert()          { return p.getBoolean(KEY_INVERT,       false); }
    public boolean isCropBorders()     { return p.getBoolean(KEY_CROP_BORDERS, false); }
    public String  getBgColor()        { return p.getString(KEY_BG_COLOR, "#000000"); }
    public boolean isPreload()         { return p.getBoolean(KEY_PRELOAD,      true); }
    public boolean isKeepScreen()      { return p.getBoolean(KEY_KEEP_SCREEN,  true); }
    public String  getDefaultSource()  { return p.getString(KEY_DEFAULT_SOURCE, "allanime"); }
    public String  getLocalUri()       { return p.getString(KEY_LOCAL_URI, null); }
    public int     getLibraryCols()    { return p.getInt(KEY_LIB_COLS, 2); }

    public void setTheme(String v)          { s(KEY_THEME, v); }
    public void setSubTheme(String v)       { s(KEY_SUB_THEME, v); }
    public void setPrimaryColor(String v)   { s(KEY_COLOR_PRIMARY, v); }
    public void setSecondaryColor(String v) { s(KEY_COLOR_SECONDARY, v); }
    public void setShiftColor1(String v)    { s(KEY_SHIFT_COLOR1, v); }
    public void setShiftColor2(String v)    { s(KEY_SHIFT_COLOR2, v); }
    public void setShiftSpeed(int v)        { p.edit().putInt(KEY_SHIFT_SPEED, v).apply(); }
    public void setShiftAngle(int v)        { p.edit().putInt(KEY_SHIFT_ANGLE, v).apply(); }
    public void setReadingMode(String v)    { s(KEY_READING_MODE, v); }
    public void setGrayscale(boolean v)     { p.edit().putBoolean(KEY_GRAYSCALE, v).apply(); }
    public void setInvert(boolean v)        { p.edit().putBoolean(KEY_INVERT, v).apply(); }
    public void setCropBorders(boolean v)   { p.edit().putBoolean(KEY_CROP_BORDERS, v).apply(); }
    public void setBgColor(String v)        { s(KEY_BG_COLOR, v); }
    public void setDefaultSource(String v)  { s(KEY_DEFAULT_SOURCE, v); }
    public void setLocalUri(String v)       { s(KEY_LOCAL_URI, v); }
    public void setLibraryCols(int v)       { p.edit().putInt(KEY_LIB_COLS, v).apply(); }

    private void s(String key, String val) { p.edit().putString(key, val).apply(); }
}
