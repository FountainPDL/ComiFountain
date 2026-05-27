package com.fountainpdl.comifountain.ui.common;

import android.content.Context;
import android.graphics.Color;
import android.widget.ImageView;
import android.widget.TextView;
import com.fountainpdl.comifountain.preference.AppPreferences;
import java.util.Calendar;

public class ThemeHelper {

    public static int getPrimaryColor(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        switch (prefs.getSubTheme()) {
            case "dynamic":    return dynamicColor(context, 0);
            case "dual-shift": return Color.parseColor(prefs.getShiftColor1());
            default:           return Color.parseColor(prefs.getPrimaryColor());
        }
    }

    public static int getSecondaryColor(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        switch (prefs.getSubTheme()) {
            case "dynamic":    return dynamicColor(context, 6);
            case "dual-shift": return Color.parseColor(prefs.getShiftColor2());
            default:           return Color.parseColor(prefs.getSecondaryColor());
        }
    }

    public static void tintImageView(Context c, ImageView v)  { v.setColorFilter(getPrimaryColor(c)); }
    public static void tintTextView(Context c, TextView v)    { v.setTextColor(getPrimaryColor(c)); }

    private static int dynamicColor(Context context, int offset) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            try {
                android.content.res.ColorStateList csl = context.getColorStateList(
                    offset == 0 ? android.R.color.system_accent1_400
                                : android.R.color.system_accent2_400);
                if (csl != null) return csl.getDefaultColor();
            } catch (Exception ignored) {}
        }
        int hour = (Calendar.getInstance().get(Calendar.HOUR_OF_DAY) + offset) % 24;
        float[] hues = {270f, 0f, 200f, 120f};
        float[] hsv  = {hues[(hour / 6) % hues.length], 0.75f, 0.85f};
        return Color.HSVToColor(hsv);
    }
}
