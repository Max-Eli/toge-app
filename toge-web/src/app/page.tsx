import Navbar from "@/components/landing/Navbar";
import Hero from "@/components/landing/Hero";
import Features from "@/components/landing/Features";
import Community from "@/components/landing/Community";
import Marketplace from "@/components/landing/Marketplace";
import CTA from "@/components/landing/CTA";
import Footer from "@/components/landing/Footer";

export default function Home() {
  return (
    <>
      <Navbar />
      <Hero />
      <Features />
      <Community />
      <Marketplace />
      <CTA />
      <Footer />
    </>
  );
}
