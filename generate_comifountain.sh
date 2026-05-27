#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════════
# ComiFountain — Full Project Generator (Part 1: Network + Source skeleton)
# ═══════════════════════════════════════════════════════════════════════════════

J="app/src/main/java/com/fountainpdl/comifountain"
R="app/src/main/res"

mkdir -p \
  "$J/network" "$J/sources" \
  "$J/ui/library" "$J/ui/search" "$J/ui/sources" \
  "$J/ui/updates" "$J/ui/settings" "$J/ui/detail" \
  "$J/ui/reader" "$J/ui/common" \
  "$J/preference" "$J/services" \
  "$R/layout" "$R/menu" "$R/values" "$R/drawable" "$R/xml"

echo "📁  Directories ready"

# ─────────────────────────────────────────────────────────────────────────────
# NETWORK
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/network/HttpClient.java" << 'EOF'
package com.fountainpdl.comifountain.network;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.logging.HttpLoggingInterceptor;
import java.util.concurrent.TimeUnit;

public class HttpClient {
    private static volatile OkHttpClient instance;

    public static OkHttpClient get() {
        if (instance == null) {
            synchronized (HttpClient.class) {
                if (instance == null) {
                    HttpLoggingInterceptor logging = new HttpLoggingInterceptor();
                    logging.setLevel(HttpLoggingInterceptor.Level.BASIC);
                    instance = new OkHttpClient.Builder()
                        .connectTimeout(30, TimeUnit.SECONDS)
                        .readTimeout(30, TimeUnit.SECONDS)
                        .writeTimeout(30, TimeUnit.SECONDS)
                        .addInterceptor(chain -> {
                            Request req = chain.request().newBuilder()
                                .header("User-Agent", "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36")
                                .header("Accept-Language", "en-US,en;q=0.9")
                                .build();
                            return chain.proceed(req);
                        })
                        .addInterceptor(logging)
                        .build();
                }
            }
        }
        return instance;
    }
}
EOF

cat > "$J/network/GqlClient.java" << 'EOF'
package com.fountainpdl.comifountain.network;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import okhttp3.MediaType;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import java.io.IOException;
import java.util.Map;

public class GqlClient {
    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");
    private static final Gson GSON = new Gson();

    public static String query(String url, String gqlQuery,
                               Map<String, Object> variables,
                               Map<String, String> headers) throws IOException {
        JsonObject body = new JsonObject();
        body.addProperty("query", gqlQuery);
        body.add("variables", GSON.toJsonTree(variables));

        Request.Builder builder = new Request.Builder()
            .url(url)
            .post(RequestBody.create(body.toString(), JSON));

        if (headers != null) {
            for (Map.Entry<String, String> e : headers.entrySet())
                builder.header(e.getKey(), e.getValue());
        }

        try (Response response = HttpClient.get().newCall(builder.build()).execute()) {
            if (!response.isSuccessful() || response.body() == null)
                throw new IOException("GQL failed: HTTP " + response.code());
            return response.body().string();
        }
    }
}
EOF

cat > "$J/network/CorsProxy.java" << 'EOF'
package com.fountainpdl.comifountain.network;

import okhttp3.Request;
import okhttp3.Response;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.Map;

public class CorsProxy {
    private static final String PROXY = "https://corsproxy.io/?";

    public static String proxied(String url) {
        try { return PROXY + URLEncoder.encode(url, "UTF-8"); }
        catch (Exception e) { return PROXY + url; }
    }

    public static String fetch(String url, Map<String, String> extraHeaders) throws IOException {
        Request.Builder builder = new Request.Builder().url(proxied(url));
        if (extraHeaders != null)
            for (Map.Entry<String, String> e : extraHeaders.entrySet())
                builder.header(e.getKey(), e.getValue());
        try (Response response = HttpClient.get().newCall(builder.build()).execute()) {
            if (!response.isSuccessful() || response.body() == null)
                throw new IOException("CorsProxy failed: HTTP " + response.code());
            return response.body().string();
        }
    }
}
EOF

echo "🌐  Network layer done"

# ─────────────────────────────────────────────────────────────────────────────
# SOURCE INTERFACE + REGISTRY
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/Source.java" << 'EOF'
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
EOF

cat > "$J/sources/SourceRegistry.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import android.content.Context;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class SourceRegistry {
    private static SourceRegistry instance;
    private final Map<String, Source> sources = new LinkedHashMap<>();

    private SourceRegistry(Context context) {
        register(new AllMangaSource());
        register(new MangaPumaSource());
        register(new RavenScansSource());
        register(new LocalSource(context));
    }

    public static SourceRegistry getInstance(Context context) {
        if (instance == null)
            synchronized (SourceRegistry.class) {
                if (instance == null)
                    instance = new SourceRegistry(context.getApplicationContext());
            }
        return instance;
    }

    private void register(Source s) { sources.put(s.getId(), s); }
    public Source       getById(String id) { return sources.get(id); }
    public List<Source> getAll()           { return new ArrayList<>(sources.values()); }
    public Source       getDefault()       { return sources.values().iterator().next(); }
}
EOF

echo "📡  Source interface + registry done"

# ─────────────────────────────────────────────────────────────────────────────
# ALLANIME SOURCE
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/AllMangaSource.java" << 'EOF'
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
EOF

# ─────────────────────────────────────────────────────────────────────────────
# MANGAPUMA SOURCE
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/MangaPumaSource.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.network.CorsProxy;
import org.jsoup.Jsoup;
import org.jsoup.nodes.*;
import org.jsoup.select.Elements;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.regex.*;

public class MangaPumaSource implements Source {

    public static final String ID   = "mangapuma";
    private static final String BASE = "https://mangapuma.com";

    @Override public String getId()        { return ID; }
    @Override public String getName()      { return "MangaPuma"; }
    @Override public String getLang()      { return "en"; }
    @Override public String getBaseUrl()   { return BASE; }
    @Override public int    getIconResId() { return R.drawable.ic_source_generic; }

    @Override
    public List<Manga> browse(int page) throws Exception {
        return parseList(Jsoup.parse(CorsProxy.fetch(BASE + "/manga-list?page=" + page, null)));
    }

    @Override
    public List<Manga> search(String query, int page) throws Exception {
        String url = BASE + "/?s=" + java.net.URLEncoder.encode(query, "UTF-8");
        return parseList(Jsoup.parse(CorsProxy.fetch(url, null)));
    }

    @Override
    public Manga getMangaDetails(String mangaId) throws Exception {
        String url = BASE + "/manga/" + mangaId;
        Document doc = Jsoup.parse(CorsProxy.fetch(url, null));
        Manga m = new Manga();
        m.id = Manga.buildId(ID, mangaId); m.sourceId = ID; m.sourceName = getName(); m.url = url;
        Element title = doc.selectFirst(".post-title h1");
        m.title = title != null ? title.text() : mangaId;
        Element cover = doc.selectFirst(".summary_image img");
        m.cover = cover != null ? lazySrc(cover) : null;
        Element desc = doc.selectFirst(".summary__content");
        m.description = desc != null ? desc.text() : "";
        Elements genres = doc.select(".genres-content a");
        List<String> gl = new ArrayList<>();
        for (Element g : genres) gl.add(g.text());
        m.genres = gl;
        Element status = doc.selectFirst(".post-status .summary-content");
        m.status = status != null ? status.text().toLowerCase() : "unknown";
        return m;
    }

    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        Document doc = Jsoup.parse(CorsProxy.fetch(BASE + "/manga/" + mangaId, null));
        List<Chapter> chapters = new ArrayList<>();
        Elements items = doc.select(".wp-manga-chapter");
        int index = 0;
        for (Element item : items) {
            Element link = item.selectFirst("a");
            Element date = item.selectFirst(".chapter-release-date");
            if (link == null) continue;
            String chapId   = slug(link.attr("href"));
            float  num      = chapNum(link.text().trim());
            Chapter c       = new Chapter();
            c.id            = Chapter.buildId(ID, chapId);
            c.mangaId       = Manga.buildId(ID, mangaId);
            c.sourceId      = ID;
            c.title         = link.text().trim();
            c.number        = num;
            c.index         = index++;
            if (date != null) c.date = parseDate(date.text().trim());
            chapters.add(c);
        }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        String url  = BASE + "/manga/" + mangaId + "/" + chapterId;
        String html = CorsProxy.fetch(url, null);
        Document doc = Jsoup.parse(html);
        List<Page> pages = new ArrayList<>();
        Elements imgs = doc.select(".reading-content img, .chapter-content img");
        int idx = 0;
        for (Element img : imgs) {
            String src = lazySrc(img);
            if (src != null && !src.isEmpty()) pages.add(new Page(idx++, src.trim()));
        }
        if (pages.isEmpty()) {
            Matcher m = Pattern.compile("\"(https?://[^\"]+\\.(jpg|jpeg|png|webp))\"").matcher(html);
            while (m.find()) pages.add(new Page(idx++, m.group(1)));
        }
        return pages;
    }

    private List<Manga> parseList(Document doc) {
        List<Manga> result = new ArrayList<>();
        for (Element item : doc.select(".manga-poster,.c-image-hover,.page-item-detail")) {
            Element link = item.selectFirst("a");
            Element img  = item.selectFirst("img");
            Element name = item.selectFirst(".manga-name a,.post-title a");
            if (link == null) continue;
            String rawId = slug(link.attr("href"));
            String title = name != null ? name.text() : rawId;
            Manga m = new Manga(Manga.buildId(ID, rawId), title, img != null ? lazySrc(img) : null, ID, getName());
            m.url = link.attr("href");
            result.add(m);
        }
        return result;
    }

    private String lazySrc(Element img) {
        for (String a : new String[]{"data-src","data-lazy-src","data-srcset","src"}) {
            String v = img.attr(a);
            if (!v.isEmpty() && v.startsWith("http")) return v;
        }
        return null;
    }

    private String slug(String href) {
        href = href.replaceAll("/$","");
        int i = href.lastIndexOf('/');
        return i >= 0 ? href.substring(i+1) : href;
    }

    private float chapNum(String title) {
        Matcher m = Pattern.compile("[Cc]hapter[\\s-]*(\\d+\\.?\\d*)").matcher(title);
        if (m.find()) try { return Float.parseFloat(m.group(1)); } catch (Exception ignored) {}
        return 0;
    }

    private long parseDate(String d) {
        try { return new SimpleDateFormat("MMMM dd, yyyy", Locale.US).parse(d).getTime(); }
        catch (Exception e) { return System.currentTimeMillis(); }
    }
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# RAVENSCANS SOURCE
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/RavenScansSource.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.network.HttpClient;
import com.google.gson.*;
import okhttp3.*;
import org.jsoup.Jsoup;
import org.jsoup.nodes.*;
import org.jsoup.select.Elements;
import java.util.*;
import java.util.regex.*;

public class RavenScansSource implements Source {

    public static final String ID    = "ravenscans";
    // NOTE: ravenscans.com — NOT ravenscan.com
    private static final String BASE = "https://ravenscans.com";

    @Override public String getId()        { return ID; }
    @Override public String getName()      { return "RavenScans"; }
    @Override public String getLang()      { return "en"; }
    @Override public String getBaseUrl()   { return BASE; }
    @Override public int    getIconResId() { return R.drawable.ic_source_generic; }

    @Override
    public List<Manga> browse(int page) throws Exception {
        return parseGrid(fetch(BASE + "/manga/?page=" + page + "&order=update"));
    }

    @Override
    public List<Manga> search(String query, int page) throws Exception {
        return parseGrid(fetch(BASE + "/?s=" + java.net.URLEncoder.encode(query,"UTF-8") + "&page=" + page));
    }

