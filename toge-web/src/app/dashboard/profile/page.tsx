"use client";

import { useAuth } from "@/contexts/AuthContext";
import { useState, useEffect, useRef } from "react";
import {
  MapPin,
  Calendar,
  Car,
  Settings,
  Camera,
  Loader2,
} from "lucide-react";
import Link from "next/link";
import { getUserProfile, uploadProfilePhoto, UserProfile } from "@/services/users";
import { getUserCars, CarBuild } from "@/services/cars";
import { getFeedPosts, Post } from "@/services/posts";
import { query, collection, where, getDocs, orderBy } from "firebase/firestore";
import { db } from "@/lib/firebase";

export default function ProfilePage() {
  const { user } = useAuth();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [cars, setCars] = useState<CarBuild[]>([]);
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploadingPhoto, setUploadingPhoto] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!user) return;

    async function loadProfile() {
      try {
        const [profileData, carsData] = await Promise.all([
          getUserProfile(user!.uid),
          getUserCars(user!.uid),
        ]);

        // Get user's posts
        const postsQuery = query(
          collection(db, "posts"),
          where("authorId", "==", user!.uid),
          orderBy("createdAt", "desc")
        );
        const postsSnap = await getDocs(postsQuery);
        const postsData = postsSnap.docs.map((d) => ({ id: d.id, ...d.data() } as Post));

        setProfile(profileData);
        setCars(carsData);
        setPosts(postsData);
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
      setProfile((prev) => (prev ? { ...prev, profileImageURL: url } : prev));
    } catch (err) {
      console.error("Error uploading photo:", err);
    } finally {
      setUploadingPhoto(false);
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-[50vh] items-center justify-center">
        <Loader2 size={32} className="animate-spin text-accent" />
      </div>
    );
  }

  const joinDate = profile?.createdAt
    ? new Date(profile.createdAt).toLocaleDateString("en-US", {
        month: "long",
        year: "numeric",
      })
    : "March 2026";

  return (
    <div className="mx-auto max-w-3xl">
      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handlePhotoUpload}
      />

      {/* Profile header */}
      <div className="relative">
        {/* Cover photo */}
        <div className="relative h-48 overflow-hidden rounded-2xl bg-card sm:h-56">
          <div className="h-full w-full bg-gradient-to-br from-accent/20 to-accent/5" />
          <div className="absolute inset-0 bg-gradient-to-t from-background/80 to-transparent" />
        </div>

        {/* Avatar */}
        <div className="relative -mt-16 ml-6 flex items-end gap-4 sm:ml-8">
          <div className="relative">
            {profile?.profileImageURL ? (
              <img
                src={profile.profileImageURL}
                alt="Profile"
                className="h-28 w-28 rounded-full border-4 border-background object-cover sm:h-32 sm:w-32"
              />
            ) : (
              <div className="flex h-28 w-28 items-center justify-center rounded-full border-4 border-background bg-accent/10 text-3xl font-bold text-accent sm:h-32 sm:w-32">
                {profile?.displayName?.charAt(0) ||
                  user?.email?.charAt(0)?.toUpperCase() ||
                  "U"}
              </div>
            )}
            <button
              onClick={() => fileInputRef.current?.click()}
              disabled={uploadingPhoto}
              className="absolute bottom-1 right-1 flex h-8 w-8 items-center justify-center rounded-full bg-accent text-white hover:bg-accent-hover disabled:opacity-50"
            >
              {uploadingPhoto ? (
                <Loader2 size={14} className="animate-spin" />
              ) : (
                <Camera size={14} />
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Profile info */}
      <div className="mt-4 px-2 sm:px-4">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold">
              {profile?.displayName || user?.displayName || "Set your name"}
            </h1>
            <p className="text-sm text-muted">
              @{profile?.username || "username"}
            </p>
          </div>
          <Link
            href="/dashboard/settings"
            className="flex items-center gap-2 rounded-xl border border-border px-4 py-2 text-sm font-medium text-muted transition-colors hover:bg-card hover:text-foreground"
          >
            <Settings size={16} />
            Edit Profile
          </Link>
        </div>

        {profile?.bio && (
          <p className="mt-3 text-sm text-muted">{profile.bio}</p>
        )}

        <div className="mt-3 flex flex-wrap items-center gap-4 text-sm text-muted">
          {profile?.location && (
            <span className="flex items-center gap-1.5">
              <MapPin size={14} className="text-accent" />
              {profile.location}
            </span>
          )}
          <span className="flex items-center gap-1.5">
            <Calendar size={14} className="text-accent" />
            Joined {joinDate}
          </span>
          <span className="flex items-center gap-1.5">
            <Car size={14} className="text-accent" />
            {cars.length} build{cars.length !== 1 ? "s" : ""}
          </span>
        </div>

        {/* Stats */}
        <div className="mt-6 flex gap-6 border-b border-border/50 pb-6">
          {[
            { value: posts.length.toString(), label: "Posts" },
          ].map((stat) => (
            <div key={stat.label} className="text-center">
              <div className="text-lg font-bold">{stat.value}</div>
              <div className="text-xs text-muted">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Garage section */}
      <div className="mt-6 px-2 sm:px-4">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold">Garage</h2>
          <Link
            href="/dashboard/garage"
            className="text-xs text-accent hover:underline"
          >
            View all
          </Link>
        </div>
        {cars.length > 0 ? (
          <div className="grid gap-3 sm:grid-cols-2">
            {cars.map((car) => (
              <div
                key={car.id}
                className="group cursor-pointer overflow-hidden rounded-xl border border-border/50 bg-card/50 transition-all hover:border-border hover:bg-card"
              >
                <div className="relative h-32 overflow-hidden">
                  {car.coverPhoto ? (
                    <img
                      src={car.coverPhoto}
                      alt={car.nickname}
                      className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                    />
                  ) : (
                    <div className="h-full w-full bg-gradient-to-br from-accent/10 to-accent/5 flex items-center justify-center">
                      <Car size={32} className="text-muted/30" />
                    </div>
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
                  <div className="absolute bottom-2 left-3">
                    <p className="text-sm font-semibold">{car.nickname || `${car.year} ${car.make} ${car.model}`}</p>
                    <p className="text-xs text-zinc-300">
                      {car.year} {car.make} {car.model}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="rounded-xl border border-dashed border-border/50 p-8 text-center">
            <Car size={32} className="mx-auto text-muted/30" />
            <p className="mt-2 text-sm text-muted">No builds yet</p>
            <Link
              href="/dashboard/garage"
              className="mt-3 inline-block text-xs text-accent hover:underline"
            >
              Add your first build
            </Link>
          </div>
        )}
      </div>

      {/* Posts grid */}
      <div className="mt-8 px-2 sm:px-4">
        <h2 className="text-lg font-semibold mb-4">Posts</h2>
        {posts.length > 0 ? (
          <div className="grid grid-cols-3 gap-1.5">
            {posts
              .filter((post) => post.images && post.images.length > 0)
              .map((post) => (
                <div
                  key={post.id}
                  className="group relative cursor-pointer overflow-hidden rounded-lg aspect-square"
                >
                  <img
                    src={post.images[0]}
                    alt="Post"
                    className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
                  />
                  <div className="absolute inset-0 bg-black/30 opacity-0 transition-opacity group-hover:opacity-100" />
                </div>
              ))}
          </div>
        ) : (
          <div className="rounded-xl border border-dashed border-border/50 p-8 text-center">
            <p className="text-sm text-muted">No posts yet</p>
          </div>
        )}
      </div>
    </div>
  );
}
