import {
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDocs,
  getDoc,
  query,
  orderBy,
  limit,
  startAfter,
  serverTimestamp,
  increment,
  where,
  setDoc,
  DocumentSnapshot,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { uploadMultipleImages } from "./storage";

export interface Post {
  id: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  carName: string;
  content: string;
  images: string[];
  likes: number;
  commentCount: number;
  createdAt: Date;
}

export interface Comment {
  id: string;
  postId: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  content: string;
  createdAt: Date;
}

export async function getFeedPosts(
  limitCount: number = 20,
  lastDoc?: DocumentSnapshot
): Promise<Post[]> {
  let q = query(
    collection(db, "posts"),
    orderBy("createdAt", "desc"),
    limit(limitCount)
  );
  if (lastDoc) {
    q = query(q, startAfter(lastDoc));
  }
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as Post));
}

export async function createPost(
  data: {
    authorId: string;
    authorName: string;
    authorAvatar: string;
    carName: string;
    content: string;
  },
  imageFiles: File[]
): Promise<string> {
  let images: string[] = [];
  if (imageFiles.length > 0) {
    images = await uploadMultipleImages(imageFiles, `posts/${data.authorId}`);
  }

  const docRef = await addDoc(collection(db, "posts"), {
    ...data,
    images,
    likes: 0,
    commentCount: 0,
    createdAt: serverTimestamp(),
  });
  return docRef.id;
}

export async function deletePost(postId: string): Promise<void> {
  await deleteDoc(doc(db, "posts", postId));
}

export async function toggleLike(
  postId: string,
  userId: string
): Promise<boolean> {
  const likeRef = doc(db, "posts", postId, "likes", userId);
  const likeSnap = await getDoc(likeRef);

  if (likeSnap.exists()) {
    await deleteDoc(likeRef);
    await updateDoc(doc(db, "posts", postId), { likes: increment(-1) });
    return false;
  } else {
    await setDoc(likeRef, { userId, createdAt: serverTimestamp() });
    await updateDoc(doc(db, "posts", postId), { likes: increment(1) });
    return true;
  }
}

export async function hasUserLiked(
  postId: string,
  userId: string
): Promise<boolean> {
  const likeRef = doc(db, "posts", postId, "likes", userId);
  const likeSnap = await getDoc(likeRef);
  return likeSnap.exists();
}

export async function getComments(postId: string): Promise<Comment[]> {
  const q = query(
    collection(db, "posts", postId, "comments"),
    orderBy("createdAt", "asc")
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as Comment));
}

export async function addComment(
  postId: string,
  data: {
    authorId: string;
    authorName: string;
    authorAvatar: string;
    content: string;
  }
): Promise<string> {
  const docRef = await addDoc(collection(db, "posts", postId, "comments"), {
    ...data,
    postId,
    createdAt: serverTimestamp(),
  });
  await updateDoc(doc(db, "posts", postId), { commentCount: increment(1) });
  return docRef.id;
}
