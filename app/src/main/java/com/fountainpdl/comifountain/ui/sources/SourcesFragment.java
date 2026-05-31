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
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.data.db.AppDatabase;
import com.fountainpdl.comifountain.data.model.*;
import com.fountainpdl.comifountain.databinding.FragmentSourcesBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.sources.*;
import com.fountainpdl.comifountain.ui.common.ToastManager;
import java.util.*;
import java.util.concurrent.Executors;

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
        binding.tabBrowse.setOnClickListener(v     -> showTab("browse"));
        binding.tabExtensions.setOnClickListener(v -> showTab("extensions"));
        binding.tabMigration.setOnClickListener(v  -> showTab("migration"));
        showTab("browse");
    }

    private void showTab(String tab) {
        binding.browsePanelContainer.setVisibility("browse".equals(tab)      ? View.VISIBLE : View.GONE);
        binding.extensionsPanelContainer.setVisibility("extensions".equals(tab) ? View.VISIBLE : View.GONE);
        binding.migrationPanelContainer.setVisibility("migration".equals(tab)   ? View.VISIBLE : View.GONE);
        binding.tabBrowse.setAlpha("browse".equals(tab)      ? 1f : 0.45f);
        binding.tabExtensions.setAlpha("extensions".equals(tab) ? 1f : 0.45f);
        binding.tabMigration.setAlpha("migration".equals(tab)   ? 1f : 0.45f);
        if ("browse".equals(tab))     setupBrowse();
        if ("extensions".equals(tab)) setupExtensions();
        if ("migration".equals(tab))  setupMigration();
    }

    // ── Browse ────────────────────────────────────────────────────────────────

    private void setupBrowse() {
        List<Source> sources = SourceManager.getInstance(requireContext()).getAll();
        SourceCardAdapter adapter = new SourceCardAdapter(sources, source -> {
            if ("local".equals(source.getId())
                    && AppPreferences.getInstance(requireContext()).getLocalUri() == null) {
                folderPicker.launch(null);
            } else if (getActivity() instanceof com.fountainpdl.comifountain.MainActivity) {
                ((com.fountainpdl.comifountain.MainActivity) getActivity())
                    .pushFragment(
                        SourceBrowseFragment.newInstance(source.getId()),
                        "browse_" + source.getId());
            }
        });
        binding.browseRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.browseRecycler.setAdapter(adapter);
        binding.pickFolderBtn.setOnClickListener(v -> folderPicker.launch(null));
    }

    // ── Extensions ────────────────────────────────────────────────────────────

    private void setupExtensions() {
        refreshExtensionList();

        // 3 add buttons
        binding.addUrlSourceBtn.setOnClickListener(v    -> showAddUrlDialog());
        binding.addRepoBtn.setOnClickListener(v         -> showAddRepoDialog());
        binding.viewReposBtn.setOnClickListener(v       -> showRepoList());
    }

    private void refreshExtensionList() {
        List<Source> custom = SourceManager.getInstance(requireContext()).getCustom();
        binding.extensionsRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.extensionsRecycler.setAdapter(new ExtensionAdapter(custom,
            new ExtensionAdapter.Listener() {
                @Override public void onEdit(Source s)   { showEditDialog(s); }
                @Override public void onDelete(Source s) { confirmDelete(s); }
                @Override public void onToggle(Source s, boolean on) {}
            }));
    }

    /** Type 1: Simple URL source */
    private void showAddUrlDialog() {
        LinearLayout layout = new LinearLayout(requireContext());
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(48, 16, 48, 0);
        EditText nameInput   = new EditText(requireContext()); nameInput.setHint("Name (e.g. MangaFox)");
        EditText urlInput    = new EditText(requireContext()); urlInput.setHint("Base URL (e.g. https://mangafox.to)");
        EditText searchInput = new EditText(requireContext()); searchInput.setHint("Search path (e.g. /search?q={query})");
        layout.addView(nameInput); layout.addView(urlInput); layout.addView(searchInput);

        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("➕ Add URL Source")
            .setView(layout)
            .setPositiveButton("Add", (d, w) -> {
                String name   = nameInput.getText().toString().trim();
                String url    = urlInput.getText().toString().trim();
                String search = searchInput.getText().toString().trim();
                if (name.isEmpty() || url.isEmpty()) {
                    ToastManager.show(requireContext(), "Name and URL required"); return;
                }
                if (!url.startsWith("http")) url = "https://" + url;
                String finalUrl = url;
                CustomSource cs = new CustomSource(
                    java.util.UUID.randomUUID().toString(), name, finalUrl,
                    search.isEmpty() ? "/?s={query}" : search);
                SourceManager.getInstance(requireContext()).addCustomSource(cs, () -> {
                    if (getActivity() != null) getActivity().runOnUiThread(() -> {
                        ToastManager.show(requireContext(), name + " added!");
                        refreshExtensionList();
                    });
                });
            })
            .setNegativeButton("Cancel", null).show();
    }

    /** Type 2: Tachiyomi repo (index.min.json URL) */
    private void showAddRepoDialog() {
        EditText urlInput = new EditText(requireContext());
        urlInput.setHint("https://raw.githubusercontent.com/.../index.min.json");
        urlInput.setPadding(48, 24, 48, 0);

        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("📦 Add Tachiyomi Repo")
            .setMessage("Paste the raw GitHub URL of an index.min.json extension repo.")
            .setView(urlInput)
            .setPositiveButton("Add", (d, w) -> {
                String url = urlInput.getText().toString().trim();
                if (url.isEmpty()) return;
                if (!url.startsWith("http")) url = "https://" + url;
                TachiyomiRepo repo = new TachiyomiRepo(url, null);
                String finalUrl = url;
                Executors.newSingleThreadExecutor().execute(() -> {
                    AppDatabase.getInstance(requireContext()).tachiyomiRepoDao().insert(repo);
                    if (getActivity() != null) getActivity().runOnUiThread(() ->
                        ToastManager.show(requireContext(), "Repo added: " + repo.name));
                });
            })
            .setNegativeButton("Cancel", null).show();
    }

    private void showRepoList() {
        AppDatabase.getInstance(requireContext())
            .tachiyomiRepoDao().getAll()
            .observe(getViewLifecycleOwner(), repos -> {
                if (repos == null || repos.isEmpty()) {
                    ToastManager.show(requireContext(), "No repos added yet"); return;
                }
                String[] names = repos.stream().map(r -> r.name).toArray(String[]::new);
                new androidx.appcompat.app.AlertDialog.Builder(requireContext())
                    .setTitle("📦 Repos")
                    .setItems(names, (d, which) -> {
                        TachiyomiRepo r = repos.get(which);
                        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
                            .setTitle(r.name)
                            .setMessage(r.url)
                            .setNegativeButton("Remove", (d2, w2) ->
                                Executors.newSingleThreadExecutor().execute(() ->
                                    AppDatabase.getInstance(requireContext())
                                        .tachiyomiRepoDao().delete(r)))
                            .setPositiveButton("Close", null).show();
                    }).show();
            });
    }

    private void showEditDialog(Source source) {
        EditText urlInput = new EditText(requireContext());
        urlInput.setText(source.getBaseUrl());
        urlInput.setPadding(48, 24, 48, 0);
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Edit: " + source.getName())
            .setView(urlInput)
            .setPositiveButton("Save", (d, w) -> {
                String newUrl = urlInput.getText().toString().trim();
                if (!newUrl.isEmpty()) {
                    SourceManager.getInstance(requireContext())
                        .updateCustomSourceUrl(source.getId(), newUrl);
                    ToastManager.show(requireContext(), "URL updated");
                    refreshExtensionList();
                }
            }).setNegativeButton("Cancel", null).show();
    }

    private void confirmDelete(Source source) {
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Remove " + source.getName() + "?")
            .setPositiveButton("Remove", (d, w) -> {
                SourceManager.getInstance(requireContext()).removeCustomSource(source.getId());
                refreshExtensionList();
            }).setNegativeButton("Cancel", null).show();
    }

    // ── Migration ─────────────────────────────────────────────────────────────

    private void setupMigration() {
        binding.migrationInfo.setText(
            "Migration lets you move manga from one source to another while " +
            "keeping your reading progress, bookmarks, and categories.");
        binding.startMigrationBtn.setOnClickListener(v ->
            ToastManager.show(requireContext(), "Select a manga from your library to migrate"));
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
