"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { ArrowRight } from "lucide-react";

export default function CTA() {
  return (
    <section className="relative px-6 py-32">
      <div className="pointer-events-none absolute top-0 left-1/2 h-px w-2/3 -translate-x-1/2 bg-gradient-to-r from-transparent via-border to-transparent" />

      <motion.div
        className="mx-auto max-w-4xl text-center"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.5 }}
      >
        {/* Background glow */}
        <div className="pointer-events-none absolute left-1/2 top-1/2 h-[300px] w-[500px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-accent/8 blur-[100px]" />

        <div className="relative">
          <h2 className="font-[family-name:var(--font-heading)] text-3xl font-extrabold tracking-tight sm:text-5xl">
            Ready to join the
            <span className="bg-gradient-to-r from-accent to-orange-400 bg-clip-text text-transparent">
              {" "}community
            </span>
            ?
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-muted">
            Your build deserves a proper home. Join thousands of enthusiasts
            sharing, connecting, and building together on Tōge.
          </p>

          <div className="mt-10 flex flex-col items-center gap-4 sm:flex-row sm:justify-center">
            <Link
              href="/signup"
              className="group flex items-center gap-2 rounded-lg bg-accent px-8 py-3.5 text-sm font-medium text-white transition-all hover:bg-accent-hover hover:gap-3"
            >
              Create Your Account
              <ArrowRight
                size={16}
                className="transition-transform group-hover:translate-x-0.5"
              />
            </Link>
          </div>

          <p className="mt-4 text-xs text-muted">
            Free to join. No credit card required.
          </p>
        </div>
      </motion.div>
    </section>
  );
}
