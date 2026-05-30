package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.*;
import com.fountainpdl.comifountain.network.GqlClient;
import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import java.text.SimpleDateFormat;
import java.util.*;

public class AllMangaSource implements Source {

    public static final String ID   = "allanime";
    private static final String API = "https://api.allanime.day/api";
    private static final Gson   GS  = new Gson();

    // ── GraphQL Queries ───────────────────────────────────────────────────────

    private static final String Q_SEARCH =
        "query($search:SearchInput,$limit:Int,$page:Int,$countryOrigin:VaildCountryOriginEnumType){" +
        "mangas(search:$search,limit:$limit,page:$page,countryOrigin:$countryOrigin){" +
        "edges{_id name thumbnail description genres status}}}";

    private static final String Q_DETAIL =
        "query($id:String!){manga(_id:$id){" +
        "_id name thumbnail description authors genres status}}";

    // Correct query: use availableChaptersDetail to get chapter numbers,
    // then fetch them page-by-page using chapters query with pagination
    private static final String Q_CHAPTERS =
        "query($id:String!,$page:Int){manga(_id:$id){" +
        "chapters(page:$page,limit:50,orderBy:\"asc\"){" +
        "edges{_id chapterNum uploadDate title}}}}";

    private static final String Q_PAGES =
        "query($chapterId:String!,$chapterNum:Float!){" +
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
        search.put("isManga",    true);
        search.put("sortBy",     "Latest");
        search.put("allowAdult", false);
        Map<String,Object> vars = new HashMap<>();
        vars.put("search", search);
        vars.put("limit",  20);
        vars.put("page",   page);
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
            Manga m = new Manga(Manga.buildId(ID, d._id), d.name, fixUrl(d.thumbnail), ID, getName());
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
        List<Chapter> all = new ArrayList<>();
        Set<String>   seen = new HashSet<>();
        int page = 1;

        while (true) {
            Map<String,Object> vars = new HashMap<>();
            vars.put("id",   mangaId);
            vars.put("page", page);
            String json = GqlClient.query(API, Q_CHAPTERS, vars, headers());
            List<Chapter> batch = parseChapterBatch(json, mangaId);
            if (batch.isEmpty()) break;

            for (Chapter c : batch) {
                if (seen.add(c.id)) all.add(c);
            }
            if (batch.size() < 50) break; // last page
            page++;
            if (page > 20) break; // safety cap (1000 chapters max)
        }

        // Re-index after collecting all
        all.sort((a, b) -> Float.compare(a.number, b.number));
        for (int i = 0; i < all.size(); i++) all.get(i).index = i;

        return all;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        String raw = chapterId.substring(chapterId.indexOf(':') + 1);
        String[] parts = raw.split("\\|");
        String rawId  = parts[0];
        float  chapNum = parts.length > 1 ? parseFloat(parts[1]) : 0f;

        Map<String,Object> vars = new HashMap<>();
        vars.put("chapterId",  rawId);
        vars.put("chapterNum", chapNum);
        String json = GqlClient.query(API, Q_PAGES, vars, headers());
        List<Page> pages = new ArrayList<>();
        try {
            PageResp r = GS.fromJson(json, PageResp.class);
            if (r == null || r.data == null || r.data.chapterPages == null) return pages;
            for (PageEdge e : r.data.chapterPages.edges) {
                if (e.pictureUrls != null)
                    for (String url : e.pictureUrls)
                        if (url != null && !url.isEmpty())
                            pages.add(new Page(e.pageNum - 1, fixUrl(url)));
            }
            pages.sort((a, b) -> Integer.compare(a.index, b.index));
        } catch (Exception e) { e.printStackTrace(); }
        return pages;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private List<Manga> parseSearch(String json) {
        List<Manga> result = new ArrayList<>();
        try {
            SearchResp r = GS.fromJson(json, SearchResp.class);
            if (r == null || r.data == null || r.data.mangas == null) return result;
            for (MangaEdge e : r.data.mangas.edges) {
                if (e == null || e._id == null) continue;
                Manga m = new Manga(Manga.buildId(ID, e._id), e.name, fixUrl(e.thumbnail), ID, getName());
                if (e.genres != null) m.genres = e.genres;
                m.status      = e.status != null ? e.status.toLowerCase() : "unknown";
                m.description = e.description;
                m.url         = getBaseUrl() + "/manga/" + e._id;
                result.add(m);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    private List<Chapter> parseChapterBatch(String json, String mangaId) {
        List<Chapter> chapters = new ArrayList<>();
        try {
            ChapterResp r = GS.fromJson(json, ChapterResp.class);
            if (r == null || r.data == null || r.data.manga == null) return chapters;
            if (r.data.manga.chapters == null || r.data.manga.chapters.edges == null)
                return chapters;
            for (ChapterEdge e : r.data.manga.chapters.edges) {
                if (e == null) continue;
                float  num   = e.chapterNum;
                String rawId = e._id != null ? e._id : ("sub|" + num);
                String title = (e.title != null && !e.title.isEmpty() && !e.title.equals("0"))
                    ? e.title
                    : "Chapter " + (num == (int)num ? String.valueOf((int)num) : String.valueOf(num));
                String chapId = Chapter.buildId(ID, rawId + "|" + num);
                Chapter c = new Chapter(chapId, Manga.buildId(ID, mangaId), ID,
                    title, num, e.uploadDate != null ? parseDate(e.uploadDate) : 0);
                chapters.add(c);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return chapters;
    }

    /** Fix relative URLs from AllManga CDN */
    private String fixUrl(String url) {
        if (url == null || url.isEmpty()) return null;
        if (url.startsWith("//"))          return "https:" + url;
        if (url.startsWith("/"))           return "https://wp.allanime.day" + url;
        if (!url.startsWith("http"))       return "https://wp.allanime.day/" + url;
        return url;
    }

    private long parseDate(String d) {
        for (String fmt : new String[]{
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd"}) {
            try { return new SimpleDateFormat(fmt, Locale.US).parse(d).getTime(); }
            catch (Exception ignored) {}
        }
        return 0;
    }

    private float parseFloat(String s) {
        try { return Float.parseFloat(s); } catch (Exception e) { return 0; }
    }

    private Map<String,String> headers() {
        Map<String,String> h = new HashMap<>();
        h.put("Referer", "https://allmanga.to");
        h.put("Origin",  "https://allmanga.to");
        return h;
    }

    // ── Gson classes ──────────────────────────────────────────────────────────
    static class SearchResp  { SearchData data;  static class SearchData  { MangaList   mangas; } static class MangaList { List<MangaEdge> edges; } }
    static class DetailResp  { DetailData data;  static class DetailData  { MangaDetail manga; } }
    static class ChapterResp { ChapData   data;  static class ChapData    { ChapManga   manga; } static class ChapManga { ChapList chapters; } static class ChapList { List<ChapterEdge> edges; } }
    static class PageResp    { PageData   data;  static class PageData    { PageList  chapterPages; } static class PageList { List<PageEdge> edges; } }

    static class MangaEdge   { @SerializedName("_id") String _id; String name,thumbnail,description,status; List<String> genres; }
    static class MangaDetail { @SerializedName("_id") String _id; String name,thumbnail,description,status; List<String> authors,genres; }
    static class ChapterEdge { @SerializedName("_id") String _id; float chapterNum; String uploadDate,title; }
    static class PageEdge    { List<String> pictureUrls; int pageNum; }
}
