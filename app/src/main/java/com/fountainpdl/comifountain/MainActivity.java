package com.fountainpdl.comifountain;

import android.os.Bundle;
import android.view.View;
import android.view.WindowInsetsController;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import com.fountainpdl.comifountain.databinding.ActivityMainBinding;
import com.fountainpdl.comifountain.ui.common.ThemeHelper;
import com.fountainpdl.comifountain.ui.history.HistoryFragment;
import com.fountainpdl.comifountain.ui.library.LibraryFragment;
import com.fountainpdl.comifountain.ui.search.SearchFragment;
import com.fountainpdl.comifountain.ui.sources.SourcesFragment;
import com.fountainpdl.comifountain.ui.updates.UpdatesFragment;
import com.fountainpdl.comifountain.ui.settings.SettingsFragment;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;

    public static final String TAG_LIBRARY  = "library";
    public static final String TAG_SEARCH   = "search";
    public static final String TAG_SOURCES  = "sources";
    public static final String TAG_UPDATES  = "updates";
    public static final String TAG_SETTINGS = "settings";
    public static final String TAG_HISTORY  = "history";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        // Content below status bar
        ViewCompat.setOnApplyWindowInsetsListener(binding.fragmentContainer, (v, insets) -> {
            Insets sys = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() |
                WindowInsetsCompat.Type.displayCutout());
            v.setPadding(0, sys.top, 0, 0);
            return insets;
        });
        // Bottom nav above nav bar
        ViewCompat.setOnApplyWindowInsetsListener(binding.bottomNav, (v, insets) -> {
            Insets sys = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(0, 0, 0, sys.bottom);
            return insets;
        });

        setupBottomNav();
        if (savedInstanceState == null) showFragment(TAG_LIBRARY);
    }

    private void setupBottomNav() {
        binding.bottomNav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_library)  { showFragment(TAG_LIBRARY);  return true; }
            if (id == R.id.nav_search)   { showFragment(TAG_SEARCH);   return true; }
            if (id == R.id.nav_sources)  { showFragment(TAG_SOURCES);  return true; }
            if (id == R.id.nav_updates)  { showFragment(TAG_UPDATES);  return true; }
            if (id == R.id.nav_settings) { showFragment(TAG_SETTINGS); return true; }
            return false;
        });
    }

    public void showFragment(String tag) {
        Fragment existing = getSupportFragmentManager().findFragmentByTag(tag);
        Fragment f = existing != null ? existing : createFragment(tag);
        getSupportFragmentManager().beginTransaction()
            .replace(R.id.fragment_container, f, tag).commit();
        getSupportFragmentManager().popBackStack(null,
            FragmentManager.POP_BACK_STACK_INCLUSIVE);
        binding.bottomNav.setVisibility(View.VISIBLE);
        binding.fragmentContainer.setPadding(
            0, binding.fragmentContainer.getPaddingTop(), 0, 0);
    }

    public void pushFragment(Fragment fragment, String tag) {
        getSupportFragmentManager().beginTransaction()
            .replace(R.id.fragment_container, fragment, tag)
            .addToBackStack(tag).commit();
        binding.bottomNav.setVisibility(View.GONE);
    }

    private Fragment createFragment(String tag) {
        switch (tag) {
            case TAG_LIBRARY:  return new LibraryFragment();
            case TAG_SEARCH:   return new SearchFragment();
            case TAG_SOURCES:  return new SourcesFragment();
            case TAG_UPDATES:  return new UpdatesFragment();
            case TAG_SETTINGS: return new SettingsFragment();
            case TAG_HISTORY:  return new HistoryFragment();
            default:           return new LibraryFragment();
        }
    }

    /** Back NEVER exits — just pops the stack or stays on Library. */
    @Override
    public void onBackPressed() {
        FragmentManager fm = getSupportFragmentManager();
        if (fm.getBackStackEntryCount() > 0) {
            fm.popBackStack();
            if (fm.getBackStackEntryCount() == 0)
                binding.bottomNav.setVisibility(View.VISIBLE);
        }
        // Do nothing when already at root — intentionally does not call super
    }

    public void hideSystemBars() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            getWindow().getInsetsController().hide(
                android.view.WindowInsets.Type.statusBars() |
                android.view.WindowInsets.Type.navigationBars());
            getWindow().getInsetsController().setSystemBarsBehavior(
                WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        }
        binding.fragmentContainer.setPadding(0, 0, 0, 0);
    }

    public void showSystemBars() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R)
            getWindow().getInsetsController().show(
                android.view.WindowInsets.Type.statusBars() |
                android.view.WindowInsets.Type.navigationBars());
    }
}