    @Override
    public Manga getMangaDetails(String mangaId) throws Exception {
        String url = BASE + "/manga/" + mangaId;
        Document doc = fetch(url);
        Manga m = new Manga();
        m.id = Manga.buildId(ID, mangaId); m.sourceId = ID; m.sourceName = getName(); m.url = url;
        Element title = doc.selectFirst(".post-title h1,h1.entry-title");
        m.title = title != null ? title.text() : mangaId;
        Element cover = doc.selectFirst(".summary_image img,.thumb img");
        m.cover = cover != null ? cover.attr("src") : null;
        Element desc = doc.selectFirst(".summary__content p,.entry-content p");
        m.description = desc != null ? desc.text() : "";
        Elements genres = doc.select(".genres-content a,.genre-list a");
        List<String> gl = new ArrayList<>();
        for (Element g : genres) gl.add(g.text());
        m.genres = gl;
        return m;
    }

    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        Document doc = fetch(BASE + "/manga/" + mangaId);
        List<Chapter> chapters = new ArrayList<>();
        Elements items = doc.select("#chapterlist li,.chapter-list li,.wp-manga-chapter");
        int index = 0;
        for (Element item : items) {
            Element link = item.selectFirst("a");
            if (link == null) continue;
            String chapSlug = slug(link.attr("href"));
            String chapTitle = link.text().trim();
            float num = extractNum(chapTitle);
            Chapter c = new Chapter();
            c.id = Chapter.buildId(ID, chapSlug);
            c.mangaId = Manga.buildId(ID, mangaId);
            c.sourceId = ID; c.title = chapTitle; c.number = num; c.index = index++;
            chapters.add(c);
        }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        String html = fetchRaw(BASE + "/" + chapterId);
        List<Page> pages = extractTsReader(html);
        if (!pages.isEmpty()) return pages;
        pages = extractVarImages(html);
        if (!pages.isEmpty()) return pages;
        return extractImgTags(Jsoup.parse(html));
    }

    private List<Manga> parseGrid(Document doc) {
        List<Manga> result = new ArrayList<>();
        for (Element item : doc.select(".bsx,.bs,.manga-poster,.page-item-detail")) {
            Element link = item.selectFirst("a");
            Element img  = item.selectFirst("img");
            Element name = item.selectFirst(".tt,.manga-name,.post-title");
            if (link == null) continue;
            String rawId = mangaSlug(link.attr("href"));
            String title = name != null ? name.text() : rawId;
            Manga m = new Manga(Manga.buildId(ID, rawId), title, img != null ? img.attr("src") : null, ID, getName());
            m.url = link.attr("href");
            result.add(m);
        }
        return result;
    }

    private List<Page> extractTsReader(String html) {
        List<Page> pages = new ArrayList<>();
        Matcher m = Pattern.compile("ts_reader\\.run\\(\\s*(\\{.*?\\})\\s*\\)", Pattern.DOTALL).matcher(html);
        if (!m.find()) return pages;
        try {
            JsonArray sources = JsonParser.parseString(m.group(1)).getAsJsonObject().getAsJsonArray("sources");
            if (sources == null || sources.size() == 0) return pages;
            JsonArray images = sources.get(0).getAsJsonObject().getAsJsonArray("images");
            for (int i = 0; i < images.size(); i++) pages.add(new Page(i, images.get(i).getAsString()));
        } catch (Exception e) { e.printStackTrace(); }
        return pages;
    }

    private List<Page> extractVarImages(String html) {
        List<Page> pages = new ArrayList<>();
        Matcher m = Pattern.compile("var\\s+images\\s*=\\s*(\\[.*?\\])", Pattern.DOTALL).matcher(html);
        if (!m.find()) return pages;
        try {
            JsonArray arr = JsonParser.parseString(m.group(1)).getAsJsonArray();
            for (int i = 0; i < arr.size(); i++) pages.add(new Page(i, arr.get(i).getAsString()));
        } catch (Exception e) { e.printStackTrace(); }
        return pages;
    }

    private List<Page> extractImgTags(Document doc) {
        List<Page> pages = new ArrayList<>();
        int idx = 0;
        for (Element img : doc.select(".reading-content img,.chapter-content img,#readerarea img")) {
            String src = img.hasAttr("data-src") ? img.attr("data-src") : img.attr("src");
            if (src != null && src.startsWith("http")) pages.add(new Page(idx++, src.trim()));
        }
        return pages;
    }

    private Document fetch(String url) throws Exception { return Jsoup.parse(fetchRaw(url)); }

    private String fetchRaw(String url) throws Exception {
        Request req = new Request.Builder().url(url).header("Referer", BASE).build();
        try (Response r = HttpClient.get().newCall(req).execute()) {
            if (!r.isSuccessful() || r.body() == null) throw new Exception("RavenScans HTTP " + r.code());
            return r.body().string();
        }
    }

    private String slug(String href) {
        href = href.replaceAll("/$",""); int i = href.lastIndexOf('/');
        return i >= 0 ? href.substring(i+1) : href;
    }

    private String mangaSlug(String href) {
        href = href.replaceAll("/$","");
        Matcher m = Pattern.compile("/manga/([^/]+)").matcher(href);
        return m.find() ? m.group(1) : slug(href);
    }

    private float extractNum(String title) {
        Matcher m = Pattern.compile("(\\d+\\.?\\d*)").matcher(title);
        if (m.find()) try { return Float.parseFloat(m.group(1)); } catch (Exception ignored) {}
        return 0;
    }
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# LOCAL SOURCE
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/LocalSource.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import android.content.Context;
import android.net.Uri;
import androidx.documentfile.provider.DocumentFile;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.*;
import java.io.*;
import java.util.*;
import java.util.zip.*;

public class LocalSource implements Source {

    public static final String ID = "local";
    private final Context context;
    private Uri rootUri;

    public LocalSource(Context context) { this.context = context.getApplicationContext(); }

    public void setRootUri(Uri uri) { this.rootUri = uri; }
    public Uri  getRootUri()        { return rootUri; }

    @Override public String getId()        { return ID; }
    @Override public String getName()      { return "Local"; }
    @Override public String getLang()      { return "local"; }
    @Override public String getBaseUrl()   { return ""; }
    @Override public int    getIconResId() { return R.drawable.ic_source_local; }

    @Override
    public List<Manga> browse(int page) throws Exception {
        List<Manga> result = new ArrayList<>();
        if (rootUri == null) return result;
        DocumentFile root = DocumentFile.fromTreeUri(context, rootUri);
        if (root == null || !root.isDirectory()) return result;
        DocumentFile[] children = root.listFiles();
        if (children == null) return result;
        for (DocumentFile child : children) {
            Manga m = child.isDirectory() ? dirToManga(child)
                    : isCbz(child.getName()) ? cbzToManga(child) : null;
            if (m != null) result.add(m);
        }
        return result;
    }

    @Override
    public List<Manga> search(String query, int page) throws Exception {
        List<Manga> filtered = new ArrayList<>();
        String q = query.toLowerCase();
        for (Manga m : browse(page))
            if (m.title != null && m.title.toLowerCase().contains(q)) filtered.add(m);
        return filtered;
    }

    @Override
    public Manga getMangaDetails(String mangaId) throws Exception {
        DocumentFile dir = DocumentFile.fromTreeUri(context, Uri.parse(mangaId));
        return dir != null ? dirToManga(dir) : null;
    }

    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        List<Chapter> chapters = new ArrayList<>();
        DocumentFile dir = DocumentFile.fromTreeUri(context, Uri.parse(mangaId));
        if (dir == null || !dir.isDirectory()) return chapters;
        DocumentFile[] children = dir.listFiles();
        if (children == null) return chapters;
        Arrays.sort(children, (a, b) -> naturalOrder(a.getName(), b.getName()));
        int index = 0;
        for (DocumentFile child : children) {
            if (!child.isDirectory() && !isCbz(child.getName())) continue;
            float  num    = extractNum(child.getName());
            String chapId = Chapter.buildId(ID, child.getUri().toString());
            Chapter c     = new Chapter(chapId, mangaId, ID, child.getName(), num, child.lastModified());
            c.index = index++;
            chapters.add(c);
        }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        String rawUri = chapterId.startsWith(ID + ":") ? chapterId.substring(ID.length()+1) : chapterId;
        DocumentFile target = DocumentFile.fromTreeUri(context, Uri.parse(rawUri));
        if (target == null) return new ArrayList<>();
        return target.isDirectory() ? pagesFromDir(target) : pagesFromCbz(target);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Manga dirToManga(DocumentFile dir) {
        if (dir == null) return null;
        String uri = dir.getUri().toString();
        Manga m = new Manga(Manga.buildId(ID, uri), dir.getName(), null, ID, getName());
        m.url = uri;
        DocumentFile[] files = dir.listFiles();
        if (files != null) {
            for (DocumentFile f : files) {
                String name = f.getName() != null ? f.getName().toLowerCase() : "";
                if (name.startsWith("cover") && isImage(name)) { m.cover = f.getUri().toString(); break; }
            }
            if (m.cover == null) {
                for (DocumentFile f : files) {
                    if (f.isDirectory()) {
                        DocumentFile[] inner = f.listFiles();
                        if (inner != null) {
                            Arrays.sort(inner, (a, b) -> naturalOrder(a.getName(), b.getName()));
                            for (DocumentFile img : inner)
                                if (isImage(img.getName())) { m.cover = img.getUri().toString(); break; }
                        }
                        if (m.cover != null) break;
                    }
                }
            }
        }
        return m;
    }

    private Manga cbzToManga(DocumentFile file) {
        String uri = file.getUri().toString();
        String title = file.getName();
        if (title != null && title.endsWith(".cbz")) title = title.substring(0, title.length()-4);
        return new Manga(Manga.buildId(ID, uri), title, null, ID, getName());
    }

    private List<Page> pagesFromDir(DocumentFile dir) {
        List<Page> pages = new ArrayList<>();
        DocumentFile[] files = dir.listFiles();
        if (files == null) return pages;
        Arrays.sort(files, (a, b) -> naturalOrder(a.getName(), b.getName()));
        int idx = 0;
        for (DocumentFile f : files)
            if (f.isFile() && isImage(f.getName())) pages.add(new Page(idx++, null, f.getUri().toString()));
        return pages;
    }

    private List<Page> pagesFromCbz(DocumentFile cbz) throws Exception {
        List<Page> pages = new ArrayList<>();
        File cacheDir = new File(context.getCacheDir(), "cbz_" + cbz.getName().hashCode());
        cacheDir.mkdirs();
        try (InputStream is = context.getContentResolver().openInputStream(cbz.getUri());
             ZipInputStream zis = new ZipInputStream(is)) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                if (!entry.isDirectory() && isImage(entry.getName())) {
                    File out = new File(cacheDir, new File(entry.getName()).getName());
                    try (FileOutputStream fos = new FileOutputStream(out)) {
                        byte[] buf = new byte[4096]; int len;
                        while ((len = zis.read(buf)) > 0) fos.write(buf, 0, len);
                    }
                }
                zis.closeEntry();
            }
        }
        File[] extracted = cacheDir.listFiles();
        if (extracted == null) return pages;
        Arrays.sort(extracted, (a, b) -> naturalOrder(a.getName(), b.getName()));
        int idx = 0;
        for (File f : extracted)
            if (isImage(f.getName())) pages.add(new Page(idx++, null, f.getAbsolutePath()));
        return pages;
    }

    private boolean isCbz(String name)  { return name != null && name.toLowerCase().endsWith(".cbz"); }
    private boolean isImage(String name) {
        if (name == null) return false;
        String l = name.toLowerCase();
        return l.endsWith(".jpg")||l.endsWith(".jpeg")||l.endsWith(".png")||l.endsWith(".webp")||l.endsWith(".gif");
    }
    private float extractNum(String name) {
        if (name == null) return 0;
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("(\\d+\\.?\\d*)").matcher(name);
        if (m.find()) try { return Float.parseFloat(m.group(1)); } catch (Exception ignored) {}
        return 0;
    }
    private int naturalOrder(String a, String b) {
        if (a == null) a = ""; if (b == null) b = "";
        int i = 0, j = 0;
        while (i < a.length() && j < b.length()) {
            if (Character.isDigit(a.charAt(i)) && Character.isDigit(b.charAt(j))) {
                int na = 0, nb = 0;
                while (i < a.length() && Character.isDigit(a.charAt(i))) na = na*10+(a.charAt(i++)-'0');
                while (j < b.length() && Character.isDigit(b.charAt(j))) nb = nb*10+(b.charAt(j++)-'0');
                if (na != nb) return Integer.compare(na, nb);
            } else { if (a.charAt(i) != b.charAt(j)) return a.charAt(i)-b.charAt(j); i++; j++; }
        }
        return a.length()-b.length();
    }
}
EOF

