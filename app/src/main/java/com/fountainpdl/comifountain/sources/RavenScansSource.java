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
