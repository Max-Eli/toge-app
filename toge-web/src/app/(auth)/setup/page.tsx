"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/contexts/AuthContext";
import { doc, updateDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Camera, Loader2, ArrowRight } from "lucide-react";

export default function ProfileSetupPage() {
  const { user } = useAuth();
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [bio, setBio] = useState("");
  const [location, setLocation] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;

    if (!username.trim()) {
      setError("Username is required.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      await updateDoc(doc(db, "users", user.uid), {
        username: username.toLowerCase().replace(/[^a-z0-9_]/g, ""),
        bio,
        location,
        updatedAt: serverTimestamp(),
      });
      router.push("/dashboard");
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-6">
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute top-1/3 left-1/2 h-[500px] w-[500px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-accent/8 blur-[120px]" />
      </div>

      <div className="relative w-full max-w-md">
        <div className="text-center">
          <span className="text-2xl font-bold tracking-tight">
            峠 <span className="text-accent">TŌGE</span>
          </span>
          <h1 className="mt-6 text-2xl font-bold">Set up your profile</h1>
          <p className="mt-1 text-sm text-muted">
            Let the community know who you are
          </p>
        </div>

        {/* Avatar */}
        <div className="mt-8 flex justify-center">
          <div className="relative">
            <div className="flex h-24 w-24 items-center justify-center rounded-full bg-accent/10 text-3xl font-bold text-accent">
              {user?.displayName?.charAt(0) ||
                user?.email?.charAt(0)?.toUpperCase() ||
                "U"}
            </div>
            <button
              type="button"
              className="absolute -bottom-1 -right-1 flex h-8 w-8 items-center justify-center rounded-full bg-accent text-white hover:bg-accent-hover"
            >
              <Camera size={14} />
            </button>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="mt-8 space-y-4">
          {error && (
            <div className="rounded-lg border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-400">
              {error}
            </div>
          )}

          <div>
            <label className="mb-1.5 block text-sm text-muted">Username</label>
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-sm text-muted">
                @
              </span>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full rounded-xl border border-border bg-card/50 py-3 pl-8 pr-4 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent focus:ring-1 focus:ring-accent"
                placeholder="username"
                required
              />
            </div>
          </div>

          <div>
            <label className="mb-1.5 block text-sm text-muted">Bio</label>
            <textarea
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              rows={3}
              maxLength={160}
              className="w-full resize-none rounded-xl border border-border bg-card/50 px-4 py-3 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent focus:ring-1 focus:ring-accent"
              placeholder="Tell the community about yourself and your cars..."
            />
          </div>

          <div>
            <label className="mb-1.5 block text-sm text-muted">Location</label>
            <input
              type="text"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              className="w-full rounded-xl border border-border bg-card/50 px-4 py-3 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent focus:ring-1 focus:ring-accent"
              placeholder="City, State"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-accent px-4 py-3 text-sm font-medium text-white transition-colors hover:bg-accent-hover disabled:opacity-50"
          >
            {loading ? (
              <Loader2 size={18} className="animate-spin" />
            ) : (
              <>
                Continue to Tōge
                <ArrowRight size={16} />
              </>
            )}
          </button>
        </form>

        <button
          onClick={() => router.push("/dashboard")}
          className="mt-4 w-full text-center text-sm text-muted hover:text-foreground"
        >
          Skip for now
        </button>
      </div>
    </div>
  );
}
