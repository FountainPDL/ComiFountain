package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.*;
import com.fountainpdl.comifountain.network.GqlClient;
import com.google.gson.*;
import com.google.gson.annotations.SerializedName;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * AllManga source — uses api.allanime.day GraphQL endpoint.
 * Chapter list uses availableChaptersDetail to enumerate chapters,
 * then fetches pages per chapter using the sub chapter ID.
 */
public class AllMangaSource implements Source {

    public static final String ID   = "allanime";
    private static final String API = "https://api.allanime.day/api";
    private static final Gson   GS  = new Gson();

    // Search / browse
    private static final String Q_SEARCH =
        "query($search:SearchInput,$limit:Int,$page:Int,$countryOrigin:VaildCountryOriginEnumType){" +
        "mangas(search:$search,limit:$limit,page:$page,countryOrigin:$countryOrigin){" +
        "edges{_id name thumbnail description genres status}}}";

    // Detail — includes availableChaptersDetail which lists chapter numbers
    private static final String Q_DETAIL =
        "query($id:String!){manga(_id:$id){" +
        "_id name thumbnail description authors genres status " +
        "availableChaptersDetail}}";

    // Pages for a chapter
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
            JsonObject root = GS.fromJson(json, JsonObject.class);
            JsonObject manga = root.getAsJsonObject("data").getAsJsonObject("manga");
            Manga m = new Manga(
                Manga.buildId(ID, manga.get("_id").getAsString()),
                getStr(manga, "name"),
                fixUrl(getStr(manga, "thumbnail")),
                ID, getName());
            m.description = getStr(manga, "description");
            m.status      = getStr(manga, "status") != null
                ? getStr(manga, "status").toLowerCase() : "unknown";
            m.url = getBaseUrl() + "/manga/" + manga.get("_id").getAsString();
            if (manga.has("authors") && !manga.get("authors").isJsonNull()) {
                JsonArray authors = manga.getAsJsonArray("authors");
                if (authors.size() > 0) m.author = authors.get(0).getAsString();
            }
            if (manga.has("genres") && !manga.get("genres").isJsonNull()) {
                List<String> genres = new ArrayList<>();
                for (JsonElement g : manga.getAsJsonArray("genres"))
                    genres.add(g.getAsString());
                m.genres = genres;
            }
            return m;
        } catch (Exception e) { e.printStackTrace(); return null; }
    }

    /**
     * Get chapter list from availableChaptersDetail.
     * This field is a JSON object like: {"sub":["1","2","3",...], "dub":[...]}
     * We parse the "sub" array to get all chapter numbers including chapter 1.
     */
    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        Map<String,Object> vars = new HashMap<>();
        vars.put("id", mangaId);
        String json = GqlClient.query(API, Q_DETAIL, vars, headers());
        List<Chapter> chapters = new ArrayList<>();
        try {
            JsonObject root  = GS.fromJson(json, JsonObject.class);
            JsonObject manga = root.getAsJsonObject("data").getAsJsonObject("manga");

            if (!manga.has("availableChaptersDetail")
                    || manga.get("availableChaptersDetail").isJsonNull())
                return chapters;

            JsonObject detail = manga.getAsJsonObject("availableChaptersDetail");

            // Try "sub" first, fallback to "raw"
            JsonArray chapNums = null;
            if (detail.has("sub") && !detail.get("sub").isJsonNull())
                chapNums = detail.getAsJsonArray("sub");
            else if (detail.has("raw") && !detail.get("raw").isJsonNull())
                chapNums = detail.getAsJsonArray("raw");

            if (chapNums == null) return chapters;

            int index = 0;
            for (int i = 0; i < chapNums.size(); i++) {
                String numStr = chapNums.get(i).getAsString().trim();
                if (numStr.isEmpty()) continue;
                float  num   = parseFloat(numStr);
                // Chapter ID format: "sub|<chapterNum>" — used in page query
                String chapId = Chapter.buildId(ID, "sub|" + numStr);
                String title  = "Chapter " + (num == (int)num
                    ? String.valueOf((int)num) : numStr);
                Chapter c = new Chapter(
                    chapId, Manga.buildId(ID, mangaId), ID, title, num, 0);
                c.index = index++;
                chapters.add(c);
            }

            // Sort ascending so Chapter 1 is first
            chapters.sort((a, b) -> Float.compare(a.number, b.number));
            // Re-index after sort
            for (int i = 0; i < chapters.size(); i++) chapters.get(i).index = i;

        } catch (Exception e) { e.printStackTrace(); }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        // chapterId: "allanime:sub|1.0"  → chapterNum = 1.0, chapterId = "sub"
        String raw     = chapterId.substring(chapterId.indexOf(':') + 1); // "sub|1.0"
        String[] parts = raw.split("\\|");
        String subId   = parts.length > 0 ? parts[0] : "sub";   // always "sub"
        float chapNum  = parts.length > 1 ? parseFloat(parts[1]) : 0f;

        Map<String,Object> vars = new HashMap<>();
        vars.put("chapterId",  subId);
        vars.put("chapterNum", chapNum);

        String json = GqlClient.query(API, Q_PAGES, vars, headers());
        List<Page> pages = new ArrayList<>();
        try {
            JsonObject root = GS.fromJson(json, JsonObject.class);
            JsonObject cp   = root.getAsJsonObject("data").getAsJsonObject("chapterPages");
            JsonArray edges = cp.getAsJsonArray("edges");
            for (JsonElement el : edges) {
                JsonObject edge = el.getAsJsonObject();
                int pageNum = edge.has("pageNum") ? edge.get("pageNum").getAsInt() : 0;
                if (edge.has("pictureUrls") && !edge.get("pictureUrls").isJsonNull()) {
                    for (JsonElement url : edge.getAsJsonArray("pictureUrls")) {
                        String u = url.getAsString();
                        if (!u.isEmpty()) pages.add(new Page(pageNum - 1, fixUrl(u)));
                    }
                }
            }
            pages.sort((a, b) -> Integer.compare(a.index, b.index));
        } catch (Exception e) { e.printStackTrace(); }
        return pages;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private List<Manga> parseSearch(String json) {
        List<Manga> result = new ArrayList<>();
        try {
            JsonObject root   = GS.fromJson(json, JsonObject.class);
            JsonArray  edges  = root.getAsJsonObject("data")
                .getAsJsonObject("mangas").getAsJsonArray("edges");
            for (JsonElement el : edges) {
                JsonObject e = el.getAsJsonObject();
                String id = e.get("_id").getAsString();
                Manga m = new Manga(Manga.buildId(ID, id),
                    getStr(e, "name"), fixUrl(getStr(e, "thumbnail")), ID, getName());
                m.description = getStr(e, "description");
                m.status = getStr(e, "status") != null
                    ? getStr(e, "status").toLowerCase() : "unknown";
                m.url = getBaseUrl() + "/manga/" + id;
                if (e.has("genres") && !e.get("genres").isJsonNull()) {
                    List<String> genres = new ArrayList<>();
                    for (JsonElement g : e.getAsJsonArray("genres"))
                        genres.add(g.getAsString());
                    m.genres = genres;
                }
                result.add(m);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    private String fixUrl(String url) {
        if (url == null || url.isEmpty()) return null;
        if (url.startsWith("//"))   return "https:" + url;
        if (url.startsWith("/"))    return "https://wp.allanime.day" + url;
        if (!url.startsWith("http")) return "https://wp.allanime.day/" + url;
        return url;
    }

    private String getStr(JsonObject o, String key) {
        if (!o.has(key) || o.get(key).isJsonNull()) return null;
        return o.get(key).getAsString();
    }

    private float parseFloat(String s) {
        try { return Float.parseFloat(s.trim()); } catch (Exception e) { return 0f; }
    }

    private Map<String,String> headers() {
        Map<String,String> h = new HashMap<>();
        h.put("Referer", "https://allmanga.to");
        h.put("Origin",  "https://allmanga.to");
        return h;
    }
}
