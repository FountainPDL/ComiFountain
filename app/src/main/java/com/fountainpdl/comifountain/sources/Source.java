package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.data.model.Page;
import java.util.List;

public interface Source {
    String getId();
    String getName();
    String getLang();
    String getBaseUrl();
    int    getIconResId();

    List<Manga>   browse(int page) throws Exception;
    List<Manga>   search(String query, int page) throws Exception;
    Manga         getMangaDetails(String mangaId) throws Exception;
    List<Chapter> getChapterList(String mangaId) throws Exception;
    List<Page>    getPageList(String mangaId, String chapterId) throws Exception;
}
