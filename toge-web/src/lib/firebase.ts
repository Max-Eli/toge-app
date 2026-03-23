import { initializeApp, getApps } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyBL3eW1byOKtnrc1yYJWTBJhmPQHi_GREg",
  authDomain: "toge-7f8e6.firebaseapp.com",
  projectId: "toge-7f8e6",
  storageBucket: "toge-7f8e6.firebasestorage.app",
  messagingSenderId: "161127513603",
  appId: "1:161127513603:web:f21658fa42517600c55836",
  measurementId: "G-4M1C09Z38Y",
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export default app;
