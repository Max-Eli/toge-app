import {
  collection,
  doc,
  addDoc,
  getDocs,
  getDoc,
  setDoc,
  query,
  where,
  orderBy,
  limit,
  serverTimestamp,
  onSnapshot,
  updateDoc,
  Unsubscribe,
  or,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

export interface ChatChannel {
  id: string;
  type: "dm" | "group";
  name: string;
  participants: string[];
  participantNames: Record<string, string>;
  lastMessage: string;
  lastMessageAt: Date;
  createdBy: string;
  createdAt: Date;
}

export interface ChatMessage {
  id: string;
  channelId: string;
  senderId: string;
  senderName: string;
  senderAvatar: string;
  content: string;
  imageURL: string;
  createdAt: Date;
}

// Channels
export async function getUserChannels(userId: string): Promise<ChatChannel[]> {
  const q = query(
    collection(db, "channels"),
    where("participants", "array-contains", userId),
    orderBy("lastMessageAt", "desc")
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() } as ChatChannel));
}

export async function createDM(
  userId: string,
  userName: string,
  otherUserId: string,
  otherUserName: string
): Promise<string> {
  // Check if DM already exists
  const q = query(
    collection(db, "channels"),
    where("type", "==", "dm"),
    where("participants", "array-contains", userId)
  );
  const snap = await getDocs(q);
  const existing = snap.docs.find((d) => {
    const data = d.data();
    return data.participants.includes(otherUserId);
  });

  if (existing) return existing.id;

  const docRef = await addDoc(collection(db, "channels"), {
    type: "dm",
    name: "",
    participants: [userId, otherUserId],
    participantNames: { [userId]: userName, [otherUserId]: otherUserName },
    lastMessage: "",
    lastMessageAt: serverTimestamp(),
    createdBy: userId,
    createdAt: serverTimestamp(),
  });
  return docRef.id;
}

export async function createGroupChat(
  name: string,
  creatorId: string,
  participants: string[],
  participantNames: Record<string, string>
): Promise<string> {
  const docRef = await addDoc(collection(db, "channels"), {
    type: "group",
    name,
    participants,
    participantNames,
    lastMessage: "",
    lastMessageAt: serverTimestamp(),
    createdBy: creatorId,
    createdAt: serverTimestamp(),
  });
  return docRef.id;
}

// Messages
export function subscribeToMessages(
  channelId: string,
  callback: (messages: ChatMessage[]) => void
): Unsubscribe {
  const q = query(
    collection(db, "channels", channelId, "messages"),
    orderBy("createdAt", "asc"),
    limit(100)
  );

  return onSnapshot(q, (snap) => {
    const messages = snap.docs.map(
      (d) => ({ id: d.id, ...d.data() } as ChatMessage)
    );
    callback(messages);
  });
}

export async function sendMessage(
  channelId: string,
  data: {
    senderId: string;
    senderName: string;
    senderAvatar: string;
    content: string;
    imageURL?: string;
  }
): Promise<void> {
  await addDoc(collection(db, "channels", channelId, "messages"), {
    ...data,
    channelId,
    imageURL: data.imageURL || "",
    createdAt: serverTimestamp(),
  });

  await updateDoc(doc(db, "channels", channelId), {
    lastMessage: data.content,
    lastMessageAt: serverTimestamp(),
  });
}

export function subscribeToChannels(
  userId: string,
  callback: (channels: ChatChannel[]) => void
): Unsubscribe {
  const q = query(
    collection(db, "channels"),
    where("participants", "array-contains", userId),
    orderBy("lastMessageAt", "desc")
  );

  return onSnapshot(q, (snap) => {
    const channels = snap.docs.map(
      (d) => ({ id: d.id, ...d.data() } as ChatChannel)
    );
    callback(channels);
  });
}
