package com.fountainpdl.comifountain.ui.settings;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import androidx.activity.result.*;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.*;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.backup.BackupManager;
import com.fountainpdl.comifountain.databinding.FragmentSettingsBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.ui.common.ToastManager;

public class SettingsFragment extends Fragment {

    private FragmentSettingsBinding binding;
    private AppPreferences prefs;
    private BackupManager backupManager;

    private final ActivityResultLauncher<String> backupPicker =
        registerForActivityResult(new ActivityResultContracts.CreateDocument("application/json"), uri -> {
            if (uri != null) backupManager.createBackup(uri, new BackupManager.BackupCallback() {
                @Override public void onSuccess(String msg) { ToastManager.show(requireContext(), msg); }
                @Override public void onError(String err)   { ToastManager.showLong(requireContext(), err); }
            });
        });

    private final ActivityResultLauncher<String[]> restorePicker =
        registerForActivityResult(new ActivityResultContracts.OpenDocument(), uri -> {
            if (uri != null) backupManager.restoreBackup(uri, new BackupManager.BackupCallback() {
                @Override public void onSuccess(String msg) { ToastManager.show(requireContext(), "✅ " + msg); }
                @Override public void onError(String err)   { ToastManager.showLong(requireContext(), "❌ " + err); }
            });
        });

    private final ActivityResultLauncher<Uri> downloadDirPicker =
        registerForActivityResult(new ActivityResultContracts.OpenDocumentTree(), uri -> {
            if (uri == null) return;
            requireContext().getContentResolver().takePersistableUriPermission(uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            prefs.setDownloadLocation(uri.toString());
            binding.downloadLocationValue.setText(uri.getLastPathSegment());
            ToastManager.show(requireContext(), "Download folder set");
        });

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSettingsBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        prefs         = AppPreferences.getInstance(requireContext());
        backupManager = new BackupManager(requireContext());

        setupAppearance();
        setupReader();
        setupLibrary();
        setupDownload();
        setupContent();
        setupBackup();
        setupCategories();
    }

    // ── Appearance ────────────────────────────────────────────────────────────

    private void setupAppearance() {
        // Theme: dark / amoled / light
        String theme = prefs.getTheme();
        binding.radioThemeDark.setChecked("dark".equals(theme));
        binding.radioThemeAmoled.setChecked("amoled".equals(theme));
        binding.radioThemeLight.setChecked("light".equals(theme));
        binding.themeGroup.setOnCheckedChangeListener((g, id) -> {
            if (id == R.id.radio_theme_dark)   prefs.setTheme("dark");
            else if (id == R.id.radio_theme_amoled) prefs.setTheme("amoled");
            else                               prefs.setTheme("light");
            ToastManager.show(requireContext(), "Restart the app to apply theme");
        });

        // Sub-theme
        String sub = prefs.getSubTheme();
        switch (sub) {
            case "solid":       binding.radioSolid.setChecked(true);      showPanel("solid"); break;
            case "dual-shift":  binding.radioDual.setChecked(true);       showPanel("dual");  break;
            case "material-you":binding.radioMaterialYou.setChecked(true);showPanel("dyn");   break;
        }
        binding.subThemeGroup.setOnCheckedChangeListener((g, id) -> {
            if (id == R.id.radio_solid)        { prefs.setSubTheme("solid");        showPanel("solid"); }
            else if (id == R.id.radio_dual)    { prefs.setSubTheme("dual-shift");   showPanel("dual"); }
            else                               { prefs.setSubTheme("material-you"); showPanel("dyn"); }
        });

        binding.primaryColorBtn.setBackgroundColor(Color.parseColor(prefs.getPrimaryColor()));
        binding.secondaryColorBtn.setBackgroundColor(Color.parseColor(prefs.getSecondaryColor()));
        binding.primaryColorBtn.setOnClickListener(v   -> colorPicker(true));
        binding.secondaryColorBtn.setOnClickListener(v -> colorPicker(false));
    }

