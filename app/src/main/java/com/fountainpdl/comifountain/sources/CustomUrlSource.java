package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.*;
import com.fountainpdl.comifountain.network.HttpClient;
import okhttp3.*;
import org.jsoup.Jsoup;
import org.jsoup.nodes.*;
import org.jsoup.select.Elements;
import java.util.*;
import java.util.regex.*;

/**
 * Generic source for user-added URLs.
 * Tries common manga site selectors and falls back to heuristic scraping.
 */
public class CustomUrlSource implements Source {

    private final CustomSource config;

    public CustomUrlSource(CustomSource config) { this.config = config; }

    @Override public String getId()        { return "custom_" + config.id; }
    @Override public String getName()      { return config.name; }
    @Override public String getLang()      { return config.lang; }
    @Override public String getBaseUrl()   { return config.baseUrl; }
    @Override public int    getIconResId() { return R.drawable.ic_source_generic; }

    @Override
    public List<Manga> browse(int page) throws Exception {
        String url = config.baseUrl + (page > 1 ? "?page=" + page : "");
        return scrapeList(fetch(url), url);
    }

    @Override
    public List<Manga> search(String query, int page) throws Exception {
        String path = config.searchPath != null
            ? config.searchPath.replace("{query}", java.net.URLEncoder.encode(query, "UTF-8"))
            : "/?s=" + java.net.URLEncoder.encode(query, "UTF-8");
        String url = config.baseUrl + path;
        return scrapeList(fetch(url), url);
    }

    @Override
    public Manga getMangaDetails(String mangaId) throws Exception {
        Document doc = fetch(config.baseUrl + "/manga/" + mangaId);
        Manga m = new Manga();
        m.id       = Manga.buildId(getId(), mangaId);
        m.sourceId = getId(); m.sourceName = getName();
        m.url      = config.baseUrl + "/manga/" + mangaId;

        // Try common title selectors
        for (String sel : new String[]{".post-title h1","h1.entry-title","h1.manga-title","h1","h2"}) {
            Element el = doc.selectFirst(sel);
            if (el != null) { m.title = el.text(); break; }
        }
        // Cover
        for (String sel : new String[]{".summary_image img",".thumb img",".manga-cover img","img.cover"}) {
            Element el = doc.selectFirst(sel);
            if (el != null) { m.cover = el.attr("src"); break; }
        }
        // Description
        for (String sel : new String[]{".summary__content",".manga-summary","#synopsis",".description"}) {
            Element el = doc.selectFirst(sel);
            if (el != null) { m.description = el.text(); break; }
        }
        return m;
    }

    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        Document doc = fetch(config.baseUrl + "/manga/" + mangaId);
        List<Chapter> chapters = new ArrayList<>();
        Elements items = doc.select(".wp-manga-chapter, #chapterlist li, .chapter-list li, .listing-chapters_wrap li");
        int index = 0;
        for (Element item : items) {
            Element link = item.selectFirst("a");
            if (link == null) continue;
            String chapSlug = lastSlug(link.attr("href"));
            String title    = link.text().trim();
            float  num      = extractNum(title);
            Chapter c       = new Chapter();
            c.id       = Chapter.buildId(getId(), chapSlug);
            c.mangaId  = Manga.buildId(getId(), mangaId);
            c.sourceId = getId(); c.title = title;
            c.number = num; c.index = index++;
            chapters.add(c);
        }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        String url  = config.baseUrl + "/" + chapterId;
        String html = fetchRaw(url);
        // Try ts_reader.run first
        Matcher m = Pattern.compile("ts_reader\\.run\\(\\s*(\\{.*?\\})\\s*\\)", Pattern.DOTALL).matcher(html);
        if (m.find()) {
            try {
                com.google.gson.JsonObject obj = com.google.gson.JsonParser.parseString(m.group(1)).getAsJsonObject();
                com.google.gson.JsonArray sources = obj.getAsJsonArray("sources");
                if (sources != null && sources.size() > 0) {
                    com.google.gson.JsonArray images = sources.get(0).getAsJsonObject().getAsJsonArray("images");
                    List<Page> pages = new ArrayList<>();
                    for (int i = 0; i < images.size(); i++) pages.add(new Page(i, images.get(i).getAsString()));
                    return pages;
                }
            } catch (Exception ignored) {}
        }
        // Fallback: img tags
        Document doc = Jsoup.parse(html);
        List<Page> pages = new ArrayList<>();
        int idx = 0;
        for (Element img : doc.select(".reading-content img,.chapter-content img,#readerarea img")) {
            String src = img.hasAttr("data-src") ? img.attr("data-src") : img.attr("src");
            if (src.startsWith("http")) pages.add(new Page(idx++, src.trim()));
        }
        return pages;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private List<Manga> scrapeList(Document doc, String baseUrl) {
        List<Manga> result = new ArrayList<>();
        Elements items = doc.select(".manga-poster,.c-image-hover,.page-item-detail,.bsx,.bs,.manga-item");
        for (Element item : items) {
            Element link = item.selectFirst("a");
            Element img  = item.selectFirst("img");
            Element name = item.selectFirst(".manga-name,.post-title,.tt,h3,h2");
            if (link == null) continue;
            String href  = link.attr("href");
            String rawId = lastSlug(href);
            String title = name != null ? name.text() : rawId;
            String cover = img != null ? (img.hasAttr("data-src") ? img.attr("data-src") : img.attr("src")) : null;
            Manga manga  = new Manga(Manga.buildId(getId(), rawId), title, cover, getId(), getName());
            manga.url    = href;
            result.add(manga);
        }
        return result;
    }

    private Document fetch(String url) throws Exception { return Jsoup.parse(fetchRaw(url)); }

    private String fetchRaw(String url) throws Exception {
        Request req = new Request.Builder().url(url)
            .header("Referer", config.baseUrl).build();
        try (okhttp3.Response r = HttpClient.get().newCall(req).execute()) {
            if (!r.isSuccessful() || r.body() == null) throw new Exception("HTTP " + r.code());
            return r.body().string();
        }
    }

    private String lastSlug(String href) {
        href = href.replaceAll("/$",""); int i = href.lastIndexOf('/');
        return i >= 0 ? href.substring(i+1) : href;
    }

    private float extractNum(String title) {
        Matcher m = Pattern.compile("(\\d+\\.?\\d*)").matcher(title);
        if (m.find()) try { return Float.parseFloat(m.group(1)); } catch (Exception ignored) {}
        return 0;
    }
}
