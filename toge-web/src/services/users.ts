import {
  doc,
  getDoc,
  updateDoc,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { uploadImage } from "./storage";

export interface UserProfile {
  uid: string;
  email: string;
  displayName: string;
  username: string;
  profileImageURL: string;
  bio: string;
  location: string;
  createdAt: Date;
  updatedAt: Date;
}

export async function getUserProfile(uid: string): Promise<UserProfile | null> {
  const userRef = doc(db, "users", uid);
  const snap = await getDoc(userRef);
  if (!snap.exists()) return null;
  return { uid: snap.id, ...snap.data() } as UserProfile;
}

export async function updateUserProfile(
  uid: string,
  data: Partial<Pick<UserProfile, "displayName" | "username" | "bio" | "location" | "profileImageURL">>
) {
  const userRef = doc(db, "users", uid);
  await updateDoc(userRef, {
    ...data,
    updatedAt: serverTimestamp(),
  });
}

export async function uploadProfilePhoto(uid: string, file: File): Promise<string> {
  const url = await uploadImage(file, `users/${uid}/profile`);
  await updateUserProfile(uid, { profileImageURL: url });
  return url;
}
