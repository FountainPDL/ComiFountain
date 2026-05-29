package com.fountainpdl.comifountain.preference;

import android.content.Context;
import android.content.SharedPreferences;

public class AppPreferences {
    private static final String PREFS = "comifountain_prefs";
    private static AppPreferences instance;
    private final SharedPreferences p;

    // Theme
    public static final String KEY_THEME           = "theme";           // dark/light/amoled
    public static final String KEY_SUB_THEME       = "sub_theme";       // none/solid/dual-shift/dynamic/material-you
    public static final String KEY_COLOR_PRIMARY   = "color_primary";
    public static final String KEY_COLOR_SECONDARY = "color_secondary";
    public static final String KEY_SHIFT_COLOR1    = "shift_color1";
    public static final String KEY_SHIFT_COLOR2    = "shift_color2";
    public static final String KEY_SHIFT_SPEED     = "shift_speed";
    public static final String KEY_SHIFT_ANGLE     = "shift_angle";
    // Reader
    public static final String KEY_READING_MODE    = "reading_mode";    // ltr/rtl/vertical/webtoon/vertical-gaps
    public static final String KEY_GRAYSCALE       = "grayscale";
    public static final String KEY_INVERT          = "invert_colors";
    public static final String KEY_CROP_BORDERS    = "crop_borders";
    public static final String KEY_BG_COLOR        = "bg_color";
    public static final String KEY_PRELOAD         = "preload_chapter";
    public static final String KEY_KEEP_SCREEN     = "keep_screen_on";
    public static final String KEY_FULLSCREEN      = "fullscreen_reader";
    public static final String KEY_PAGE_ANIM       = "page_animation";
    public static final String KEY_WEBTOON_GAPS    = "webtoon_gaps";
    // Library
    public static final String KEY_LIB_DISPLAY     = "lib_display";     // grid/list
    public static final String KEY_LIB_COLS        = "library_columns";
    public static final String KEY_LIB_COMPACT     = "lib_compact";
    public static final String KEY_SHOW_UNREAD     = "show_unread_badge";
    public static final String KEY_SHOW_DOWNLOADED = "show_downloaded_badge";
    // Download
    public static final String KEY_DOWNLOAD_LOCATION = "download_location";
    public static final String KEY_DOWNLOAD_QUALITY  = "download_quality"; // low/medium/high/original
    public static final String KEY_AUTO_DELETE_READ  = "auto_delete_read";
    public static final String KEY_WIFI_ONLY         = "download_wifi_only";
    // Filter / Content
    public static final String KEY_SHOW_18_PLUS    = "show_18_plus";
    public static final String KEY_DEFAULT_SOURCE  = "default_source";
    public static final String KEY_LOCAL_URI       = "local_source_uri";
    // Updates
    public static final String KEY_AUTO_UPDATE     = "auto_update_library";
    public static final String KEY_UPDATE_INTERVAL = "update_interval_hours";
    // Tracking
    public static final String KEY_TRACK_HISTORY   = "track_reading_history";

