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