echo "📚  All sources done"

# ─────────────────────────────────────────────────────────────────────────────
# PREFERENCES
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/preference/AppPreferences.java" << 'EOF'
package com.fountainpdl.comifountain.preference;

import android.content.Context;
import android.content.SharedPreferences;

public class AppPreferences {
    private static final String PREFS = "comifountain_prefs";
    private static AppPreferences instance;
    private final SharedPreferences p;

    public static final String KEY_THEME           = "theme";
    public static final String KEY_SUB_THEME       = "sub_theme";
    public static final String KEY_COLOR_PRIMARY   = "color_primary";
    public static final String KEY_COLOR_SECONDARY = "color_secondary";
    public static final String KEY_SHIFT_COLOR1    = "shift_color1";
    public static final String KEY_SHIFT_COLOR2    = "shift_color2";
    public static final String KEY_SHIFT_SPEED     = "shift_speed";
    public static final String KEY_SHIFT_ANGLE     = "shift_angle";
    public static final String KEY_READING_MODE    = "reading_mode";
    public static final String KEY_GRAYSCALE       = "grayscale";
    public static final String KEY_INVERT          = "invert_colors";
    public static final String KEY_CROP_BORDERS    = "crop_borders";
    public static final String KEY_BG_COLOR        = "bg_color";
    public static final String KEY_PRELOAD         = "preload_chapter";
    public static final String KEY_KEEP_SCREEN     = "keep_screen_on";
    public static final String KEY_DEFAULT_SOURCE  = "default_source";
    public static final String KEY_LOCAL_URI       = "local_source_uri";
    public static final String KEY_LIB_COLS        = "library_columns";

    private AppPreferences(Context c) {
        p = c.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public static AppPreferences getInstance(Context c) {
        if (instance == null) synchronized (AppPreferences.class) {
            if (instance == null) instance = new AppPreferences(c);
        }
        return instance;
    }

    public String  getTheme()          { return p.getString(KEY_THEME,           "dark"); }
    public String  getSubTheme()       { return p.getString(KEY_SUB_THEME,       "solid"); }
    public String  getPrimaryColor()   { return p.getString(KEY_COLOR_PRIMARY,   "#9b30ff"); }
    public String  getSecondaryColor() { return p.getString(KEY_COLOR_SECONDARY, "#e63946"); }
    public String  getShiftColor1()    { return p.getString(KEY_SHIFT_COLOR1,    "#9b30ff"); }
    public String  getShiftColor2()    { return p.getString(KEY_SHIFT_COLOR2,    "#e63946"); }
    public int     getShiftSpeed()     { return p.getInt(KEY_SHIFT_SPEED, 8); }
    public int     getShiftAngle()     { return p.getInt(KEY_SHIFT_ANGLE, 45); }
    public String  getReadingMode()    { return p.getString(KEY_READING_MODE, "ltr"); }
    public boolean isGrayscale()       { return p.getBoolean(KEY_GRAYSCALE,    false); }
    public boolean isInvert()          { return p.getBoolean(KEY_INVERT,       false); }
    public boolean isCropBorders()     { return p.getBoolean(KEY_CROP_BORDERS, false); }
    public String  getBgColor()        { return p.getString(KEY_BG_COLOR, "#000000"); }
    public boolean isPreload()         { return p.getBoolean(KEY_PRELOAD,      true); }
    public boolean isKeepScreen()      { return p.getBoolean(KEY_KEEP_SCREEN,  true); }
    public String  getDefaultSource()  { return p.getString(KEY_DEFAULT_SOURCE, "allanime"); }
    public String  getLocalUri()       { return p.getString(KEY_LOCAL_URI, null); }
    public int     getLibraryCols()    { return p.getInt(KEY_LIB_COLS, 2); }

    public void setTheme(String v)          { s(KEY_THEME, v); }
    public void setSubTheme(String v)       { s(KEY_SUB_THEME, v); }
    public void setPrimaryColor(String v)   { s(KEY_COLOR_PRIMARY, v); }
    public void setSecondaryColor(String v) { s(KEY_COLOR_SECONDARY, v); }
    public void setShiftColor1(String v)    { s(KEY_SHIFT_COLOR1, v); }
    public void setShiftColor2(String v)    { s(KEY_SHIFT_COLOR2, v); }
    public void setShiftSpeed(int v)        { p.edit().putInt(KEY_SHIFT_SPEED, v).apply(); }
    public void setShiftAngle(int v)        { p.edit().putInt(KEY_SHIFT_ANGLE, v).apply(); }
    public void setReadingMode(String v)    { s(KEY_READING_MODE, v); }
    public void setGrayscale(boolean v)     { p.edit().putBoolean(KEY_GRAYSCALE, v).apply(); }
    public void setInvert(boolean v)        { p.edit().putBoolean(KEY_INVERT, v).apply(); }
    public void setCropBorders(boolean v)   { p.edit().putBoolean(KEY_CROP_BORDERS, v).apply(); }
    public void setBgColor(String v)        { s(KEY_BG_COLOR, v); }
    public void setDefaultSource(String v)  { s(KEY_DEFAULT_SOURCE, v); }
    public void setLocalUri(String v)       { s(KEY_LOCAL_URI, v); }
    public void setLibraryCols(int v)       { p.edit().putInt(KEY_LIB_COLS, v).apply(); }

    private void s(String key, String val) { p.edit().putString(key, val).apply(); }
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# THEME HELPER + TOAST
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/common/ThemeHelper.java" << 'EOF'
package com.fountainpdl.comifountain.ui.common;

import android.content.Context;
import android.graphics.Color;
import android.widget.ImageView;
import android.widget.TextView;
import com.fountainpdl.comifountain.preference.AppPreferences;
import java.util.Calendar;

public class ThemeHelper {

    public static int getPrimaryColor(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        switch (prefs.getSubTheme()) {
            case "dynamic":    return dynamicColor(context, 0);
            case "dual-shift": return Color.parseColor(prefs.getShiftColor1());
            default:           return Color.parseColor(prefs.getPrimaryColor());
        }
    }

    public static int getSecondaryColor(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        switch (prefs.getSubTheme()) {
            case "dynamic":    return dynamicColor(context, 6);
            case "dual-shift": return Color.parseColor(prefs.getShiftColor2());
            default:           return Color.parseColor(prefs.getSecondaryColor());
        }
    }

    public static void tintImageView(Context c, ImageView v)  { v.setColorFilter(getPrimaryColor(c)); }
    public static void tintTextView(Context c, TextView v)    { v.setTextColor(getPrimaryColor(c)); }

    private static int dynamicColor(Context context, int offset) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            try {
                android.content.res.ColorStateList csl = context.getColorStateList(
                    offset == 0 ? android.R.color.system_accent1_400
                                : android.R.color.system_accent2_400);
                if (csl != null) return csl.getDefaultColor();
            } catch (Exception ignored) {}
        }
        int hour = (Calendar.getInstance().get(Calendar.HOUR_OF_DAY) + offset) % 24;
        float[] hues = {270f, 0f, 200f, 120f};
        float[] hsv  = {hues[(hour / 6) % hues.length], 0.75f, 0.85f};
        return Color.HSVToColor(hsv);
    }
}
EOF

cat > "$J/ui/common/ToastManager.java" << 'EOF'
package com.fountainpdl.comifountain.ui.common;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;

public class ToastManager {
    private static Toast current;
    private static final Handler H = new Handler(Looper.getMainLooper());

    public static void show(Context c, String msg) {
        H.post(() -> { if (current != null) current.cancel();
            current = Toast.makeText(c.getApplicationContext(), msg, Toast.LENGTH_SHORT);
            current.show(); });
    }

    public static void showLong(Context c, String msg) {
        H.post(() -> { if (current != null) current.cancel();
            current = Toast.makeText(c.getApplicationContext(), msg, Toast.LENGTH_LONG);
            current.show(); });
    }
}
EOF

echo "⚙️   Preferences + helpers done"

# ─────────────────────────────────────────────────────────────────────────────
# MAIN ACTIVITY
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/MainActivity.java" << 'EOF'
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
EOF

echo "🏠  MainActivity done"

# ─────────────────────────────────────────────────────────────────────────────
# LIBRARY
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/library/LibraryViewModel.java" << 'EOF'
package com.fountainpdl.comifountain.ui.library;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.Manga;
import java.util.List;

public class LibraryViewModel extends AndroidViewModel {
    private final MangaRepository repo;
    public final MutableLiveData<String> activeCategory = new MutableLiveData<>("All");

    public LibraryViewModel(@NonNull Application app) {
        super(app);
        repo = ((ComiFountainApp) app).getRepository();
    }

    public LiveData<List<Manga>> getLibraryManga()               { return repo.getLibraryManga(); }
    public LiveData<List<Manga>> getLibraryByCategory(String c)  { return repo.getLibraryMangaByCategory(c); }
    public LiveData<List<Manga>> getMangaWithUpdates()           { return repo.getMangaWithUpdates(); }
    public LiveData<Integer>     getUpdatesBadge()               { return repo.getUpdatesBadgeCount(); }
    public void removeFromLibrary(String mangaId)                { repo.removeFromLibrary(mangaId); }
    public void markAllRead(String mangaId)                      { repo.markAllRead(mangaId); }
}
EOF

cat > "$J/ui/library/MangaGridAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.library;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Manga;

public class MangaGridAdapter extends ListAdapter<Manga, MangaGridAdapter.VH> {

    public interface Listener {
        void onClick(Manga m);
        void onLongClick(Manga m);
    }

    private final Listener listener;

    public MangaGridAdapter(Listener listener) {
        super(DIFF);
        this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_manga_card, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Manga m = getItem(pos);
        h.title.setText(m.title);
        h.badge.setVisibility(m.unreadCount > 0 ? View.VISIBLE : View.GONE);
        if (m.unreadCount > 0) h.badge.setText(String.valueOf(m.unreadCount));
        Glide.with(h.cover).load(m.cover)
            .placeholder(R.drawable.ic_manga_placeholder)
            .diskCacheStrategy(DiskCacheStrategy.ALL).centerCrop().into(h.cover);
        h.itemView.setOnClickListener(v -> listener.onClick(m));
        h.itemView.setOnLongClickListener(v -> { listener.onLongClick(m); return true; });
    }

    static class VH extends RecyclerView.ViewHolder {
        ImageView cover; TextView title, badge;
        VH(View v) { super(v);
            cover = v.findViewById(R.id.manga_cover);
            title = v.findViewById(R.id.manga_title);
            badge = v.findViewById(R.id.manga_unread_badge); }
    }

