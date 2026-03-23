"use client";

import { motion } from "framer-motion";

const communities = [
  { name: "JDM Legends", members: "12.4K", tag: "jdm" },
  { name: "Euro Gang", members: "8.7K", tag: "euro" },
  { name: "Muscle & Pony", members: "6.2K", tag: "american" },
  { name: "Stance Nation", members: "9.1K", tag: "stance" },
  { name: "Track Rats", members: "4.8K", tag: "track" },
  { name: "Overland & Off-Road", members: "5.3K", tag: "offroad" },
];

export default function Community() {
  return (
    <section id="community" className="relative px-6 py-32">
      <div className="pointer-events-none absolute top-0 left-1/2 h-px w-2/3 -translate-x-1/2 bg-gradient-to-r from-transparent via-border to-transparent" />

      <div className="mx-auto max-w-7xl">
        <div className="grid items-center gap-16 lg:grid-cols-2">
          {/* Left: text */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
          >
            <span className="text-sm font-medium text-accent">Community</span>
            <h2 className="mt-3 font-[family-name:var(--font-heading)] text-3xl font-extrabold tracking-tight sm:text-5xl">
              Find your crew
            </h2>
            <p className="mt-4 max-w-lg text-muted">
              Whether you&apos;re into JDM, Euro, American muscle, or anything
              in between — there&apos;s a community waiting for you. Real
              conversations with real enthusiasts.
            </p>

            <div className="mt-8 space-y-3">
              {[
                "Join communities by make, model, or interest",
                "Real-time group chats and direct messages",
                "Share photos, videos, and build updates",
                "Local and regional car communities",
              ].map((item) => (
                <div key={item} className="flex items-center gap-3">
                  <div className="h-1.5 w-1.5 rounded-full bg-accent" />
                  <span className="text-sm text-muted">{item}</span>
                </div>
              ))}
            </div>
          </motion.div>

          {/* Right: community cards */}
          <motion.div
            className="grid grid-cols-2 gap-3"
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            {communities.map((community, i) => (
              <motion.div
                key={community.name}
                className="group rounded-xl border border-border/50 bg-card/50 p-5 backdrop-blur-sm transition-all hover:border-accent/30 hover:bg-card"
                initial={{ opacity: 0, scale: 0.95 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.3, delay: 0.1 * i }}
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-accent/10 text-xs font-bold text-accent uppercase">
                    {community.tag.slice(0, 2)}
                  </div>
                  <div>
                    <div className="text-sm font-medium">{community.name}</div>
                    <div className="text-xs text-muted">
                      {community.members} members
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </div>
    </section>
  );
}
