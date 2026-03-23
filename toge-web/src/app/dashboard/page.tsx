"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import {
  Heart,
  MessageCircle,
  Share2,
  MoreHorizontal,
  ImagePlus,
  Send,
  X,
  Loader2,
  ChevronDown,
  ChevronUp,
  Trash2,
} from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import {
  getFeedPosts,
  createPost,
  toggleLike as toggleLikeService,
  hasUserLiked,
  getComments,
  addComment,
  deletePost,
  type Post,
  type Comment,
} from "@/services/posts";

function timeAgo(date: Date | undefined | null): string {
  if (!date) return "";
  const now = new Date();
  const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);
  if (seconds < 60) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d`;
  const weeks = Math.floor(days / 7);
  return `${weeks}w`;
}

function getInitials(name: string | null | undefined, email: string | null | undefined): string {
  if (name) {
    return name
      .split(" ")
      .map((w) => w[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  }
  return email?.charAt(0)?.toUpperCase() || "U";
}

/* ── Comment Section ──────────────────────────────────────────── */

function CommentSection({
  postId,
  commentCount,
}: {
  postId: string;
  commentCount: number;
}) {
  const { user } = useAuth();
  const [open, setOpen] = useState(false);
  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(false);
  const [newComment, setNewComment] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [localCount, setLocalCount] = useState(commentCount);

  useEffect(() => {
    setLocalCount(commentCount);
  }, [commentCount]);

  async function loadComments() {
    setLoading(true);
    try {
      const data = await getComments(postId);
      setComments(data);
    } catch (err) {
      console.error("Failed to load comments", err);
    } finally {
      setLoading(false);
    }
  }

  function handleToggle() {
    if (!open) loadComments();
    setOpen((v) => !v);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user || !newComment.trim()) return;
    setSubmitting(true);
    try {
      await addComment(postId, {
        authorId: user.uid,
        authorName: user.displayName || user.email || "Anonymous",
        authorAvatar: user.photoURL || "",
        content: newComment.trim(),
      });
      setNewComment("");
      setLocalCount((c) => c + 1);
      await loadComments();
    } catch (err) {
      console.error("Failed to add comment", err);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <button
        onClick={handleToggle}
        className="flex items-center gap-2 text-sm text-muted transition-colors hover:text-foreground"
      >
        <MessageCircle size={18} />
        {localCount}
        {open ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
      </button>

      {open && (
        <div className="mt-3 border-t border-border/50 px-4 pb-4 pt-3">
          {loading ? (
            <div className="flex justify-center py-4">
              <Loader2 size={20} className="animate-spin text-muted" />
            </div>
          ) : comments.length === 0 ? (
            <p className="py-3 text-center text-xs text-muted">
              No comments yet. Be the first!
            </p>
          ) : (
            <div className="max-h-60 space-y-3 overflow-y-auto pr-1">
              {comments.map((c) => (
                <div key={c.id} className="flex gap-2">
                  {c.authorAvatar ? (
                    <img
                      src={c.authorAvatar}
                      alt={c.authorName}
                      className="h-7 w-7 flex-shrink-0 rounded-full object-cover"
                    />
                  ) : (
                    <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-accent/10 text-[10px] font-bold text-accent">
                      {getInitials(c.authorName, null)}
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="flex items-baseline gap-2">
                      <span className="text-xs font-semibold">
                        {c.authorName}
                      </span>
                      <span className="text-[10px] text-muted">
                        {timeAgo(c.createdAt instanceof Date ? c.createdAt : c.createdAt ? new Date((c.createdAt as any).seconds * 1000) : null)}
                      </span>
                    </div>
                    <p className="text-xs leading-relaxed text-foreground/80">
                      {c.content}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Add comment form */}
          <form
            onSubmit={handleSubmit}
            className="mt-3 flex items-center gap-2"
          >
            <input
              type="text"
              value={newComment}
              onChange={(e) => setNewComment(e.target.value)}
              placeholder="Write a comment..."
              className="flex-1 rounded-lg border border-border/50 bg-card/30 px-3 py-1.5 text-xs text-foreground placeholder-muted/50 outline-none focus:border-accent/50"
            />
            <button
              type="submit"
              disabled={!newComment.trim() || submitting}
              className="flex items-center justify-center rounded-lg bg-accent p-1.5 text-white transition-colors hover:bg-accent-hover disabled:opacity-30"
            >
              {submitting ? (
                <Loader2 size={14} className="animate-spin" />
              ) : (
                <Send size={14} />
              )}
            </button>
          </form>
        </div>
      )}
    </div>
  );
}

/* ── Post Card ────────────────────────────────────────────────── */

function PostCard({
  post,
  currentUserId,
  onDelete,
}: {
  post: Post;
  currentUserId: string;
  onDelete: (id: string) => void;
}) {
  const [liked, setLiked] = useState(false);
  const [likeCount, setLikeCount] = useState(post.likes);
  const [likeLoading, setLikeLoading] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  // Check if the current user has liked this post
  useEffect(() => {
    let cancelled = false;
    hasUserLiked(post.id, currentUserId).then((val) => {
      if (!cancelled) setLiked(val);
    });
    return () => {
      cancelled = true;
    };
  }, [post.id, currentUserId]);

  async function handleToggleLike() {
    if (likeLoading) return;
    setLikeLoading(true);
    // Optimistic update
    const wasLiked = liked;
    setLiked(!wasLiked);
    setLikeCount((c) => (wasLiked ? c - 1 : c + 1));
    try {
      await toggleLikeService(post.id, currentUserId);
    } catch (err) {
      // Revert on error
      setLiked(wasLiked);
      setLikeCount((c) => (wasLiked ? c + 1 : c - 1));
      console.error("Failed to toggle like", err);
    } finally {
      setLikeLoading(false);
    }
  }

  async function handleDelete() {
    setDeleting(true);
    try {
      await deletePost(post.id);
      onDelete(post.id);
    } catch (err) {
      console.error("Failed to delete post", err);
    } finally {
      setDeleting(false);
      setMenuOpen(false);
    }
  }

  const createdAt =
    post.createdAt instanceof Date
      ? post.createdAt
      : post.createdAt
        ? new Date((post.createdAt as any).seconds * 1000)
        : null;

  return (
    <div className="overflow-hidden rounded-2xl border border-border/50 bg-card/50">
      {/* Post header */}
      <div className="flex items-center justify-between p-4">
        <div className="flex items-center gap-3">
          {post.authorAvatar ? (
            <img
              src={post.authorAvatar}
              alt={post.authorName}
              className="h-10 w-10 rounded-full object-cover"
            />
          ) : (
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-accent/10 text-sm font-bold text-accent">
              {getInitials(post.authorName, null)}
            </div>
          )}
          <div>
            <div className="text-sm font-semibold">{post.authorName}</div>
            <div className="text-xs text-muted">
              {post.carName ? `${post.carName} · ` : ""}
              {timeAgo(createdAt)}
            </div>
          </div>
        </div>
        {post.authorId === currentUserId && (
          <div className="relative">
            <button
              onClick={() => setMenuOpen((v) => !v)}
              className="text-muted hover:text-foreground"
            >
              <MoreHorizontal size={18} />
            </button>
            {menuOpen && (
              <div className="absolute right-0 top-8 z-10 min-w-[120px] rounded-lg border border-border/50 bg-card p-1 shadow-lg">
                <button
                  onClick={handleDelete}
                  disabled={deleting}
                  className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-left text-xs text-red-400 transition-colors hover:bg-red-500/10"
                >
                  {deleting ? (
                    <Loader2 size={14} className="animate-spin" />
                  ) : (
                    <Trash2 size={14} />
                  )}
                  Delete
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Post content */}
      <div className="px-4 pb-3">
        <p className="whitespace-pre-wrap text-sm leading-relaxed">
          {post.content}
        </p>
      </div>

      {/* Post images */}
      {post.images && post.images.length > 0 && (
        <div
          className={`w-full overflow-hidden bg-card ${
            post.images.length === 1 ? "aspect-video" : "grid grid-cols-2 gap-0.5"
          }`}
        >
          {post.images.map((img, i) => (
            <img
              key={i}
              src={img}
              alt={`${post.carName || "Post"} image ${i + 1}`}
              className={`w-full object-cover ${
                post.images.length === 1
                  ? "h-full"
                  : "aspect-square"
              }`}
            />
          ))}
        </div>
      )}

      {/* Post actions */}
      <div className="flex items-center gap-6 px-4 py-3">
        <button
          onClick={handleToggleLike}
          disabled={likeLoading}
          className={`flex items-center gap-2 text-sm transition-colors ${
            liked ? "text-accent" : "text-muted hover:text-foreground"
          }`}
        >
          <Heart size={18} fill={liked ? "currentColor" : "none"} />
          {likeCount}
        </button>

        <CommentSection postId={post.id} commentCount={post.commentCount} />

        <button
          onClick={() => {
            navigator.clipboard.writeText(window.location.href);
          }}
          className="flex items-center gap-2 text-sm text-muted transition-colors hover:text-foreground"
        >
          <Share2 size={18} />
          Share
        </button>
      </div>
    </div>
  );
}

/* ── Main Feed Page ───────────────────────────────────────────── */

export default function FeedPage() {
  const { user } = useAuth();

  // Feed state
  const [posts, setPosts] = useState<Post[]>([]);
  const [feedLoading, setFeedLoading] = useState(true);
  const [feedError, setFeedError] = useState<string | null>(null);

  // Create-post state
  const [newPostContent, setNewPostContent] = useState("");
  const [newPostCar, setNewPostCar] = useState("");
  const [selectedImages, setSelectedImages] = useState<File[]>([]);
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [posting, setPosting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Load feed
  const loadFeed = useCallback(async () => {
    setFeedLoading(true);
    setFeedError(null);
    try {
      const data = await getFeedPosts(30);
      setPosts(data);
    } catch (err: any) {
      console.error("Failed to load feed", err);
      setFeedError("Failed to load feed. Please try again.");
    } finally {
      setFeedLoading(false);
    }
  }, []);

  useEffect(() => {
    loadFeed();
  }, [loadFeed]);

  // Image handling
  function handleImageSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    const newFiles = [...selectedImages, ...files].slice(0, 4); // max 4 images
    setSelectedImages(newFiles);

    // Generate previews
    const previews = newFiles.map((f) => URL.createObjectURL(f));
    // Revoke old previews
    imagePreviews.forEach((url) => URL.revokeObjectURL(url));
    setImagePreviews(previews);

    // Reset file input so selecting the same file works
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  function removeImage(index: number) {
    URL.revokeObjectURL(imagePreviews[index]);
    setSelectedImages((prev) => prev.filter((_, i) => i !== index));
    setImagePreviews((prev) => prev.filter((_, i) => i !== index));
  }

  async function handleCreatePost() {
    if (!user || !newPostContent.trim()) return;
    setPosting(true);
    try {
      await createPost(
        {
          authorId: user.uid,
          authorName: user.displayName || user.email || "Anonymous",
          authorAvatar: user.photoURL || "",
          carName: newPostCar.trim(),
          content: newPostContent.trim(),
        },
        selectedImages
      );

      // Reset form
      setNewPostContent("");
      setNewPostCar("");
      imagePreviews.forEach((url) => URL.revokeObjectURL(url));
      setSelectedImages([]);
      setImagePreviews([]);

      // Reload feed to show new post
      await loadFeed();
    } catch (err) {
      console.error("Failed to create post", err);
    } finally {
      setPosting(false);
    }
  }

  function handleDeletePost(postId: string) {
    setPosts((prev) => prev.filter((p) => p.id !== postId));
  }

  return (
    <div className="mx-auto max-w-2xl">
      {/* Page header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Feed</h1>
        <p className="text-sm text-muted">See what the community is building</p>
      </div>

      {/* Create post */}
      <div className="mb-6 rounded-2xl border border-border/50 bg-card/50 p-4">
        <div className="flex gap-3">
          {user?.photoURL ? (
            <img
              src={user.photoURL}
              alt={user.displayName || "You"}
              className="h-10 w-10 flex-shrink-0 rounded-full object-cover"
            />
          ) : (
            <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-accent/10 text-sm font-bold text-accent">
              {getInitials(user?.displayName, user?.email)}
            </div>
          )}
          <div className="flex-1">
            <textarea
              value={newPostContent}
              onChange={(e) => setNewPostContent(e.target.value)}
              placeholder="Share an update on your build..."
              rows={3}
              className="w-full resize-none bg-transparent text-sm text-foreground placeholder-muted/50 outline-none"
            />

            {/* Car name input */}
            <input
              type="text"
              value={newPostCar}
              onChange={(e) => setNewPostCar(e.target.value)}
              placeholder="Car (e.g. 1995 Nissan Skyline R33 GTR)"
              className="mt-1 w-full rounded-lg border border-border/30 bg-card/30 px-3 py-1.5 text-xs text-foreground placeholder-muted/40 outline-none focus:border-accent/50"
            />

            {/* Image previews */}
            {imagePreviews.length > 0 && (
              <div className="mt-3 flex flex-wrap gap-2">
                {imagePreviews.map((src, i) => (
                  <div key={i} className="group relative">
                    <img
                      src={src}
                      alt={`Preview ${i + 1}`}
                      className="h-20 w-20 rounded-lg object-cover"
                    />
                    <button
                      onClick={() => removeImage(i)}
                      className="absolute -right-1.5 -top-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-white opacity-0 transition-opacity group-hover:opacity-100"
                    >
                      <X size={12} />
                    </button>
                  </div>
                ))}
              </div>
            )}

            <div className="mt-3 flex items-center justify-between border-t border-border/50 pt-3">
              <button
                onClick={() => fileInputRef.current?.click()}
                disabled={selectedImages.length >= 4}
                className="flex items-center gap-2 text-sm text-muted transition-colors hover:text-foreground disabled:opacity-30"
              >
                <ImagePlus size={18} />
                Photo {selectedImages.length > 0 && `(${selectedImages.length}/4)`}
              </button>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                multiple
                onChange={handleImageSelect}
                className="hidden"
              />
              <button
                onClick={handleCreatePost}
                disabled={!newPostContent.trim() || posting}
                className="flex items-center gap-2 rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-accent-hover disabled:opacity-30"
              >
                {posting ? (
                  <Loader2 size={16} className="animate-spin" />
                ) : (
                  <Send size={16} />
                )}
                {posting ? "Posting..." : "Post"}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Feed content */}
      {feedLoading ? (
        <div className="flex flex-col items-center justify-center py-20">
          <Loader2 size={28} className="animate-spin text-accent" />
          <p className="mt-3 text-sm text-muted">Loading feed...</p>
        </div>
      ) : feedError ? (
        <div className="flex flex-col items-center justify-center py-20">
          <p className="text-sm text-red-400">{feedError}</p>
          <button
            onClick={loadFeed}
            className="mt-3 rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-accent-hover"
          >
            Retry
          </button>
        </div>
      ) : posts.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-2xl border border-border/50 bg-card/30 py-16">
          <MessageCircle size={40} className="text-muted/30" />
          <h3 className="mt-4 text-lg font-semibold">No posts yet</h3>
          <p className="mt-1 text-sm text-muted">
            Be the first to share your build with the community.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {posts.map((post) => (
            <PostCard
              key={post.id}
              post={post}
              currentUserId={user?.uid || ""}
              onDelete={handleDeletePost}
            />
          ))}
        </div>
      )}
    </div>
  );
}