    private void showPanel(String w) {
        binding.panelSolid.setVisibility("solid".equals(w) ? View.VISIBLE : View.GONE);
        binding.panelDualShift.setVisibility("dual".equals(w) ? View.VISIBLE : View.GONE);
        binding.panelDynamic.setVisibility("dyn".equals(w)  ? View.VISIBLE : View.GONE);
    }

    private void colorPicker(boolean primary) {
        EditText et = new EditText(requireContext());
        et.setText(primary ? prefs.getPrimaryColor() : prefs.getSecondaryColor());
        new AlertDialog.Builder(requireContext())
            .setTitle(primary ? "Primary Color" : "Secondary Color")
            .setView(et)
            .setPositiveButton("Apply", (d, w) -> {
                try {
                    Color.parseColor(et.getText().toString());
                    if (primary) { prefs.setPrimaryColor(et.getText().toString());
                                   binding.primaryColorBtn.setBackgroundColor(Color.parseColor(et.getText().toString())); }
                    else         { prefs.setSecondaryColor(et.getText().toString());
                                   binding.secondaryColorBtn.setBackgroundColor(Color.parseColor(et.getText().toString())); }
                } catch (Exception e) { ToastManager.show(requireContext(), "Invalid color"); }
            })
            .setNegativeButton("Cancel", null).show();
    }

    // ── Reader ────────────────────────────────────────────────────────────────

    private void setupReader() {
        binding.switchGrayscale.setChecked(prefs.isGrayscale());
        binding.switchInvert.setChecked(prefs.isInvert());
        binding.switchCropBorders.setChecked(prefs.isCropBorders());
        binding.switchKeepScreen.setChecked(prefs.isKeepScreen());
        binding.switchFullscreen.setChecked(prefs.isFullscreen());
        binding.switchPageAnim.setChecked(prefs.isPageAnim());

        binding.switchGrayscale.setOnCheckedChangeListener((v, c)   -> prefs.setGrayscale(c));
        binding.switchInvert.setOnCheckedChangeListener((v, c)      -> prefs.setInvert(c));
        binding.switchCropBorders.setOnCheckedChangeListener((v, c) -> prefs.setCropBorders(c));
        binding.switchKeepScreen.setOnCheckedChangeListener((v, c)  -> prefs.setGrayscale(c));
        binding.switchFullscreen.setOnCheckedChangeListener((v, c)  -> prefs.setFullscreen(c));
        binding.switchPageAnim.setOnCheckedChangeListener((v, c)    -> prefs.setGrayscale(c));

        // Reading mode picker
        String[] modes = {"Right to Left (Default)", "Left to Right", "Vertical", "Webtoon", "Vertical with Gaps"};
        String[] values = {"rtl", "ltr", "vertical", "webtoon", "vertical-gaps"};
        String current = prefs.getReadingMode();
        int idx = 0;
        for (int i = 0; i < values.length; i++) if (values[i].equals(current)) idx = i;
        final int[] selectedIdx = {idx};
        binding.readingModeValue.setText(modes[idx]);
        binding.readingModeRow.setOnClickListener(v -> new AlertDialog.Builder(requireContext())
            .setTitle("Reading Mode")
            .setSingleChoiceItems(modes, selectedIdx[0], (d, which) -> selectedIdx[0] = which)
            .setPositiveButton("Apply", (d, w) -> {
                prefs.setReadingMode(values[selectedIdx[0]]);
                binding.readingModeValue.setText(modes[selectedIdx[0]]);
            })
            .setNegativeButton("Cancel", null).show());
    }

    // ── Library ───────────────────────────────────────────────────────────────

    private void setupLibrary() {
        binding.switchShowUnread.setChecked(prefs.isShowUnread());
        binding.switchShowDownloaded.setChecked(prefs.isShowDownloaded());
        binding.switchCompact.setChecked(prefs.isLibCompact());
        binding.switchShowUnread.setOnCheckedChangeListener((v, c)      -> prefs.setGrayscale(c));
        binding.switchShowDownloaded.setOnCheckedChangeListener((v, c)  -> prefs.setGrayscale(c));
        binding.switchCompact.setOnCheckedChangeListener((v, c)         -> prefs.setLibCompact(c));

        binding.colsSlider.setValue(prefs.getLibraryCols());
        binding.colsValue.setText(prefs.getLibraryCols() + " columns");
        binding.colsSlider.addOnChangeListener((s, val, fromUser) -> {
            if (fromUser) {
                prefs.setLibraryCols((int) val);
                binding.colsValue.setText((int) val + " columns");
            }
        });
    }