    private static final DiffUtil.ItemCallback<Manga> DIFF = new DiffUtil.ItemCallback<Manga>() {
        @Override public boolean areItemsTheSame(@NonNull Manga a, @NonNull Manga b) { return a.id.equals(b.id); }
        @Override public boolean areContentsTheSame(@NonNull Manga a, @NonNull Manga b) {
            return a.title.equals(b.title) && a.unreadCount == b.unreadCount
                && java.util.Objects.equals(a.cover, b.cover); }
    };
}
EOF

cat > "$J/ui/library/LibraryFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.library;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.GridLayoutManager;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.databinding.FragmentLibraryBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.ui.detail.MangaDetailFragment;

public class LibraryFragment extends Fragment {

    private FragmentLibraryBinding binding;
    private LibraryViewModel viewModel;
    private MangaGridAdapter adapter;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentLibraryBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        viewModel = new ViewModelProvider(this).get(LibraryViewModel.class);

        adapter = new MangaGridAdapter(new MangaGridAdapter.Listener() {
            @Override public void onClick(Manga m)     { openDetail(m); }
            @Override public void onLongClick(Manga m) { showOptions(m); }
        });

        int cols = AppPreferences.getInstance(requireContext()).getLibraryCols();
        binding.libraryRecycler.setLayoutManager(new GridLayoutManager(requireContext(), cols));
        binding.libraryRecycler.setAdapter(adapter);
        binding.libraryRecycler.setHasFixedSize(true);

        binding.swipeRefresh.setOnRefreshListener(() -> binding.swipeRefresh.setRefreshing(false));

        viewModel.getLibraryManga().observe(getViewLifecycleOwner(), list -> {
            adapter.submitList(list);
            binding.emptyState.setVisibility(list.isEmpty() ? View.VISIBLE : View.GONE);
            binding.swipeRefresh.setRefreshing(false);
        });
    }

    private void openDetail(Manga manga) {
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).pushFragment(
                MangaDetailFragment.newInstance(manga.id), "detail_" + manga.id);
    }

    private void showOptions(Manga manga) {
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle(manga.title)
            .setItems(new String[]{"Remove from library", "Mark all read"}, (d, which) -> {
                if (which == 0) viewModel.removeFromLibrary(manga.id);
                else            viewModel.markAllRead(manga.id);
            }).show();
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

echo "📚  Library done"

# ─────────────────────────────────────────────────────────────────────────────
# SEARCH
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/search/SearchViewModel.java" << 'EOF'
package com.fountainpdl.comifountain.ui.search;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.sources.*;
import java.util.*;
import java.util.concurrent.*;

public class SearchViewModel extends AndroidViewModel {
    public enum State { IDLE, LOADING, RESULTS, ERROR }

    public final MutableLiveData<List<Manga>> results  = new MutableLiveData<>(new ArrayList<>());
    public final MutableLiveData<State>       state    = new MutableLiveData<>(State.IDLE);
    public final MutableLiveData<String>      errorMsg = new MutableLiveData<>();
    public final MutableLiveData<String>      query    = new MutableLiveData<>("");
    public final MutableLiveData<String>      sourceId = new MutableLiveData<>();

    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    public SearchViewModel(@NonNull Application app) {
        super(app);
        Source def = SourceRegistry.getInstance(app).getDefault();
        sourceId.setValue(def != null ? def.getId() : "allanime");
    }

    public void search(String q, int page) {
        query.setValue(q);
        state.setValue(State.LOADING);
        executor.execute(() -> {
            try {
                SourceRegistry reg = SourceRegistry.getInstance(getApplication());
                Source source = reg.getById(sourceId.getValue());
                if (source == null) source = reg.getDefault();
                List<Manga> found = (q == null || q.isEmpty())
                    ? source.browse(page) : source.search(q, page);
                results.postValue(found);
                state.postValue(State.RESULTS);
            } catch (Exception e) {
                errorMsg.postValue(e.getMessage());
                state.postValue(State.ERROR);
            }
        });
    }

    public void setSource(String id) {
        sourceId.setValue(id);
        search(query.getValue(), 1);
    }
}
EOF

cat > "$J/ui/search/SearchFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.search;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.appcompat.widget.SearchView;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.GridLayoutManager;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.databinding.FragmentSearchBinding;
import com.fountainpdl.comifountain.sources.*;
import com.fountainpdl.comifountain.ui.detail.MangaDetailFragment;
import com.fountainpdl.comifountain.ui.library.MangaGridAdapter;
import java.util.List;

public class SearchFragment extends Fragment {

    private FragmentSearchBinding binding;
    private SearchViewModel viewModel;
    private MangaGridAdapter adapter;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSearchBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        viewModel = new ViewModelProvider(this).get(SearchViewModel.class);

        adapter = new MangaGridAdapter(new MangaGridAdapter.Listener() {
            @Override public void onClick(Manga m)     { openDetail(m); }
            @Override public void onLongClick(Manga m) {}
        });
        binding.searchRecycler.setLayoutManager(new GridLayoutManager(requireContext(), 2));
        binding.searchRecycler.setAdapter(adapter);

        setupSourcePicker();

        binding.searchView.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
            @Override public boolean onQueryTextSubmit(String q)  { viewModel.search(q, 1); return true; }
            @Override public boolean onQueryTextChange(String t)  { if (t.isEmpty()) viewModel.search("", 1); return false; }
        });

        viewModel.state.observe(getViewLifecycleOwner(), s -> {
            binding.progressBar.setVisibility(s == SearchViewModel.State.LOADING ? View.VISIBLE : View.GONE);
        });
        viewModel.results.observe(getViewLifecycleOwner(), adapter::submitList);

        if (savedInstanceState == null) viewModel.search("", 1);
    }

    private void setupSourcePicker() {
        List<Source> sources = SourceRegistry.getInstance(requireContext()).getAll();
        String[] names = sources.stream().map(Source::getName).toArray(String[]::new);
        binding.sourcePickerBtn.setText(getSourceName(sources));
        binding.sourcePickerBtn.setOnClickListener(v ->
            new androidx.appcompat.app.AlertDialog.Builder(requireContext())
                .setTitle("Select Source")
                .setItems(names, (d, which) -> {
                    Source chosen = sources.get(which);
                    viewModel.setSource(chosen.getId());
                    binding.sourcePickerBtn.setText(chosen.getName());
                }).show());
    }

    private String getSourceName(List<Source> sources) {
        String id = viewModel.sourceId.getValue();
        for (Source s : sources) if (s.getId().equals(id)) return s.getName();
        return sources.isEmpty() ? "Source" : sources.get(0).getName();
    }

    private void openDetail(Manga manga) {
        ((ComiFountainApp) requireActivity().getApplication()).getRepository().saveManga(manga);
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).pushFragment(
                MangaDetailFragment.newInstance(manga.id), "detail_" + manga.id);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

echo "🔍  Search done"

# ─────────────────────────────────────────────────────────────────────────────
# SOURCES
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/sources/SourceCardAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.sources;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.sources.Source;
import java.util.List;

public class SourceCardAdapter extends RecyclerView.Adapter<SourceCardAdapter.VH> {
    public interface OnBrowse { void onBrowse(Source s); }
    private final List<Source> sources;
    private final OnBrowse listener;

    public SourceCardAdapter(List<Source> sources, OnBrowse listener) {
        this.sources = sources; this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_source_card, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Source s = sources.get(pos);
        h.name.setText(s.getName());
        h.lang.setText(s.getLang().toUpperCase());
        h.icon.setImageResource(s.getIconResId());
        h.browseBtn.setOnClickListener(v -> listener.onBrowse(s));
    }

    @Override public int getItemCount() { return sources.size(); }

    static class VH extends RecyclerView.ViewHolder {
        ImageView icon; TextView name, lang; Button browseBtn;
        VH(View v) { super(v);
            icon      = v.findViewById(R.id.source_icon);
            name      = v.findViewById(R.id.source_name);
            lang      = v.findViewById(R.id.source_lang);
            browseBtn = v.findViewById(R.id.source_browse_btn); }
    }
}
EOF

cat > "$J/ui/sources/SourcesFragment.java" << 'EOF'
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
EOF

echo "🌐  Sources done"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATES
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/updates/UpdatesFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.updates;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.fountainpdl.comifountain.databinding.FragmentUpdatesBinding;
import com.fountainpdl.comifountain.ui.library.*;

public class UpdatesFragment extends Fragment {

    private FragmentUpdatesBinding binding;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentUpdatesBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        LibraryViewModel vm = new ViewModelProvider(this).get(LibraryViewModel.class);
        MangaGridAdapter adapter = new MangaGridAdapter(new MangaGridAdapter.Listener() {
            @Override public void onClick(com.fountainpdl.comifountain.data.model.Manga m) {}
            @Override public void onLongClick(com.fountainpdl.comifountain.data.model.Manga m) {}
        });
        binding.updatesRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.updatesRecycler.setAdapter(adapter);
        vm.getMangaWithUpdates().observe(getViewLifecycleOwner(), list -> {
            adapter.submitList(list);
            binding.emptyUpdates.setVisibility(list.isEmpty() ? View.VISIBLE : View.GONE);
        });
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

echo "🔄  Updates done"

# ─────────────────────────────────────────────────────────────────────────────
# SETTINGS
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/settings/SettingsFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.settings;

import android.graphics.Color;
import android.os.Bundle;
import android.view.*;
import android.widget.EditText;
import androidx.annotation.*;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.databinding.FragmentSettingsBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.ui.common.ToastManager;

public class SettingsFragment extends Fragment {

    private FragmentSettingsBinding binding;
    private AppPreferences prefs;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSettingsBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        prefs = AppPreferences.getInstance(requireContext());
        setupTheme();
        setupReader();
    }

    private void setupTheme() {
        binding.radioThemeDark.setChecked("dark".equals(prefs.getTheme()));
        binding.radioThemeLight.setChecked("light".equals(prefs.getTheme()));
        binding.themeGroup.setOnCheckedChangeListener((g, id) ->
            prefs.setTheme(id == R.id.radio_theme_dark ? "dark" : "light"));

        switch (prefs.getSubTheme()) {
            case "solid":       binding.radioSolid.setChecked(true);     showPanel("solid"); break;
            case "dual-shift":  binding.radioDualShift.setChecked(true); showPanel("dual");  break;
            case "dynamic":     binding.radioDynamic.setChecked(true);   showPanel("dyn");   break;
        }

        binding.subThemeGroup.setOnCheckedChangeListener((g, id) -> {
            if (id == R.id.radio_solid)      { prefs.setSubTheme("solid");      showPanel("solid"); }
            else if (id == R.id.radio_dual)  { prefs.setSubTheme("dual-shift"); showPanel("dual"); }
            else                             { prefs.setSubTheme("dynamic");    showPanel("dyn"); }
        });

        binding.primaryColorBtn.setBackgroundColor(Color.parseColor(prefs.getPrimaryColor()));
        binding.secondaryColorBtn.setBackgroundColor(Color.parseColor(prefs.getSecondaryColor()));
        binding.primaryColorBtn.setOnClickListener(v   -> colorPicker(true));
        binding.secondaryColorBtn.setOnClickListener(v -> colorPicker(false));
    }

    private void showPanel(String which) {
        binding.panelSolid.setVisibility("solid".equals(which) ? View.VISIBLE : View.GONE);
        binding.panelDualShift.setVisibility("dual".equals(which) ? View.VISIBLE : View.GONE);
        binding.panelDynamic.setVisibility("dyn".equals(which)  ? View.VISIBLE : View.GONE);
    }

