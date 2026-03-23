"use client";

import { motion } from "framer-motion";
import { Shield, Search, MessageSquare, Tag } from "lucide-react";

const listings = [
  {
    title: "Tomei Expreme Ti Exhaust",
    car: "Nissan 350Z",
    price: "$850",
    condition: "Used",
    location: "Los Angeles, CA",
  },
  {
    title: "Bride Zeta III Seat",
    car: "Universal",
    price: "$1,200",
    condition: "New",
    location: "Houston, TX",
  },
  {
    title: "BC Racing Coilovers BR Series",
    car: "Honda Civic EK",
    price: "$680",
    condition: "Used",
    location: "Miami, FL",
  },
];

export default function Marketplace() {
  return (
    <section id="marketplace" className="relative px-6 py-32">
      <div className="pointer-events-none absolute top-0 left-1/2 h-px w-2/3 -translate-x-1/2 bg-gradient-to-r from-transparent via-border to-transparent" />

      <div className="mx-auto max-w-7xl">
        <div className="grid items-center gap-16 lg:grid-cols-2">
          {/* Left: listing previews */}
          <motion.div
            className="order-2 space-y-3 lg:order-1"
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            {listings.map((listing, i) => (
              <motion.div
                key={listing.title}
                className="group flex items-center gap-4 rounded-xl border border-border/50 bg-card/50 p-4 backdrop-blur-sm transition-all hover:border-border hover:bg-card"
                initial={{ opacity: 0, x: -10 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.3, delay: 0.1 * i }}
              >
                {/* Placeholder image */}
                <div className="flex h-16 w-16 flex-shrink-0 items-center justify-center rounded-lg bg-accent/10">
                  <Tag size={20} className="text-accent" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-medium truncate">
                    {listing.title}
                  </div>
                  <div className="mt-0.5 text-xs text-muted">
                    {listing.car} · {listing.condition} · {listing.location}
                  </div>
                </div>
                <div className="text-sm font-bold text-accent">
                  {listing.price}
                </div>
              </motion.div>
            ))}
          </motion.div>

          {/* Right: text */}
          <motion.div
            className="order-1 lg:order-2"
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
          >
            <span className="text-sm font-medium text-accent">Marketplace</span>
            <h2 className="mt-3 font-[family-name:var(--font-heading)] text-3xl font-extrabold tracking-tight sm:text-5xl">
              Parts, direct from enthusiasts
            </h2>
            <p className="mt-4 max-w-lg text-muted">
              Skip the dealer markup. Buy and sell parts directly with other
              builders. Filter by make, model, and category to find exactly
              what your build needs.
            </p>

            <div className="mt-8 grid grid-cols-2 gap-4">
              {[
                {
                  icon: Search,
                  title: "Smart Search",
                  desc: "Filter by car, category, and location",
                },
                {
                  icon: MessageSquare,
                  title: "Direct Chat",
                  desc: "Message sellers instantly",
                },
                {
                  icon: Shield,
                  title: "Verified Sellers",
                  desc: "Community reputation system",
                },
                {
                  icon: Tag,
                  title: "Fair Pricing",
                  desc: "No hidden fees or markups",
                },
              ].map((item) => (
                <div key={item.title} className="flex items-start gap-3">
                  <item.icon size={18} className="mt-0.5 text-accent flex-shrink-0" />
                  <div>
                    <div className="text-sm font-medium">{item.title}</div>
                    <div className="text-xs text-muted">{item.desc}</div>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
