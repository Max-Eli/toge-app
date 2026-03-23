"use client";

import Link from "next/link";
import { ReactNode, useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";

const carImages = [
  {
    url: "https://images.unsplash.com/photo-1632245889029-e406faaa34cd?q=80&w=2070&auto=format&fit=crop",
    caption: "Share your build story",
  },
  {
    url: "https://images.unsplash.com/photo-1611651338412-8403fa6e3599?q=80&w=2070&auto=format&fit=crop",
    caption: "Connect with enthusiasts",
  },
  {
    url: "https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?q=80&w=2070&auto=format&fit=crop",
    caption: "Discover local meets",
  },
  {
    url: "https://images.unsplash.com/photo-1619405399517-d7fce0f13302?q=80&w=2070&auto=format&fit=crop",
    caption: "Find the parts you need",
  },
  {
    url: "https://images.unsplash.com/photo-1580274455191-1c62238ce452?q=80&w=2070&auto=format&fit=crop",
    caption: "Built by enthusiasts, for enthusiasts",
  },
];

export default function AuthLayout({ children }: { children: ReactNode }) {
  const [current, setCurrent] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrent((prev) => (prev + 1) % carImages.length);
    }, 5000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="flex min-h-screen">
      {/* Left side — slideshow panel (hidden on mobile) */}
      <div className="relative hidden w-1/2 overflow-hidden lg:block">
        {/* Slideshow images */}
        <AnimatePresence mode="wait">
          <motion.div
            key={current}
            className="absolute inset-0 bg-cover bg-center"
            style={{ backgroundImage: `url('${carImages[current].url}')` }}
            initial={{ opacity: 0, scale: 1.1 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 1, ease: "easeInOut" }}
          />
        </AnimatePresence>

        {/* Dark overlay with gradient */}
        <div className="absolute inset-0 bg-gradient-to-t from-black via-black/70 to-black/40" />

        {/* Grid pattern */}
        <div
          className="absolute inset-0 opacity-[0.05]"
          style={{
            backgroundImage: `linear-gradient(rgba(255,255,255,0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.3) 1px, transparent 1px)`,
            backgroundSize: "48px 48px",
          }}
        />

        {/* Content */}
        <div className="relative z-10 flex h-full flex-col justify-between p-12">
          {/* Logo */}
          <Link href="/">
            <span className="text-2xl font-bold tracking-tight">
              峠 <span className="text-accent">TŌGE</span>
            </span>
          </Link>

          {/* Bottom content */}
          <div>
            <AnimatePresence mode="wait">
              <motion.h2
                key={current}
                className="text-4xl font-bold leading-tight tracking-tight"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.5 }}
              >
                {carImages[current].caption}
              </motion.h2>
            </AnimatePresence>

            <p className="mt-4 max-w-md text-sm leading-relaxed text-zinc-400">
              Join thousands of enthusiasts sharing builds, connecting with
              communities, and discovering the best parts and meets near you.
            </p>

            {/* Slide indicators */}
            <div className="mt-8 flex items-center gap-2">
              {carImages.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setCurrent(i)}
                  className={`h-1 rounded-full transition-all duration-500 ${
                    i === current
                      ? "w-8 bg-accent"
                      : "w-2 bg-zinc-600 hover:bg-zinc-500"
                  }`}
                />
              ))}
            </div>

            {/* Stats */}
            <div className="mt-6 flex items-center gap-6">
              {[
                { value: "10K+", label: "Builders" },
                { value: "50+", label: "Communities" },
                { value: "5K+", label: "Parts" },
              ].map((stat) => (
                <div key={stat.label}>
                  <div className="text-lg font-bold">{stat.value}</div>
                  <div className="text-xs text-zinc-500">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Right side — form */}
      <div className="flex w-full flex-col items-center justify-center px-6 lg:w-1/2">
        {/* Mobile logo */}
        <div className="mb-8 lg:hidden">
          <Link href="/">
            <span className="text-2xl font-bold tracking-tight">
              峠 <span className="text-accent">TŌGE</span>
            </span>
          </Link>
        </div>

        <div className="w-full max-w-md">{children}</div>
      </div>
    </div>
  );
}
