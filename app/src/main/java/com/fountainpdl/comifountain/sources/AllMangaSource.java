package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.network.GqlClient;
import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import java.text.SimpleDateFormat;
import java.util.*;

public class AllMangaSource implements Source {

    public static final String ID  = "allanime";
    private static final String API = "https://api.allanime.day/api";
    private static final Gson   GS  = new Gson();

    private static final String Q_SEARCH =
        "query($search:SearchInput,$limit:Int,$page:Int,$countryOrigin:VaildCountryOriginEnumType){" +
        "mangas(search:$search,limit:$limit,page:$page,countryOrigin:$countryOrigin){" +
        "edges{_id name thumbnail description genres status}}}";

    private static final String Q_DETAIL =
        "query($id:String!){manga(_id:$id){_id name thumbnail description authors genres status}}";

    private static final String Q_CHAPTERS =
        "query($id:String!,$chapterNumStart:Float,$chapterNumEnd:Float){" +
        "manga(_id:$id){chapters(chapterNumStart:$chapterNumStart,chapterNumEnd:$chapterNumEnd){" +
        "edges{chapterNum uploadDate}}}}";

    private static final String Q_PAGES =
        "query($chapterId:String!,$chapterNum:Float){" +
        "chapterPages(chapterId:$chapterId,chapterNum:$chapterNum){" +
        "edges{pictureUrls pageNum}}}";

    @Override public String getId()        { return ID; }
    @Override public String getName()      { return "AllManga"; }
    @Override public String getLang()      { return "en"; }
    @Override public String getBaseUrl()   { return "https://allmanga.to"; }
    @Override public int    getIconResId() { return R.drawable.ic_source_allanime; }

    @Override
    public List<Manga> browse(int page) throws Exception {
        Map<String,Object> search = new HashMap<>();
        search.put("isManga", true);
        search.put("sortBy", "Latest");
        Map<String,Object> vars = new HashMap<>();
        vars.put("search", search);
        vars.put("limit", 20);
        vars.put("page",  page);
        vars.put("countryOrigin", "ALL");
        return parseSearch(GqlClient.query(API, Q_SEARCH, vars, headers()));
    }

    @Override
    public List<Manga> search(String query, int page) throws Exception {
        Map<String,Object> search = new HashMap<>();
        search.put("query",        query);
        search.put("isManga",      true);
        search.put("sortBy",       "Top");
        search.put("allowAdult",   false);
        search.put("allowUnknown", true);
        Map<String,Object> vars = new HashMap<>();
        vars.put("search", search);
        vars.put("limit",  20);
        vars.put("page",   page);
        vars.put("countryOrigin", "ALL");
        return parseSearch(GqlClient.query(API, Q_SEARCH, vars, headers()));
    }

