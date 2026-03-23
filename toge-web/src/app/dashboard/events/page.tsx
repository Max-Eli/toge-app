"use client";

import { useState, useEffect, useRef, useMemo } from "react";
import {
  Search,
  MapPin,
  Calendar,
  Users,
  Plus,
  Clock,
  Filter,
  ChevronRight,
  X,
  ImagePlus,
  Loader2,
  CalendarOff,
  Check,
} from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import {
  getEvents,
  createEvent,
  rsvpEvent,
  cancelRsvp,
  isAttending,
  type CarEvent,
} from "@/services/events";

const eventCategories = [
  "All",
  "Cars & Coffee",
  "Track Day",
  "Cruise",
  "Show & Shine",
  "Drift",
  "Auction",
];

interface EventForm {
  title: string;
  description: string;
  date: string;
  time: string;
  location: string;
  address: string;
  category: string;
  maxAttendees: string;
}

const emptyForm: EventForm = {
  title: "",
  description: "",
  date: "",
  time: "",
  location: "",
  address: "",
  category: "Cars & Coffee",
  maxAttendees: "50",
};

export default function EventsPage() {
  const { user } = useAuth();
  const [events, setEvents] = useState<CarEvent[]>([]);
  const [attendingMap, setAttendingMap] = useState<Record<string, boolean>>({});
  const [rsvpLoading, setRsvpLoading] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const [activeCategory, setActiveCategory] = useState("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState<EventForm>(emptyForm);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Fetch events
  useEffect(() => {
    async function load() {
      try {
        const data = await getEvents();
        setEvents(data);

        // Check attending status for each event
        if (user) {
          const checks = await Promise.all(
            data.map((e) => isAttending(e.id, user.uid))
          );
          const map: Record<string, boolean> = {};
          data.forEach((e, i) => {
            map[e.id] = checks[i];
          });
          setAttendingMap(map);
        }
      } catch (err) {
        console.error("Failed to load events:", err);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [user]);

  // Filter + search
  const filtered = useMemo(() => {
    let result = events;
    if (activeCategory !== "All") {
      result = result.filter((e) => e.category === activeCategory);
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        (e) =>
          e.title.toLowerCase().includes(q) ||
          e.location.toLowerCase().includes(q) ||
          e.category.toLowerCase().includes(q)
      );
    }
    return result;
  }, [events, activeCategory, searchQuery]);

  // Handle image pick
  function handleImagePick(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    const reader = new FileReader();
    reader.onloadend = () => setImagePreview(reader.result as string);
    reader.readAsDataURL(file);
  }

  // Create event
  async function handleCreate() {
    if (!user) return;
    if (!form.title || !form.date || !form.time || !form.location) return;
    setCreating(true);
    try {
      await createEvent(
        {
          title: form.title,
          description: form.description,
          date: form.date,
          time: form.time,
          location: form.location,
          address: form.address,
          category: form.category,
          organizerId: user.uid,
          organizerName: user.displayName || "Anonymous",
          maxAttendees: parseInt(form.maxAttendees) || 50,
        },
        imageFile || undefined
      );

      // Refresh events
      const data = await getEvents();
      setEvents(data);
      const checks = await Promise.all(
        data.map((e) => isAttending(e.id, user.uid))
      );
      const map: Record<string, boolean> = {};
      data.forEach((e, i) => {
        map[e.id] = checks[i];
      });
      setAttendingMap(map);

      // Reset
      setShowModal(false);
      setForm(emptyForm);
      setImageFile(null);
      setImagePreview(null);
    } catch (err) {
      console.error("Failed to create event:", err);
    } finally {
      setCreating(false);
    }
  }

  // RSVP / Cancel
  async function handleRsvp(eventId: string) {
    if (!user) return;
    setRsvpLoading((prev) => ({ ...prev, [eventId]: true }));
    try {
      const attending = attendingMap[eventId];
      if (attending) {
        await cancelRsvp(eventId, user.uid);
        setAttendingMap((prev) => ({ ...prev, [eventId]: false }));
        setEvents((prev) =>
          prev.map((e) =>
            e.id === eventId
              ? { ...e, attendeeCount: Math.max(0, e.attendeeCount - 1) }
              : e
          )
        );
      } else {
        await rsvpEvent(eventId, {
          userId: user.uid,
          userName: user.displayName || "Anonymous",
          userAvatar: user.photoURL || "",
        });
        setAttendingMap((prev) => ({ ...prev, [eventId]: true }));
        setEvents((prev) =>
          prev.map((e) =>
            e.id === eventId
              ? { ...e, attendeeCount: e.attendeeCount + 1 }
              : e
          )
        );
      }
    } catch (err) {
      console.error("RSVP error:", err);
    } finally {
      setRsvpLoading((prev) => ({ ...prev, [eventId]: false }));
    }
  }

  // Format date for display
  function formatDate(dateStr: string) {
    try {
      const d = new Date(dateStr + "T00:00:00");
      return d.toLocaleDateString("en-US", {
        weekday: "short",
        month: "short",
        day: "numeric",
      });
    } catch {
      return dateStr;
    }
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Events & Meets</h1>
          <p className="text-sm text-muted">
            Discover and organize car events near you
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 rounded-xl bg-accent px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-accent-hover"
        >
          <Plus size={18} />
          Create Event
        </button>
      </div>

      {/* Search */}
      <div className="mb-4 flex gap-3">
        <div className="relative flex-1">
          <Search
            size={18}
            className="absolute left-4 top-1/2 -translate-y-1/2 text-muted"
          />
          <input
            type="text"
            placeholder="Search events..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-xl border border-border bg-card/50 py-3 pl-11 pr-4 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
          />
        </div>
        <button className="flex items-center gap-2 rounded-xl border border-border bg-card/50 px-4 text-sm text-muted hover:bg-card hover:text-foreground">
          <Filter size={18} />
        </button>
      </div>

      {/* Categories */}
      <div className="mb-6 flex gap-2 overflow-x-auto pb-2">
        {eventCategories.map((cat) => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`flex-shrink-0 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
              activeCategory === cat
                ? "bg-accent text-white"
                : "bg-card/50 text-muted hover:bg-card hover:text-foreground"
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Loading state */}
      {loading && (
        <div className="flex flex-col items-center justify-center py-24">
          <Loader2 size={32} className="animate-spin text-accent" />
          <p className="mt-3 text-sm text-muted">Loading events...</p>
        </div>
      )}

      {/* Empty state */}
      {!loading && filtered.length === 0 && (
        <div className="flex flex-col items-center justify-center py-24">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-card/30 border border-border/50">
            <CalendarOff size={28} className="text-muted" />
          </div>
          <h3 className="mt-4 text-lg font-semibold">No events found</h3>
          <p className="mt-1 text-sm text-muted">
            {searchQuery || activeCategory !== "All"
              ? "Try adjusting your filters or search query."
              : "Be the first to create an event for the community."}
          </p>
          {!searchQuery && activeCategory === "All" && (
            <button
              onClick={() => setShowModal(true)}
              className="mt-5 flex items-center gap-2 rounded-xl bg-accent px-5 py-2.5 text-sm font-medium text-white transition-colors hover:bg-accent-hover"
            >
              <Plus size={16} />
              Create Event
            </button>
          )}
        </div>
      )}

      {/* Events list */}
      {!loading && filtered.length > 0 && (
        <div className="space-y-4">
          {filtered.map((event) => (
            <div
              key={event.id}
              className="group cursor-pointer overflow-hidden rounded-2xl border border-border/50 bg-card/30 transition-all hover:border-border hover:bg-card/50"
            >
              <div className="flex flex-col sm:flex-row">
                {/* Image */}
                <div className="relative h-48 w-full overflow-hidden sm:h-auto sm:w-64 flex-shrink-0">
                  {event.imageURL ? (
                    <img
                      src={event.imageURL}
                      alt={event.title}
                      className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                    />
                  ) : (
                    <div className="flex h-full min-h-[12rem] w-full items-center justify-center bg-card/50">
                      <Calendar size={36} className="text-muted/30" />
                    </div>
                  )}
                  <div className="absolute top-3 left-3">
                    <span className="rounded-lg bg-black/70 px-2.5 py-1 text-xs font-medium backdrop-blur-sm">
                      {event.category}
                    </span>
                  </div>
                </div>

                {/* Info */}
                <div className="flex flex-1 flex-col justify-between p-5">
                  <div>
                    <h3 className="text-lg font-semibold">{event.title}</h3>
                    <p className="mt-1 text-xs text-muted">
                      Hosted by {event.organizerName}
                    </p>

                    {event.description && (
                      <p className="mt-2 text-sm text-muted line-clamp-2">
                        {event.description}
                      </p>
                    )}

                    <div className="mt-4 space-y-2">
                      <div className="flex items-center gap-2 text-sm text-muted">
                        <Calendar size={15} className="text-accent" />
                        {formatDate(event.date)}
                      </div>
                      <div className="flex items-center gap-2 text-sm text-muted">
                        <Clock size={15} className="text-accent" />
                        {event.time}
                      </div>
                      <div className="flex items-center gap-2 text-sm text-muted">
                        <MapPin size={15} className="text-accent" />
                        {event.location}
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 flex items-center justify-between">
                    <div className="flex items-center gap-2 text-sm text-muted">
                      <Users size={15} />
                      {event.attendeeCount}/{event.maxAttendees} going
                    </div>
                    <button
                      disabled={rsvpLoading[event.id]}
                      onClick={() => handleRsvp(event.id)}
                      className={`flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50 ${
                        attendingMap[event.id]
                          ? "bg-accent/10 text-accent"
                          : "bg-accent text-white hover:bg-accent-hover"
                      }`}
                    >
                      {rsvpLoading[event.id] ? (
                        <Loader2 size={14} className="animate-spin" />
                      ) : attendingMap[event.id] ? (
                        <>
                          <Check size={14} />
                          Going
                        </>
                      ) : (
                        <>
                          RSVP
                          <ChevronRight size={14} />
                        </>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Event Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => !creating && setShowModal(false)}
          />

          {/* Modal */}
          <div className="relative w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl border border-border/50 bg-background p-6">
            {/* Close */}
            <button
              onClick={() => !creating && setShowModal(false)}
              className="absolute right-4 top-4 rounded-lg p-1 text-muted hover:bg-card hover:text-foreground"
            >
              <X size={20} />
            </button>

            <h2 className="text-xl font-bold">Create Event</h2>
            <p className="mt-1 text-sm text-muted">
              Set up a new car event for the community.
            </p>

            <div className="mt-6 space-y-4">
              {/* Image upload */}
              <div>
                <label className="mb-1.5 block text-sm font-medium text-muted">
                  Cover Image
                </label>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={handleImagePick}
                />
                {imagePreview ? (
                  <div className="relative h-40 overflow-hidden rounded-xl border border-border/50">
                    <img
                      src={imagePreview}
                      alt="Preview"
                      className="h-full w-full object-cover"
                    />
                    <button
                      onClick={() => {
                        setImageFile(null);
                        setImagePreview(null);
                      }}
                      className="absolute right-2 top-2 rounded-lg bg-black/60 p-1 text-white hover:bg-black/80"
                    >
                      <X size={16} />
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => fileInputRef.current?.click()}
                    className="flex h-40 w-full flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-border/50 bg-card/30 text-muted transition-colors hover:border-accent hover:text-accent"
                  >
                    <ImagePlus size={28} />
                    <span className="text-sm">Click to upload</span>
                  </button>
                )}
              </div>

              {/* Title */}
              <div>
                <label className="mb-1.5 block text-sm font-medium text-muted">
                  Title *
                </label>
                <input
                  type="text"
                  placeholder="e.g. SoCal JDM Cars & Coffee"
                  value={form.title}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, title: e.target.value }))
                  }
                  className="w-full rounded-xl border border-border/50 bg-card/30 px-4 py-3 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
                />
              </div>

              {/* Description */}
              <div>
                <label className="mb-1.5 block text-sm font-medium text-muted">
                  Description
                </label>
                <textarea
                  rows={3}
                  placeholder="Tell people what this event is about..."
                  value={form.description}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, description: e.target.value }))
                  }
                  className="w-full rounded-xl border border-border/50 bg-card/30 px-4 py-3 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent resize-none"
                />
              </div>

              {/* Date + Time */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-muted">
                    Date *
                  </label>
                  <input
                    type="date"
                    value={form.date}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, date: e.target.value }))
                    }
                    className="w-full rounded-xl border border-border/50 bg-card/30 px-4 py-3 text-sm text-foreground outline-none focus:border-accent"
                  />
                </div>
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-muted">
                    Time *
                  </label>
                  <input
                    type="text"
                    placeholder="8:00 AM - 12:00 PM"
                    value={form.time}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, time: e.target.value }))
                    }
                    className="w-full rounded-xl border border-border/50 bg-card/30 px-4 py-3 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
                  />
                </div>
              </div>

              {/* Location */}
              <div>
                <label className="mb-1.5 block text-sm font-medium text-muted">
                  Location *
                </label>
                <input
                  type="text"
                  placeholder="e.g. Irwindale Speedway, CA"
                  value={form.location}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, location: e.target.value }))
                  }
                  className="w-full rounded-xl border border-border/50 bg-card/30 px-4 py-3 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
                />
              </div>

              {/* Address */}
              <div>
                <label className="mb-1.5 block text-sm font-medium text-muted">
                  Address
                </label>
                <input
                  type="text"
                  placeholder="Full street address"
                  value={form.address}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, address: e.target.value }))
                  }
                  className="w-full rounded-xl border border-border/50 bg-card/30 px-4 py-3 text-sm text-foreground placeholder-muted/50 outline-none focus:border-accent"
                />
              </div>

              {/* Category + Max Attendees */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-muted">
                    Category
                  </label>
                  <select
                    value={form.category}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, category: e.target.value }))
                    }
                    className="w-full rounded-xl border border-border/50 bg-card/30 px-4 py-3 text-sm text-foreground outline-none focus:border-accent"
                  >
                    {eventCategories.slice(1).map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-muted">
                    Max Attendees
                  </label>
                  <input
                    type="number"
                    min="2"
                    value={form.maxAttendees}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, maxAttendees: e.target.value }))
                    }
                    className="w-full rounded-xl border border-border/50 bg-card/30 px-4 py-3 text-sm text-foreground outline-none focus:border-accent"
                  />
                </div>
              </div>

              {/* Submit */}
              <button
                onClick={handleCreate}
                disabled={
                  creating ||
                  !form.title ||
                  !form.date ||
                  !form.time ||
                  !form.location
                }
                className="mt-2 flex w-full items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-white transition-colors hover:bg-accent-hover disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {creating ? (
                  <>
                    <Loader2 size={16} className="animate-spin" />
                    Creating...
                  </>
                ) : (
                  <>
                    <Plus size={16} />
                    Create Event
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
