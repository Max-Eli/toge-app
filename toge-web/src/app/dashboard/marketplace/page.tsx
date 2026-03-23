"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import {
  Search,
  SlidersHorizontal,
  MapPin,
  Heart,
  MessageSquare,
  Plus,
  Grid3X3,
  List,
  X,
  ImagePlus,
  Loader2,
  Trash2,
  CheckCircle,
  PackageOpen,
  MoreVertical,
} from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import {
  getListings,
  createListing,
  deleteListing,
  markAsSold,
  saveListing,
  unsaveListing,
  getSavedListingIds,
  type Listing,
} from "@/services/marketplace";

const categories = [
  "All",
  "Engine",
  "Suspension",
  "Exhaust",
  "Wheels/Tires",
  "Body/Aero",
  "Interior",
  "Electronics",
  "Drivetrain",
];

const conditions: Listing["condition"][] = ["New", "Like New", "Used", "Fair"];

function timeAgo(date: Date | { toDate?: () => Date } | undefined): string {
  if (!date) return "";
  const d = typeof (date as { toDate?: () => Date }).toDate === "function"
    ? (date as { toDate: () => Date }).toDate()
    : new Date(date as Date);
  const seconds = Math.floor((Date.now() - d.getTime()) / 1000);
  if (seconds < 60) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d ago`;
  const months = Math.floor(days / 30);
  return `${months}mo ago`;
}

// ────────────────────────────────────────────────────────────────
// Create Listing Modal
// ────────────────────────────────────────────────────────────────
function CreateListingModal({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
}) {
  const { user } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [condition, setCondition] = useState<Listing["condition"]>("Used");
  const [category, setCategory] = useState("Engine");
  const [carFitment, setCarFitment] = useState("");
  const [location, setLocation] = useState("");
  const [imageFiles, setImageFiles] = useState<File[]>([]);
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  function handleImageSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files || []);
    if (files.length + imageFiles.length > 6) {
      setError("Maximum 6 images allowed");
      return;
    }
    setImageFiles((prev) => [...prev, ...files]);
    files.forEach((file) => {
      const reader = new FileReader();
      reader.onload = () =>
        setImagePreviews((prev) => [...prev, reader.result as string]);
      reader.readAsDataURL(file);
    });
  }

  function removeImage(index: number) {
    setImageFiles((prev) => prev.filter((_, i) => i !== index));
    setImagePreviews((prev) => prev.filter((_, i) => i !== index));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;
    if (!title.trim() || !price || !location.trim()) {
      setError("Title, price, and location are required");
      return;
    }

    setSubmitting(true);
    setError("");

    try {
      await createListing(
        {
          sellerId: user.uid,
          sellerName: user.displayName || "Anonymous",
          sellerAvatar: user.photoURL || "",
          title: title.trim(),
          description: description.trim(),
          price: Number(price),
          condition,
          category,
          carFitment: carFitment.trim(),
          location: location.trim(),
        },
        imageFiles
      );
      // Reset form
      setTitle("");
      setDescription("");
      setPrice("");
      setCondition("Used");
      setCategory("Engine");
      setCarFitment("");
      setLocation("");
      setImageFiles([]);
      setImagePreviews([]);
      onCreated();
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to create listing");
    } finally {
      setSubmitting(false);
    }
  }

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="relative w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl border border-border/50 bg-card p-6">
        {/* Close */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-muted hover:text-foreground"
        >
          <X size={20} />
        </button>

        <h2 className="text-lg font-bold mb-5">Create Listing</h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Title */}
          <div>
            <label className="mb-1 block text-xs font-medium text-muted">
              Title *
            </label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Garrett GTX3582R Turbo Kit"
              className="w-full rounded-xl border border-border bg-card/30 px-4 py-2.5 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
            />
          </div>

          {/* Description */}
          <div>
            <label className="mb-1 block text-xs font-medium text-muted">
              Description
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              placeholder="Describe condition, history, modifications..."
              className="w-full rounded-xl border border-border bg-card/30 px-4 py-2.5 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent resize-none"
            />
          </div>

          {/* Price + Condition */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-muted">
                Price ($) *
              </label>
              <input
                type="number"
                min="0"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="0"
                className="w-full rounded-xl border border-border bg-card/30 px-4 py-2.5 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-muted">
                Condition
              </label>
              <select
                value={condition}
                onChange={(e) =>
                  setCondition(e.target.value as Listing["condition"])
                }
                className="w-full rounded-xl border border-border bg-card/30 px-4 py-2.5 text-sm text-foreground outline-none focus:border-accent"
              >
                {conditions.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Category */}
          <div>
            <label className="mb-1 block text-xs font-medium text-muted">
              Category
            </label>
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="w-full rounded-xl border border-border bg-card/30 px-4 py-2.5 text-sm text-foreground outline-none focus:border-accent"
            >
              {categories.filter((c) => c !== "All").map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </div>

          {/* Car fitment */}
          <div>
            <label className="mb-1 block text-xs font-medium text-muted">
              Car Fitment
            </label>
            <input
              value={carFitment}
              onChange={(e) => setCarFitment(e.target.value)}
              placeholder="e.g. Nissan 240SX S14, Universal"
              className="w-full rounded-xl border border-border bg-card/30 px-4 py-2.5 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
            />
          </div>

          {/* Location */}
          <div>
            <label className="mb-1 block text-xs font-medium text-muted">
              Location *
            </label>
            <input
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              placeholder="e.g. Los Angeles, CA"
              className="w-full rounded-xl border border-border bg-card/30 px-4 py-2.5 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
            />
          </div>

          {/* Images */}
          <div>
            <label className="mb-1 block text-xs font-medium text-muted">
              Images (max 6)
            </label>
            <div className="flex flex-wrap gap-2">
              {imagePreviews.map((src, i) => (
                <div
                  key={i}
                  className="relative h-20 w-20 overflow-hidden rounded-lg border border-border/50"
                >
                  <img
                    src={src}
                    alt=""
                    className="h-full w-full object-cover"
                  />
                  <button
                    type="button"
                    onClick={() => removeImage(i)}
                    className="absolute top-0.5 right-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-black/60 text-white"
                  >
                    <X size={12} />
                  </button>
                </div>
              ))}
              {imageFiles.length < 6 && (
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="flex h-20 w-20 items-center justify-center rounded-lg border border-dashed border-border/50 text-muted hover:border-accent hover:text-accent"
                >
                  <ImagePlus size={20} />
                </button>
              )}
            </div>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              multiple
              onChange={handleImageSelect}
              className="hidden"
            />
          </div>

          {error && (
            <p className="text-xs text-red-400">{error}</p>
          )}

          <button
            type="submit"
            disabled={submitting}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-medium text-white transition-colors hover:bg-accent-hover disabled:opacity-50"
          >
            {submitting ? (
              <>
                <Loader2 size={16} className="animate-spin" />
                Publishing...
              </>
            ) : (
              <>
                <Plus size={16} />
                Publish Listing
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Listing Card Menu (own listings)
// ────────────────────────────────────────────────────────────────
function ListingMenu({
  listingId,
  onDeleted,
}: {
  listingId: string;
  onDeleted: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  async function handleMarkSold() {
    setBusy(true);
    try {
      await markAsSold(listingId);
      onDeleted();
    } finally {
      setBusy(false);
      setOpen(false);
    }
  }

  async function handleDelete() {
    setBusy(true);
    try {
      await deleteListing(listingId);
      onDeleted();
    } finally {
      setBusy(false);
      setOpen(false);
    }
  }

  return (
    <div ref={menuRef} className="relative">
      <button
        onClick={(e) => {
          e.stopPropagation();
          setOpen((v) => !v);
        }}
        className="flex h-8 w-8 items-center justify-center rounded-full bg-black/40 text-white backdrop-blur-sm hover:bg-black/60"
      >
        <MoreVertical size={16} />
      </button>
      {open && (
        <div className="absolute right-0 top-10 z-20 w-40 overflow-hidden rounded-xl border border-border/50 bg-card shadow-lg">
          <button
            disabled={busy}
            onClick={(e) => {
              e.stopPropagation();
              handleMarkSold();
            }}
            className="flex w-full items-center gap-2 px-4 py-2.5 text-xs text-foreground hover:bg-card/80 disabled:opacity-50"
          >
            <CheckCircle size={14} />
            Mark as Sold
          </button>
          <button
            disabled={busy}
            onClick={(e) => {
              e.stopPropagation();
              handleDelete();
            }}
            className="flex w-full items-center gap-2 px-4 py-2.5 text-xs text-red-400 hover:bg-card/80 disabled:opacity-50"
          >
            <Trash2 size={14} />
            Remove
          </button>
        </div>
      )}
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Main Page
// ────────────────────────────────────────────────────────────────
export default function MarketplacePage() {
  const { user } = useAuth();

  const [listings, setListings] = useState<Listing[]>([]);
  const [savedIds, setSavedIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [activeCategory, setActiveCategory] = useState("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");
  const [modalOpen, setModalOpen] = useState(false);
  const [savingIds, setSavingIds] = useState<Set<string>>(new Set());

  // Debounce search
  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(searchQuery), 300);
    return () => clearTimeout(t);
  }, [searchQuery]);

  // Fetch listings
  const fetchListings = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getListings(activeCategory, debouncedSearch);
      setListings(data);
    } catch (err) {
      console.error("Failed to fetch listings", err);
    } finally {
      setLoading(false);
    }
  }, [activeCategory, debouncedSearch]);

  useEffect(() => {
    fetchListings();
  }, [fetchListings]);

  // Fetch saved listing IDs
  useEffect(() => {
    if (!user) return;
    getSavedListingIds(user.uid).then((ids) => setSavedIds(new Set(ids)));
  }, [user]);

  // Toggle save
  async function toggleSave(listingId: string) {
    if (!user) return;
    setSavingIds((prev) => new Set(prev).add(listingId));
    try {
      if (savedIds.has(listingId)) {
        await unsaveListing(user.uid, listingId);
        setSavedIds((prev) => {
          const next = new Set(prev);
          next.delete(listingId);
          return next;
        });
      } else {
        await saveListing(user.uid, listingId);
        setSavedIds((prev) => new Set(prev).add(listingId));
      }
    } catch (err) {
      console.error("Failed to toggle save", err);
    } finally {
      setSavingIds((prev) => {
        const next = new Set(prev);
        next.delete(listingId);
        return next;
      });
    }
  }

  // ── Render ─────────────────────────────────────────────────
  return (
    <div>
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Marketplace</h1>
          <p className="text-sm text-muted">
            Buy and sell parts from enthusiasts
          </p>
        </div>
        <button
          onClick={() => setModalOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-accent-hover"
        >
          <Plus size={18} />
          List Part
        </button>
      </div>

      {/* Search & filters */}
      <div className="mb-4 flex gap-3">
        <div className="relative flex-1">
          <Search
            size={18}
            className="absolute left-4 top-1/2 -translate-y-1/2 text-muted"
          />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search parts, brands, cars..."
            className="w-full rounded-xl border border-border bg-card/50 py-3 pl-11 pr-4 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
          />
        </div>
        <button className="flex items-center gap-2 rounded-xl border border-border bg-card/50 px-4 text-sm text-muted hover:bg-card hover:text-foreground">
          <SlidersHorizontal size={18} />
        </button>
        <div className="hidden items-center gap-1 rounded-xl border border-border bg-card/50 p-1 sm:flex">
          <button
            onClick={() => setViewMode("grid")}
            className={`rounded-lg p-2 ${
              viewMode === "grid" ? "bg-card text-foreground" : "text-muted"
            }`}
          >
            <Grid3X3 size={16} />
          </button>
          <button
            onClick={() => setViewMode("list")}
            className={`rounded-lg p-2 ${
              viewMode === "list" ? "bg-card text-foreground" : "text-muted"
            }`}
          >
            <List size={16} />
          </button>
        </div>
      </div>

      {/* Categories */}
      <div className="mb-6 flex gap-2 overflow-x-auto pb-2">
        {categories.map((cat) => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`flex-shrink-0 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
              activeCategory === cat
                ? "bg-accent text-white"
                : "bg-card/50 text-muted hover:bg-card hover:text-foreground"
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Loading state */}
      {loading && (
        <div className="flex flex-col items-center justify-center py-20 text-muted">
          <Loader2 size={32} className="animate-spin mb-3" />
          <p className="text-sm">Loading listings...</p>
        </div>
      )}

      {/* Empty state */}
      {!loading && listings.length === 0 && (
        <div className="flex flex-col items-center justify-center py-20 text-muted">
          <PackageOpen size={48} className="mb-4 opacity-40" />
          <p className="text-sm font-medium">No listings found</p>
          <p className="mt-1 text-xs text-muted/60">
            {debouncedSearch || activeCategory !== "All"
              ? "Try adjusting your search or filters"
              : "Be the first to list a part!"}
          </p>
        </div>
      )}

      {/* ── Grid View ──────────────────────────────────────── */}
      {!loading && listings.length > 0 && viewMode === "grid" && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {listings.map((listing) => {
            const isSaved = savedIds.has(listing.id);
            const isOwn = user?.uid === listing.sellerId;

            return (
              <div
                key={listing.id}
                className="group cursor-pointer overflow-hidden rounded-2xl border border-border/50 bg-card/30 transition-all hover:border-border hover:bg-card"
              >
                {/* Image */}
                <div className="relative aspect-[4/3] overflow-hidden bg-card/50">
                  {listing.images && listing.images.length > 0 ? (
                    <img
                      src={listing.images[0]}
                      alt={listing.title}
                      className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                    />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center text-muted/30">
                      <PackageOpen size={48} />
                    </div>
                  )}

                  {/* Top-right actions */}
                  <div className="absolute top-3 right-3 flex gap-2">
                    {isOwn ? (
                      <ListingMenu
                        listingId={listing.id}
                        onDeleted={fetchListings}
                      />
                    ) : (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          toggleSave(listing.id);
                        }}
                        disabled={savingIds.has(listing.id)}
                        className={`flex h-8 w-8 items-center justify-center rounded-full backdrop-blur-sm transition-colors disabled:opacity-50 ${
                          isSaved
                            ? "bg-accent/20 text-accent"
                            : "bg-black/40 text-white hover:bg-black/60"
                        }`}
                      >
                        <Heart
                          size={16}
                          fill={isSaved ? "currentColor" : "none"}
                        />
                      </button>
                    )}
                  </div>

                  <div className="absolute bottom-3 left-3">
                    <span className="rounded-lg bg-black/70 px-2.5 py-1 text-xs font-medium backdrop-blur-sm">
                      {listing.condition}
                    </span>
                  </div>
                </div>

                {/* Info */}
                <div className="p-4">
                  <h3 className="text-sm font-semibold leading-snug line-clamp-2">
                    {listing.title}
                  </h3>
                  <p className="mt-2 text-lg font-bold text-accent">
                    ${listing.price.toLocaleString()}
                  </p>
                  <p className="mt-1 text-xs text-muted">
                    {listing.carFitment}
                  </p>

                  <div className="mt-3 flex items-center justify-between border-t border-border/50 pt-3">
                    <div className="flex items-center gap-1.5 text-xs text-muted">
                      <MapPin size={12} />
                      {listing.location}
                    </div>
                    <span className="text-xs text-muted">
                      {timeAgo(listing.createdAt)}
                    </span>
                  </div>

                  <div className="mt-3 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      {listing.sellerAvatar ? (
                        <img
                          src={listing.sellerAvatar}
                          alt=""
                          className="h-5 w-5 rounded-full object-cover"
                        />
                      ) : (
                        <div className="h-5 w-5 rounded-full bg-accent/20" />
                      )}
                      <span className="text-xs text-muted">
                        {listing.sellerName}
                      </span>
                    </div>
                    {!isOwn && (
                      <button className="flex items-center gap-1.5 rounded-lg bg-accent/10 px-3 py-1.5 text-xs font-medium text-accent transition-colors hover:bg-accent/20">
                        <MessageSquare size={12} />
                        Message
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* ── List View ──────────────────────────────────────── */}
      {!loading && listings.length > 0 && viewMode === "list" && (
        <div className="flex flex-col gap-3">
          {listings.map((listing) => {
            const isSaved = savedIds.has(listing.id);
            const isOwn = user?.uid === listing.sellerId;

            return (
              <div
                key={listing.id}
                className="group flex cursor-pointer overflow-hidden rounded-2xl border border-border/50 bg-card/30 transition-all hover:border-border hover:bg-card"
              >
                {/* Thumbnail */}
                <div className="relative h-32 w-40 flex-shrink-0 overflow-hidden sm:h-36 sm:w-48 bg-card/50">
                  {listing.images && listing.images.length > 0 ? (
                    <img
                      src={listing.images[0]}
                      alt={listing.title}
                      className="h-full w-full object-cover"
                    />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center text-muted/30">
                      <PackageOpen size={32} />
                    </div>
                  )}
                  <div className="absolute bottom-2 left-2">
                    <span className="rounded-md bg-black/70 px-2 py-0.5 text-[10px] font-medium backdrop-blur-sm">
                      {listing.condition}
                    </span>
                  </div>
                </div>

                {/* Details */}
                <div className="flex flex-1 flex-col justify-between p-4">
                  <div>
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="text-sm font-semibold leading-snug line-clamp-1">
                        {listing.title}
                      </h3>
                      <p className="flex-shrink-0 text-base font-bold text-accent">
                        ${listing.price.toLocaleString()}
                      </p>
                    </div>
                    <p className="mt-1 text-xs text-muted">
                      {listing.carFitment}
                    </p>
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="flex items-center gap-1.5 text-xs text-muted">
                        <MapPin size={12} />
                        {listing.location}
                      </div>
                      <div className="flex items-center gap-2">
                        {listing.sellerAvatar ? (
                          <img
                            src={listing.sellerAvatar}
                            alt=""
                            className="h-4 w-4 rounded-full object-cover"
                          />
                        ) : (
                          <div className="h-4 w-4 rounded-full bg-accent/20" />
                        )}
                        <span className="text-xs text-muted">
                          {listing.sellerName}
                        </span>
                      </div>
                      <span className="text-xs text-muted">
                        {timeAgo(listing.createdAt)}
                      </span>
                    </div>

                    <div className="flex items-center gap-2">
                      {isOwn ? (
                        <ListingMenu
                          listingId={listing.id}
                          onDeleted={fetchListings}
                        />
                      ) : (
                        <>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              toggleSave(listing.id);
                            }}
                            disabled={savingIds.has(listing.id)}
                            className={`flex h-7 w-7 items-center justify-center rounded-full transition-colors disabled:opacity-50 ${
                              isSaved
                                ? "bg-accent/20 text-accent"
                                : "bg-card text-muted hover:text-foreground"
                            }`}
                          >
                            <Heart
                              size={14}
                              fill={isSaved ? "currentColor" : "none"}
                            />
                          </button>
                          <button className="flex items-center gap-1.5 rounded-lg bg-accent/10 px-3 py-1.5 text-xs font-medium text-accent transition-colors hover:bg-accent/20">
                            <MessageSquare size={12} />
                            Message
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Create listing modal */}
      <CreateListingModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onCreated={fetchListings}
      />
    </div>
  );
}