    private void colorPicker(boolean primary) {
        EditText et = new EditText(requireContext());
        et.setHint("#9b30ff");
        et.setText(primary ? prefs.getPrimaryColor() : prefs.getSecondaryColor());
        new AlertDialog.Builder(requireContext())
            .setTitle(primary ? "Primary Color" : "Secondary Color")
            .setView(et)
            .setPositiveButton("Apply", (d, w) -> {
                String hex = et.getText().toString();
                try {
                    Color.parseColor(hex);
                    if (primary) { prefs.setPrimaryColor(hex);   binding.primaryColorBtn.setBackgroundColor(Color.parseColor(hex)); }
                    else         { prefs.setSecondaryColor(hex); binding.secondaryColorBtn.setBackgroundColor(Color.parseColor(hex)); }
                } catch (Exception e) { ToastManager.show(requireContext(), "Invalid hex color"); }
            })
            .setNegativeButton("Cancel", null).show();
    }

    private void setupReader() {
        binding.switchGrayscale.setChecked(prefs.isGrayscale());
        binding.switchInvert.setChecked(prefs.isInvert());
        binding.switchCropBorders.setChecked(prefs.isCropBorders());
        binding.switchKeepScreen.setChecked(prefs.isKeepScreen());
        binding.switchGrayscale.setOnCheckedChangeListener((v, c)   -> prefs.setGrayscale(c));
        binding.switchInvert.setOnCheckedChangeListener((v, c)      -> prefs.setInvert(c));
        binding.switchCropBorders.setOnCheckedChangeListener((v, c) -> prefs.setCropBorders(c));
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

echo "⚙️   Settings done"

# ─────────────────────────────────────────────────────────────────────────────
# MANGA DETAIL
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/detail/MangaDetailViewModel.java" << 'EOF'
package com.fountainpdl.comifountain.ui.detail;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.*;
import com.fountainpdl.comifountain.sources.*;
import java.util.List;
import java.util.concurrent.*;

public class MangaDetailViewModel extends AndroidViewModel {
    public enum State { LOADING, READY, ERROR }

    public final MutableLiveData<Manga>         manga     = new MutableLiveData<>();
    public final MutableLiveData<List<Chapter>> chapters  = new MutableLiveData<>();
    public final MutableLiveData<State>         state     = new MutableLiveData<>(State.LOADING);
    public final MutableLiveData<Boolean>       inLibrary = new MutableLiveData<>(false);
    public final MutableLiveData<String>        error     = new MutableLiveData<>();

    private final MangaRepository repo;
    private final ExecutorService exec = Executors.newFixedThreadPool(2);

    public MangaDetailViewModel(@NonNull Application app) {
        super(app);
        repo = ((ComiFountainApp) app).getRepository();
    }

    public void load(String mangaId) {
        exec.execute(() -> {
            try {
                String sourceId = mangaId.substring(0, mangaId.indexOf(':'));
                String rawId    = mangaId.substring(mangaId.indexOf(':') + 1);
                Source source   = SourceRegistry.getInstance(getApplication()).getById(sourceId);
                if (source == null) throw new Exception("Unknown source: " + sourceId);

                Manga detail = source.getMangaDetails(rawId);
                if (detail == null) throw new Exception("Manga not found");
                detail.id = mangaId;
                manga.postValue(detail);
                repo.saveManga(detail);

                List<Chapter> chaps = source.getChapterList(rawId);
                chapters.postValue(chaps);
                if (!chaps.isEmpty()) repo.saveChapters(chaps);

                repo.checkIsInLibrary(mangaId, lib -> inLibrary.postValue(lib));
                state.postValue(State.READY);
            } catch (Exception e) {
                error.postValue(e.getMessage());
                state.postValue(State.ERROR);
            }
        });
    }

    public void toggleLibrary(String mangaId) {
        Boolean lib = inLibrary.getValue();
        if (Boolean.TRUE.equals(lib)) { repo.removeFromLibrary(mangaId); inLibrary.postValue(false); }
        else                          { repo.addToLibrary(mangaId);      inLibrary.postValue(true); }
    }
}
EOF

cat > "$J/ui/detail/ChapterListAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.detail;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Chapter;
import java.text.SimpleDateFormat;
import java.util.*;

public class ChapterListAdapter extends ListAdapter<Chapter, ChapterListAdapter.VH> {
    public interface Listener { void onRead(Chapter c); void onDownload(Chapter c); }

    private final Listener listener;
    private static final SimpleDateFormat FMT = new SimpleDateFormat("MMM dd, yyyy", Locale.US);

    public ChapterListAdapter(Listener l) { super(DIFF); this.listener = l; }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_chapter, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Chapter c = getItem(pos);
        h.title.setText(c.displayName());
        h.title.setAlpha(c.isRead ? 0.4f : 1.0f);
        h.date.setText(c.date > 0 ? FMT.format(new Date(c.date)) : "");
        h.bookmark.setVisibility(c.bookmarked ? View.VISIBLE : View.GONE);
        h.downloaded.setVisibility(c.isDownloaded() ? View.VISIBLE : View.GONE);
        h.itemView.setOnClickListener(v -> listener.onRead(c));
        h.downloadBtn.setOnClickListener(v -> listener.onDownload(c));
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView title, date; ImageButton downloadBtn; View bookmark, downloaded;
        VH(View v) { super(v);
            title       = v.findViewById(R.id.chapter_title);
            date        = v.findViewById(R.id.chapter_date);
            downloadBtn = v.findViewById(R.id.chapter_download_btn);
            bookmark    = v.findViewById(R.id.chapter_bookmark_icon);
            downloaded  = v.findViewById(R.id.chapter_download_icon); }
    }

    private static final DiffUtil.ItemCallback<Chapter> DIFF = new DiffUtil.ItemCallback<Chapter>() {
        @Override public boolean areItemsTheSame(@NonNull Chapter a, @NonNull Chapter b) { return a.id.equals(b.id); }
        @Override public boolean areContentsTheSame(@NonNull Chapter a, @NonNull Chapter b) {
            return a.isRead == b.isRead && a.bookmarked == b.bookmarked && a.isDownloaded() == b.isDownloaded(); }
    };
}
EOF

cat > "$J/ui/detail/MangaDetailFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.detail;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.bumptech.glide.Glide;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.databinding.FragmentMangaDetailBinding;
import com.fountainpdl.comifountain.ui.reader.ReaderFragment;

public class MangaDetailFragment extends Fragment {

    private static final String ARG = "manga_id";
    private FragmentMangaDetailBinding binding;
    private MangaDetailViewModel vm;
    private ChapterListAdapter adapter;
    private String mangaId;

    public static MangaDetailFragment newInstance(String id) {
        MangaDetailFragment f = new MangaDetailFragment();
        Bundle b = new Bundle(); b.putString(ARG, id); f.setArguments(b);
        return f;
    }

    @Override public void onCreate(@Nullable Bundle s) {
        super.onCreate(s);
        mangaId = getArguments() != null ? getArguments().getString(ARG) : "";
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentMangaDetailBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        vm = new ViewModelProvider(this).get(MangaDetailViewModel.class);

        binding.detailBackBtn.setOnClickListener(v -> requireActivity().onBackPressed());
        binding.libraryBtn.setOnClickListener(v -> vm.toggleLibrary(mangaId));

        adapter = new ChapterListAdapter(new ChapterListAdapter.Listener() {
            @Override public void onRead(Chapter c)     { openReader(c); }
            @Override public void onDownload(Chapter c) { /* TODO */ }
        });
        binding.chapterRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.chapterRecycler.setAdapter(adapter);

        vm.manga.observe(getViewLifecycleOwner(), m -> {
            if (m == null) return;
            binding.detailTitle.setText(m.title);
            binding.detailAuthor.setText(m.author != null ? m.author : "Unknown");
            binding.detailStatus.setText(m.status != null ? m.status : "");
            binding.detailDescription.setText(m.description != null ? m.description : "");
            Glide.with(this).load(m.cover).into(binding.detailCover);
        });
        vm.chapters.observe(getViewLifecycleOwner(), list -> {
            adapter.submitList(list);
            binding.chapterCount.setText(list.size() + " chapters");
        });
        vm.inLibrary.observe(getViewLifecycleOwner(), lib ->
            binding.libraryBtn.setText(Boolean.TRUE.equals(lib) ? "In Library ✓" : "Add to Library"));
        vm.state.observe(getViewLifecycleOwner(), s ->
            binding.detailProgress.setVisibility(s == MangaDetailViewModel.State.LOADING ? View.VISIBLE : View.GONE));

        vm.load(mangaId);
    }

    private void openReader(Chapter chapter) {
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).pushFragment(
                ReaderFragment.newInstance(mangaId, chapter.id), "reader_" + chapter.id);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

echo "📖  Detail done"

# ─────────────────────────────────────────────────────────────────────────────
# READER
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/reader/ReaderViewModel.java" << 'EOF'
package com.fountainpdl.comifountain.ui.reader;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.sources.*;
import java.util.List;
import java.util.concurrent.*;

public class ReaderViewModel extends AndroidViewModel {
    public final MutableLiveData<List<Page>> pages       = new MutableLiveData<>();
    public final MutableLiveData<Integer>    currentPage = new MutableLiveData<>(0);
    public final MutableLiveData<Boolean>    loading     = new MutableLiveData<>(false);
    public final MutableLiveData<String>     error       = new MutableLiveData<>();

    private final MangaRepository repo;
    private final ExecutorService exec = Executors.newSingleThreadExecutor();
    private String chapterId;

    public ReaderViewModel(@NonNull Application app) {
        super(app);
        repo = ((ComiFountainApp) app).getRepository();
    }

    public void load(String mangaId, String chapterId) {
        this.chapterId = chapterId;
        loading.setValue(true);
        exec.execute(() -> {
            try {
                String sourceId = mangaId.substring(0, mangaId.indexOf(':'));
                String rawManga = mangaId.substring(mangaId.indexOf(':') + 1);
                String rawChap  = chapterId.substring(chapterId.indexOf(':') + 1);
                Source source   = SourceRegistry.getInstance(getApplication()).getById(sourceId);
                if (source == null) throw new Exception("Unknown source: " + sourceId);
                List<Page> p = source.getPageList(rawManga, rawChap);
                pages.postValue(p);
                loading.postValue(false);
                repo.markChapterRead(chapterId, mangaId);
            } catch (Exception e) {
                error.postValue("Failed to load pages: " + e.getMessage());
                loading.postValue(false);
            }
        });
    }

    public void updatePage(int index) {
        currentPage.setValue(index);
        repo.updateLastPageRead(chapterId, index);
    }

    public int getTotalPages() {
        List<Page> p = pages.getValue();
        return p != null ? p.size() : 0;
    }
}
EOF

cat > "$J/ui/reader/PageAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.reader;

import android.graphics.*;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.*;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.DataSource;
import com.bumptech.glide.load.engine.*;
import com.bumptech.glide.request.RequestListener;
import com.bumptech.glide.request.target.Target;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Page;
import java.util.*;

public class PageAdapter extends RecyclerView.Adapter<PageAdapter.VH> {
    private List<Page> pages = new ArrayList<>();
    private boolean grayscale = false;

    public void setPages(List<Page> p)      { this.pages = p; notifyDataSetChanged(); }
    public void setGrayscale(boolean g)     { this.grayscale = g; notifyDataSetChanged(); }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_reader_page, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Page page = pages.get(pos);
        h.progress.setVisibility(View.VISIBLE);
        h.error.setVisibility(View.GONE);

        if (grayscale) {
            ColorMatrix cm = new ColorMatrix(); cm.setSaturation(0);
            h.image.setColorFilter(new ColorMatrixColorFilter(cm));
        } else { h.image.clearColorFilter(); }

