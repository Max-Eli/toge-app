"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/contexts/AuthContext";
import {
  ArrowLeft, Users, Globe, Lock, Plus, ThumbsUp, MessageSquare,
  Share2, MoreHorizontal, Pin, TrendingUp, Clock, Image as ImageIcon,
  Send, X, Shield, Loader2,
} from "lucide-react";
import {
  getCommunity, getCommunityPosts, createCommunityPost,
  toggleCommunityPostLike, addCommunityComment, getCommunityComments,
  isMember, joinCommunity, leaveCommunity, requestToJoin,
  Community, CommunityPost,
} from "@/services/communities";
import { getUserProfile } from "@/services/users";

type SortType = "hot" | "new" | "top";
type PostType = "discussion" | "question" | "build" | "media";

const postTypeLabels: Record<PostType, { label: string; color: string }> = {
  discussion: { label: "Discussion", color: "text-blue-400 bg-blue-400/10" },
  question: { label: "Question", color: "text-yellow-400 bg-yellow-400/10" },
  build: { label: "Build", color: "text-green-400 bg-green-400/10" },
  media: { label: "Media", color: "text-purple-400 bg-purple-400/10" },
};

export default function CommunityDetailPage() {
  const params = useParams();
  const communityId = params.id as string;
  const { user } = useAuth();

  const [community, setCommunity] = useState<Community | null>(null);
  const [posts, setPosts] = useState<CommunityPost[]>([]);
  const [joined, setJoined] = useState(false);
  const [loading, setLoading] = useState(true);
  const [sortBy, setSortBy] = useState<SortType>("new");
  const [filterType, setFilterType] = useState<PostType | "all">("all");
  const [showCreatePost, setShowCreatePost] = useState(false);
  const [likedPosts, setLikedPosts] = useState<Set<string>>(new Set());
  const [expandedComments, setExpandedComments] = useState<string | null>(null);
  const [comments, setComments] = useState<Record<string, Array<{ id: string; authorName: string; authorAvatar: string; content: string; createdAt: Date }>>>({});
  const [commentText, setCommentText] = useState("");
  const [profile, setProfile] = useState<{ displayName: string; profileImageURL: string } | null>(null);

  useEffect(() => {
    if (!user || !communityId) return;
    loadData();
  }, [user, communityId]);

  async function loadData() {
    try {
      const [communityData, postsData, memberStatus, profileData] = await Promise.all([
        getCommunity(communityId),
        getCommunityPosts(communityId, sortBy),
        isMember(communityId, user!.uid),
        getUserProfile(user!.uid),
      ]);
      setCommunity(communityData);
      setPosts(postsData);
      setJoined(memberStatus);
      if (profileData) setProfile({ displayName: profileData.displayName, profileImageURL: profileData.profileImageURL });
    } catch (err) {
      console.error("Error loading community:", err);
    } finally {
      setLoading(false);
    }
  }

  async function handleJoin() {
    if (!user || !community) return;
    try {
      if (community.type === "private") {
        await requestToJoin(communityId, {
          userId: user.uid,
          userName: profile?.displayName || user.displayName || "User",
          userAvatar: profile?.displayName?.charAt(0) || "U",
          message: "",
        });
        alert("Join request sent!");
      } else {
        await joinCommunity(communityId, user.uid);
        setJoined(true);
        setCommunity((prev) => prev ? { ...prev, memberCount: prev.memberCount + 1 } : prev);
      }
    } catch (err) {
      console.error("Error joining:", err);
    }
  }

  async function handleLeave() {
    if (!user) return;
    try {
      await leaveCommunity(communityId, user.uid);
      setJoined(false);
      setCommunity((prev) => prev ? { ...prev, memberCount: prev.memberCount - 1 } : prev);
    } catch (err) {
      console.error("Error leaving:", err);
    }
  }

  async function handleLike(postId: string) {
    if (!user) return;
    try {
      const liked = await toggleCommunityPostLike(communityId, postId, user.uid);
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

  async function handleLoadComments(postId: string) {
    if (expandedComments === postId) {
      setExpandedComments(null);
      return;
    }
    try {
      const data = await getCommunityComments(communityId, postId);
      setComments((prev) => ({ ...prev, [postId]: data }));
      setExpandedComments(postId);
    } catch (err) {
      console.error("Error loading comments:", err);
    }
  }

  async function handleAddComment(postId: string) {
    if (!commentText.trim() || !user || !profile) return;
    try {
      await addCommunityComment(communityId, postId, {
        authorId: user.uid,
        authorName: profile.displayName || "User",
        authorAvatar: profile.displayName?.charAt(0) || "U",
        content: commentText.trim(),
      });
      setCommentText("");
      // Reload comments
      const data = await getCommunityComments(communityId, postId);
      setComments((prev) => ({ ...prev, [postId]: data }));
      setPosts((prev) =>
        prev.map((p) => p.id === postId ? { ...p, commentCount: p.commentCount + 1 } : p)
      );
    } catch (err) {
      console.error("Error adding comment:", err);
    }
  }

  const filteredPosts = posts.filter((p) => filterType === "all" || p.type === filterType);

  if (loading) {
    return <div className="flex min-h-[50vh] items-center justify-center"><Loader2 size={32} className="animate-spin text-accent" /></div>;
  }

  if (!community) {
    return <div className="text-center py-20"><p className="text-muted">Community not found</p></div>;
  }

  return (
    <div className="space-y-0">
      {/* Banner */}
      <div className="relative -mx-4 -mt-6 h-48 overflow-hidden sm:-mx-6 lg:-mx-8 lg:h-56">
        {community.bannerURL ? (
          <img src={community.bannerURL} alt="" className="h-full w-full object-cover" />
        ) : (
          <div className="h-full w-full bg-gradient-to-br from-accent/20 to-accent/5" />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/50 to-transparent" />
        <Link href="/dashboard/communities" className="absolute left-4 top-4 flex items-center gap-2 rounded-lg bg-black/40 px-3 py-1.5 text-sm font-medium backdrop-blur-sm hover:bg-black/60 sm:left-6 lg:left-8">
          <ArrowLeft size={16} />Back
        </Link>
      </div>

      {/* Header */}
      <div className="relative -mt-12 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div className="flex items-end gap-4">
          <div className="flex h-20 w-20 items-center justify-center rounded-2xl border-4 border-background bg-accent/10 text-2xl font-bold text-accent">
            {community.name.charAt(0)}
          </div>
          <div className="pb-1">
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold">{community.name}</h1>
              {community.type === "private" ? <Lock size={16} className="text-muted" /> : <Globe size={16} className="text-muted" />}
            </div>
            <div className="mt-1 flex items-center gap-3 text-sm text-muted">
              <span className="flex items-center gap-1"><Users size={14} />{community.memberCount?.toLocaleString() || 0} members</span>
              <span>•</span>
              <span>{community.postCount || 0} posts</span>
              <span>•</span>
              <span>{community.category}</span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {joined ? (
            <>
              <button onClick={() => setShowCreatePost(true)} className="flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 text-sm font-medium text-white hover:bg-accent-hover">
                <Plus size={16} />New Post
              </button>
              <button onClick={handleLeave} className="rounded-xl border border-border/50 bg-card/30 px-4 py-2.5 text-sm font-medium text-muted hover:text-foreground">
                Joined
              </button>
            </>
          ) : (
            <button onClick={handleJoin} className="flex items-center gap-2 rounded-xl bg-accent px-6 py-2.5 text-sm font-medium text-white hover:bg-accent-hover">
              {community.type === "private" ? "Request to Join" : "Join Community"}
            </button>
          )}
        </div>
      </div>

      <p className="mt-4 text-sm leading-relaxed text-muted">{community.description}</p>

      {/* Content */}
      <div className="mt-6 space-y-4">
        {/* Sort & Filter */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-1 rounded-xl border border-border/50 bg-card/30 p-1">
            {(["hot", "new", "top"] as SortType[]).map((sort) => (
              <button key={sort} onClick={() => setSortBy(sort)} className={`flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-medium capitalize ${sortBy === sort ? "bg-accent text-white" : "text-muted hover:text-foreground"}`}>
                {sort === "hot" && <TrendingUp size={12} />}
                {sort === "new" && <Clock size={12} />}
                {sort === "top" && <ThumbsUp size={12} />}
                {sort}
              </button>
            ))}
          </div>
          <div className="flex gap-2 overflow-x-auto">
            {(["all", "discussion", "question", "build", "media"] as const).map((type) => (
              <button key={type} onClick={() => setFilterType(type)} className={`flex-shrink-0 rounded-full px-3 py-1 text-xs font-medium capitalize ${filterType === type ? "bg-accent/10 text-accent" : "text-muted hover:text-foreground"}`}>
                {type}
              </button>
            ))}
          </div>
        </div>

        {/* Posts */}
        {filteredPosts.length === 0 ? (
          <div className="py-16 text-center">
            <MessageSquare size={48} className="mx-auto text-muted/20" />
            <h3 className="mt-4 font-semibold">No posts yet</h3>
            <p className="mt-1 text-sm text-muted">Be the first to post in this community</p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredPosts.map((post) => (
              <article key={post.id} className="rounded-2xl border border-border/50 bg-card/30 p-4">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-full bg-accent/10 text-xs font-bold text-accent">
                      {post.authorAvatar || post.authorName?.charAt(0) || "U"}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium">{post.authorName}</span>
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${postTypeLabels[post.type]?.color || ""}`}>
                          {postTypeLabels[post.type]?.label || post.type}
                        </span>
                        {post.isPinned && <Pin size={12} className="text-accent" />}
                      </div>
                      <span className="text-xs text-muted">
                        {post.createdAt && typeof post.createdAt === "object" && "toDate" in post.createdAt
                          ? (post.createdAt as { toDate: () => Date }).toDate().toLocaleDateString()
                          : ""}
                      </span>
                    </div>
                  </div>
                </div>

                <h3 className="mt-3 font-semibold">{post.title}</h3>
                <p className="mt-1.5 text-sm leading-relaxed text-muted">{post.content}</p>

                {post.images && post.images.length > 0 && (
                  <div className="mt-3 overflow-hidden rounded-xl">
                    <img src={post.images[0]} alt="" className="h-52 w-full object-cover" />
                  </div>
                )}

                {post.tags && post.tags.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-1.5">
                    {post.tags.map((tag) => (
                      <span key={tag} className="rounded-full bg-card px-2 py-0.5 text-[10px] text-muted">#{tag}</span>
                    ))}
                  </div>
                )}

                <div className="mt-3 flex items-center gap-4 border-t border-border/30 pt-3">
                  <button onClick={() => handleLike(post.id)} className={`flex items-center gap-1.5 text-xs font-medium ${likedPosts.has(post.id) ? "text-accent" : "text-muted hover:text-foreground"}`}>
                    <ThumbsUp size={14} className={likedPosts.has(post.id) ? "fill-accent" : ""} />{post.likes}
                  </button>
                  <button onClick={() => handleLoadComments(post.id)} className="flex items-center gap-1.5 text-xs font-medium text-muted hover:text-foreground">
                    <MessageSquare size={14} />{post.commentCount}
                  </button>
                </div>

                {/* Comments section */}
                {expandedComments === post.id && (
                  <div className="mt-3 border-t border-border/30 pt-3 space-y-3">
                    {(comments[post.id] || []).map((c) => (
                      <div key={c.id} className="flex gap-2">
                        <div className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-accent/10 text-[10px] font-bold text-accent">
                          {c.authorAvatar || c.authorName?.charAt(0) || "U"}
                        </div>
                        <div>
                          <span className="text-xs font-medium">{c.authorName}</span>
                          <p className="text-xs text-muted">{c.content}</p>
                        </div>
                      </div>
                    ))}
                    <div className="flex gap-2">
                      <input
                        type="text"
                        value={commentText}
                        onChange={(e) => setCommentText(e.target.value)}
                        placeholder="Write a comment..."
                        onKeyDown={(e) => e.key === "Enter" && handleAddComment(post.id)}
                        className="flex-1 rounded-lg border border-border bg-card/50 px-3 py-1.5 text-xs outline-none focus:border-accent"
                      />
                      <button onClick={() => handleAddComment(post.id)} disabled={!commentText.trim()} className="rounded-lg bg-accent px-3 py-1.5 text-xs text-white disabled:opacity-30">
                        <Send size={12} />
                      </button>
                    </div>
                  </div>
                )}
              </article>
            ))}
          </div>
        )}
      </div>

      {/* Create Post Modal */}
      {showCreatePost && (
        <CreatePostModal
          communityId={communityId}
          userId={user?.uid || ""}
          userName={profile?.displayName || user?.displayName || "User"}
          userAvatar={profile?.displayName?.charAt(0) || "U"}
          onClose={() => setShowCreatePost(false)}
          onCreated={() => { setShowCreatePost(false); loadData(); }}
        />
      )}
    </div>
  );
}

function CreatePostModal({ communityId, userId, userName, userAvatar, onClose, onCreated }: {
  communityId: string; userId: string; userName: string; userAvatar: string; onClose: () => void; onCreated: () => void;
}) {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [postType, setPostType] = useState<PostType>("discussion");
  const [tags, setTags] = useState("");
  const [creating, setCreating] = useState(false);

  async function handleCreate() {
    if (!title.trim() || !content.trim()) return;
    setCreating(true);
    try {
      await createCommunityPost(communityId, {
        authorId: userId,
        authorName: userName,
        authorAvatar: userAvatar,
        type: postType,
        title: title.trim(),
        content: content.trim(),
        tags: tags.split(",").map((t) => t.trim()).filter(Boolean),
      }, []);
      onCreated();
    } catch (err) {
      console.error("Error creating post:", err);
    } finally {
      setCreating(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative w-full max-w-lg rounded-2xl border border-border/50 bg-background p-6">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold">Create Post</h2>
          <button onClick={onClose} className="text-muted hover:text-foreground"><X size={20} /></button>
        </div>

        <div className="mt-4 space-y-4">
          <div className="flex gap-2">
            {(["discussion", "question", "build", "media"] as PostType[]).map((type) => (
              <button key={type} onClick={() => setPostType(type)} className={`rounded-full px-3 py-1.5 text-xs font-medium capitalize ${postType === type ? postTypeLabels[type].color : "text-muted hover:text-foreground"}`}>
                {type}
              </button>
            ))}
          </div>
          <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Post title" className="w-full rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm font-medium outline-none focus:border-accent" />
          <textarea value={content} onChange={(e) => setContent(e.target.value)} placeholder="What's on your mind?" rows={5} className="w-full resize-none rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent" />
          <input type="text" value={tags} onChange={(e) => setTags(e.target.value)} placeholder="Tags (comma separated)" className="w-full rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent" />
        </div>

        <div className="mt-6 flex items-center justify-end gap-3">
          <button onClick={onClose} className="rounded-xl px-4 py-2.5 text-sm font-medium text-muted hover:text-foreground">Cancel</button>
          <button onClick={handleCreate} disabled={!title.trim() || !content.trim() || creating} className="flex items-center gap-2 rounded-xl bg-accent px-6 py-2.5 text-sm font-medium text-white disabled:opacity-50">
            {creating ? <Loader2 size={14} className="animate-spin" /> : <><Send size={14} />Post</>}
          </button>
        </div>
      </div>
    </div>
  );
}
