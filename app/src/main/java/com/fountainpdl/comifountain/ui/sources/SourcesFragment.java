package com.fountainpdl.comifountain.ui.sources;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import androidx.activity.result.*;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.fountainpdl.comifountain.data.model.CustomSource;
import com.fountainpdl.comifountain.databinding.FragmentSourcesBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.sources.*;
import com.fountainpdl.comifountain.ui.common.ToastManager;
import java.util.*;

public class SourcesFragment extends Fragment {

    private FragmentSourcesBinding binding;

    private final ActivityResultLauncher<Uri> folderPicker =
        registerForActivityResult(new ActivityResultContracts.OpenDocumentTree(), uri -> {
            if (uri == null) return;
            requireContext().getContentResolver().takePersistableUriPermission(uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            AppPreferences.getInstance(requireContext()).setLocalUri(uri.toString());
            Source local = SourceManager.getInstance(requireContext()).getById("local");
            if (local instanceof LocalSource) ((LocalSource) local).setRootUri(uri);
            ToastManager.show(requireContext(), "Local folder set!");
        });

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSourcesBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // Tab selection
        binding.tabBrowse.setOnClickListener(v -> showTab("browse"));
        binding.tabExtensions.setOnClickListener(v -> showTab("extensions"));
        binding.tabMigration.setOnClickListener(v -> showTab("migration"));

        showTab("browse");
    }

    private void showTab(String tab) {
        binding.browsePanelContainer.setVisibility(tab.equals("browse")      ? View.VISIBLE : View.GONE);
        binding.extensionsPanelContainer.setVisibility(tab.equals("extensions") ? View.VISIBLE : View.GONE);
        binding.migrationPanelContainer.setVisibility(tab.equals("migration")  ? View.VISIBLE : View.GONE);

        // Bold active tab
        binding.tabBrowse.setAlpha(tab.equals("browse")      ? 1f : 0.5f);
        binding.tabExtensions.setAlpha(tab.equals("extensions") ? 1f : 0.5f);
        binding.tabMigration.setAlpha(tab.equals("migration")  ? 1f : 0.5f);

        if (tab.equals("browse"))     setupBrowse();
        if (tab.equals("extensions")) setupExtensions();
        if (tab.equals("migration"))  setupMigration();
    }

    // ── Browse tab ────────────────────────────────────────────────────────────

    private void setupBrowse() {
        List<Source> sources = SourceManager.getInstance(requireContext()).getAll();
        SourceCardAdapter adapter = new SourceCardAdapter(sources, source -> {
            if ("local".equals(source.getId())
                    && AppPreferences.getInstance(requireContext()).getLocalUri() == null) {
                folderPicker.launch(null);
            } else {
                if (getActivity() instanceof com.fountainpdl.comifountain.MainActivity)
                    ((com.fountainpdl.comifountain.MainActivity) getActivity()).showFragment("search");
            }
        });
        binding.browseRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.browseRecycler.setAdapter(adapter);
        binding.pickFolderBtn.setOnClickListener(v -> folderPicker.launch(null));
    }

    // ── Extensions tab ────────────────────────────────────────────────────────

    private void setupExtensions() {
        refreshExtensionList();
        binding.addSourceBtn.setOnClickListener(v -> showAddSourceDialog());
    }

    private void refreshExtensionList() {
        List<Source> custom = SourceManager.getInstance(requireContext()).getCustom();
        binding.extensionsRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.extensionsRecycler.setAdapter(new ExtensionAdapter(custom,
            new ExtensionAdapter.Listener() {
                @Override public void onEdit(Source s)   { showEditSourceDialog(s); }
                @Override public void onDelete(Source s) { confirmDelete(s); }
                @Override public void onToggle(Source s, boolean enabled) {
                    SourceManager.getInstance(requireContext())
                        .updateCustomSourceUrl(s.getId(), s.getBaseUrl());
                }
            }
        ));
    }

    private void showAddSourceDialog() {
        View dialogView = LayoutInflater.from(requireContext())
            .inflate(android.R.layout.simple_list_item_2, null);
        EditText nameInput = new EditText(requireContext());
        nameInput.setHint("Source Name (e.g. MangaFox)");
        EditText urlInput = new EditText(requireContext());
        urlInput.setHint("Base URL (e.g. https://mangafox.to)");
        EditText searchInput = new EditText(requireContext());
        searchInput.setHint("Search path (e.g. /search?q={query})");

        LinearLayout layout = new LinearLayout(requireContext());
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(48, 24, 48, 0);
        layout.addView(nameInput);
        layout.addView(urlInput);
        layout.addView(searchInput);

        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Add Source")
            .setView(layout)
            .setPositiveButton("Add", (d, w) -> {
                String name   = nameInput.getText().toString().trim();
                String url    = urlInput.getText().toString().trim();
                String search = searchInput.getText().toString().trim();
                if (name.isEmpty() || url.isEmpty()) {
                    ToastManager.show(requireContext(), "Name and URL required");
                    return;
                }
                if (!url.startsWith("http")) url = "https://" + url;
                CustomSource cs = new CustomSource(
                    java.util.UUID.randomUUID().toString(), name, url,
                    search.isEmpty() ? "/?s={query}" : search);
                SourceManager.getInstance(requireContext()).addCustomSource(cs);
                ToastManager.show(requireContext(), name + " added!");
                refreshExtensionList();
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    private void showEditSourceDialog(Source source) {
        EditText urlInput = new EditText(requireContext());
        urlInput.setHint("New base URL");
        urlInput.setText(source.getBaseUrl());
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Edit: " + source.getName())
            .setView(urlInput)
            .setPositiveButton("Save", (d, w) -> {
                String newUrl = urlInput.getText().toString().trim();
                if (!newUrl.isEmpty()) {
                    SourceManager.getInstance(requireContext())
                        .updateCustomSourceUrl(source.getId(), newUrl);
                    ToastManager.show(requireContext(), "URL updated!");
                    refreshExtensionList();
                }
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    private void confirmDelete(Source source) {
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Remove " + source.getName() + "?")
            .setMessage("This will remove the source. Downloaded manga will not be affected.")
            .setPositiveButton("Remove", (d, w) -> {
                SourceManager.getInstance(requireContext()).removeCustomSource(source.getId());
                refreshExtensionList();
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    // ── Migration tab ─────────────────────────────────────────────────────────

    private void setupMigration() {
        binding.migrationInfo.setText(
            "Migration lets you move manga from one source to another while keeping " +
            "your reading progress, bookmarks, and categories.\n\n" +
            "Select a manga from your library to begin.");
        binding.startMigrationBtn.setOnClickListener(v -> showMigrationPicker());
    }

    private void showMigrationPicker() {
        ToastManager.show(requireContext(), "Select manga from library to migrate");
        // TODO: open library picker sheet
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
