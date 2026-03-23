"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { Search, Heart, Loader2 } from "lucide-react";
import { getFeedPosts, toggleLike, Post } from "@/services/posts";
import { getCommunities, Community } from "@/services/communities";
import Link from "next/link";

const categories = ["All", "Latest", "Builds", "Photos", "Videos"];

export default function ExplorePage() {
  const { user } = useAuth();
  const [posts, setPosts] = useState<Post[]>([]);
  const [communities, setCommunities] = useState<Community[]>([]);
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [likedPosts, setLikedPosts] = useState<Set<string>>(new Set());

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    try {
      const [postsData, communitiesData] = await Promise.all([
        getFeedPosts(30),
        getCommunities(),
      ]);
      setPosts(postsData);
      setCommunities(communitiesData);
    } catch (err) {
      console.error("Error loading explore:", err);
    } finally {
      setLoading(false);
    }
  }

  async function handleLike(postId: string) {
    if (!user) return;
    try {
      const liked = await toggleLike(postId, user.uid);
      setLikedPosts((prev) => {
        const next = new Set(prev);
        liked ? next.add(postId) : next.delete(postId);
        return next;
      });
      setPosts((prev) =>
        prev.map((p) => p.id === postId ? { ...p, likes: p.likes + (liked ? 1 : -1) } : p)
      );
    } catch (err) {
      console.error("Error toggling like:", err);
    }
  }

  const postsWithImages = posts.filter((p) => p.images && p.images.length > 0);

  const filteredPosts = searchQuery
    ? postsWithImages.filter(
        (p) =>
          p.content.toLowerCase().includes(searchQuery.toLowerCase()) ||
          p.authorName.toLowerCase().includes(searchQuery.toLowerCase()) ||
          p.carName?.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : postsWithImages;

  if (loading) {
    return <div className="flex min-h-[50vh] items-center justify-center"><Loader2 size={32} className="animate-spin text-accent" /></div>;
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Explore</h1>
        <p className="mt-1 text-sm text-muted">Discover builds, photos, and communities</p>
      </div>

      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search posts, users, cars..." className="w-full rounded-xl border border-border bg-card/50 py-2.5 pl-9 pr-4 text-sm placeholder-muted/50 outline-none focus:border-accent" />
      </div>

      <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
        {categories.map((cat) => (
          <button key={cat} onClick={() => setSelectedCategory(cat)} className={`flex-shrink-0 rounded-full px-4 py-1.5 text-xs font-medium transition-colors ${selectedCategory === cat ? "bg-accent text-white" : "border border-border/50 bg-card/30 text-muted hover:text-foreground"}`}>
            {cat}
          </button>
        ))}
      </div>

      {/* Trending Communities */}
      {communities.length > 0 && (
        <div>
          <h2 className="mb-3 text-sm font-semibold text-muted">Trending Communities</h2>
          <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
            {communities.slice(0, 6).map((c) => (
              <Link key={c.id} href={`/dashboard/communities/${c.id}`} className="flex-shrink-0 rounded-xl border border-border/50 bg-card/30 p-3 hover:bg-card/50 w-40">
                <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent/10 text-xs font-bold text-accent">{c.name.charAt(0)}</div>
                <p className="mt-2 text-xs font-medium truncate">{c.name}</p>
                <p className="text-[10px] text-muted">{c.memberCount?.toLocaleString() || 0} members</p>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* Photo Grid */}
      {filteredPosts.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <Search size={48} className="text-muted/30" />
          <h3 className="mt-4 font-semibold">Nothing to explore yet</h3>
          <p className="mt-1 text-sm text-muted">Posts with photos will appear here</p>
        </div>
      ) : (
        <div className="columns-2 gap-3 sm:columns-3">
          {filteredPosts.map((post) => (
            <div key={post.id} className="group relative mb-3 break-inside-avoid overflow-hidden rounded-xl">
              <img src={post.images[0]} alt="" className="w-full object-cover transition-transform duration-500 group-hover:scale-105" />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 transition-opacity group-hover:opacity-100">
                <div className="absolute bottom-0 left-0 right-0 p-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-xs font-medium">{post.authorName}</p>
                      {post.carName && <p className="text-[10px] text-zinc-300">{post.carName}</p>}
                    </div>
                    <button
                      onClick={(e) => { e.stopPropagation(); handleLike(post.id); }}
                      className="flex items-center gap-1 text-xs"
                    >
                      <Heart size={14} className={likedPosts.has(post.id) ? "fill-red-500 text-red-500" : ""} />
                      {post.likes}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
