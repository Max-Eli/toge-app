"use client";

import { motion } from "framer-motion";
import {
  Car,
  Camera,
  MessageCircle,
  PlayCircle,
  MapPin,
  ShoppingBag,
} from "lucide-react";

const features = [
  {
    icon: Car,
    title: "Your Garage",
    description:
      "Showcase your builds with full specs, mod lists, and build timelines. Track every bolt-on and upgrade.",
  },
  {
    icon: Camera,
    title: "Share Your Build",
    description:
      "Post photos and videos of your ride. Get love from the community with likes, comments, and shares.",
  },
  {
    icon: MessageCircle,
    title: "Community Chats",
    description:
      "Join communities for your make and model. Talk shop, get advice, and connect with local enthusiasts.",
  },
  {
    icon: PlayCircle,
    title: "How-To Videos",
    description:
      "Learn from the community. Step-by-step tutorials for installs, maintenance, and builds.",
  },
  {
    icon: MapPin,
    title: "Meets & Events",
    description:
      "Discover and organize local car meets, track days, and cruises. RSVP and see who's pulling up.",
  },
  {
    icon: ShoppingBag,
    title: "Parts Marketplace",
    description:
      "Buy and sell parts directly with other enthusiasts. No dealer markups, no sketchy listings.",
  },
];

export default function Features() {
  return (
    <section id="features" className="relative px-6 py-32">
      {/* Background accent */}
      <div className="pointer-events-none absolute top-0 left-1/2 h-px w-2/3 -translate-x-1/2 bg-gradient-to-r from-transparent via-border to-transparent" />

      <div className="mx-auto max-w-7xl">
        {/* Section header */}
        <motion.div
          className="text-center"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
        >
          <span className="text-sm font-medium text-accent">Features</span>
          <h2 className="mt-3 font-[family-name:var(--font-heading)] text-3xl font-extrabold tracking-tight sm:text-5xl">
            Everything car culture needs
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-muted">
            One platform for your entire car life. No more bouncing between
            Instagram, forums, Facebook groups, and Craigslist.
          </p>
        </motion.div>

        {/* Feature grid */}
        <div className="mt-16 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, i) => (
            <motion.div
              key={feature.title}
              className="group rounded-2xl border border-border/50 bg-card/50 p-8 backdrop-blur-sm transition-all hover:border-border hover:bg-card"
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.4, delay: i * 0.1 }}
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-accent/10 text-accent transition-colors group-hover:bg-accent/20">
                <feature.icon size={24} />
              </div>
              <h3 className="mt-5 text-lg font-semibold">{feature.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-muted">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