    private AppPreferences(Context c) {
        p = c.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public static AppPreferences getInstance(Context c) {
        if (instance == null) synchronized (AppPreferences.class) {
            if (instance == null) instance = new AppPreferences(c);
        }
        return instance;
    }

    // Theme
    public String  getTheme()           { return p.getString(KEY_THEME, "dark"); }
    public String  getSubTheme()        { return p.getString(KEY_SUB_THEME, "solid"); }
    public String  getPrimaryColor()    { return p.getString(KEY_COLOR_PRIMARY, "#9b30ff"); }
    public String  getSecondaryColor()  { return p.getString(KEY_COLOR_SECONDARY, "#e63946"); }
    public String  getShiftColor1()     { return p.getString(KEY_SHIFT_COLOR1, "#9b30ff"); }
    public String  getShiftColor2()     { return p.getString(KEY_SHIFT_COLOR2, "#e63946"); }
    public int     getShiftSpeed()      { return p.getInt(KEY_SHIFT_SPEED, 8); }
    public int     getShiftAngle()      { return p.getInt(KEY_SHIFT_ANGLE, 45); }
    // Reader
    public String  getReadingMode()     { return p.getString(KEY_READING_MODE, "rtl"); }
    public boolean isGrayscale()        { return p.getBoolean(KEY_GRAYSCALE, false); }
    public boolean isInvert()           { return p.getBoolean(KEY_INVERT, false); }
    public boolean isCropBorders()      { return p.getBoolean(KEY_CROP_BORDERS, false); }
    public String  getBgColor()         { return p.getString(KEY_BG_COLOR, "#000000"); }
    public boolean isPreload()          { return p.getBoolean(KEY_PRELOAD, true); }
    public boolean isKeepScreen()       { return p.getBoolean(KEY_KEEP_SCREEN, true); }
    public boolean isFullscreen()       { return p.getBoolean(KEY_FULLSCREEN, true); }
    public boolean isPageAnim()         { return p.getBoolean(KEY_PAGE_ANIM, true); }
    public int     getWebtoonGaps()     { return p.getInt(KEY_WEBTOON_GAPS, 8); }
    // Library
    public String  getLibDisplay()      { return p.getString(KEY_LIB_DISPLAY, "grid"); }
    public int     getLibraryCols()     { return p.getInt(KEY_LIB_COLS, 2); }
    public boolean isLibCompact()       { return p.getBoolean(KEY_LIB_COMPACT, false); }
    public boolean isShowUnread()       { return p.getBoolean(KEY_SHOW_UNREAD, true); }
    public boolean isShowDownloaded()   { return p.getBoolean(KEY_SHOW_DOWNLOADED, true); }
    // Download
    public String  getDownloadLocation(){ return p.getString(KEY_DOWNLOAD_LOCATION, null); }
    public String  getDownloadQuality() { return p.getString(KEY_DOWNLOAD_QUALITY, "original"); }
    public boolean isAutoDeleteRead()   { return p.getBoolean(KEY_AUTO_DELETE_READ, false); }
    public boolean isWifiOnly()         { return p.getBoolean(KEY_WIFI_ONLY, false); }
    // Content
    public boolean isShow18Plus()       { return p.getBoolean(KEY_SHOW_18_PLUS, false); }
    public String  getDefaultSource()   { return p.getString(KEY_DEFAULT_SOURCE, "allanime"); }
    public String  getLocalUri()        { return p.getString(KEY_LOCAL_URI, null); }
    // Updates
    public boolean isAutoUpdate()       { return p.getBoolean(KEY_AUTO_UPDATE, false); }
    public int     getUpdateInterval()  { return p.getInt(KEY_UPDATE_INTERVAL, 12); }
    // Tracking
    public boolean isTrackHistory()     { return p.getBoolean(KEY_TRACK_HISTORY, true); }

    // Setters
    public void setTheme(String v)            { s(KEY_THEME, v); }
    public void setSubTheme(String v)         { s(KEY_SUB_THEME, v); }
    public void setPrimaryColor(String v)     { s(KEY_COLOR_PRIMARY, v); }
    public void setSecondaryColor(String v)   { s(KEY_COLOR_SECONDARY, v); }
    public void setShiftColor1(String v)      { s(KEY_SHIFT_COLOR1, v); }
    public void setShiftColor2(String v)      { s(KEY_SHIFT_COLOR2, v); }
    public void setShiftSpeed(int v)          { p.edit().putInt(KEY_SHIFT_SPEED, v).apply(); }
    public void setShiftAngle(int v)          { p.edit().putInt(KEY_SHIFT_ANGLE, v).apply(); }
    public void setReadingMode(String v)      { s(KEY_READING_MODE, v); }
    public void setGrayscale(boolean v)       { b(KEY_GRAYSCALE, v); }
    public void setInvert(boolean v)          { b(KEY_INVERT, v); }
    public void setCropBorders(boolean v)     { b(KEY_CROP_BORDERS, v); }
    public void setBgColor(String v)          { s(KEY_BG_COLOR, v); }
    public void setFullscreen(boolean v)      { b(KEY_FULLSCREEN, v); }
    public void setLibDisplay(String v)       { s(KEY_LIB_DISPLAY, v); }
    public void setLibraryCols(int v)         { p.edit().putInt(KEY_LIB_COLS, v).apply(); }
    public void setLibCompact(boolean v)      { b(KEY_LIB_COMPACT, v); }
    public void setDownloadLocation(String v) { s(KEY_DOWNLOAD_LOCATION, v); }
    public void setDownloadQuality(String v)  { s(KEY_DOWNLOAD_QUALITY, v); }
    public void setAutoDeleteRead(boolean v)  { b(KEY_AUTO_DELETE_READ, v); }
    public void setWifiOnly(boolean v)        { b(KEY_WIFI_ONLY, v); }
    public void setShow18Plus(boolean v)      { b(KEY_SHOW_18_PLUS, v); }
    public void setDefaultSource(String v)    { s(KEY_DEFAULT_SOURCE, v); }
    public void setLocalUri(String v)         { s(KEY_LOCAL_URI, v); }
    public void setAutoUpdate(boolean v)      { b(KEY_AUTO_UPDATE, v); }
    public void setUpdateInterval(int v)      { p.edit().putInt(KEY_UPDATE_INTERVAL, v).apply(); }

    private void s(String k, String v) { p.edit().putString(k, v).apply(); }
    private void b(String k, boolean v){ p.edit().putBoolean(k, v).apply(); }
}
