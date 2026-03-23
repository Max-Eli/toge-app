"use client";

import { useState, useEffect, useRef } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { Search, Play, Clock, Eye, Plus, X, Loader2, Upload } from "lucide-react";
import { getVideos, createVideo, incrementViews, Video } from "@/services/videos";
import { getUserProfile } from "@/services/users";

const categories = ["All", "Engine", "Suspension", "Turbo", "Exhaust", "Body Work", "Interior", "Electrical", "Maintenance", "Restoration"];

const difficultyColors: Record<string, string> = {
  Beginner: "text-green-400 bg-green-400/10",
  Intermediate: "text-yellow-400 bg-yellow-400/10",
  Advanced: "text-red-400 bg-red-400/10",
};

export default function VideosPage() {
  const { user } = useAuth();
  const [videos, setVideos] = useState<Video[]>([]);
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [showUpload, setShowUpload] = useState(false);
  const [playingVideo, setPlayingVideo] = useState<Video | null>(null);

  useEffect(() => {
    loadVideos();
  }, []);

  async function loadVideos() {
    try {
      const data = await getVideos();
      setVideos(data);
    } catch (err) {
      console.error("Error loading videos:", err);
    } finally {
      setLoading(false);
    }
  }

  async function handlePlay(video: Video) {
    setPlayingVideo(video);
    try {
      await incrementViews(video.id);
    } catch (err) {
      // silent fail for view count
    }
  }

  const filteredVideos = videos.filter((v) => {
    const matchesCategory = selectedCategory === "All" || v.category === selectedCategory;
    const matchesSearch = v.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      v.description.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  if (loading) {
    return <div className="flex min-h-[50vh] items-center justify-center"><Loader2 size={32} className="animate-spin text-accent" /></div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold">How-To Videos</h1>
          <p className="mt-1 text-sm text-muted">Learn from the community</p>
        </div>
        <button onClick={() => setShowUpload(true)} className="flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 text-sm font-medium text-white hover:bg-accent-hover">
          <Upload size={18} />
          Upload Video
        </button>
      </div>

      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search videos..." className="w-full rounded-xl border border-border bg-card/50 py-2.5 pl-9 pr-4 text-sm placeholder-muted/50 outline-none focus:border-accent" />
      </div>

      <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
        {categories.map((cat) => (
          <button key={cat} onClick={() => setSelectedCategory(cat)} className={`flex-shrink-0 rounded-full px-4 py-1.5 text-xs font-medium transition-colors ${selectedCategory === cat ? "bg-accent text-white" : "border border-border/50 bg-card/30 text-muted hover:text-foreground"}`}>
            {cat}
          </button>
        ))}
      </div>

      {filteredVideos.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <Play size={48} className="text-muted/30" />
          <h3 className="mt-4 font-semibold">No videos yet</h3>
          <p className="mt-1 text-sm text-muted">Be the first to upload a how-to video</p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filteredVideos.map((video) => (
            <div key={video.id} onClick={() => handlePlay(video)} className="group cursor-pointer overflow-hidden rounded-2xl border border-border/50 bg-card/30 transition-all hover:border-accent/30 hover:bg-card/50">
              <div className="relative aspect-video overflow-hidden">
                {video.thumbnailURL ? (
                  <img src={video.thumbnailURL} alt={video.title} className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105" />
                ) : (
                  <div className="h-full w-full bg-gradient-to-br from-accent/20 to-accent/5 flex items-center justify-center">
                    <Play size={32} className="text-muted/30" />
                  </div>
                )}
                <div className="absolute inset-0 flex items-center justify-center bg-black/20 opacity-0 transition-opacity group-hover:opacity-100">
                  <div className="flex h-14 w-14 items-center justify-center rounded-full bg-accent/90 text-white"><Play size={24} className="ml-1" /></div>
                </div>
                {video.duration && (
                  <span className="absolute bottom-2 right-2 flex items-center gap-1 rounded bg-black/70 px-1.5 py-0.5 text-xs font-medium">
                    <Clock size={10} />{video.duration}
                  </span>
                )}
                {video.difficulty && (
                  <span className={`absolute left-2 top-2 rounded-full px-2 py-0.5 text-xs font-medium ${difficultyColors[video.difficulty] || ""}`}>
                    {video.difficulty}
                  </span>
                )}
              </div>
              <div className="p-4">
                <h3 className="font-semibold line-clamp-2">{video.title}</h3>
                <p className="mt-1 text-xs text-muted line-clamp-1">{video.authorName}</p>
                <div className="mt-2 flex items-center gap-3 text-xs text-muted">
                  <span className="flex items-center gap-1"><Eye size={12} />{video.views?.toLocaleString() || 0}</span>
                  <span className="rounded-full bg-card px-2 py-0.5">{video.category}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Video Player Modal */}
      {playingVideo && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/80" onClick={() => setPlayingVideo(null)} />
          <div className="relative w-full max-w-3xl rounded-2xl border border-border/50 bg-background">
            <button onClick={() => setPlayingVideo(null)} className="absolute -top-10 right-0 text-white hover:text-accent"><X size={24} /></button>
            <div className="aspect-video overflow-hidden rounded-t-2xl">
              {playingVideo.videoURL ? (
                <iframe src={playingVideo.videoURL} className="h-full w-full" allowFullScreen />
              ) : (
                <div className="flex h-full w-full items-center justify-center bg-black">
                  <p className="text-muted">Video URL not available</p>
                </div>
              )}
            </div>
            <div className="p-4">
              <h2 className="text-lg font-bold">{playingVideo.title}</h2>
              <p className="mt-1 text-sm text-muted">{playingVideo.authorName}</p>
              <p className="mt-2 text-sm text-muted">{playingVideo.description}</p>
            </div>
          </div>
        </div>
      )}

      {/* Upload Modal */}
      {showUpload && (
        <UploadVideoModal
          userId={user?.uid || ""}
          userName={user?.displayName || ""}
          onClose={() => setShowUpload(false)}
          onUploaded={() => { setShowUpload(false); loadVideos(); }}
        />
      )}
    </div>
  );
}

function UploadVideoModal({ userId, userName, onClose, onUploaded }: { userId: string; userName: string; onClose: () => void; onUploaded: () => void }) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [videoURL, setVideoURL] = useState("");
  const [category, setCategory] = useState("Engine");
  const [difficulty, setDifficulty] = useState<"Beginner" | "Intermediate" | "Advanced">("Beginner");
  const [duration, setDuration] = useState("");
  const [uploading, setUploading] = useState(false);

  async function handleUpload() {
    if (!title.trim() || !videoURL.trim()) return;
    setUploading(true);
    try {
      await createVideo({
        title: title.trim(),
        description: description.trim(),
        videoURL: videoURL.trim(),
        authorId: userId,
        authorName: userName,
        authorAvatar: userName?.charAt(0) || "U",
        category,
        difficulty,
        duration: duration.trim(),
      });
      onUploaded();
    } catch (err) {
      console.error("Error uploading video:", err);
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative w-full max-w-lg rounded-2xl border border-border/50 bg-background p-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold">Upload How-To Video</h2>
          <button onClick={onClose} className="text-muted hover:text-foreground"><X size={20} /></button>
        </div>

        <div className="mt-4 space-y-4">
          <div><label className="mb-1.5 block text-sm font-medium">Title</label><input type="text" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. How to install coilovers" className="w-full rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent" /></div>
          <div><label className="mb-1.5 block text-sm font-medium">Video URL (YouTube embed link)</label><input type="text" value={videoURL} onChange={(e) => setVideoURL(e.target.value)} placeholder="https://www.youtube.com/embed/..." className="w-full rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent" /></div>
          <div><label className="mb-1.5 block text-sm font-medium">Description</label><textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={3} placeholder="What does this video cover?" className="w-full resize-none rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent" /></div>
          <div className="grid grid-cols-3 gap-3">
            <div><label className="mb-1.5 block text-sm font-medium">Category</label><select value={category} onChange={(e) => setCategory(e.target.value)} className="w-full rounded-xl border border-border bg-card/50 px-3 py-2.5 text-sm outline-none focus:border-accent">{categories.filter((c) => c !== "All").map((c) => (<option key={c} value={c}>{c}</option>))}</select></div>
            <div><label className="mb-1.5 block text-sm font-medium">Difficulty</label><select value={difficulty} onChange={(e) => setDifficulty(e.target.value as "Beginner" | "Intermediate" | "Advanced")} className="w-full rounded-xl border border-border bg-card/50 px-3 py-2.5 text-sm outline-none focus:border-accent"><option>Beginner</option><option>Intermediate</option><option>Advanced</option></select></div>
            <div><label className="mb-1.5 block text-sm font-medium">Duration</label><input type="text" value={duration} onChange={(e) => setDuration(e.target.value)} placeholder="12:30" className="w-full rounded-xl border border-border bg-card/50 px-3 py-2.5 text-sm outline-none focus:border-accent" /></div>
          </div>
        </div>

        <div className="mt-6 flex justify-end gap-3">
          <button onClick={onClose} className="rounded-xl px-4 py-2.5 text-sm font-medium text-muted hover:text-foreground">Cancel</button>
          <button onClick={handleUpload} disabled={!title.trim() || !videoURL.trim() || uploading} className="flex items-center gap-2 rounded-xl bg-accent px-6 py-2.5 text-sm font-medium text-white disabled:opacity-50">
            {uploading ? <Loader2 size={16} className="animate-spin" /> : "Upload"}
          </button>
        </div>
      </div>
    </div>
  );
}
