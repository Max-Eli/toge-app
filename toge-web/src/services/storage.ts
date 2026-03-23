import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { storage } from "@/lib/firebase";
import { v4 as uuidv4 } from "uuid";

export async function uploadImage(
  file: File,
  path: string
): Promise<string> {
  const ext = file.name.split(".").pop();
  const fileName = `${uuidv4()}.${ext}`;
  const storageRef = ref(storage, `${path}/${fileName}`);
  await uploadBytes(storageRef, file);
  return getDownloadURL(storageRef);
}

export async function uploadMultipleImages(
  files: File[],
  path: string
): Promise<string[]> {
  const promises = files.map((file) => uploadImage(file, path));
  return Promise.all(promises);
}
