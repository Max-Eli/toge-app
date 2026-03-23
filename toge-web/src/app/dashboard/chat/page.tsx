"use client";

import { useState, useEffect, useRef } from "react";
import { useAuth } from "@/contexts/AuthContext";
import {
  Search,
  Send,
  MoreVertical,
  Users,
  Plus,
  ImagePlus,
  Hash,
  ArrowLeft,
  X,
  Loader2,
} from "lucide-react";
import {
  ChatChannel,
  ChatMessage,
  subscribeToChannels,
  subscribeToMessages,
  sendMessage,
  createGroupChat,
  createDM,
} from "@/services/chat";
import { getUserProfile } from "@/services/users";

export default function ChatPage() {
  const { user } = useAuth();
  const [channels, setChannels] = useState<ChatChannel[]>([]);
  const [activeChannel, setActiveChannel] = useState<ChatChannel | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [message, setMessage] = useState("");
  const [showChannels, setShowChannels] = useState(true);
  const [sending, setSending] = useState(false);
  const [loadingChannels, setLoadingChannels] = useState(true);
  const [showNewChat, setShowNewChat] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [profile, setProfile] = useState<{ displayName: string; profileImageURL: string } | null>(null);

  useEffect(() => {
    if (!user) return;

    getUserProfile(user.uid).then((p) => {
      if (p) setProfile({ displayName: p.displayName, profileImageURL: p.profileImageURL });
    });

    const unsub = subscribeToChannels(user.uid, (channelList) => {
      setChannels(channelList);
      setLoadingChannels(false);
    });
    return unsub;
  }, [user]);

  useEffect(() => {
    if (!activeChannel) return;

    const unsub = subscribeToMessages(activeChannel.id, (msgs) => {
      setMessages(msgs);
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: "smooth" }), 100);
    });
    return unsub;
  }, [activeChannel]);

  async function handleSend(e: React.FormEvent) {
    e.preventDefault();
    if (!message.trim() || !activeChannel || !user || !profile) return;

    setSending(true);
    try {
      await sendMessage(activeChannel.id, {
        senderId: user.uid,
        senderName: profile.displayName || user.displayName || "User",
        senderAvatar: profile.displayName?.charAt(0)?.toUpperCase() || "U",
        content: message.trim(),
      });
      setMessage("");
    } catch (err) {
      console.error("Error sending message:", err);
    } finally {
      setSending(false);
    }
  }

  function getChannelName(channel: ChatChannel) {
    if (channel.type === "group") return channel.name;
    if (!user) return "";
    const otherNames = Object.entries(channel.participantNames || {})
      .filter(([id]) => id !== user.uid)
      .map(([, name]) => name);
    return otherNames[0] || "Unknown";
  }

  function getChannelAvatar(channel: ChatChannel) {
    const name = getChannelName(channel);
    return name.charAt(0).toUpperCase();
  }

  return (
    <div className="-mx-4 -my-6 flex h-[calc(100vh-3.5rem)] lg:-mx-8 lg:h-screen">
      {/* Channel list */}
      <div className={`${showChannels ? "flex" : "hidden"} w-full flex-col border-r border-border/50 sm:flex sm:w-80`}>
        <div className="flex items-center justify-between border-b border-border/50 p-4">
          <h2 className="text-lg font-bold">Messages</h2>
          <button onClick={() => setShowNewChat(true)} className="text-muted hover:text-foreground">
            <Plus size={20} />
          </button>
        </div>

        <div className="p-3">
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
            <input type="text" placeholder="Search conversations..." className="w-full rounded-lg border border-border bg-card/50 py-2 pl-9 pr-3 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent" />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {loadingChannels ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 size={24} className="animate-spin text-accent" />
            </div>
          ) : channels.length === 0 ? (
            <div className="px-4 py-8 text-center">
              <p className="text-sm text-muted">No conversations yet</p>
              <button onClick={() => setShowNewChat(true)} className="mt-2 text-xs text-accent hover:underline">
                Start a new chat
              </button>
            </div>
          ) : (
            channels.map((channel) => (
              <button
                key={channel.id}
                onClick={() => { setActiveChannel(channel); setShowChannels(false); }}
                className={`flex w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-card ${
                  activeChannel?.id === channel.id ? "bg-card" : ""
                }`}
              >
                <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-accent/10 text-sm font-bold text-accent">
                  {channel.type === "group" ? <Hash size={18} /> : getChannelAvatar(channel)}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium truncate">{getChannelName(channel)}</span>
                  </div>
                  <p className="text-xs text-muted truncate">{channel.lastMessage || "No messages yet"}</p>
                </div>
              </button>
            ))
          )}
        </div>
      </div>

      {/* Chat area */}
      <div className={`${showChannels ? "hidden" : "flex"} flex-1 flex-col sm:flex`}>
        {activeChannel ? (
          <>
            <div className="flex items-center justify-between border-b border-border/50 px-4 py-3">
              <div className="flex items-center gap-3">
                <button onClick={() => setShowChannels(true)} className="text-muted hover:text-foreground sm:hidden">
                  <ArrowLeft size={20} />
                </button>
                <div className="flex h-9 w-9 items-center justify-center rounded-full bg-accent/10 text-sm font-bold text-accent">
                  {activeChannel.type === "group" ? <Hash size={16} /> : getChannelAvatar(activeChannel)}
                </div>
                <div>
                  <h3 className="text-sm font-semibold">{getChannelName(activeChannel)}</h3>
                  <p className="text-xs text-muted">
                    {activeChannel.participants?.length || 0} participant{(activeChannel.participants?.length || 0) !== 1 ? "s" : ""}
                  </p>
                </div>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              {messages.length === 0 ? (
                <div className="flex h-full items-center justify-center">
                  <p className="text-sm text-muted">No messages yet. Say hello!</p>
                </div>
              ) : (
                messages.map((msg) => {
                  const isOwn = msg.senderId === user?.uid;
                  return (
                    <div key={msg.id} className={`flex gap-3 ${isOwn ? "flex-row-reverse" : ""}`}>
                      <div className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-accent/10 text-xs font-bold text-accent">
                        {msg.senderAvatar || msg.senderName?.charAt(0)?.toUpperCase() || "U"}
                      </div>
                      <div className={`max-w-[70%] ${isOwn ? "text-right" : ""}`}>
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-xs font-medium">{isOwn ? "You" : msg.senderName}</span>
                          <span className="text-xs text-muted">
                            {msg.createdAt && typeof msg.createdAt === "object" && "toDate" in msg.createdAt
                              ? (msg.createdAt as { toDate: () => Date }).toDate().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
                              : ""}
                          </span>
                        </div>
                        <div className={`inline-block rounded-2xl px-4 py-2.5 text-sm ${isOwn ? "bg-accent text-white" : "bg-card border border-border/50"}`}>
                          {msg.content}
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
              <div ref={messagesEndRef} />
            </div>

            <form onSubmit={handleSend} className="border-t border-border/50 p-4">
              <div className="flex items-center gap-3">
                <input
                  type="text"
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder={`Message ${getChannelName(activeChannel)}...`}
                  className="flex-1 rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
                />
                <button
                  type="submit"
                  disabled={!message.trim() || sending}
                  className="flex h-10 w-10 items-center justify-center rounded-xl bg-accent text-white transition-colors hover:bg-accent-hover disabled:opacity-30"
                >
                  {sending ? <Loader2 size={18} className="animate-spin" /> : <Send size={18} />}
                </button>
              </div>
            </form>
          </>
        ) : (
          <div className="flex h-full items-center justify-center">
            <div className="text-center">
              <Hash size={48} className="mx-auto text-muted/20" />
              <p className="mt-4 text-sm text-muted">Select a conversation or start a new one</p>
            </div>
          </div>
        )}
      </div>

      {/* New Chat Modal */}
      {showNewChat && (
        <NewChatModal
          userId={user?.uid || ""}
          userName={profile?.displayName || user?.displayName || "User"}
          onClose={() => setShowNewChat(false)}
          onCreated={(channel) => {
            setShowNewChat(false);
            setActiveChannel(channel);
            setShowChannels(false);
          }}
        />
      )}
    </div>
  );
}

function NewChatModal({
  userId,
  userName,
  onClose,
  onCreated,
}: {
  userId: string;
  userName: string;
  onClose: () => void;
  onCreated: (channel: ChatChannel) => void;
}) {
  const [type, setType] = useState<"dm" | "group">("group");
  const [groupName, setGroupName] = useState("");
  const [creating, setCreating] = useState(false);

  async function handleCreate() {
    if (type === "group" && !groupName.trim()) return;
    setCreating(true);
    try {
      if (type === "group") {
        const id = await createGroupChat(groupName.trim(), userId, [userId], { [userId]: userName });
        onCreated({
          id,
          type: "group",
          name: groupName.trim(),
          participants: [userId],
          participantNames: { [userId]: userName },
          lastMessage: "",
          lastMessageAt: new Date(),
          createdBy: userId,
          createdAt: new Date(),
        });
      }
    } catch (err) {
      console.error("Error creating chat:", err);
    } finally {
      setCreating(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div className="relative w-full max-w-md rounded-2xl border border-border/50 bg-background p-6">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold">New Conversation</h2>
          <button onClick={onClose} className="text-muted hover:text-foreground"><X size={20} /></button>
        </div>

        <div className="mt-4 space-y-4">
          <div>
            <label className="mb-1.5 block text-sm font-medium">Group Name</label>
            <input
              type="text"
              value={groupName}
              onChange={(e) => setGroupName(e.target.value)}
              placeholder="e.g. JDM Crew"
              className="w-full rounded-xl border border-border bg-card/50 px-4 py-2.5 text-sm outline-none focus:border-accent"
            />
          </div>
        </div>

        <div className="mt-6 flex justify-end gap-3">
          <button onClick={onClose} className="rounded-xl px-4 py-2.5 text-sm font-medium text-muted hover:text-foreground">Cancel</button>
          <button
            onClick={handleCreate}
            disabled={creating || !groupName.trim()}
            className="flex items-center gap-2 rounded-xl bg-accent px-6 py-2.5 text-sm font-medium text-white disabled:opacity-50"
          >
            {creating ? <Loader2 size={16} className="animate-spin" /> : "Create"}
          </button>
        </div>
      </div>
    </div>
  );
}
