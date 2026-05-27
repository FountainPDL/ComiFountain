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
