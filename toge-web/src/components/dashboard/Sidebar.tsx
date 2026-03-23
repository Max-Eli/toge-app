"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Home,
  Car,
  Image,
  MessageCircle,
  PlayCircle,
  MapPin,
  ShoppingBag,
  Users,
  User,
  Settings,
  LogOut,
  Menu,
  X,
} from "lucide-react";
import { useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { useRouter } from "next/navigation";

const navItems = [
  { href: "/dashboard", label: "Feed", icon: Home },
  { href: "/dashboard/garage", label: "Garage", icon: Car },
  { href: "/dashboard/explore", label: "Explore", icon: Image },
  { href: "/dashboard/communities", label: "Communities", icon: Users },
  { href: "/dashboard/chat", label: "Chat", icon: MessageCircle },
  { href: "/dashboard/videos", label: "How-To", icon: PlayCircle },
  { href: "/dashboard/events", label: "Events", icon: MapPin },
  { href: "/dashboard/marketplace", label: "Market", icon: ShoppingBag },
];

const bottomItems = [
  { href: "/dashboard/profile", label: "Profile", icon: User },
  { href: "/dashboard/settings", label: "Settings", icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);
  const { signOut } = useAuth();
  const router = useRouter();

  async function handleSignOut() {
    await signOut();
    router.push("/");
  }

  function NavContent() {
    return (
      <div className="flex h-full flex-col">
        {/* Logo */}
        <div className="px-6 py-6">
          <Link href="/dashboard" onClick={() => setMobileOpen(false)}>
            <span className="text-xl font-bold tracking-tight">
              峠 <span className="text-accent">TŌGE</span>
            </span>
          </Link>
        </div>

        {/* Main nav */}
        <nav className="flex-1 space-y-1 px-3">
          {navItems.map((item) => {
            const isActive =
              pathname === item.href ||
              (item.href !== "/dashboard" && pathname.startsWith(item.href));

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setMobileOpen(false)}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${
                  isActive
                    ? "bg-accent/10 text-accent"
                    : "text-muted hover:bg-card hover:text-foreground"
                }`}
              >
                <item.icon size={20} />
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* Bottom nav */}
        <div className="border-t border-border/50 px-3 py-4 space-y-1">
          {bottomItems.map((item) => {
            const isActive = pathname === item.href;

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setMobileOpen(false)}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${
                  isActive
                    ? "bg-accent/10 text-accent"
                    : "text-muted hover:bg-card hover:text-foreground"
                }`}
              >
                <item.icon size={20} />
                {item.label}
              </Link>
            );
          })}
          <button
            onClick={handleSignOut}
            className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-muted transition-colors hover:bg-card hover:text-foreground"
          >
            <LogOut size={20} />
            Log out
          </button>
        </div>
      </div>
    );
  }

  return (
    <>
      {/* Desktop sidebar */}
      <aside className="hidden w-64 flex-shrink-0 border-r border-border/50 bg-background lg:block">
        <div className="sticky top-0 h-screen overflow-y-auto">
          <NavContent />
        </div>
      </aside>

      {/* Mobile top bar */}
      <div className="fixed top-0 left-0 right-0 z-50 flex h-14 items-center justify-between border-b border-border/50 bg-background/80 px-4 backdrop-blur-xl lg:hidden">
        <Link href="/dashboard">
          <span className="text-lg font-bold tracking-tight">
            峠 <span className="text-accent">TŌGE</span>
          </span>
        </Link>
        <button
          onClick={() => setMobileOpen(!mobileOpen)}
          className="text-muted hover:text-foreground"
        >
          {mobileOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {/* Mobile drawer */}
      {mobileOpen && (
        <>
          <div
            className="fixed inset-0 z-40 bg-black/60 lg:hidden"
            onClick={() => setMobileOpen(false)}
          />
          <aside className="fixed top-0 left-0 z-50 h-screen w-64 border-r border-border/50 bg-background lg:hidden">
            <NavContent />
          </aside>
        </>
      )}
    </>
  );
}
