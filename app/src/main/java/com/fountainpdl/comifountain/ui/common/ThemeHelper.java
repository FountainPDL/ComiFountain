package com.fountainpdl.comifountain.ui.common;

import android.content.Context;
import android.graphics.Color;
import android.widget.ImageView;
import android.widget.TextView;
import com.fountainpdl.comifountain.preference.AppPreferences;
import java.util.Calendar;

public class ThemeHelper {

    /**
     * Apply the correct theme to an activity before setContentView.
     * Call in Activity.onCreate() BEFORE super.
     */
    public static void applyTheme(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        String theme = prefs.getTheme();
        if (theme.equals("amoled")) {
            context.setTheme(com.fountainpdl.comifountain.R.style.Theme_ComiFountain_Amoled);
        } else if (theme.equals("light")) {
            context.setTheme(com.fountainpdl.comifountain.R.style.Theme_ComiFountain_Light);
        }
        // "dark" uses the default theme already set in manifest
    }

    public static int getPrimaryColor(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        switch (prefs.getSubTheme()) {
            case "dynamic":
            case "material-you": return getMaterialYouColor(context, true);
            case "dual-shift":   return Color.parseColor(prefs.getShiftColor1());
            default:             return Color.parseColor(prefs.getPrimaryColor());
        }
    }

    public static int getSecondaryColor(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        switch (prefs.getSubTheme()) {
            case "dynamic":
            case "material-you": return getMaterialYouColor(context, false);
            case "dual-shift":   return Color.parseColor(prefs.getShiftColor2());
            default:             return Color.parseColor(prefs.getSecondaryColor());
        }
    }

    public static void tintImageView(Context c, ImageView v)  { v.setColorFilter(getPrimaryColor(c)); }
    public static void tintTextView(Context c, TextView v)    { v.setTextColor(getPrimaryColor(c)); }

    /** Android 12+ wallpaper-based Material You colors, fallback to clock palette. */
    private static int getMaterialYouColor(Context context, boolean primary) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            try {
                int resId = primary ? android.R.color.system_accent1_400
                                    : android.R.color.system_accent2_400;
                android.content.res.ColorStateList csl = context.getColorStateList(resId);
                if (csl != null) return csl.getDefaultColor();
            } catch (Exception ignored) {}
        }
        return clockColor(primary ? 0 : 6);
    }

    private static int clockColor(int offset) {
        int hour = (Calendar.getInstance().get(Calendar.HOUR_OF_DAY) + offset) % 24;
        float[] hues = {270f, 0f, 200f, 120f};
        float[] hsv  = {hues[(hour / 6) % hues.length], 0.75f, 0.85f};
        return Color.HSVToColor(hsv);
    }

    public static boolean isDark(Context context) {
        String theme = AppPreferences.getInstance(context).getTheme();
        return theme.equals("dark") || theme.equals("amoled");
    }
}
