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