    @Override
    public Manga getMangaDetails(String mangaId) throws Exception {
        Map<String,Object> vars = new HashMap<>();
        vars.put("id", mangaId);
        String json = GqlClient.query(API, Q_DETAIL, vars, headers());
        try {
            DetailResp r = GS.fromJson(json, DetailResp.class);
            if (r == null || r.data == null || r.data.manga == null) return null;
            MangaDetail d = r.data.manga;
            Manga m = new Manga(Manga.buildId(ID, d._id), d.name, d.thumbnail, ID, getName());
            m.description = d.description;
            m.author      = (d.authors != null && !d.authors.isEmpty()) ? d.authors.get(0) : "";
            if (d.genres != null) m.genres = d.genres;
            m.status      = d.status != null ? d.status.toLowerCase() : "unknown";
            m.url         = getBaseUrl() + "/manga/" + d._id;
            return m;
        } catch (Exception e) { e.printStackTrace(); return null; }
    }

    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        Map<String,Object> vars = new HashMap<>();
        vars.put("id",              mangaId);
        vars.put("chapterNumStart", 0);
        vars.put("chapterNumEnd",   99999);
        String json = GqlClient.query(API, Q_CHAPTERS, vars, headers());
        List<Chapter> chapters = new ArrayList<>();
        try {
            ChapterResp r = GS.fromJson(json, ChapterResp.class);
            if (r == null || r.data == null || r.data.manga == null
                    || r.data.manga.chapters == null) return chapters;
            int index = 0;
            for (ChapterEdge e : r.data.manga.chapters.edges) {
                float num = e.chapterNum;
                String chapId = Chapter.buildId(ID, "sub|" + num);
                Chapter c = new Chapter(
                    chapId, Manga.buildId(ID, mangaId), ID,
                    "Chapter " + (num == (int)num ? String.valueOf((int)num) : num),
                    num, e.uploadDate != null ? parseDate(e.uploadDate) : 0);
                c.index = index++;
                chapters.add(c);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        String[] parts = chapterId.split("\\|");
        float chapterNum = 0;
        String rawId = chapterId;
        if (parts.length == 2) {
            rawId = parts[0];
            try { chapterNum = Float.parseFloat(parts[1]); } catch (Exception ignored) {}
        }
        Map<String,Object> vars = new HashMap<>();
        vars.put("chapterId",  rawId);
        vars.put("chapterNum", chapterNum);
        String json = GqlClient.query(API, Q_PAGES, vars, headers());
        List<Page> pages = new ArrayList<>();
        try {
            PageResp r = GS.fromJson(json, PageResp.class);
            if (r == null || r.data == null || r.data.chapterPages == null) return pages;
            for (PageEdge e : r.data.chapterPages.edges) {
                if (e.pictureUrls != null)
                    for (String url : e.pictureUrls)
                        pages.add(new Page(e.pageNum - 1, url));
            }
            pages.sort((a, b) -> Integer.compare(a.index, b.index));
        } catch (Exception e) { e.printStackTrace(); }
        return pages;
    }

    private List<Manga> parseSearch(String json) {
        List<Manga> result = new ArrayList<>();
        try {
            SearchResp r = GS.fromJson(json, SearchResp.class);
            if (r == null || r.data == null || r.data.mangas == null) return result;
            for (MangaEdge e : r.data.mangas.edges) {
                Manga m = new Manga(Manga.buildId(ID, e._id), e.name, e.thumbnail, ID, getName());
                if (e.genres != null) m.genres = e.genres;
                m.status      = e.status != null ? e.status.toLowerCase() : "unknown";
                m.description = e.description;
                m.url         = getBaseUrl() + "/manga/" + e._id;
                result.add(m);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    private long parseDate(String d) {
        try { return new SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(d).getTime(); }
        catch (Exception e) { return 0; }
    }

    private Map<String,String> headers() {
        Map<String,String> h = new HashMap<>();
        h.put("Referer", "https://allmanga.to");
        h.put("Origin",  "https://allmanga.to");
        return h;
    }

    // Gson response classes
    static class SearchResp  { SearchData  data; static class SearchData  { MangaList  mangas; } static class MangaList  { List<MangaEdge>   edges; } }
    static class DetailResp  { DetailData  data; static class DetailData  { MangaDetail manga; } }
    static class ChapterResp { ChapterData data; static class ChapterData { MangaChaps  manga; } static class MangaChaps { ChapList chapters; } static class ChapList { List<ChapterEdge> edges; } }
    static class PageResp    { PageData    data; static class PageData    { PageList  chapterPages; } static class PageList  { List<PageEdge>    edges; } }

    static class MangaEdge   { @SerializedName("_id") String _id; String name, thumbnail, description, status; List<String> genres; }
    static class MangaDetail { @SerializedName("_id") String _id; String name, thumbnail, description, status; List<String> authors, genres; }
    static class ChapterEdge { float chapterNum; String uploadDate; }
    static class PageEdge    { List<String> pictureUrls; int pageNum; }
}
