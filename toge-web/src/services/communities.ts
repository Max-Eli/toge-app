import {
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDocs,
  getDoc,
  setDoc,
  query,
  where,
  orderBy,
  limit,
  serverTimestamp,
  increment,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { uploadImage } from "./storage";

export interface Community {
  id: string;
  name: string;
  description: string;
  type: "public" | "private";
  category: string;
  ownerId: string;
  ownerName: string;
  bannerURL: string;
  avatarURL: string;
  memberCount: number;
  postCount: number;
  rules: string[];
  createdAt: Date;
}

export interface CommunityPost {
  id: string;
  communityId: string;
  authorId: string;
  authorName: string;
  authorAvatar: string;
  type: "discussion" | "question" | "build" | "media";
  title: string;
  content: string;
  images: string[];
  likes: number;
  commentCount: number;
  isPinned: boolean;
  tags: string[];
  createdAt: Date;
}

export interface CommunityMember {
  userId: string;
  role: "owner" | "moderator" | "member";
  joinedAt: Date;
}

export interface JoinRequest {
  userId: string;
  userName: string;
  userAvatar: string;
  message: string;
  status: "pending" | "approved" | "rejected";
  createdAt: Date;
}

// Communities CRUD
export async function getCommunities(): Promise<Community[]> {
  const q = query(collection(db, "communities"), orderBy("memberCount", "desc"));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as Community));
}

export async function getCommunity(id: string): Promise<Community | null> {
  const snap = await getDoc(doc(db, "communities", id));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as Community;
}

export async function createCommunity(data: {
  name: string;
  description: string;
  type: "public" | "private";
  category: string;
  ownerId: string;
  ownerName: string;
  rules: string[];
  bannerFile?: File;
}): Promise<string> {
  let bannerURL = "";
  if (data.bannerFile) {
    bannerURL = await uploadImage(data.bannerFile, `communities/banners`);
  }

  const { bannerFile, ...rest } = data;
  const docRef = await addDoc(collection(db, "communities"), {
    ...rest,
    bannerURL,
    avatarURL: "",
    memberCount: 1,
    postCount: 0,
    createdAt: serverTimestamp(),
  });

  // Add owner as first member
  await setDoc(doc(db, "communities", docRef.id, "members", data.ownerId), {
    userId: data.ownerId,
    role: "owner",
    joinedAt: serverTimestamp(),
  });

  return docRef.id;
}

// Membership
export async function joinCommunity(communityId: string, userId: string): Promise<void> {
  await setDoc(doc(db, "communities", communityId, "members", userId), {
    userId,
    role: "member",
    joinedAt: serverTimestamp(),
  });
  await updateDoc(doc(db, "communities", communityId), {
    memberCount: increment(1),
  });
}

export async function leaveCommunity(communityId: string, userId: string): Promise<void> {
  await deleteDoc(doc(db, "communities", communityId, "members", userId));
  await updateDoc(doc(db, "communities", communityId), {
    memberCount: increment(-1),
  });
}

export async function isMember(communityId: string, userId: string): Promise<boolean> {
  const snap = await getDoc(doc(db, "communities", communityId, "members", userId));
  return snap.exists();
}

export async function getMembers(communityId: string): Promise<CommunityMember[]> {
  const snap = await getDocs(collection(db, "communities", communityId, "members"));
  return snap.docs.map((d) => d.data() as CommunityMember);
}

// Join requests (private communities)
export async function requestToJoin(
  communityId: string,
  data: { userId: string; userName: string; userAvatar: string; message: string }
): Promise<void> {
  await setDoc(doc(db, "communities", communityId, "requests", data.userId), {
    ...data,
    status: "pending",
    createdAt: serverTimestamp(),
  });
}

export async function getJoinRequests(communityId: string): Promise<JoinRequest[]> {
  const q = query(
    collection(db, "communities", communityId, "requests"),
    where("status", "==", "pending")
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => d.data() as JoinRequest);
}

export async function approveRequest(communityId: string, userId: string): Promise<void> {
  await updateDoc(doc(db, "communities", communityId, "requests", userId), {
    status: "approved",
  });
  await joinCommunity(communityId, userId);
}

export async function rejectRequest(communityId: string, userId: string): Promise<void> {
  await updateDoc(doc(db, "communities", communityId, "requests", userId), {
    status: "rejected",
  });
}

// Community posts
export async function getCommunityPosts(
  communityId: string,
  sortBy: "hot" | "new" | "top" = "new"
): Promise<CommunityPost[]> {
  const orderField = sortBy === "top" ? "likes" : "createdAt";
  const q = query(
    collection(db, "communities", communityId, "posts"),
    orderBy(orderField, "desc"),
    limit(50)
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as CommunityPost));
}

export async function createCommunityPost(
  communityId: string,
  data: {
    authorId: string;
    authorName: string;
    authorAvatar: string;
    type: "discussion" | "question" | "build" | "media";
    title: string;
    content: string;
    tags: string[];
  },
  imageFiles: File[]
): Promise<string> {
  let images: string[] = [];
  if (imageFiles.length > 0) {
    images = await uploadImage(imageFiles[0], `communities/${communityId}/posts`).then(
      (url) => [url]
    );
  }

  const docRef = await addDoc(collection(db, "communities", communityId, "posts"), {
    ...data,
    communityId,
    images,
    likes: 0,
    commentCount: 0,
    isPinned: false,
    createdAt: serverTimestamp(),
  });

  await updateDoc(doc(db, "communities", communityId), {
    postCount: increment(1),
  });

  return docRef.id;
}

export async function toggleCommunityPostLike(
  communityId: string,
  postId: string,
  userId: string
): Promise<boolean> {
  const likeRef = doc(db, "communities", communityId, "posts", postId, "likes", userId);
  const likeSnap = await getDoc(likeRef);

  if (likeSnap.exists()) {
    await deleteDoc(likeRef);
    await updateDoc(doc(db, "communities", communityId, "posts", postId), {
      likes: increment(-1),
    });
    return false;
  } else {
    await setDoc(likeRef, { userId, createdAt: serverTimestamp() });
    await updateDoc(doc(db, "communities", communityId, "posts", postId), {
      likes: increment(1),
    });
    return true;
  }
}

export async function addCommunityComment(
  communityId: string,
  postId: string,
  data: {
    authorId: string;
    authorName: string;
    authorAvatar: string;
    content: string;
  }
): Promise<string> {
  const docRef = await addDoc(
    collection(db, "communities", communityId, "posts", postId, "comments"),
    {
      ...data,
      createdAt: serverTimestamp(),
    }
  );
  await updateDoc(doc(db, "communities", communityId, "posts", postId), {
    commentCount: increment(1),
  });
  return docRef.id;
}

export async function getCommunityComments(
  communityId: string,
  postId: string
): Promise<Array<{ id: string; authorId: string; authorName: string; authorAvatar: string; content: string; createdAt: Date }>> {
  const q = query(
    collection(db, "communities", communityId, "posts", postId, "comments"),
    orderBy("createdAt", "asc")
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as { id: string; authorId: string; authorName: string; authorAvatar: string; content: string; createdAt: Date }));
}
