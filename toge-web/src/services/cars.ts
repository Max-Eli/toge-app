import {
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDocs,
  getDoc,
  query,
  where,
  orderBy,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { uploadMultipleImages } from "./storage";

export interface CarMod {
  name: string;
  category: string;
}

export interface CarBuild {
  id: string;
  ownerId: string;
  year: string;
  make: string;
  model: string;
  trim: string;
  nickname: string;
  description: string;
  horsepower: string;
  torque: string;
  engine: string;
  drivetrain: string;
  transmission: string;
  weight: string;
  mods: CarMod[];
  photos: string[];
  coverPhoto: string;
  createdAt: Date;
  updatedAt: Date;
}

export async function getUserCars(userId: string): Promise<CarBuild[]> {
  const q = query(
    collection(db, "cars"),
    where("ownerId", "==", userId),
    orderBy("createdAt", "desc")
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as CarBuild));
}

export async function getCarById(carId: string): Promise<CarBuild | null> {
  const snap = await getDoc(doc(db, "cars", carId));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as CarBuild;
}

export async function addCar(
  data: Omit<CarBuild, "id" | "createdAt" | "updatedAt" | "photos" | "coverPhoto">,
  photoFiles: File[]
): Promise<string> {
  let photos: string[] = [];
  if (photoFiles.length > 0) {
    photos = await uploadMultipleImages(photoFiles, `cars/${data.ownerId}`);
  }

  const docRef = await addDoc(collection(db, "cars"), {
    ...data,
    photos,
    coverPhoto: photos[0] || "",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return docRef.id;
}

export async function updateCar(
  carId: string,
  data: Partial<Omit<CarBuild, "id" | "createdAt" | "updatedAt">>,
  newPhotoFiles?: File[]
): Promise<void> {
  let updateData: Record<string, unknown> = { ...data, updatedAt: serverTimestamp() };

  if (newPhotoFiles && newPhotoFiles.length > 0) {
    const ownerId = data.ownerId || "";
    const newPhotos = await uploadMultipleImages(newPhotoFiles, `cars/${ownerId}`);
    const existingPhotos = data.photos || [];
    updateData.photos = [...existingPhotos, ...newPhotos];
    if (!updateData.coverPhoto) {
      updateData.coverPhoto = (updateData.photos as string[])[0];
    }
  }

  await updateDoc(doc(db, "cars", carId), updateData);
}

export async function deleteCar(carId: string): Promise<void> {
  await deleteDoc(doc(db, "cars", carId));
}
