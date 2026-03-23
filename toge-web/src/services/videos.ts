import {
  collection,
  doc,
  addDoc,
  getDocs,
  getDoc,
  query,
  orderBy,
  where,
  limit,
  serverTimestamp,
  updateDoc,
  increment,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { uploadImage } from "./storage";

export interface Video {
  id: string;
  title: string;
  description: string;
  videoURL: string;
  thumbnailURL: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  category: string;
  difficulty: "Beginner" | "Intermediate" | "Advanced";
  duration: string;
  views: number;
  likes: number;
  createdAt: Date;
}

export async function getVideos(category?: string): Promise<Video[]> {
  let q = query(
    collection(db, "videos"),
    orderBy("createdAt", "desc"),
    limit(50)
  );

  const snap = await getDocs(q);
  let results = snap.docs.map((d) => ({ id: d.id, ...d.data() } as Video));

  if (category && category !== "All") {
    results = results.filter((v) => v.category === category);
  }

  return results;
}

export async function getVideo(id: string): Promise<Video | null> {
  const snap = await getDoc(doc(db, "videos", id));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as Video;
}

export async function createVideo(
  data: {
    title: string;
    description: string;
    videoURL: string;
    authorId: string;
    authorName: string;
    authorAvatar: string;
    category: string;
    difficulty: "Beginner" | "Intermediate" | "Advanced";
    duration: string;
  },
  thumbnailFile?: File
): Promise<string> {
  let thumbnailURL = "";
  if (thumbnailFile) {
    thumbnailURL = await uploadImage(thumbnailFile, `videos/thumbnails`);
  }

  const docRef = await addDoc(collection(db, "videos"), {
    ...data,
    thumbnailURL,
    views: 0,
    likes: 0,
    createdAt: serverTimestamp(),
  });
  return docRef.id;
}

export async function incrementViews(videoId: string): Promise<void> {
  await updateDoc(doc(db, "videos", videoId), { views: increment(1) });
}