        Glide.with(h.image.getContext())
            .load(page.isLocal() ? page.localPath : page.url)
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .listener(new RequestListener<android.graphics.drawable.Drawable>() {
                @Override public boolean onLoadFailed(@Nullable GlideException e, Object m,
                    Target<android.graphics.drawable.Drawable> t, boolean f) {
                    h.progress.setVisibility(View.GONE); h.error.setVisibility(View.VISIBLE); return false; }
                @Override public boolean onResourceReady(android.graphics.drawable.Drawable r, Object m,
                    Target<android.graphics.drawable.Drawable> t, DataSource d, boolean f) {
                    h.progress.setVisibility(View.GONE); return false; }
            }).into(h.image);
    }

    @Override public int getItemCount() { return pages.size(); }

    static class VH extends RecyclerView.ViewHolder {
        com.github.chrisbanes.photoview.PhotoView image;
        ProgressBar progress; View error;
        VH(View v) { super(v);
            image    = v.findViewById(R.id.page_image);
            progress = v.findViewById(R.id.page_progress);
            error    = v.findViewById(R.id.page_error); }
    }
}
EOF

cat > "$J/ui/reader/ReaderFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.reader;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.viewpager2.widget.ViewPager2;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.databinding.FragmentReaderBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;

public class ReaderFragment extends Fragment {

    private static final String ARG_MANGA   = "manga_id";
    private static final String ARG_CHAPTER = "chapter_id";

    private FragmentReaderBinding binding;
    private ReaderViewModel vm;
    private PageAdapter adapter;
    private boolean barsVisible = true;
    private String mangaId, chapterId;

    public static ReaderFragment newInstance(String mangaId, String chapterId) {
        ReaderFragment f = new ReaderFragment();
        Bundle b = new Bundle();
        b.putString(ARG_MANGA, mangaId);
        b.putString(ARG_CHAPTER, chapterId);
        f.setArguments(b);
        return f;
    }

    @Override public void onCreate(@Nullable Bundle s) {
        super.onCreate(s);
        if (getArguments() != null) {
            mangaId   = getArguments().getString(ARG_MANGA);
            chapterId = getArguments().getString(ARG_CHAPTER);
        }
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentReaderBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        vm = new ViewModelProvider(this).get(ReaderViewModel.class);
        AppPreferences prefs = AppPreferences.getInstance(requireContext());

        if (prefs.isKeepScreen())
            requireActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).hideSystemBars();

        adapter = new PageAdapter();
        adapter.setGrayscale(prefs.isGrayscale());

        String mode = prefs.getReadingMode();
        binding.readerPager.setOrientation(
            ("vertical".equals(mode) || "webtoon".equals(mode))
                ? ViewPager2.ORIENTATION_VERTICAL
                : ViewPager2.ORIENTATION_HORIZONTAL);
        if ("rtl".equals(mode))
            binding.readerPager.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);