    // ── Download ──────────────────────────────────────────────────────────────

    private void setupDownload() {
        String loc = prefs.getDownloadLocation();
        binding.downloadLocationValue.setText(loc != null ? Uri.parse(loc).getLastPathSegment() : "Default");
        binding.downloadLocationRow.setOnClickListener(v -> downloadDirPicker.launch(null));

        String[] qualities = {"Original", "High (90%)", "Medium (75%)", "Low (50%)"};
        String[] qValues   = {"original", "high", "medium", "low"};
        String curQ = prefs.getDownloadQuality();
        int qi = 0;
        for (int i = 0; i < qValues.length; i++) if (qValues[i].equals(curQ)) qi = i;
        final int[] qIdx = {qi};
        binding.downloadQualityValue.setText(qualities[qi]);
        binding.downloadQualityRow.setOnClickListener(v -> new AlertDialog.Builder(requireContext())
            .setTitle("Download Quality")
            .setSingleChoiceItems(qualities, qIdx[0], (d, which) -> qIdx[0] = which)
            .setPositiveButton("Apply", (d, w) -> {
                prefs.setDownloadQuality(qValues[qIdx[0]]);
                binding.downloadQualityValue.setText(qualities[qIdx[0]]);
            })
            .setNegativeButton("Cancel", null).show());

        binding.switchWifiOnly.setChecked(prefs.isWifiOnly());
        binding.switchAutoDelete.setChecked(prefs.isAutoDeleteRead());
        binding.switchWifiOnly.setOnCheckedChangeListener((v, c)   -> prefs.setWifiOnly(c));
        binding.switchAutoDelete.setOnCheckedChangeListener((v, c) -> prefs.setAutoDeleteRead(c));
    }

    // ── Content ───────────────────────────────────────────────────────────────

    private void setupContent() {
        binding.switch18Plus.setChecked(prefs.isShow18Plus());
        binding.switch18Plus.setOnCheckedChangeListener((v, c) -> {
            if (c) {
                new AlertDialog.Builder(requireContext())
                    .setTitle("18+ Content")
                    .setMessage("Enable adult content? This will show NSFW manga from supported sources.")
                    .setPositiveButton("Enable", (d, w) -> prefs.setShow18Plus(true))
                    .setNegativeButton("Cancel", (d, w) -> binding.switch18Plus.setChecked(false))
                    .show();
            } else { prefs.setShow18Plus(false); }
        });
    }

    // ── Backup ────────────────────────────────────────────────────────────────

    private void setupBackup() {
        binding.createBackupBtn.setOnClickListener(v ->
            backupPicker.launch(BackupManager.suggestFileName()));
        binding.restoreBackupBtn.setOnClickListener(v ->
            restorePicker.launch(new String[]{"application/json", "*/*"}));
    }

    // ── Categories ────────────────────────────────────────────────────────────

    private void setupCategories() {
        binding.addCategoryBtn.setOnClickListener(v -> {
            EditText et = new EditText(requireContext());
            et.setHint("Category name");
            new AlertDialog.Builder(requireContext())
                .setTitle("New Category")
                .setView(et)
                .setPositiveButton("Add", (d, w) -> {
                    String name = et.getText().toString().trim();
                    if (!name.isEmpty()) {
                        ((com.fountainpdl.comifountain.ComiFountainApp) requireActivity().getApplication())
                            .getRepository().addCategory(name);
                        ToastManager.show(requireContext(), "Category \"" + name + "\" added");
                    }
                })
                .setNegativeButton("Cancel", null).show();
        });
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
