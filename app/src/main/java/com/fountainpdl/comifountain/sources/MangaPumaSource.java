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