        binding.readerPager.setAdapter(adapter);
        binding.readerPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override public void onPageSelected(int pos) {
                vm.updatePage(pos);
                int total = vm.getTotalPages();
                binding.pageIndicator.setText((pos + 1) + " / " + total);
                if (total > 1) binding.pageSlider.setValue(pos);
            }
        });

        binding.pageSlider.addOnChangeListener((s2, val, fromUser) -> {
            if (fromUser) binding.readerPager.setCurrentItem((int) val, false);
        });

        binding.readerPager.setOnClickListener(v -> toggleBars());
        binding.readerBackBtn.setOnClickListener(v -> requireActivity().onBackPressed());

        vm.pages.observe(getViewLifecycleOwner(), p -> {
            adapter.setPages(p);
            if (!p.isEmpty()) {
                binding.pageSlider.setValueFrom(0);
                binding.pageSlider.setValueTo(Math.max(1, p.size() - 1));
                binding.pageSlider.setValue(0);
                binding.pageIndicator.setText("1 / " + p.size());
            }
        });
        vm.loading.observe(getViewLifecycleOwner(), l ->
            binding.readerProgress.setVisibility(Boolean.TRUE.equals(l) ? View.VISIBLE : View.GONE));

        vm.load(mangaId, chapterId);
    }

    private void toggleBars() {
        barsVisible = !barsVisible;
        int vis = barsVisible ? View.VISIBLE : View.GONE;
        binding.readerTopBar.setVisibility(vis);
        binding.readerBottomBar.setVisibility(vis);
    }

    @Override
    public void onPause() {
        super.onPause();
        if (getActivity() instanceof MainActivity) ((MainActivity) getActivity()).showSystemBars();
        requireActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

echo "📖  Reader done"

# ─────────────────────────────────────────────────────────────────────────────
# SERVICES
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/services/DownloadService.java" << 'EOF'
package com.fountainpdl.comifountain.services;

import android.app.*;
import android.content.Intent;
import android.os.IBinder;
import androidx.core.app.NotificationCompat;
import com.fountainpdl.comifountain.R;

public class DownloadService extends Service {
    private static final String CH = "cf_downloads";
    @Override public void onCreate() { super.onCreate(); makeChannel(); }
    @Override public int onStartCommand(Intent i, int f, int id) {
        startForeground(1, new NotificationCompat.Builder(this, CH)
            .setSmallIcon(R.drawable.ic_updates).setContentTitle("ComiFountain")
            .setContentText("Downloading…").build());
        return START_NOT_STICKY;
    }
    @Override public IBinder onBind(Intent i) { return null; }
    private void makeChannel() {
        getSystemService(NotificationManager.class).createNotificationChannel(
            new NotificationChannel(CH, "Downloads", NotificationManager.IMPORTANCE_LOW));
    }
}
EOF

cat > "$J/services/UpdateService.java" << 'EOF'
package com.fountainpdl.comifountain.services;

import android.app.*;
import android.content.Intent;
import android.os.IBinder;
import androidx.core.app.NotificationCompat;
import com.fountainpdl.comifountain.R;

public class UpdateService extends Service {
    private static final String CH = "cf_updates";
    @Override public void onCreate() { super.onCreate(); makeChannel(); }
    @Override public int onStartCommand(Intent i, int f, int id) {
        startForeground(2, new NotificationCompat.Builder(this, CH)
            .setSmallIcon(R.drawable.ic_updates).setContentTitle("ComiFountain")
            .setContentText("Checking for updates…").build());
        stopSelf();
        return START_NOT_STICKY;
    }
    @Override public IBinder onBind(Intent i) { return null; }
    private void makeChannel() {
        getSystemService(NotificationManager.class).createNotificationChannel(
            new NotificationChannel(CH, "Library Updates", NotificationManager.IMPORTANCE_DEFAULT));
    }
}
EOF

echo "🔧  Services done"

# ═══════════════════════════════════════════════════════════════════════════════
# LAYOUTS
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$R/layout/activity_main.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.coordinatorlayout.widget.CoordinatorLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <FrameLayout
        android:id="@+id/fragment_container"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:paddingBottom="56dp"/>

    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/bottom_nav"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom"
        android:background="?attr/colorSurface"
        app:menu="@menu/bottom_nav_menu"
        app:labelVisibilityMode="labeled"/>

</androidx.coordinatorlayout.widget.CoordinatorLayout>
EOF

cat > "$R/layout/fragment_library.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="?attr/colorBackground">

    <TextView android:id="@+id/library_title"
        android:layout_width="0dp" android:layout_height="wrap_content"
        android:text="Library" android:textSize="22sp" android:textStyle="bold"
        android:padding="16dp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"/>

    <androidx.swiperefreshlayout.widget.SwipeRefreshLayout
        android:id="@+id/swipe_refresh"
        android:layout_width="0dp" android:layout_height="0dp"
        app:layout_constraintTop_toBottomOf="@id/library_title"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent">

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/library_recycler"
            android:layout_width="match_parent" android:layout_height="match_parent"
            android:padding="8dp" android:clipToPadding="false"/>

    </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>

    <TextView android:id="@+id/empty_state"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="No manga in library.\nBrowse Sources to add some!"
        android:textAlignment="center" android:visibility="gone"
        app:layout_constraintTop_toTopOf="parent" app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintStart_toStartOf="parent" app:layout_constraintEnd_toEndOf="parent"/>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

cat > "$R/layout/fragment_search.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?attr/colorBackground">

    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal" android:padding="8dp">

        <androidx.appcompat.widget.SearchView
            android:id="@+id/search_view"
            android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1"/>

        <Button android:id="@+id/source_picker_btn"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:text="AllManga" style="@style/Widget.Material3.Button.TextButton"/>

    </LinearLayout>

    <ProgressBar android:id="@+id/progress_bar"
        android:layout_width="match_parent" android:layout_height="4dp"
        android:indeterminate="true" android:visibility="gone"
        style="@style/Widget.Material3.LinearProgressIndicator"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/search_recycler"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1" android:padding="8dp" android:clipToPadding="false"/>

</LinearLayout>
EOF

cat > "$R/layout/fragment_sources.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?attr/colorBackground">

    <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
        android:text="Sources" android:textSize="22sp" android:textStyle="bold" android:padding="16dp"/>

    <Button android:id="@+id/pick_folder_btn"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_marginStart="16dp" android:text="📁  Pick Local Folder"
        style="@style/Widget.Material3.Button.OutlinedButton"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/sources_recycler"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1" android:padding="8dp" android:clipToPadding="false"/>

</LinearLayout>
EOF

cat > "$R/layout/fragment_updates.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="?attr/colorBackground">

    <TextView android:id="@+id/updates_title"
        android:layout_width="0dp" android:layout_height="wrap_content"
        android:text="Updates" android:textSize="22sp" android:textStyle="bold" android:padding="16dp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent" app:layout_constraintEnd_toEndOf="parent"/>

    <androidx.recyclerview.widget.RecyclerView android:id="@+id/updates_recycler"
        android:layout_width="0dp" android:layout_height="0dp"
        app:layout_constraintTop_toBottomOf="@id/updates_title"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintStart_toStartOf="parent" app:layout_constraintEnd_toEndOf="parent"/>

    <TextView android:id="@+id/empty_updates"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:text="All caught up!" android:visibility="gone"
        app:layout_constraintTop_toTopOf="parent" app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintStart_toStartOf="parent" app:layout_constraintEnd_toEndOf="parent"/>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

cat > "$R/layout/fragment_settings.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="?attr/colorBackground">

    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="vertical" android:padding="16dp">

        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="Appearance" android:textSize="14sp" android:textStyle="bold"
            android:textColor="?attr/colorPrimary" android:paddingBottom="8dp"/>

        <com.google.android.material.card.MaterialCardView
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:layout_marginBottom="16dp">
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="vertical" android:padding="16dp">

                <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:text="Theme" android:textStyle="bold" android:paddingBottom="8dp"/>
                <RadioGroup android:id="@+id/theme_group" android:layout_width="match_parent"
                    android:layout_height="wrap_content" android:orientation="horizontal">
                    <RadioButton android:id="@+id/radio_theme_dark"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"
                        android:text="Dark" android:layout_marginEnd="16dp"/>
                    <RadioButton android:id="@+id/radio_theme_light"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"
                        android:text="Light"/>
                </RadioGroup>

                <View android:layout_width="match_parent" android:layout_height="1dp"
                    android:background="?attr/colorOutlineVariant" android:layout_marginVertical="12dp"/>

                <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:text="Sub-theme" android:textStyle="bold" android:paddingBottom="8dp"/>
                <RadioGroup android:id="@+id/sub_theme_group" android:layout_width="match_parent"
                    android:layout_height="wrap_content" android:orientation="horizontal">
                    <RadioButton android:id="@+id/radio_solid"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"
                        android:text="Solid" android:layout_marginEnd="8dp"/>
                    <RadioButton android:id="@+id/radio_dual"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"
                        android:text="Dual-Shift" android:layout_marginEnd="8dp"/>
                    <RadioButton android:id="@+id/radio_dynamic"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"
                        android:text="Dynamic"/>
                </RadioGroup>

                <LinearLayout android:id="@+id/panel_solid"
                    android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="horizontal" android:paddingTop="12dp">
                    <Button android:id="@+id/primary_color_btn"
                        android:layout_width="0dp" android:layout_height="48dp"
                        android:layout_weight="1" android:layout_marginEnd="8dp" android:text="Primary"/>
                    <Button android:id="@+id/secondary_color_btn"
                        android:layout_width="0dp" android:layout_height="48dp"
                        android:layout_weight="1" android:text="Secondary"/>
                </LinearLayout>

                <LinearLayout android:id="@+id/panel_dual_shift"
                    android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="horizontal" android:paddingTop="12dp" android:visibility="gone">
                    <Button android:id="@+id/shift_color1_btn"
                        android:layout_width="0dp" android:layout_height="48dp"
                        android:layout_weight="1" android:layout_marginEnd="8dp" android:text="Color 1"/>
                    <Button android:id="@+id/shift_color2_btn"
                        android:layout_width="0dp" android:layout_height="48dp"
                        android:layout_weight="1" android:text="Color 2"/>
                </LinearLayout>

                <TextView android:id="@+id/panel_dynamic"
                    android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:paddingTop="12dp" android:visibility="gone"
                    android:text="Uses system accent (Android 12+) or time-of-day palette."
                    android:textColor="?attr/colorOnSurfaceVariant"/>

            </LinearLayout>
        </com.google.android.material.card.MaterialCardView>

        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="Reader" android:textSize="14sp" android:textStyle="bold"
            android:textColor="?attr/colorPrimary" android:paddingBottom="8dp"/>

        <com.google.android.material.card.MaterialCardView
            android:layout_width="match_parent" android:layout_height="wrap_content">
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="vertical" android:padding="16dp">

                <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Grayscale"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_grayscale"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>

                <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="horizontal" android:gravity="center_vertical" android:paddingTop="8dp">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Invert Colors"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_invert"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>

                <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="horizontal" android:gravity="center_vertical" android:paddingTop="8dp">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Crop Borders"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_crop_borders"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>

                <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="horizontal" android:gravity="center_vertical" android:paddingTop="8dp">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Keep Screen On"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_keep_screen"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>

            </LinearLayout>
        </com.google.android.material.card.MaterialCardView>

    </LinearLayout>
</ScrollView>
EOF

cat > "$R/layout/fragment_manga_detail.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="?attr/colorBackground">

    <LinearLayout android:id="@+id/detail_top_bar"
        android:layout_width="0dp" android:layout_height="56dp"
        android:orientation="horizontal" android:gravity="center_vertical"
        android:background="?attr/colorSurface"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent">

        <ImageButton android:id="@+id/detail_back_btn"
            android:layout_width="48dp" android:layout_height="48dp"
            android:src="@drawable/ic_back"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="Back"/>

        <TextView android:id="@+id/detail_title"
            android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:textSize="18sp" android:textStyle="bold"
            android:singleLine="true" android:ellipsize="end" android:paddingEnd="8dp"/>

    </LinearLayout>

    <ProgressBar android:id="@+id/detail_progress"
        android:layout_width="match_parent" android:layout_height="4dp"
        android:indeterminate="true" android:visibility="gone"
        style="@style/Widget.Material3.LinearProgressIndicator"
        app:layout_constraintTop_toBottomOf="@id/detail_top_bar"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"/>

    <androidx.core.widget.NestedScrollView
        android:layout_width="0dp" android:layout_height="0dp"
        app:layout_constraintTop_toBottomOf="@id/detail_progress"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent">

        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
            android:orientation="vertical">

            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="horizontal" android:padding="16dp">

                <ImageView android:id="@+id/detail_cover"
                    android:layout_width="120dp" android:layout_height="180dp"
                    android:scaleType="centerCrop" android:background="@color/surface_variant"/>

                <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
                    android:layout_weight="1" android:orientation="vertical" android:paddingStart="16dp">

                    <TextView android:id="@+id/detail_author"
                        android:layout_width="match_parent" android:layout_height="wrap_content"
                        android:textSize="14sp" android:alpha="0.7"/>

                    <TextView android:id="@+id/detail_status"
                        android:layout_width="match_parent" android:layout_height="wrap_content"
                        android:textSize="13sp" android:paddingTop="4dp"/>

                    <Button android:id="@+id/library_btn"
                        android:layout_width="match_parent" android:layout_height="wrap_content"
                        android:layout_marginTop="12dp" android:text="Add to Library"
                        style="@style/Widget.Material3.Button.OutlinedButton"/>

                </LinearLayout>
            </LinearLayout>

            <TextView android:id="@+id/detail_description"
                android:layout_width="match_parent" android:layout_height="wrap_content"
                android:paddingHorizontal="16dp" android:paddingBottom="8dp"
                android:textSize="14sp" android:alpha="0.85" android:maxLines="4" android:ellipsize="end"/>

            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="horizontal" android:gravity="center_vertical"
                android:paddingHorizontal="16dp" android:paddingVertical="8dp">
                <TextView android:id="@+id/chapter_count"
                    android:layout_width="0dp" android:layout_height="wrap_content"
                    android:layout_weight="1" android:textStyle="bold"/>
            </LinearLayout>

            <androidx.recyclerview.widget.RecyclerView android:id="@+id/chapter_recycler"
                android:layout_width="match_parent" android:layout_height="wrap_content"
                android:nestedScrollingEnabled="false"/>

        </LinearLayout>
    </androidx.core.widget.NestedScrollView>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

cat > "$R/layout/fragment_reader.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="#000">

    <androidx.viewpager2.widget.ViewPager2
        android:id="@+id/reader_pager"
        android:layout_width="match_parent" android:layout_height="match_parent"/>

    <ProgressBar android:id="@+id/reader_progress"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="center" android:visibility="gone"/>

    <LinearLayout android:id="@+id/reader_top_bar"
        android:layout_width="match_parent" android:layout_height="56dp"
        android:layout_gravity="top" android:orientation="horizontal"
        android:gravity="center_vertical" android:background="#AA000000" android:paddingHorizontal="8dp">

        <ImageButton android:id="@+id/reader_back_btn"
            android:layout_width="48dp" android:layout_height="48dp"
            android:src="@drawable/ic_back"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="Back" android:tint="#FFFFFF"/>

        <TextView android:id="@+id/reader_chapter_title"
            android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:textColor="#FFFFFF" android:textSize="15sp"
            android:singleLine="true" android:ellipsize="end" android:paddingHorizontal="8dp"/>

    </LinearLayout>

    <LinearLayout android:id="@+id/reader_bottom_bar"
        android:layout_width="match_parent" android:layout_height="72dp"
        android:layout_gravity="bottom" android:orientation="horizontal"
        android:gravity="center_vertical" android:background="#AA000000" android:paddingHorizontal="8dp">

        <TextView android:id="@+id/page_indicator"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:textColor="#FFFFFF" android:textSize="13sp"
            android:minWidth="52dp" android:gravity="center"/>

        <com.google.android.material.slider.Slider
            android:id="@+id/page_slider"
            android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:valueFrom="0" android:valueTo="1" android:stepSize="1"/>

    </LinearLayout>

</FrameLayout>
EOF

cat > "$R/layout/item_manga_card.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<com.google.android.material.card.MaterialCardView
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:layout_margin="6dp" app:cardCornerRadius="8dp" app:cardElevation="2dp">

    <FrameLayout android:layout_width="match_parent" android:layout_height="wrap_content">

        <ImageView android:id="@+id/manga_cover"
            android:layout_width="match_parent" android:layout_height="200dp"
            android:scaleType="centerCrop" android:background="@color/surface_variant"/>

        <TextView android:id="@+id/manga_unread_badge"
            android:layout_width="28dp" android:layout_height="28dp"
            android:layout_gravity="top|end" android:layout_margin="4dp"
            android:background="@drawable/bg_badge" android:gravity="center"
            android:textColor="#FFFFFF" android:textSize="11sp" android:textStyle="bold"
            android:visibility="gone"/>

        <LinearLayout android:layout_width="match_parent" android:layout_height="64dp"
            android:layout_gravity="bottom" android:background="@drawable/gradient_bottom"
            android:gravity="bottom" android:padding="8dp">
            <TextView android:id="@+id/manga_title"
                android:layout_width="match_parent" android:layout_height="wrap_content"
                android:textColor="#FFFFFF" android:textSize="13sp" android:textStyle="bold"
                android:maxLines="2" android:ellipsize="end"/>
        </LinearLayout>

    </FrameLayout>

</com.google.android.material.card.MaterialCardView>
EOF

cat > "$R/layout/item_chapter.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:orientation="horizontal" android:gravity="center_vertical"
    android:paddingHorizontal="16dp" android:paddingVertical="12dp"
    android:background="?attr/selectableItemBackground">

    <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
        android:layout_weight="1" android:orientation="vertical">

        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
            android:orientation="horizontal" android:gravity="center_vertical">
            <TextView android:id="@+id/chapter_title"
                android:layout_width="0dp" android:layout_height="wrap_content"
                android:layout_weight="1" android:textSize="15sp"/>
            <ImageView android:id="@+id/chapter_bookmark_icon"
                android:layout_width="16dp" android:layout_height="16dp"
                android:src="@drawable/ic_settings" android:visibility="gone"
                android:layout_marginEnd="4dp"/>
            <ImageView android:id="@+id/chapter_download_icon"
                android:layout_width="16dp" android:layout_height="16dp"
                android:src="@drawable/ic_updates" android:visibility="gone"/>
        </LinearLayout>

        <TextView android:id="@+id/chapter_date"
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:textSize="12sp" android:alpha="0.6" android:paddingTop="2dp"/>

    </LinearLayout>

    <ImageButton android:id="@+id/chapter_download_btn"
        android:layout_width="40dp" android:layout_height="40dp"
        android:src="@drawable/ic_updates"
        android:background="?attr/selectableItemBackgroundBorderless"
        android:contentDescription="Download"/>

</LinearLayout>
EOF

cat > "$R/layout/item_source_card.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<com.google.android.material.card.MaterialCardView
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:layout_marginHorizontal="16dp" android:layout_marginVertical="6dp"
    app:cardCornerRadius="12dp">

    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal" android:gravity="center_vertical" android:padding="16dp">

        <ImageView android:id="@+id/source_icon"
            android:layout_width="40dp" android:layout_height="40dp" android:scaleType="fitCenter"/>

        <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:orientation="vertical" android:paddingHorizontal="12dp">
            <TextView android:id="@+id/source_name"
                android:layout_width="match_parent" android:layout_height="wrap_content"
                android:textSize="16sp" android:textStyle="bold"/>
            <TextView android:id="@+id/source_lang"
                android:layout_width="match_parent" android:layout_height="wrap_content"
                android:textSize="12sp" android:alpha="0.6"/>
        </LinearLayout>

        <Button android:id="@+id/source_browse_btn"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:text="Browse" style="@style/Widget.Material3.Button.OutlinedButton"/>

    </LinearLayout>

</com.google.android.material.card.MaterialCardView>
EOF

cat > "$R/layout/item_reader_page.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="#000">

    <com.github.chrisbanes.photoview.PhotoView
        android:id="@+id/page_image"
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:scaleType="fitCenter"/>

    <ProgressBar android:id="@+id/page_progress"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="center"/>

    <ImageView android:id="@+id/page_error"
        android:layout_width="48dp" android:layout_height="48dp"
        android:layout_gravity="center" android:src="@drawable/ic_sources"
        android:alpha="0.5" android:visibility="gone"/>

</FrameLayout>
EOF

echo "📐  Layouts done"

# ═══════════════════════════════════════════════════════════════════════════════
# MENU
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$R/menu/bottom_nav_menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@+id/nav_library"  android:icon="@drawable/ic_library"  android:title="Library"/>
    <item android:id="@+id/nav_search"   android:icon="@drawable/ic_search"   android:title="Search"/>
    <item android:id="@+id/nav_sources"  android:icon="@drawable/ic_sources"  android:title="Sources"/>
    <item android:id="@+id/nav_updates"  android:icon="@drawable/ic_updates"  android:title="Updates"/>
    <item android:id="@+id/nav_settings" android:icon="@drawable/ic_settings" android:title="Settings"/>
</menu>
EOF

echo "📋  Menu done"

# ═══════════════════════════════════════════════════════════════════════════════
# VALUES
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$R/values/strings.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">ComiFountain</string>
    <string name="nav_library">Library</string>
    <string name="nav_search">Search</string>
    <string name="nav_sources">Sources</string>
    <string name="nav_updates">Updates</string>
    <string name="nav_settings">Settings</string>
    <string name="add_to_library">Add to Library</string>
    <string name="remove_from_library">Remove from Library</string>
    <string name="mark_all_read">Mark All Read</string>
    <string name="loading">Loading…</string>
    <string name="no_results">No results found</string>
    <string name="error_loading">Failed to load. Tap to retry.</string>
</resources>
EOF

cat > "$R/values/colors.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="cf_purple">#9b30ff</color>
    <color name="cf_red">#e63946</color>
    <color name="surface_dark">#1a1a2e</color>
    <color name="surface_variant">#2d2d44</color>
    <color name="background_dark">#121212</color>
    <color name="surface_light">#FFFFFF</color>
    <color name="background_light">#F5F5F5</color>
    <color name="text_primary_dark">#FFFFFFFF</color>
    <color name="text_secondary_dark">#AAFFFFFF</color>
    <color name="ripple_accent">#339b30ff</color>
    <color name="transparent">#00000000</color>
</resources>
EOF

cat > "$R/values/themes.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.ComiFountain" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="colorPrimary">@color/cf_purple</item>
        <item name="colorSecondary">@color/cf_red</item>
        <item name="colorBackground">@color/background_dark</item>
        <item name="android:windowBackground">@color/background_dark</item>
        <item name="colorSurface">@color/surface_dark</item>
        <item name="colorOnSurface">@color/text_primary_dark</item>
        <item name="android:navigationBarColor">@color/surface_dark</item>
        <item name="android:statusBarColor">#00000000</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
</resources>
EOF

cat > "$R/values/dimens.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <dimen name="bottom_nav_height">56dp</dimen>
    <dimen name="manga_card_corner">8dp</dimen>
    <dimen name="manga_cover_height">200dp</dimen>
    <dimen name="grid_spacing">6dp</dimen>
    <dimen name="detail_cover_width">120dp</dimen>
    <dimen name="detail_cover_height">180dp</dimen>
    <dimen name="source_card_corner">12dp</dimen>
</resources>
EOF

echo "🎨  Values done"

# ═══════════════════════════════════════════════════════════════════════════════
# DRAWABLES
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$R/drawable/ic_library.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="?attr/colorOnSurface"
        android:pathData="M19,2L14,2a2,2,0,0,0,-2,2L12,6a2,2,0,0,0,2,2L19,8a2,2,0,0,0,2,-2L21,4a2,2,0,0,0,-2,-2ZM19,10L14,10a2,2,0,0,0,-2,2L12,14a2,2,0,0,0,2,2L19,16a2,2,0,0,0,2,-2L21,12a2,2,0,0,0,-2,-2ZM5,2L10,2a2,2,0,0,1,2,2L12,20a2,2,0,0,1,-2,2L5,22a2,2,0,0,1,-2,-2L3,4a2,2,0,0,1,2,-2Z"/>
</vector>
EOF

cat > "$R/drawable/ic_search.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="?attr/colorOnSurface"
        android:pathData="M15.5,14L14.71,14L14.43,13.73A6.5,6.5,0,1,0,13.73,14.43L14,14.71L14,15.5L19,20.5L20.5,19ZM9.5,14a4.5,4.5,0,1,1,4.5,-4.5,4.5,4.5,0,0,1,-4.5,4.5Z"/>
</vector>
EOF

cat > "$R/drawable/ic_sources.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="?attr/colorOnSurface"
        android:pathData="M12,2C6.48,2 2,6.48 2,12s4.48,10 10,10 10,-4.48 10,-10S17.52,2 12,2zM11,17.93c-3.95,-0.49 -7,-3.85 -7,-7.93 0,-0.62 0.08,-1.21 0.21,-1.79L9,13v1c0,1.1 0.9,2 2,2v1.93zM17.9,17.39c-0.26,-0.81 -1,-1.39 -1.9,-1.39h-1v-3c0,-0.55 -0.45,-1 -1,-1H8v-2h2c0.55,0 1,-0.45 1,-1V7h2c1.1,0 2,-0.9 2,-2v-0.41c2.93,1.19 5,4.06 5,7.41 0,2.08 -0.8,3.97 -2.1,5.39z"/>
</vector>
EOF

cat > "$R/drawable/ic_updates.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="?attr/colorOnSurface"
        android:pathData="M12,4V1L8,5l4,4V6c3.31,0 6,2.69 6,6 0,1.01 -0.25,1.97 -0.7,2.8l1.46,1.46C19.54,15.03 20,13.57 20,12c0,-4.42 -3.58,-8 -8,-8zM12,18c-3.31,0 -6,-2.69 -6,-6 0,-1.01 0.25,-1.97 0.7,-2.8L5.24,7.74C4.46,8.97 4,10.43 4,12c0,4.42 3.58,8 8,8v3l4,-4 -4,-4v3z"/>
</vector>
EOF

cat > "$R/drawable/ic_settings.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="?attr/colorOnSurface"
        android:pathData="M19.14,12.94c0.04,-0.3 0.06,-0.61 0.06,-0.94 0,-0.32 -0.02,-0.64 -0.07,-0.94l2.03,-1.58c0.18,-0.14 0.23,-0.41 0.12,-0.61l-1.92,-3.32c-0.12,-0.22 -0.37,-0.29 -0.59,-0.22l-2.39,0.96c-0.5,-0.38 -1.03,-0.7 -1.62,-0.94L14.4,2.81c-0.04,-0.24 -0.24,-0.41 -0.48,-0.41h-3.84c-0.24,0 -0.43,0.17 -0.47,0.41L9.25,5.35C8.66,5.59 8.12,5.92 7.63,6.29L5.24,5.33c-0.22,-0.08 -0.47,0 -0.59,0.22L2.74,8.87C2.62,9.08 2.66,9.34 2.86,9.48l2.03,1.58C4.84,11.36 4.8,11.69 4.8,12s0.02,0.64 0.07,0.94l-2.03,1.58c-0.18,0.14 -0.23,0.41 -0.12,0.61l1.92,3.32c0.12,0.22 0.37,0.29 0.59,0.22l2.39,-0.96c0.5,0.38 1.03,0.7 1.62,0.94l0.36,2.54c0.05,0.24 0.24,0.41 0.48,0.41h3.84c0.24,0 0.44,-0.17 0.47,-0.41l0.36,-2.54c0.59,-0.24 1.13,-0.56 1.62,-0.94l2.39,0.96c0.22,0.08 0.47,0 0.59,-0.22l1.92,-3.32c0.12,-0.22 0.07,-0.47 -0.12,-0.61L19.14,12.94zM12,15.6c-1.98,0 -3.6,-1.62 -3.6,-3.6 0,-1.98 1.62,-3.6 3.6,-3.6 1.98,0 3.6,1.62 3.6,3.6 0,1.98 -1.62,3.6 -3.6,3.6z"/>
</vector>
EOF

cat > "$R/drawable/ic_back.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="?attr/colorOnSurface"
        android:pathData="M20,11H7.83l5.59,-5.59L12,4l-8,8 8,8 1.41,-1.41L7.83,13H20v-2z"/>
</vector>
EOF

cat > "$R/drawable/ic_source_generic.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="40dp" android:height="40dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="@color/cf_purple"
        android:pathData="M12,2C6.48,2 2,6.48 2,12s4.48,10 10,10 10,-4.48 10,-10S17.52,2 12,2zM13,17h-2v-6h2v6zM13,9h-2V7h2v2z"/>
</vector>
EOF

cat > "$R/drawable/ic_source_allanime.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="40dp" android:height="40dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="@color/cf_purple"
        android:pathData="M12,2L2,7l10,5 10,-5zM2,17l10,5 10,-5M2,12l10,5 10,-5"/>
</vector>
EOF

cat > "$R/drawable/ic_source_local.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="40dp" android:height="40dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="@color/cf_red"
        android:pathData="M10,4H4C2.9,4 2,4.9 2,6L2,18c0,1.1 0.9,2 2,2L20,20c1.1,0 2,-0.9 2,-2L22,8c0,-1.1 -0.9,-2 -2,-2L12,6L10,4z"/>
</vector>
EOF

cat > "$R/drawable/ic_manga_placeholder.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="120dp" android:height="180dp" android:viewportWidth="120" android:viewportHeight="180">
    <path android:fillColor="@color/surface_variant" android:pathData="M0,0L120,0L120,180L0,180Z"/>
    <path android:fillColor="#33FFFFFF" android:pathData="M45,70L75,70L75,110L45,110Z"/>
</vector>
EOF

cat > "$R/drawable/gradient_bottom.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient android:type="linear" android:angle="270"
        android:startColor="#00000000" android:endColor="#CC000000"/>
</shape>
EOF

cat > "$R/drawable/bg_badge.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="@color/cf_purple"/>
</shape>
EOF

echo "🖼️   Drawables done"

# ═══════════════════════════════════════════════════════════════════════════════
# XML CONFIGS
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$R/xml/file_paths.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="downloads" path="Downloads/"/>
    <cache-path name="cbz_cache" path="."/>
</paths>
EOF

cat > "$R/xml/backup_rules.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <include domain="sharedpref" path="comifountain_prefs.xml"/>
    <exclude domain="database" path="comifountain.db-shm"/>
    <exclude domain="database" path="comifountain.db-wal"/>
</full-backup-content>
EOF

cat > "$R/xml/data_extraction_rules.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <include domain="sharedpref" path="comifountain_prefs.xml"/>
    </cloud-backup>
    <device-transfer>
        <include domain="database" path="comifountain.db"/>
    </device-transfer>
</data-extraction-rules>
EOF

echo "📄  XML configs done"

# ═══════════════════════════════════════════════════════════════════════════════
# GRADLE + PROGUARD
# ═══════════════════════════════════════════════════════════════════════════════

cat > "gradle.properties" << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=false
EOF

cat > "app/proguard-rules.pro" << 'EOF'
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keepclassmembers,allowobfuscation class * { @com.google.gson.annotations.SerializedName <fields>; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class * { *; }
-keep class org.jsoup.** { *; }
-keep class com.fountainpdl.comifountain.sources.** { *; }
-keep class com.fountainpdl.comifountain.data.model.** { *; }
EOF

# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS.GRADLE — add JitPack for PhotoView
# ═══════════════════════════════════════════════════════════════════════════════

cat > "settings.gradle" << 'EOF'
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
rootProject.name = "ComiFountain"
include ':app'
EOF

echo ""
echo "✅  ComiFountain — full project generated!"
echo ""
echo "Java files:"
find app/src -name "*.java" | sort | sed 's/^/  📄 /'
echo ""
echo "Layouts:"
find app/src -name "*.xml" -path "*/layout/*" | sort | sed 's/^/  🖼  /'
echo ""
echo "Next steps:"
echo "  1. Open project root in Android Studio"
echo "  2. File → Sync Project with Gradle Files"
echo "  3. Add your app icon to res/mipmap-* folders"
echo "  4. Build → Run on device or emulator"
