"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/contexts/AuthContext";
import {
  Search,
  Plus,
  Users,
  Lock,
  Globe,
  ChevronRight,
  TrendingUp,
  Star,
  X,
  Loader2,
} from "lucide-react";
import Link from "next/link";
import {
  getCommunities,
  createCommunity,
  isMember,
  joinCommunity,
  leaveCommunity,
  Community,
} from "@/services/communities";
import { getUserProfile } from "@/services/users";

type TabType = "discover" | "joined" | "owned";

const categories = [
  "All", "JDM", "Euro", "American Muscle", "Trucks & Off-Road",
  "EV & Hybrid", "Track & Racing", "Stance & Show", "Drifting",
  "Restoration", "General",
];

export default function CommunitiesPage() {
  const { user } = useAuth();
  const [communities, setCommunities] = useState<Community[]>([]);
  const [membershipMap, setMembershipMap] = useState<Record<string, boolean>>({});
  const [activeTab, setActiveTab] = useState<TabType>("discover");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    loadCommunities();
  }, [user]);

  async function loadCommunities() {
    try {
      const data = await getCommunities();
      setCommunities(data);

      // Check membership for each community
      const memberMap: Record<string, boolean> = {};
      await Promise.all(
        data.map(async (c) => {
          memberMap[c.id] = await isMember(c.id, user!.uid);
        })
      );
      setMembershipMap(memberMap);
    } catch (err) {
      console.error("Error loading communities:", err);
    } finally {
      setLoading(false);
    }
  }

  async function handleJoin(communityId: string) {
    if (!user) return;
    try {
      await joinCommunity(communityId, user.uid);
      setMembershipMap((prev) => ({ ...prev, [communityId]: true }));
      setCommunities((prev) =>
        prev.map((c) => c.id === communityId ? { ...c, memberCount: c.memberCount + 1 } : c)
      );
    } catch (err) {
      console.error("Error joining:", err);
    }
  }

  async function handleLeave(communityId: string) {
    if (!user) return;
    try {
      await leaveCommunity(communityId, user.uid);
      setMembershipMap((prev) => ({ ...prev, [communityId]: false }));
      setCommunities((prev) =>
        prev.map((c) => c.id === communityId ? { ...c, memberCount: c.memberCount - 1 } : c)
      );
    } catch (err) {
      console.error("Error leaving:", err);
    }
  }

  const filteredCommunities = communities.filter((c) => {
    const isJoined = membershipMap[c.id];
    const isOwner = c.ownerId === user?.uid;
    const matchesTab =
      activeTab === "discover" ? true : activeTab === "joined" ? isJoined : isOwner;
    const matchesCategory = selectedCategory === "All" || c.category === selectedCategory;
    const matchesSearch =
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.description.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesTab && matchesCategory && matchesSearch;
  });

  if (loading) {
    return (
      <div className="flex min-h-[50vh] items-center justify-center">
        <Loader2 size={32} className="animate-spin text-accent" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold">Communities</h1>
          <p className="mt-1 text-sm text-muted">Join communities, ask questions, and connect with enthusiasts</p>
        </div>
        <button onClick={() => setShowCreateModal(true)} className="flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-accent-hover">
          <Plus size={18} />
          Create Community
        </button>
      </div>

      <div className="flex items-center gap-1 rounded-xl border border-border/50 bg-card/30 p-1">
        {(["discover", "joined", "owned"] as TabType[]).map((tab) => (
          <button key={tab} onClick={() => setActiveTab(tab)} className={`flex-1 rounded-lg px-4 py-2 text-sm font-medium capitalize transition-colors ${activeTab === tab ? "bg-accent text-white" : "text-muted hover:text-foreground"}`}>
            {tab === "owned" ? "My Communities" : tab}
          </button>
        ))}
      </div>

      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Search communities..." className="w-full rounded-xl border border-border bg-card/50 py-2.5 pl-9 pr-4 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent" />
      </div>

      <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
        {categories.map((cat) => (
          <button key={cat} onClick={() => setSelectedCategory(cat)} className={`flex-shrink-0 rounded-full px-4 py-1.5 text-xs font-medium transition-colors ${selectedCategory === cat ? "bg-accent text-white" : "border border-border/50 bg-card/30 text-muted hover:text-foreground"}`}>
            {cat}
          </button>
        ))}
      </div>

      {filteredCommunities.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <Users size={48} className="text-muted/30" />
          <h3 className="mt-4 font-semibold">No communities found</h3>
          <p className="mt-1 text-sm text-muted">
            {activeTab === "owned" ? "You haven't created any communities yet." : activeTab === "joined" ? "You haven't joined any communities yet." : "Try a different search or category."}
          </p>
          {activeTab === "owned" && (
            <button onClick={() => setShowCreateModal(true)} className="mt-4 flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 text-sm font-medium text-white">
              <Plus size={18} />
              Create Community
            </button>
          )}
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filteredCommunities.map((community) => (
            <div key={community.id} className="group overflow-hidden rounded-2xl border border-border/50 bg-card/30 transition-all hover:border-accent/30 hover:bg-card/50">
              <Link href={`/dashboard/communities/${community.id}`}>
                <div className="relative h-28 overflow-hidden">
                  {community.bannerURL ? (
                    <img src={community.bannerURL} alt="" className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105" />
                  ) : (
                    <div className="h-full w-full bg-gradient-to-br from-accent/20 to-accent/5" />
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent" />
                  <div className="absolute right-3 top-3 flex items-center gap-1 rounded-full bg-black/50 px-2 py-1 text-xs font-medium backdrop-blur-sm">
                    {community.type === "private" ? <><Lock size={10} />Private</> : <><Globe size={10} />Public</>}
                  </div>
                  <div className="absolute -bottom-5 left-4 flex h-10 w-10 items-center justify-center rounded-xl border-2 border-background bg-accent/10 text-sm font-bold text-accent backdrop-blur-sm">
                    {community.name.charAt(0)}
                  </div>
                </div>
                <div className="p-4 pt-7">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-semibold">{community.name}</h3>
                      <div className="mt-0.5 flex items-center gap-2 text-xs text-muted">
                        <span className="flex items-center gap-1"><Users size={12} />{community.memberCount?.toLocaleString() || 0}</span>
                        <span>•</span>
                        <span>{community.postCount || 0} posts</span>
                      </div>
                    </div>
                    <ChevronRight size={16} className="mt-1 text-muted" />
                  </div>
                  <p className="mt-2 text-xs leading-relaxed text-muted line-clamp-2">{community.description}</p>
                  <div className="mt-3 flex items-center justify-between">
                    <span className="rounded-full bg-card px-2.5 py-0.5 text-xs text-muted">{community.category}</span>
                    {membershipMap[community.id] && (
                      <span className="flex items-center gap-1 text-xs font-medium text-accent">
                        <Star size={12} className="fill-accent" />Joined
                      </span>
                    )}
                  </div>
                </div>
              </Link>
              {!membershipMap[community.id] && community.type === "public" && (
                <div className="border-t border-border/30 px-4 py-3">
                  <button
                    onClick={(e) => { e.preventDefault(); handleJoin(community.id); }}
                    className="w-full rounded-lg bg-accent/10 py-1.5 text-xs font-medium text-accent hover:bg-accent/20"
                  >
                    Join Community
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {showCreateModal && (
        <CreateCommunityModal
          userId={user?.uid || ""}
          userName={user?.displayName || ""}
          onClose={() => setShowCreateModal(false)}
          onCreated={() => { setShowCreateModal(false); loadCommunities(); }}
        />
      )}
    </div>
  );
}

function CreateCommunityModal({ userId, userName, onClose, onCreated }: { userId: string; userName: string; onClose: () => void; onCreated: () => void }) {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [type, setType] = useState<"public" | "private">("public");
  const [category, setCategory] = useState("General");
  const [creating, setCreating] = useState(false);

  async function handleCreate() {
    if (!name.trim() || !description.trim()) return;
    setCreating(true);
    try {
      await createCommunity({
        name: name.trim(),
        description: description.trim(),
        type,
        category,
        ownerId: userId,
        ownerName: userName,
        rules: ["Be respectful to all members", "Keep posts on topic", "No spam or self-promotion"],
      });
      onCreated();
    } catch (err) {
      console.error("Error creating community:", err);
    } finally {
      setCreating(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative w-full max-w-lg rounded-2xl border border-border/50 bg-background p-6">
        <h2 className="text-xl font-bold">Create a Community</h2>
        <p className="mt-1 text-sm text-muted">Build your own space for car enthusiasts</p>

        <div className="mt-6 space-y-4">
          <div>
            <label className="mb-1.5 block text-sm font-medium">Community Name</label>
            <input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. SoCal Supra Club" className="w-full rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent" />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium">Description</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} placeholder="What's this community about?" rows={3} className="w-full resize-none rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent" />
          </div>
          <div>
            <label className="mb-2 block text-sm font-medium">Type</label>
            <div className="grid grid-cols-2 gap-3">
              <button type="button" onClick={() => setType("public")} className={`flex items-center gap-3 rounded-xl border p-3 text-left ${type === "public" ? "border-accent bg-accent/5" : "border-border/50 bg-card/30"}`}>
                <Globe size={20} className={type === "public" ? "text-accent" : "text-muted"} />
                <div><div className="text-sm font-medium">Public</div><div className="text-xs text-muted">Anyone can join</div></div>
              </button>
              <button type="button" onClick={() => setType("private")} className={`flex items-center gap-3 rounded-xl border p-3 text-left ${type === "private" ? "border-accent bg-accent/5" : "border-border/50 bg-card/30"}`}>
                <Lock size={20} className={type === "private" ? "text-accent" : "text-muted"} />
                <div><div className="text-sm font-medium">Private</div><div className="text-xs text-muted">Invite or request</div></div>
              </button>
            </div>
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium">Category</label>
            <select value={category} onChange={(e) => setCategory(e.target.value)} className="w-full rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent">
              {categories.filter((c) => c !== "All").map((cat) => (<option key={cat} value={cat}>{cat}</option>))}
            </select>
          </div>
        </div>

        <div className="mt-6 flex items-center justify-end gap-3">
          <button onClick={onClose} className="rounded-xl px-4 py-2.5 text-sm font-medium text-muted hover:text-foreground">Cancel</button>
          <button onClick={handleCreate} disabled={!name.trim() || !description.trim() || creating} className="flex items-center gap-2 rounded-xl bg-accent px-6 py-2.5 text-sm font-medium text-white disabled:opacity-50">
            {creating ? <Loader2 size={16} className="animate-spin" /> : "Create Community"}
          </button>
        </div>
      </div>
    </div>
  );
}
