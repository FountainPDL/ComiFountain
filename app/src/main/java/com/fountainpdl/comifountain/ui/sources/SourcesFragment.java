package com.fountainpdl.comifountain.ui.sources;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import androidx.activity.result.*;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.databinding.FragmentSourcesBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.sources.*;
import com.fountainpdl.comifountain.ui.common.ToastManager;
import java.util.List;

public class SourcesFragment extends Fragment {

    private FragmentSourcesBinding binding;

    private final ActivityResultLauncher<Uri> folderPicker =
        registerForActivityResult(new ActivityResultContracts.OpenDocumentTree(), uri -> {
            if (uri == null) return;
            requireContext().getContentResolver().takePersistableUriPermission(uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            AppPreferences.getInstance(requireContext()).setLocalUri(uri.toString());
            Source local = SourceRegistry.getInstance(requireContext()).getById("local");
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
        List<Source> sources = SourceRegistry.getInstance(requireContext()).getAll();

        binding.sourcesRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.sourcesRecycler.setAdapter(new SourceCardAdapter(sources, source -> {
            if ("local".equals(source.getId())
                    && AppPreferences.getInstance(requireContext()).getLocalUri() == null) {
                folderPicker.launch(null);
            } else {
                if (getActivity() instanceof MainActivity)
                    ((MainActivity) getActivity()).showFragment("search");
            }
        }));

        binding.pickFolderBtn.setOnClickListener(v -> folderPicker.launch(null));
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
