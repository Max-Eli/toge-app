"use client";

import { useState } from "react";
import Link from "next/link";
import { Menu, X } from "lucide-react";

export default function Navbar() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 border-b border-border/50 bg-background/80 backdrop-blur-xl">
      <div className="mx-auto max-w-7xl px-6">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <span className="text-xl font-bold tracking-tight">
              峠 <span className="text-accent">TŌGE</span>
            </span>
          </Link>

          {/* Desktop Nav */}
          <div className="hidden items-center gap-8 md:flex">
            <a href="#features" className="text-sm text-muted transition-colors hover:text-foreground">
              Features
            </a>
            <a href="#community" className="text-sm text-muted transition-colors hover:text-foreground">
              Community
            </a>
            <a href="#marketplace" className="text-sm text-muted transition-colors hover:text-foreground">
              Marketplace
            </a>
          </div>

          {/* CTA */}
          <div className="hidden items-center gap-4 md:flex">
            <Link
              href="/login"
              className="text-sm text-muted transition-colors hover:text-foreground"
            >
              Log in
            </Link>
            <Link
              href="/signup"
              className="rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-accent-hover"
            >
              Get Started
            </Link>
          </div>

          {/* Mobile menu button */}
          <button
            onClick={() => setIsOpen(!isOpen)}
            className="md:hidden text-muted hover:text-foreground"
          >
            {isOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>

        {/* Mobile Nav */}
        {isOpen && (
          <div className="border-t border-border/50 py-4 md:hidden">
            <div className="flex flex-col gap-4">
              <a
                href="#features"
                onClick={() => setIsOpen(false)}
                className="text-sm text-muted transition-colors hover:text-foreground"
              >
                Features
              </a>
              <a
                href="#community"
                onClick={() => setIsOpen(false)}
                className="text-sm text-muted transition-colors hover:text-foreground"
              >
                Community
              </a>
              <a
                href="#marketplace"
                onClick={() => setIsOpen(false)}
                className="text-sm text-muted transition-colors hover:text-foreground"
              >
                Marketplace
              </a>
              <div className="flex flex-col gap-2 pt-4 border-t border-border/50">
                <Link href="/login" className="text-sm text-muted hover:text-foreground">
                  Log in
                </Link>
                <Link
                  href="/signup"
                  className="rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white text-center hover:bg-accent-hover"
                >
                  Get Started
                </Link>
              </div>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}
