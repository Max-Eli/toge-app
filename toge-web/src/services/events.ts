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
  serverTimestamp,
  increment,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { uploadImage } from "./storage";

export interface CarEvent {
  id: string;
  title: string;
  description: string;
  date: string;
  time: string;
  location: string;
  address: string;
  category: string;
  imageURL: string;
  organizerId: string;
  organizerName: string;
  attendeeCount: number;
  maxAttendees: number;
  createdAt: Date;
}

export interface EventAttendee {
  userId: string;
  userName: string;
  userAvatar: string;
  joinedAt: Date;
}

export async function getEvents(): Promise<CarEvent[]> {
  const q = query(collection(db, "events"), orderBy("date", "asc"));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as CarEvent));
}

export async function getEvent(id: string): Promise<CarEvent | null> {
  const snap = await getDoc(doc(db, "events", id));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() } as CarEvent;
}

export async function createEvent(
  data: {
    title: string;
    description: string;
    date: string;
    time: string;
    location: string;
    address: string;
    category: string;
    organizerId: string;
    organizerName: string;
    maxAttendees: number;
  },
  imageFile?: File
): Promise<string> {
  let imageURL = "";
  if (imageFile) {
    imageURL = await uploadImage(imageFile, `events`);
  }

  const docRef = await addDoc(collection(db, "events"), {
    ...data,
    imageURL,
    attendeeCount: 1,
    createdAt: serverTimestamp(),
  });

  // Organizer is first attendee
  await setDoc(doc(db, "events", docRef.id, "attendees", data.organizerId), {
    userId: data.organizerId,
    userName: data.organizerName,
    userAvatar: "",
    joinedAt: serverTimestamp(),
  });

  return docRef.id;
}

export async function rsvpEvent(
  eventId: string,
  data: { userId: string; userName: string; userAvatar: string }
): Promise<void> {
  await setDoc(doc(db, "events", eventId, "attendees", data.userId), {
    ...data,
    joinedAt: serverTimestamp(),
  });
  await updateDoc(doc(db, "events", eventId), {
    attendeeCount: increment(1),
  });
}

export async function cancelRsvp(eventId: string, userId: string): Promise<void> {
  await deleteDoc(doc(db, "events", eventId, "attendees", userId));
  await updateDoc(doc(db, "events", eventId), {
    attendeeCount: increment(-1),
  });
}

export async function isAttending(eventId: string, userId: string): Promise<boolean> {
  const snap = await getDoc(doc(db, "events", eventId, "attendees", userId));
  return snap.exists();
}

export async function getAttendees(eventId: string): Promise<EventAttendee[]> {
  const snap = await getDocs(collection(db, "events", eventId, "attendees"));
  return snap.docs.map((d) => d.data() as EventAttendee);
}

export async function deleteEvent(eventId: string): Promise<void> {
  await deleteDoc(doc(db, "events", eventId));
}
