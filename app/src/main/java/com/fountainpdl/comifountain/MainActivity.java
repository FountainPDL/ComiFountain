package com.fountainpdl.comifountain;

import android.os.Bundle;
import android.view.View;
import android.view.WindowInsetsController;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.WindowCompat;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import com.fountainpdl.comifountain.databinding.ActivityMainBinding;
import com.fountainpdl.comifountain.ui.library.LibraryFragment;
import com.fountainpdl.comifountain.ui.search.SearchFragment;
import com.fountainpdl.comifountain.ui.sources.SourcesFragment;
import com.fountainpdl.comifountain.ui.updates.UpdatesFragment;
import com.fountainpdl.comifountain.ui.settings.SettingsFragment;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;

    private static final String TAG_LIBRARY  = "library";
    private static final String TAG_SEARCH   = "search";
    private static final String TAG_SOURCES  = "sources";
    private static final String TAG_UPDATES  = "updates";
    private static final String TAG_SETTINGS = "settings";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
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
        Fragment f = getSupportFragmentManager().findFragmentByTag(tag);
        if (f == null) f = createFragment(tag);
        getSupportFragmentManager().beginTransaction()
            .replace(R.id.fragment_container, f, tag).commit();
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
            default:           return new LibraryFragment();
        }
    }

    @Override
    public void onBackPressed() {
        FragmentManager fm = getSupportFragmentManager();
        if (fm.getBackStackEntryCount() > 0) {
            fm.popBackStack();
            if (fm.getBackStackEntryCount() == 1)
                binding.bottomNav.setVisibility(View.VISIBLE);
        } else {
            super.onBackPressed();
        }
    }

    public void hideSystemBars() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            getWindow().getInsetsController().hide(
                android.view.WindowInsets.Type.statusBars() |
                android.view.WindowInsets.Type.navigationBars());
            getWindow().getInsetsController().setSystemBarsBehavior(
                WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        }
    }

    public void showSystemBars() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R)
            getWindow().getInsetsController().show(
                android.view.WindowInsets.Type.statusBars() |
                android.view.WindowInsets.Type.navigationBars());
    }
}
