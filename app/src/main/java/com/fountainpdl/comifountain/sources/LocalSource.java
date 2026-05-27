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
