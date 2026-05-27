package com.fountainpdl.comifountain.ui.settings;

import android.graphics.Color;
import android.os.Bundle;
import android.view.*;
import android.widget.EditText;
import androidx.annotation.*;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.databinding.FragmentSettingsBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.ui.common.ToastManager;

public class SettingsFragment extends Fragment {

    private FragmentSettingsBinding binding;
    private AppPreferences prefs;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSettingsBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        prefs = AppPreferences.getInstance(requireContext());
        setupTheme();
        setupReader();
    }

    private void setupTheme() {
        binding.radioThemeDark.setChecked("dark".equals(prefs.getTheme()));
        binding.radioThemeLight.setChecked("light".equals(prefs.getTheme()));
        binding.themeGroup.setOnCheckedChangeListener((g, id) ->
            prefs.setTheme(id == R.id.radio_theme_dark ? "dark" : "light"));

        switch (prefs.getSubTheme()) {
            case "solid":       binding.radioSolid.setChecked(true);     showPanel("solid"); break;
            case "dual-shift":  binding.radioDual.setChecked(true); showPanel("dual");  break;
            case "dynamic":     binding.radioDynamic.setChecked(true);   showPanel("dyn");   break;
        }

        binding.subThemeGroup.setOnCheckedChangeListener((g, id) -> {
            if (id == R.id.radio_solid)      { prefs.setSubTheme("solid");      showPanel("solid"); }
            else if (id == R.id.radio_dual)  { prefs.setSubTheme("dual-shift"); showPanel("dual"); }
            else                             { prefs.setSubTheme("dynamic");    showPanel("dyn"); }
        });

        binding.primaryColorBtn.setBackgroundColor(Color.parseColor(prefs.getPrimaryColor()));
        binding.secondaryColorBtn.setBackgroundColor(Color.parseColor(prefs.getSecondaryColor()));
        binding.primaryColorBtn.setOnClickListener(v   -> colorPicker(true));
        binding.secondaryColorBtn.setOnClickListener(v -> colorPicker(false));
    }

    private void showPanel(String which) {
        binding.panelSolid.setVisibility("solid".equals(which) ? View.VISIBLE : View.GONE);
        binding.panelDualShift.setVisibility("dual".equals(which) ? View.VISIBLE : View.GONE);
        binding.panelDynamic.setVisibility("dyn".equals(which)  ? View.VISIBLE : View.GONE);
    }

    private void colorPicker(boolean primary) {
        EditText et = new EditText(requireContext());
        et.setHint("#9b30ff");
        et.setText(primary ? prefs.getPrimaryColor() : prefs.getSecondaryColor());
        new AlertDialog.Builder(requireContext())
            .setTitle(primary ? "Primary Color" : "Secondary Color")
            .setView(et)
            .setPositiveButton("Apply", (d, w) -> {
                String hex = et.getText().toString();
                try {
                    Color.parseColor(hex);
                    if (primary) { prefs.setPrimaryColor(hex);   binding.primaryColorBtn.setBackgroundColor(Color.parseColor(hex)); }
                    else         { prefs.setSecondaryColor(hex); binding.secondaryColorBtn.setBackgroundColor(Color.parseColor(hex)); }
                } catch (Exception e) { ToastManager.show(requireContext(), "Invalid hex color"); }
            })
            .setNegativeButton("Cancel", null).show();
    }

    private void setupReader() {
        binding.switchGrayscale.setChecked(prefs.isGrayscale());
        binding.switchInvert.setChecked(prefs.isInvert());
        binding.switchCropBorders.setChecked(prefs.isCropBorders());
        binding.switchKeepScreen.setChecked(prefs.isKeepScreen());
        binding.switchGrayscale.setOnCheckedChangeListener((v, c)   -> prefs.setGrayscale(c));
        binding.switchInvert.setOnCheckedChangeListener((v, c)      -> prefs.setInvert(c));
        binding.switchCropBorders.setOnCheckedChangeListener((v, c) -> prefs.setCropBorders(c));
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
