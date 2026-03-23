"use client";

import { useState, useEffect, useRef } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { Camera, Loader2, Check } from "lucide-react";
import { getUserProfile, updateUserProfile, uploadProfilePhoto } from "@/services/users";

export default function SettingsPage() {
  const { user } = useAuth();
  const [displayName, setDisplayName] = useState("");
  const [username, setUsername] = useState("");
  const [bio, setBio] = useState("");
  const [location, setLocation] = useState("");
  const [profileImageURL, setProfileImageURL] = useState("");
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [uploadingPhoto, setUploadingPhoto] = useState(false);
  const [loading, setLoading] = useState(true);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!user) return;

    async function loadProfile() {
      try {
        const profile = await getUserProfile(user!.uid);
        if (profile) {
          setDisplayName(profile.displayName || "");
          setUsername(profile.username || "");
          setBio(profile.bio || "");
          setLocation(profile.location || "");
          setProfileImageURL(profile.profileImageURL || "");
        }
      } catch (err) {
        console.error("Error loading profile:", err);
      } finally {
        setLoading(false);
      }
    }

    loadProfile();
  }, [user]);

  async function handlePhotoUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file || !user) return;

    setUploadingPhoto(true);
    try {
      const url = await uploadProfilePhoto(user.uid, file);
      setProfileImageURL(url);
    } catch (err) {
      console.error("Error uploading photo:", err);
    } finally {
      setUploadingPhoto(false);
    }
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;

    setSaving(true);
    setSaved(false);
    try {
      await updateUserProfile(user.uid, {
        displayName,
        username,
        bio,
        location,
      });
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (err) {
      console.error("Error saving profile:", err);
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-[50vh] items-center justify-center">
        <Loader2 size={32} className="animate-spin text-accent" />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl">
      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handlePhotoUpload}
      />

      <div className="mb-6">
        <h1 className="text-2xl font-bold">Settings</h1>
        <p className="text-sm text-muted">Manage your profile and preferences</p>
      </div>

      <form onSubmit={handleSave} className="space-y-8">
        {/* Profile Photo */}
        <div className="rounded-2xl border border-border/50 bg-card/50 p-6">
          <h2 className="text-sm font-semibold mb-4">Profile Photo</h2>
          <div className="flex items-center gap-6">
            <div className="relative">
              {profileImageURL ? (
                <img
                  src={profileImageURL}
                  alt="Profile"
                  className="h-20 w-20 rounded-full object-cover"
                />
              ) : (
                <div className="flex h-20 w-20 items-center justify-center rounded-full bg-accent/10 text-2xl font-bold text-accent">
                  {displayName?.charAt(0) ||
                    user?.email?.charAt(0)?.toUpperCase() ||
                    "U"}
                </div>
              )}
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploadingPhoto}
                className="absolute -bottom-1 -right-1 flex h-7 w-7 items-center justify-center rounded-full bg-accent text-white hover:bg-accent-hover disabled:opacity-50"
              >
                {uploadingPhoto ? (
                  <Loader2 size={12} className="animate-spin" />
                ) : (
                  <Camera size={12} />
                )}
              </button>
            </div>
            <div>
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploadingPhoto}
                className="rounded-lg bg-card border border-border px-4 py-2 text-sm font-medium hover:bg-card-hover disabled:opacity-50"
              >
                {uploadingPhoto ? "Uploading..." : "Upload Photo"}
              </button>
              <p className="mt-1.5 text-xs text-muted">
                JPG, PNG, or GIF. Max 5MB.
              </p>
            </div>
          </div>
        </div>

        {/* Profile Info */}
        <div className="rounded-2xl border border-border/50 bg-card/50 p-6">
          <h2 className="text-sm font-semibold mb-4">Profile Information</h2>
          <div className="space-y-4">
            <div>
              <label className="mb-1.5 block text-sm text-muted">
                Display Name
              </label>
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm text-foreground outline-none focus:border-accent focus:ring-1 focus:ring-accent"
                placeholder="Your name"
              />
            </div>

            <div>
              <label className="mb-1.5 block text-sm text-muted">
                Username
              </label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-sm text-muted">
                  @
                </span>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full rounded-xl border border-border bg-background py-3 pl-8 pr-4 text-sm text-foreground outline-none focus:border-accent focus:ring-1 focus:ring-accent"
                  placeholder="username"
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
                className="w-full resize-none rounded-xl border border-border bg-background px-4 py-3 text-sm text-foreground outline-none focus:border-accent focus:ring-1 focus:ring-accent"
                placeholder="Tell the community about yourself..."
              />
              <p className="mt-1 text-xs text-muted text-right">
                {bio.length}/160
              </p>
            </div>

            <div>
              <label className="mb-1.5 block text-sm text-muted">
                Location
              </label>
              <input
                type="text"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                className="w-full rounded-xl border border-border bg-background px-4 py-3 text-sm text-foreground outline-none focus:border-accent focus:ring-1 focus:ring-accent"
                placeholder="City, State"
              />
            </div>
          </div>
        </div>

        {/* Account */}
        <div className="rounded-2xl border border-border/50 bg-card/50 p-6">
          <h2 className="text-sm font-semibold mb-4">Account</h2>
          <div className="space-y-4">
            <div>
              <label className="mb-1.5 block text-sm text-muted">Email</label>
              <input
                type="email"
                value={user?.email || ""}
                disabled
                className="w-full rounded-xl border border-border bg-background/50 px-4 py-3 text-sm text-muted outline-none"
              />
            </div>
          </div>
        </div>

        {/* Save button */}
        <div className="flex items-center justify-end gap-3">
          {saved && (
            <span className="flex items-center gap-1 text-sm text-green-400">
              <Check size={16} />
              Saved successfully
            </span>
          )}
          <button
            type="submit"
            disabled={saving}
            className="flex items-center gap-2 rounded-xl bg-accent px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-accent-hover disabled:opacity-50"
          >
            {saving ? (
              <Loader2 size={18} className="animate-spin" />
            ) : (
              "Save Changes"
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
