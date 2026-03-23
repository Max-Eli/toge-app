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
  orderBy,
  where,
  limit,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { uploadMultipleImages } from "./storage";

export interface Listing {
  id: string;
  sellerId: string;
  sellerName: string;
  sellerAvatar: string;
  title: string;
  description: string;
  price: number;
  condition: "New" | "Like New" | "Used" | "Fair";
  category: string;
  carFitment: string;
  images: string[];
  location: string;
  status: "active" | "sold" | "removed";
  createdAt: Date;
}

export async function getListings(
  category?: string,
  searchQuery?: string
): Promise<Listing[]> {
  let q = query(
    collection(db, "listings"),
    where("status", "==", "active"),
    orderBy("createdAt", "desc"),
    limit(50)
  );

  const snap = await getDocs(q);
  let results = snap.docs.map((d) => ({ id: d.id, ...d.data() } as Listing));

  if (category && category !== "All") {
    results = results.filter((l) => l.category === category);
  }
  if (searchQuery) {
    const lowerQuery = searchQuery.toLowerCase();
    results = results.filter(
      (l) =>
        l.title.toLowerCase().includes(lowerQuery) ||
        l.description.toLowerCase().includes(lowerQuery)
    );
  }

  return results;
}

export async function getListing(id: string): Promise<Listing | null> {
  const snap = await getDoc(doc(db, "listings", id));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as Listing;
}

export async function createListing(
  data: {
    sellerId: string;
    sellerName: string;
    sellerAvatar: string;
    title: string;
    description: string;
    price: number;
    condition: "New" | "Like New" | "Used" | "Fair";
    category: string;
    carFitment: string;
    location: string;
  },
  imageFiles: File[]
): Promise<string> {
  let images: string[] = [];
  if (imageFiles.length > 0) {
    images = await uploadMultipleImages(imageFiles, `listings/${data.sellerId}`);
  }

  const docRef = await addDoc(collection(db, "listings"), {
    ...data,
    images,
    status: "active",
    createdAt: serverTimestamp(),
  });
  return docRef.id;
}

export async function updateListing(
  listingId: string,
  data: Partial<Omit<Listing, "id" | "createdAt">>
): Promise<void> {
  await updateDoc(doc(db, "listings", listingId), data);
}

export async function deleteListing(listingId: string): Promise<void> {
  await updateDoc(doc(db, "listings", listingId), { status: "removed" });
}

export async function markAsSold(listingId: string): Promise<void> {
  await updateDoc(doc(db, "listings", listingId), { status: "sold" });
}

// Saved listings
export async function saveListing(userId: string, listingId: string): Promise<void> {
  await setDoc(doc(db, "users", userId, "savedListings", listingId), {
    listingId,
    savedAt: serverTimestamp(),
  });
}

export async function unsaveListing(userId: string, listingId: string): Promise<void> {
  await deleteDoc(doc(db, "users", userId, "savedListings", listingId));
}

export async function getSavedListingIds(userId: string): Promise<string[]> {
  const snap = await getDocs(collection(db, "users", userId, "savedListings"));
  return snap.docs.map((d) => d.id);
}
