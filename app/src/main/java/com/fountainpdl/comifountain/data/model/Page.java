package com.fountainpdl.comifountain.data.model;

/**
 * Single page in a chapter.
 * NOT persisted in Room — fetched from source on demand or from local storage.
 *
 * IMPORTANT: always sort pages by `index`, never alphabetically.
 */
public class Page {

    public int    index;        // 0-based; sort by this
    public String url;          // Remote image URL
    public String localPath;    // Non-null when downloaded (absolute file or content URI)
    public PageState state;

    public enum PageState { WAITING, LOADING, READY, ERROR }

    public Page() { state = PageState.WAITING; }

    public Page(int index, String url) {
        this.index = index;
        this.url   = url;
        this.state = PageState.WAITING;
    }

    public Page(int index, String url, String localPath) {
        this.index     = index;
        this.url       = url;
        this.localPath = localPath;
        this.state     = localPath != null ? PageState.READY : PageState.WAITING;
    }

    /** Returns the URI/path to load — local takes priority over remote. */
    public String getLoadPath() {
        return (localPath != null && !localPath.isEmpty()) ? localPath : url;
    }

    public boolean isLocal() { return localPath != null && !localPath.isEmpty(); }
    public boolean isReady() { return state == PageState.READY; }

    @Override
    public String toString() {
        return "Page{index=" + index + ", state=" + state + "}";
    }
}
